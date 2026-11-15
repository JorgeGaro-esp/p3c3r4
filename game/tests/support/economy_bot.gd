class_name EconomyBot
extends RefCounted
## Jugador automático «mixto» para medir la economía (Fase 16.1).
##
## Juega con el servicio `Game` real, paso a paso: cada [constant VISIT_SECONDS] mira
## la pecera como lo haría una persona que vuelve de vez en cuando: cobra una parte
## de las perlas, da de comer, limpia y compra lo que mejor se amortiza. Registra
## cuánto tarda en llegar a cada hito. Es determinista (misma semilla, mismo resultado).

## Paso de simulación del bot (la partida real usa 0,1 s; 1 s basta para medir y es 10× más rápido).
const STEP: float = 1.0
## Cada cuánto «mira» el jugador la pecera, en segundos.
const VISIT_SECONDS: float = 120.0
## Fracción de perlas que se cobra (las demás se pierden por no estar mirando).
const PEARL_CATCH: float = 0.3
## Saciedad por debajo de la que da de comer, y limpieza por debajo de la que limpia.
const FEED_BELOW: float = 70.0
const CLEAN_BELOW: float = 70.0
## Peces mínimos en la pecera actual antes de abrir la siguiente.
const FISH_BEFORE_NEXT_TANK: int = 12
## Máximo de peces de una especie que compra para llenar (el resto: variedad).
const MAX_PER_SPECIES: int = 14
## Cambia un pez por otro solo si el nuevo produce al menos tanto más.
const SWAP_RATIO: float = 3.0
## Huecos que deja libres en la pecera para que sigan poniéndose huevos.
const FREE_SLOTS: int = 4
## Peces normales que conserva de cada una de las especies que más producen.
const KEEP_TOP: int = 8

## Hitos: nombre → segundos de juego en que se alcanzó por primera vez.
var milestones: Dictionary[String, float] = {}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pearls: Array[float] = []
var _next_visit: float = 0.0
var _total_species: int = 0
var _clock: float = 0.0
var _run: int = 1
var _run_start: float = 0.0
var _prestige_at: float = 0.0


func _init() -> void:
	_rng.seed = 20261114


## Juega [param hours] horas de juego y devuelve los hitos alcanzados.
## Con [param prestige_at_earned] > 0 hace la Gran marea cada vez que el ciclo gana
## esa cantidad de conchas y gasta las perlas negras en mejoras.
func run(hours: float, prestige_at_earned: float = 0.0) -> Dictionary[String, float]:
	Game.start_new_game(Game.DEFAULT_SEED)
	_total_species = Game.content.species_ids().size()
	_prestige_at = prestige_at_earned
	var steps: int = int(hours * 3600.0 / STEP)
	for _step: int in range(steps):
		_advance()
		if _clock >= _next_visit:
			_next_visit = _clock + VISIT_SECONDS
			_visit()
			_record()
			_maybe_prestige()
	return milestones


## Estado resumido para depurar: horas, conchas, producción, peces y descubiertos.
func summary() -> String:
	var state: GameState = Game.state
	return (
		"t=%.2fh earned=%s rate=%s fish=%d tanks=%d dex=%d"
		% [
			_clock / 3600.0,
			String.num_scientific(state.wallet.total_earned),
			String.num_scientific(state.production_rate),
			state.fish_total(),
			state.tanks.size(),
			state.discovered.size()
		]
	)


## Lo mismo que hace `Game._process` con un paso, pero con el paso del bot.
func _advance() -> void:
	var state: GameState = Game.state
	_clock += STEP
	Simulation.step(state, STEP, Game.content, Game.rng)
	Game.events.advance(STEP)
	for spawn: PearlSpawn in state.take_pearls():
		if spawn.tank_index != state.active_tank:
			Game.collect_pearl(spawn.value)
		elif _rng.randf() < PEARL_CATCH:
			_pearls.append(spawn.value)
	for hatching: HatchEvent in state.take_hatched():
		state.stats.add(GameStats.EGGS_HATCHED)
		Game._register_discovery(hatching.fish, false)


func _visit() -> void:
	# Sin avisos por el bus: miles de pasos con interfaces escuchando lo harían lentísimo.
	Game._refresh_unlocks(false)
	Game._check_achievements(false)
	for value: float in _pearls:
		Game.collect_pearl(value)
	_pearls.clear()
	var newest: int = Game.state.tanks.size() - 1
	for tank_index: int in range(Game.state.tanks.size()):
		Game.biomes.set_active(tank_index)
		_care(tank_index)
		_shop(tank_index)
	Game.biomes.set_active(newest)
	_open_next_tank()


