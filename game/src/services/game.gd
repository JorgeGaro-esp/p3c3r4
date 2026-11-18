# gdlint: disable=max-public-methods,max-returns
class_name GameService
extends Node
## Dueño del estado de la partida y del bucle de simulación a paso fijo.
##
## Las acciones del jugador entran por aquí y se validan aquí: la interfaz nunca
## modifica el estado directamente. Lo ocurrido se anuncia por [EventBus].

enum BuyResult {
	OK,
	UNKNOWN_SPECIES,
	NOT_ENOUGH_SHELLS,
	TANK_FULL,
	LOCKED,
	WRONG_BIOME,
	LEGENDARY_OWNED,
}
enum EquipResult { OK, UNKNOWN, MAXED, NOT_ENOUGH_SHELLS }
enum DecorResult { OK, UNKNOWN, NOT_ENOUGH_SHELLS, NO_STOCK, TOO_MANY, OUT_OF_BOUNDS, OVERLAP }

## Aumento de coste de cada objeto de decoración que ya se tiene del mismo tipo.
const DECORATION_COST_GROWTH: float = 1.3

const START_SHELLS: float = 20.0
## Cada cuántos segundos se comprueban los logros.
const ACHIEVEMENT_CHECK_SECONDS: float = 0.5
const DEFAULT_SEED: int = 20261113
const START_FISH: PackedStringArray = ["pond_guppy", "pond_guppy"]
## Peces que nadan detrás de la pantalla de título (una partida que no se guarda).
const TITLE_FISH: PackedStringArray = [
	"pond_guppy",
	"pond_carp",
	"pond_goldfish",
	"pond_catfish",
	"pond_trout",
	"pond_salmon",
	"pond_koi",
	"pond_wels",
]

var state: GameState = GameState.new()
var content: ContentDB = ContentDB.new()
## Pecera activa, apertura de biomas y sus costes.
var biomes: BiomeDirector = BiomeDirector.new(self)
## El día y la noche, y los eventos aleatorios (Fase 12).
var daylight: DaylightDirector = DaylightDirector.new(self)
var events: EventDirector = EventDirector.new(self)
## La Gran marea (prestigio) y el final (Fase 13).
var prestige: PrestigeDirector = PrestigeDirector.new(self)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _stepper: FixedStepper = FixedStepper.new()
var _in_background: bool = false
var _last_shells: float = -1.0
var _last_rate: float = -1.0
var _achievement_timer: float = 0.0


func _ready() -> void:
	var variants_ok: bool = content.load_variants_dir()
	var species_ok: bool = content.load_species_dir()
	var equipment_ok: bool = content.load_equipment_dir()
	var decorations_ok: bool = content.load_decorations_dir()
	var biomes_ok: bool = content.biomes.load_dir()
	var achievements_ok: bool = content.achievements.load_dir()
	var events_ok: bool = content.events.load_dir()
	var prestige_ok: bool = content.prestige.load_dir()
	var refs_ok: bool = BiomeCatalog.check_references(content)
	var achievement_refs_ok: bool = AchievementCatalog.check_references(content)
	var all_ok: bool = variants_ok and species_ok and equipment_ok and decorations_ok
	var extra_ok: bool = biomes_ok and refs_ok and achievements_ok and achievement_refs_ok
	extra_ok = extra_ok and events_ok and prestige_ok
	if not all_ok or not extra_ok:
		var messages: PackedStringArray = content.errors + content.biomes.errors
		messages += content.achievements.errors + content.events.errors
		messages += content.prestige.errors
		for message: String in messages:
			push_error("ContentDB: %s" % message)
	start_new_game(DEFAULT_SEED)


