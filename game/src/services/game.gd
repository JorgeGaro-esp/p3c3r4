class_name GameService
extends Node
## Dueño del estado de la partida y del bucle de simulación a paso fijo.
##
## Las acciones del jugador entran por aquí y se validan aquí: la interfaz nunca
## modifica el estado directamente. Lo ocurrido se anuncia por [EventBus].

enum BuyResult { OK, UNKNOWN_SPECIES, NOT_ENOUGH_SHELLS, TANK_FULL }

const START_SHELLS: float = 20.0
const DEFAULT_SEED: int = 20261113
const START_FISH: PackedStringArray = ["test_guppy", "test_minnow", "test_angelfish"]

var state: GameState = GameState.new()
var content: ContentDB = ContentDB.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _stepper: FixedStepper = FixedStepper.new()
var _last_shells: float = -1.0
var _last_rate: float = -1.0


func _ready() -> void:
	if not content.load_species_dir():
		for message: String in content.errors:
			push_error("ContentDB: %s" % message)
	start_new_game(DEFAULT_SEED)


func _process(delta: float) -> void:
	for _step: int in range(_stepper.advance(delta)):
		Simulation.step(state, FixedStepper.STEP_SECONDS, content, rng)
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
	if state.tanks[0].is_full():
		return BuyResult.TANK_FULL
	if not state.wallet.spend(fish_cost(species_id)):
		return BuyResult.NOT_ENOUGH_SHELLS
	_add_fish(0, species_id)
	EventBus.purchase_made.emit()
	return BuyResult.OK


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
	_publish_changes()


func _add_fish(tank_index: int, species_id: String) -> void:
	var fish: Fish = Fish.new(species_id)
	if state.tanks[tank_index].add_fish(fish):
		state.mark_production_dirty()
		EventBus.fish_added.emit(tank_index, fish)


func _publish_changes() -> void:
	if state.production_dirty:
		state.production_rate = Simulation.total_production(state, content)
		state.production_dirty = false
	if state.production_rate != _last_rate:
		_last_rate = state.production_rate
		EventBus.production_changed.emit(_last_rate)
	if state.wallet.shells != _last_shells:
		_last_shells = state.wallet.shells
		EventBus.shells_changed.emit(_last_shells)