func _care(tank_index: int) -> void:
	var tank: Tank = Game.state.tanks[tank_index]
	for fish: Fish in tank.fish:
		while fish.hunger < FEED_BELOW and Game.feed_fish(fish):
			pass
	while tank.cleanliness < CLEAN_BELOW and Game.clean_spot(tank_index):
		pass


## Compras de la pecera activa: equipo, decoración que abre especies, una de cada
## especie y, con lo que sobra, el pez que antes se amortiza.
func _shop(tank_index: int) -> void:
	var tank: Tank = Game.state.tanks[tank_index]
	_buy_equipment()
	_buy_tag_decorations(tank)
	_free_space(tank)
	for species_id: String in Game.content.species_ids():
		var species: SpeciesDef = Game.content.get_species(species_id)
		if species.biome_id != tank.biome_id or not Game.state.is_unlocked(species_id):
			continue
		if tank.count_of(species_id) == 0 and Game.fish_cost(species_id) <= _budget(0.3):
			Game.buy_fish(species_id)
	for _attempt: int in range(200):
		if not _fill_one(tank):
			return


## Con la pecera casi llena vende los sobrantes de todo lo que no sea de las tres
## especies que más producen (las variantes raras y la cría siguen su curso).
func _free_space(tank: Tank) -> void:
	if tank.occupied() < tank.total_capacity() - FREE_SLOTS:
		return
	var keep: Array[String] = _top_species(tank, 3)
	var combos: Dictionary[String, Array] = {}
	for fish: Fish in tank.fish:
		if keep.has(fish.species_id) and fish.variant_id == VariantDef.NORMAL_ID:
			continue
		combos[fish.species_id + "|" + fish.variant_id] = [fish.species_id, fish.variant_id]
	for pair: Array in combos.values():
		var species_id: String = pair[0]
		var variant_id: String = pair[1]
		Game.sell_surplus(species_id, variant_id)
	if tank.occupied() < tank.total_capacity() - FREE_SLOTS:
		return
	# Todavía lleno: de las especies que más producen se quedan solo KEEP_TOP normales.
	for species_id: String in keep:
		var extra: Array[Fish] = Selling.surplus(tank, species_id, VariantDef.NORMAL_ID)
		for index: int in range(KEEP_TOP - Selling.KEEP_BREEDERS, extra.size()):
			Game.sell_fish(extra[index])


func _top_species(tank: Tank, count: int) -> Array[String]:
	var ids: Array[String] = []
	for fish: Fish in tank.fish:
		if not ids.has(fish.species_id):
			ids.append(fish.species_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			return (
				Game.content.get_species(a).base_production
				> Game.content.get_species(b).base_production
			)
	)
	return ids.slice(0, count)


func _budget(fraction: float) -> float:
	return Game.state.wallet.shells * fraction


func _fill_one(tank: Tank) -> bool:
	var best: String = _best_species(tank)
	if best.is_empty():
		return false
	if tank.is_full():
		return _swap_weakest(tank, best)
	return Game.buy_fish(best) == GameService.BuyResult.OK


## Con la pecera llena, vende el pez que menos produce si el nuevo produce mucho más.
func _swap_weakest(tank: Tank, species_id: String) -> bool:
	var wanted: SpeciesDef = Game.content.get_species(species_id)
	if Game.fish_cost(species_id) > Game.state.wallet.shells + 0.0:
		return false
	var weakest: Fish = null
	var weakest_rate: float = INF
	for fish: Fish in tank.fish:
		var rate: float = Game.content.get_species(fish.species_id).base_production
		if rate < weakest_rate and tank.count_of(fish.species_id) > 2:
			weakest = fish
			weakest_rate = rate
	if weakest == null or wanted.base_production < weakest_rate * SWAP_RATIO:
		return false
	Game.sell_fish(weakest)
	return Game.buy_fish(species_id) == GameService.BuyResult.OK


func _best_species(tank: Tank) -> String:
	var best: String = ""
	var best_payback: float = INF
	for species_id: String in Game.content.species_ids():
		var species: SpeciesDef = Game.content.get_species(species_id)
		if species.biome_id != tank.biome_id or not Game.state.is_unlocked(species_id):
			continue
		if tank.count_of(species_id) >= MAX_PER_SPECIES:
			continue
		var payback: float = Game.fish_cost(species_id) / maxf(species.base_production, 1.0e-9)
		if payback < best_payback:
			best_payback = payback
			best = species_id
	return best