func _process(delta: float) -> void:
	var max_steps: int = FixedStepper.MAX_STEPS_PER_FRAME
	if _in_background:
		max_steps = FixedStepper.BACKGROUND_MAX_STEPS
	for _step: int in range(_stepper.advance(delta, max_steps)):
		Simulation.step(state, FixedStepper.STEP_SECONDS, content, rng)
		events.advance(FixedStepper.STEP_SECONDS)
	daylight.refresh()
	for spawn: PearlSpawn in state.take_pearls():
		if spawn.tank_index == state.active_tank:
			EventBus.pearl_spawned.emit(spawn.tank_index, spawn.fish, spawn.value)
		else:
			# Una pecera que no se ve no puede ofrecer la perla: se cobra sola.
			collect_pearl(spawn.value)
	for hatching: HatchEvent in state.take_hatched():
		EventBus.fish_added.emit(hatching.tank_index, hatching.fish)
		EventBus.egg_hatched.emit(hatching.tank_index)
		state.stats.add(GameStats.EGGS_HATCHED)
		_register_discovery(hatching.fish, true)
	_achievement_timer += delta
	if _achievement_timer >= ACHIEVEMENT_CHECK_SECONDS:
		_achievement_timer = 0.0
		_check_achievements(true)
		prestige.check_final()
	_publish_changes()


## Empieza una partida nueva con la semilla dada.
func start_new_game(seed_value: int = DEFAULT_SEED) -> void:
	var fresh: GameState = GameState.new()
	fresh.rng_seed = seed_value
	fresh.wallet.add(START_SHELLS)
	for index: int in range(START_FISH.size()):
		var species_id: String = START_FISH[index]
		if content.has_species(species_id):
			var starter: Fish = Fish.new(species_id)
			# Los primeros peces salen de colores distintos, sin gastar números al azar.
			var coats: int = content.get_species(species_id).coat_count()
			if coats > 1:
				starter.coat = index % coats
			fresh.tanks[0].add_fish(starter)
	rng.seed = seed_value
	_replace_state(fresh)


## Partida de adorno para el título: una pecera con varios peces. No se guarda.
func start_title_demo() -> void:
	start_new_game()
	for species_id: String in TITLE_FISH:
		if content.has_species(species_id):
			_add_fish(0, species_id)


## Sustituye la partida por una cargada de disco y continúa su secuencia aleatoria.
func adopt_state(loaded: GameState) -> void:
	rng.seed = loaded.rng_seed
	if loaded.rng_state != 0:
		rng.state = loaded.rng_state
	_replace_state(loaded)


## Con la ventana minimizada la partida sigue produciendo, sin dibujar. Los
## fotogramas llegan más espaciados y así no se pierde tiempo de juego.
func set_background(value: bool) -> void:
	_in_background = value


