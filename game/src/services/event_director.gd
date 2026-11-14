class_name EventDirector
extends RefCounted
## Los eventos aleatorios como parte de la partida: cuenta el tiempo, lanza el que
## toca, paga las recompensas y avisa por [EventBus]. Cuelga de `Game.events`.
##
## Usa su propio generador aleatorio (no toca el de la partida), así que añadir
## eventos no cambia lo que salga de las perlas ni de las crías.

const SEED_SALT: int = 7919

var _game: GameService = null
var _planner: EventPlanner = EventPlanner.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(game: GameService) -> void:
	_game = game


## Reinicia el planificador con la semilla de la partida. Se llama al empezar o
## cargar una partida: los eventos en curso no sobreviven (D11).
func reseed(seed_value: int) -> void:
	_rng.seed = seed_value + SEED_SALT
	_planner.reset(_rng)


## Segundos hasta el próximo intento de evento.
func seconds_until_next() -> float:
	return _planner.seconds_left()


## Avanza [param dt] segundos: caducidades, fin de plaga y, si toca, un evento nuevo.
func advance(dt: float) -> void:
	var state: GameState = _game.state
	for ended: EventDef in state.events.tick(dt):
		if ended.kind == EventDef.Kind.WARM_CURRENT:
			state.mark_production_dirty()
		EventBus.event_finished.emit(ended.id)
	_finish_bloom(EventEffects.bloom_progress(state, false), state.events.bloom_def)
	var def: EventDef = _planner.step(dt, state, _game.content, _rng)
	if def != null:
		start(def)


## Lanza [param def] ahora. Devuelve falso si no se pudo.
func start(def: EventDef) -> bool:
	var state: GameState = _game.state
	if not EventEffects.start(def, state, _game.content, _rng):
		return false
	var species_id: String = state.events.pickup_species_id
	EventBus.event_started.emit(def.id, species_id)
	if def.kind == EventDef.Kind.FOOD_RAIN:
		EventBus.event_finished.emit(def.id)
	return true


## Lanza el evento con el id dado (herramienta de desarrollo y tests).
func start_by_id(event_id: String) -> bool:
	var def: EventDef = _game.content.events.get_event(event_id)
	return def != null and start(def)


## Lanza el siguiente evento posible (herramienta de desarrollo, F7).
func debug_trigger() -> void:
	var candidates: Array[EventDef] = []
	for event_id: String in _game.content.events.ids():
		var def: EventDef = _game.content.events.get_event(event_id)
		if EventPlanner.is_eligible(def, _game.state, _game.content):
			candidates.append(def)
	var chosen: EventDef = EventPlanner.pick(candidates, _rng)
	if chosen != null:
		start(chosen)


## El jugador cobra el clicable que hay en la pecera. Devuelve falso si no había.
func claim() -> bool:
	var def: EventDef = _game.state.events.pickup
	var reward: EventReward = EventEffects.claim(_game.state, _game.content, _rng)
	if reward == null:
		return false
	_game.state.wallet.add(reward.shells)
	EventBus.event_rewarded.emit(def.id, reward.shells, reward.decoration_id)
	if not reward.decoration_id.is_empty():
		EventBus.decoration_changed.emit(_game.state.active_tank)
	EventBus.event_finished.emit(def.id)
	return true


## El jugador limpió una mancha: cuenta para la plaga de algas.
func on_spot_cleaned() -> void:
	var def: EventDef = _game.state.events.bloom_def
	_finish_bloom(EventEffects.bloom_progress(_game.state, true), def)


func _finish_bloom(reward: EventReward, def: EventDef) -> void:
	if reward == null or def == null:
		return
	if reward.shells > 0.0:
		_game.state.wallet.add(reward.shells)
		EventBus.event_rewarded.emit(def.id, reward.shells, "")
	EventBus.event_finished.emit(def.id)