func _buy_equipment() -> void:
	for equipment_id: String in Game.content.equipment_ids():
		while Game.equipment_cost(equipment_id) <= _budget(0.2):
			if Game.buy_equipment(equipment_id) != GameService.EquipResult.OK:
				break


## Compra y coloca la decoración más barata de cada etiqueta que pide una especie
## bloqueada de esta pecera.
func _buy_tag_decorations(tank: Tank) -> void:
	for species_id: String in Game.content.species_ids():
		var species: SpeciesDef = Game.content.get_species(species_id)
		if species.biome_id != tank.biome_id or Game.state.is_unlocked(species_id):
			continue
		if species.unlock_kind != SpeciesDef.UnlockKind.DECORATION_TAG:
			continue
		if Game.state.count_tag(species.unlock_tag) > 0:
			continue
		var cheapest: String = _cheapest_tagged(species.unlock_tag, tank.biome_id)
		if cheapest.is_empty() or Game.decoration_cost(cheapest) > Game.state.wallet.shells:
			continue
		Game.buy_decoration(cheapest)
		for slot: int in range(1, 10):
			if Game.place_decoration(cheapest, slot * 100, 0, 100, 8) == GameService.DecorResult.OK:
				break


func _cheapest_tagged(tag: String, biome_id: String) -> String:
	var best: String = ""
	var best_cost: float = INF
	for decoration_id: String in Game.content.decoration_ids():
		var def: DecorationDef = Game.content.get_decoration(decoration_id)
		if def.tag != tag or def.is_reward:
			continue
		if not def.biome_id.is_empty() and def.biome_id != biome_id:
			continue
		if def.base_cost < best_cost:
			best_cost = def.base_cost
			best = decoration_id
	return best


func _open_next_tank() -> void:
	var state: GameState = Game.state
	if state.active().fish.size() < FISH_BEFORE_NEXT_TANK:
		return
	for biome_id: String in Game.content.biomes.ids():
		var biome: BiomeDef = Game.content.biomes.get_biome(biome_id)
		if state.tank_index_of(biome.id) >= 0:
			continue
		if (
			not biome.requires_biome_id.is_empty()
			and state.tank_index_of(biome.requires_biome_id) < 0
		):
			return
		Game.biomes.unlock(biome.id)
		return


func _mark(name: String, absolute: bool = false) -> void:
	var key: String = name if _run == 1 else "r%d_%s" % [_run, name]
	if absolute:
		key = name
	if not milestones.has(key):
		milestones[key] = _clock if absolute else _clock - _run_start


## Gran marea cuando el ciclo ya ha ganado lo pedido; gasta las perlas en mejoras.
func _maybe_prestige() -> void:
	if _prestige_at <= 0.0 or Prestige.run_earned(Game.state) < _prestige_at:
		return
	_mark("prestige_ready")
	Game.prestige.reset()
	_run += 1
	_run_start = _clock
	_spend_pearls()


## Compra siempre la mejora a la que menos avance de nivel lleva (reparte entre todas).
func _spend_pearls() -> void:
	for _attempt: int in range(500):
		var best: String = ""
		var best_ratio: float = INF
		for upgrade_id: String in Game.content.prestige.ids():
			var def: PrestigeUpgradeDef = Game.content.prestige.get_upgrade(upgrade_id)
			var level: int = Game.state.prestige.levels.get(upgrade_id, 0)
			if level >= def.max_level or not Prestige.can_buy(Game.state, def):
				continue
			var ratio: float = float(level) / float(def.max_level)
			if ratio < best_ratio:
				best_ratio = ratio
				best = upgrade_id
		if best.is_empty() or not Game.prestige.buy_upgrade(best):
			return


func _record() -> void:
	var state: GameState = Game.state
	for biome_index: int in range(state.tanks.size()):
		_mark("tank_%s" % state.tanks[biome_index].biome_id)
	var unlocked: int = 0
	for species_id: String in Game.content.species_ids():
		if state.is_unlocked(species_id):
			unlocked += 1
	if unlocked >= _total_species:
		_mark("all_species_unlocked")
	for exponent: int in [6, 7, 8, 9, 10, 11, 12]:
		if Prestige.run_earned(state) >= pow(10.0, float(exponent)):
			_mark("earned_1e%d" % exponent)
	var dex: int = state.discovered.size()
	for quarter: int in [25, 50, 75, 100]:
		if dex >= int(float(_total_species * 5) * float(quarter) / 100.0):
			_mark("dex_%d" % quarter, true)