## Detiene o reanuda la simulación (pantalla de título).
func set_paused(paused: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	_stepper.reset()


## Coste del siguiente pez de [param species_id] en la pecera activa.
func fish_cost(species_id: String) -> float:
	var species: SpeciesDef = content.get_species(species_id)
	if species == null:
		return INF
	return Economy.fish_cost(species.base_cost, state.active().count_of(species_id))


## Compra un pez para la pecera activa.
func buy_fish(species_id: String) -> BuyResult:
	if not content.has_species(species_id):
		return BuyResult.UNKNOWN_SPECIES
	if not state.is_unlocked(species_id):
		return BuyResult.LOCKED
	if content.get_species(species_id).biome_id != state.active().biome_id:
		return BuyResult.WRONG_BIOME
	if not state.active().accepts_species(content.get_species(species_id)):
		return BuyResult.LEGENDARY_OWNED
	if state.active().is_full():
		return BuyResult.TANK_FULL
	if not state.wallet.spend(fish_cost(species_id)):
		return BuyResult.NOT_ENOUGH_SHELLS
	_add_fish(state.active_tank, species_id)
	state.stats.add(GameStats.FISH_BOUGHT)
	EventBus.purchase_made.emit()
	return BuyResult.OK


## Coste de subir el equipo [param equipment_id] de la pecera activa al nivel siguiente
## (INF si no existe o ya está al máximo).
func equipment_cost(equipment_id: String) -> float:
	var def: EquipmentDef = content.get_equipment(equipment_id)
	if def == null:
		return INF
	var level: int = state.active().level_of(equipment_id)
	if level >= def.max_level:
		return INF
	return Economy.equipment_cost(def.base_cost, level)


## Sube un nivel el equipo [param equipment_id] de la pecera activa.
func buy_equipment(equipment_id: String) -> EquipResult:
	var def: EquipmentDef = content.get_equipment(equipment_id)
	if def == null:
		return EquipResult.UNKNOWN
	var tank: Tank = state.active()
	var level: int = tank.level_of(equipment_id)
	if level >= def.max_level:
		return EquipResult.MAXED
	if not state.wallet.spend(equipment_cost(equipment_id)):
		return EquipResult.NOT_ENOUGH_SHELLS
	tank.set_level(equipment_id, level + 1, content)
	state.stats.add(GameStats.EQUIPMENT_BOUGHT)
	tank.feeder_timer = 0.0
	EventBus.equipment_changed.emit(state.active_tank, equipment_id, level + 1)
	EventBus.purchase_made.emit()
	return EquipResult.OK


## Coste del siguiente objeto de [param decoration_id] (INF si no existe).
func decoration_cost(decoration_id: String) -> float:
	var def: DecorationDef = content.get_decoration(decoration_id)
	if def == null:
		return INF
	var owned: int = state.decoration_owned(decoration_id)
	return ceilf(def.base_cost * pow(DECORATION_COST_GROWTH, float(owned)) - 1.0e-9)


## Compra un objeto de decoración: va al inventario, aún sin colocar.
func buy_decoration(decoration_id: String) -> DecorResult:
	if not content.has_decoration(decoration_id):
		return DecorResult.UNKNOWN
	var owned: int = state.decoration_stock.get(decoration_id, 0)
	if owned >= GameState.MAX_STOCK:
		return DecorResult.TOO_MANY
	if not state.wallet.spend(decoration_cost(decoration_id)):
		return DecorResult.NOT_ENOUGH_SHELLS
	state.decoration_stock[decoration_id] = owned + 1
	state.stats.add(GameStats.DECORATIONS_BOUGHT)
	EventBus.decoration_changed.emit(state.active_tank)
	EventBus.purchase_made.emit()
	return DecorResult.OK


## Coloca un objeto del inventario en la pecera activa. [param tank_width] y
## [param water_rows] son las celdas de la pecera que dibuja la vista.
func place_decoration(
	decoration_id: String, x_permille: int, lift: int, tank_width: int, water_rows: int
) -> DecorResult:
	var def: DecorationDef = content.get_decoration(decoration_id)
	if def == null:
		return DecorResult.UNKNOWN
	if state.decoration_stock.get(decoration_id, 0) <= 0:
		return DecorResult.NO_STOCK
	var tank: Tank = state.active()
	var verdict: DecorationLayout.Result = DecorationLayout.check(
		tank, def, x_permille, lift, tank_width, water_rows
	)
	if verdict != DecorationLayout.Result.OK:
		return _decor_result(verdict)
	state.decoration_stock[decoration_id] = state.decoration_stock[decoration_id] - 1
	if state.decoration_stock[decoration_id] <= 0:
		state.decoration_stock.erase(decoration_id)
	tank.decorations.append(PlacedDecoration.new(def, x_permille, lift))
	_decorations_changed(tank)
	return DecorResult.OK


## Guarda en el inventario el objeto [param placed] de la pecera activa.
func remove_decoration(placed: PlacedDecoration) -> bool:
	var tank: Tank = state.active()
	var index: int = tank.decorations.find(placed)
	if index < 0:
		return false
	tank.decorations.remove_at(index)
	var owned: int = state.decoration_stock.get(placed.def.id, 0)
	state.decoration_stock[placed.def.id] = mini(owned + 1, GameState.MAX_STOCK)
	_decorations_changed(tank)
	return true


## Vende [param fish] de la pecera activa. Devuelve las conchas ganadas, o -1 si el pez
## no está en ella.
func sell_fish(fish: Fish) -> float:
	var tank: Tank = state.active()
	if not tank.fish.has(fish) or fish.favorite:
		return -1.0
	var value: float = Selling.value_of(fish, content)
	tank.remove_fish(fish)
	state.wallet.add(value)
	state.mark_production_dirty()
	state.stats.add(GameStats.FISH_SOLD)
	EventBus.fish_removed.emit(state.active_tank, fish)
	EventBus.fish_sold.emit(value)
	EventBus.purchase_made.emit()
	return value


## Vende los sobrantes de [param species_id] y [param variant_id] (ver
## [method Selling.surplus]). Devuelve las conchas ganadas en total.
func sell_surplus(species_id: String, variant_id: String) -> float:
	var total: float = 0.0
	for fish: Fish in Selling.surplus(state.active(), species_id, variant_id):
		var value: float = Selling.value_of(fish, content)
		state.active().remove_fish(fish)
		state.wallet.add(value)
		state.stats.add(GameStats.FISH_SOLD)
		EventBus.fish_removed.emit(state.active_tank, fish)
		total += value
	if total > 0.0:
		state.mark_production_dirty()
		EventBus.fish_sold.emit(total)
		EventBus.purchase_made.emit()
	return total


## Vende todos los peces de la pecera [param tank_index] y descarta sus huevos.
## Devuelve las conchas ganadas.
func sell_all_fish(tank_index: int = -1) -> float:
	if tank_index < 0:
		tank_index = state.active_tank
	var tank: Tank = state.tanks[tank_index]
	var total: float = 0.0
	for fish: Fish in tank.fish.duplicate():
		total += Selling.value_of(fish, content)
		tank.remove_fish(fish)
		state.stats.add(GameStats.FISH_SOLD)
		EventBus.fish_removed.emit(tank_index, fish)
	tank.eggs.clear()
	tank.breed_timers.clear()
	state.wallet.add(total)
	state.mark_production_dirty()
	EventBus.fish_sold.emit(total)
	EventBus.purchase_made.emit()
	return total


## Da de comer un copo a [param fish]. Devuelve falso si ya estaba lleno.
func feed_fish(fish: Fish) -> bool:
	if fish.hunger >= Care.MAX_HUNGER:
		return false
	fish.feed(Care.HUNGER_PER_FLAKE)
	state.stats.add(GameStats.FISH_FED)
	return true


## Limpia una mancha de alga de la pecera [param tank_index]. Devuelve falso si
## ya estaba impecable.
func clean_spot(tank_index: int = -1) -> bool:
	var tank: Tank = state.active() if tank_index < 0 else state.tanks[tank_index]
	if tank.cleanliness >= Care.MAX_CLEANLINESS:
		return false
	tank.cleanliness = minf(tank.cleanliness + Care.SPOT_STEP, Care.MAX_CLEANLINESS)
	state.stats.add(GameStats.SPOTS_CLEANED)
	events.on_spot_cleaned()
	return true


## El jugador recoge una perla de [param value] conchas.
func collect_pearl(value: float) -> void:
	if state.wallet.add(value):
		state.stats.add(GameStats.PEARLS_COLLECTED)
		EventBus.pearl_collected.emit(value)


## Herramienta de desarrollo (F4): añade peces sin coste, hasta llenar la pecera.
func debug_add_fish(count: int) -> void:
	var ids: PackedStringArray = PackedStringArray()
	for species_id: String in content.species_ids():
		if content.get_species(species_id).biome_id == state.active().biome_id:
			ids.append(species_id)
	if ids.is_empty():
		return
	for _index: int in range(count):
		if state.active().is_full():
			return
		# Se salta lo que no cabe (legendarias ya presentes) y se prueba la siguiente especie.
		var start: int = state.active().fish.size() % ids.size()
		for offset: int in range(ids.size()):
			var species_id: String = ids[(start + offset) % ids.size()]
			if state.active().accepts_species(content.get_species(species_id)):
				_add_fish(state.active_tank, species_id)
				break


## Herramienta de desarrollo (Mayús+F4): quita los últimos peces.
func debug_remove_fish(count: int) -> void:
	var tank: Tank = state.active()
	for _index: int in range(count):
		if tank.fish.is_empty():
			break
		var last: Fish = tank.fish.back()
		tank.remove_fish(last)
		EventBus.fish_removed.emit(state.active_tank, last)
	state.mark_production_dirty()


## Cambia el estado y avisa a las vistas: primero quita los peces viejos y luego
## anuncia los nuevos.
func _replace_state(fresh: GameState) -> void:
	for tank_index: int in range(state.tanks.size()):
		for fish: Fish in state.tanks[tank_index].fish.duplicate():
			EventBus.fish_removed.emit(tank_index, fish)
	state = fresh
	for tank: Tank in state.tanks:
		tank.refresh_bonuses(content)
	state.mark_production_dirty()
	_stepper.reset()
	events.reseed(state.rng_seed)
	daylight.refresh(false)
	for tank_index: int in range(state.tanks.size()):
		for fish: Fish in state.tanks[tank_index].fish:
			EventBus.fish_added.emit(tank_index, fish)
	_last_shells = -1.0
	_last_rate = -1.0
	EventBus.active_tank_changed.emit(state.active_tank)
	_refresh_unlocks(false)
	for tank: Tank in state.tanks:
		for fish: Fish in tank.fish:
			_register_discovery(fish, false)
	_check_achievements(false)
	_publish_changes()


## Desbloquea los logros que ya se cumplen. Con [param announce] falso (al cargar)
## se concede sin avisar. Un logro puede dar producción que cumple otro, así que
## se repite hasta que no salga ninguno nuevo.
func _check_achievements(announce: bool) -> void:
	var pending: Array[AchievementDef] = Achievements.newly_met(state, content)
	while not pending.is_empty():
		for def: AchievementDef in pending:
			state.achievements[def.id] = true
			if announce:
				EventBus.achievement_unlocked.emit(def.id)
		state.mark_production_dirty()
		Simulation.refresh_production(state, content)
		pending = Achievements.newly_met(state, content)


func _decor_result(verdict: DecorationLayout.Result) -> DecorResult:
	match verdict:
		DecorationLayout.Result.TOO_MANY:
			return DecorResult.TOO_MANY
		DecorationLayout.Result.OVERLAP:
			return DecorResult.OVERLAP
		_:
			return DecorResult.OUT_OF_BOUNDS


func _decorations_changed(tank: Tank) -> void:
	tank.refresh_bonuses(content)
	state.mark_production_dirty()
	EventBus.decoration_changed.emit(state.active_tank)
	EventBus.purchase_made.emit()


func _add_fish(tank_index: int, species_id: String) -> void:
	var fish: Fish = Fish.new(species_id)
	var species: SpeciesDef = content.get_species(species_id)
	if species != null:
		fish.coat = species.random_coat(rng)
	if state.tanks[tank_index].add_fish(fish):
		state.mark_production_dirty()
		_register_discovery(fish, false)
		EventBus.fish_added.emit(tank_index, fish)


## Anota la combinación de especie y variante de [param fish]. Con [param announce]
## avisa de las variantes nuevas que no son la normal.
func _register_discovery(fish: Fish, announce: bool) -> void:
	var is_new: bool = state.discover(fish.species_id, fish.variant_id)
	if is_new and announce and fish.variant_id != VariantDef.NORMAL_ID:
		EventBus.variant_discovered.emit(fish.species_id, fish.variant_id)


## Desbloquea las especies cuya condición ya se cumple. Con [param announce] avisa
## de cada una por [signal EventBus.species_unlocked].
func _refresh_unlocks(announce: bool = true) -> void:
	for species_id: String in content.species_ids():
		if state.is_unlocked(species_id):
			continue
		var species: SpeciesDef = content.get_species(species_id)
		if Unlocks.is_met(species, state):
			state.unlocked[species_id] = true
			if announce:
				EventBus.species_unlocked.emit(species_id)


func _publish_changes() -> void:
	_refresh_unlocks()
	if state.production_dirty:
		state.production_rate = Simulation.total_production(state, content)
		state.production_dirty = false
	if state.production_rate != _last_rate:
		_last_rate = state.production_rate
		EventBus.production_changed.emit(_last_rate)
	if state.wallet.shells != _last_shells:
		_last_shells = state.wallet.shells
		EventBus.shells_changed.emit(_last_shells)
