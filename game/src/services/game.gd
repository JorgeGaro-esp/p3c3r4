class_name GameService
extends Node
## Dueño del estado de la partida y del bucle de simulación a paso fijo.
##
## Las acciones del jugador entran por aquí y se validan aquí: la interfaz nunca
## modifica el estado directamente. Lo ocurrido se anuncia por [EventBus].

enum BuyResult { OK, UNKNOWN_SPECIES, NOT_ENOUGH_SHELLS, TANK_FULL, LOCKED }

const START_SHELLS: float = 20.0
const DEFAULT_SEED: int = 20261113
const START_FISH: PackedStringArray = ["pond_guppy", "pond_guppy"]

var state: GameState = GameState.new()
var content: ContentDB = ContentDB.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _stepper: FixedStepper = FixedStepper.new()
var _last_shells: float = -1.0
var _last_rate: float = -1.0


func _ready() -> void:
	var variants_ok: bool = content.load_variants_dir()
	var species_ok: bool = content.load_species_dir()
	if not variants_ok or not species_ok:
		for message: String in content.errors:
			push_error("ContentDB: %s" % message)
	start_new_game(DEFAULT_SEED)


func _process(delta: float) -> void:
	for _step: int in range(_stepper.advance(delta)):
		Simulation.step(state, FixedStepper.STEP_SECONDS, content, rng)
	for spawn: PearlSpawn in state.take_pearls():
		EventBus.pearl_spawned.emit(spawn.tank_index, spawn.fish, spawn.value)
	for hatching: HatchEvent in state.take_hatched():
		EventBus.fish_added.emit(hatching.tank_index, hatching.fish)
		_register_discovery(hatching.fish, true)
	_publish_changes()


## Empieza una partida nueva con la semilla dada.
func start_new_game(seed_value: int = DEFAULT_SEED) -> void:
	var fresh: GameState = GameState.new()
	fresh.rng_seed = seed_value
	fresh.wallet.add(START_SHELLS)
	for species_id: String in START_FISH:
		if content.has_species(species_id):
			fresh.tanks[0].add_fish(Fish.new(species_id))
	rng.seed = seed_value
	_replace_state(fresh)


## Sustituye la partida por una cargada de disco y continúa su secuencia aleatoria.
func adopt_state(loaded: GameState) -> void:
	rng.seed = loaded.rng_seed
	if loaded.rng_state != 0:
		rng.state = loaded.rng_state
	_replace_state(loaded)


## Detiene o reanuda la simulación (ventana minimizada, D11).
func set_paused(paused: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	_stepper.reset()


## Coste del siguiente pez de [param species_id] en la pecera 0.
func fish_cost(species_id: String) -> float:
	var species: SpeciesDef = content.get_species(species_id)
	if species == null:
		return INF
	return Economy.fish_cost(species.base_cost, state.tanks[0].count_of(species_id))


## Compra un pez para la pecera 0.
func buy_fish(species_id: String) -> BuyResult:
	if not content.has_species(species_id):
		return BuyResult.UNKNOWN_SPECIES
	if not state.is_unlocked(species_id):
		return BuyResult.LOCKED
	if state.tanks[0].is_full():
		return BuyResult.TANK_FULL
	if not state.wallet.spend(fish_cost(species_id)):
		return BuyResult.NOT_ENOUGH_SHELLS
	_add_fish(0, species_id)
	EventBus.purchase_made.emit()
	return BuyResult.OK


## Vende [param fish] de la pecera 0. Devuelve las conchas ganadas, o -1 si el pez
## no está en ella.
func sell_fish(fish: Fish) -> float:
	var tank: Tank = state.tanks[0]
	if not tank.fish.has(fish):
		return -1.0
	var value: float = Selling.value_of(fish, content)
	tank.remove_fish(fish)
	state.wallet.add(value)
	state.mark_production_dirty()
	EventBus.fish_removed.emit(0, fish)
	EventBus.fish_sold.emit(value)
	EventBus.purchase_made.emit()
	return value


## Vende los sobrantes de [param species_id] y [param variant_id] (ver
## [method Selling.surplus]). Devuelve las conchas ganadas en total.
func sell_surplus(species_id: String, variant_id: String) -> float:
	var total: float = 0.0
	for fish: Fish in Selling.surplus(state.tanks[0], species_id, variant_id):
		var value: float = Selling.value_of(fish, content)
		state.tanks[0].remove_fish(fish)
		state.wallet.add(value)
		EventBus.fish_removed.emit(0, fish)
		total += value
	if total > 0.0:
		state.mark_production_dirty()
		EventBus.fish_sold.emit(total)
		EventBus.purchase_made.emit()
	return total


## Vende todos los peces de la pecera [param tank_index] y descarta sus huevos.
## Devuelve las conchas ganadas.
func sell_all_fish(tank_index: int = 0) -> float:
	var tank: Tank = state.tanks[tank_index]
	var total: float = 0.0
	for fish: Fish in tank.fish.duplicate():
		total += Selling.value_of(fish, content)
		tank.remove_fish(fish)
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
	return true


## Limpia una mancha de alga de la pecera [param tank_index]. Devuelve falso si
## ya estaba impecable.
func clean_spot(tank_index: int = 0) -> bool:
	var tank: Tank = state.tanks[tank_index]
	if tank.cleanliness >= Care.MAX_CLEANLINESS:
		return false
	tank.cleanliness = minf(tank.cleanliness + Care.SPOT_STEP, Care.MAX_CLEANLINESS)
	return true


## El jugador recoge una perla de [param value] conchas.
func collect_pearl(value: float) -> void:
	if state.wallet.add(value):
		EventBus.pearl_collected.emit(value)


## Herramienta de desarrollo (F4): añade peces sin coste, hasta llenar la pecera.
func debug_add_fish(count: int) -> void:
	var ids: PackedStringArray = content.species_ids()
	if ids.is_empty():
		return
	for _index: int in range(count):
		if state.tanks[0].is_full():
			return
		_add_fish(0, ids[state.tanks[0].fish.size() % ids.size()])


## Herramienta de desarrollo (Mayús+F4): quita los últimos peces.
func debug_remove_fish(count: int) -> void:
	var tank: Tank = state.tanks[0]
	for _index: int in range(count):
		if tank.fish.is_empty():
			break
		var last: Fish = tank.fish.back()
		tank.remove_fish(last)
		EventBus.fish_removed.emit(0, last)
	state.mark_production_dirty()


## Cambia el estado y avisa a las vistas: primero quita los peces viejos y luego
## anuncia los nuevos.
func _replace_state(fresh: GameState) -> void:
	for tank_index: int in range(state.tanks.size()):
		for fish: Fish in state.tanks[tank_index].fish.duplicate():
			EventBus.fish_removed.emit(tank_index, fish)
	state = fresh
	state.mark_production_dirty()
	_stepper.reset()
	for tank_index: int in range(state.tanks.size()):
		for fish: Fish in state.tanks[tank_index].fish:
			EventBus.fish_added.emit(tank_index, fish)
	_last_shells = -1.0
	_last_rate = -1.0
	_refresh_unlocks(false)
	for tank: Tank in state.tanks:
		for fish: Fish in tank.fish:
			_register_discovery(fish, false)
	_publish_changes()


func _add_fish(tank_index: int, species_id: String) -> void:
	var fish: Fish = Fish.new(species_id)
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
