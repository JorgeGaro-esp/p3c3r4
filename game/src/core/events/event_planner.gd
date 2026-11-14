class_name EventPlanner
extends RefCounted
## Decide cuándo sale un evento aleatorio y cuál. Solo cuenta el tiempo con el
## juego abierto (no hay progreso con él cerrado, D11).
##
## Espera entre [constant MIN_WAIT] y [constant MAX_WAIT] segundos; si al cumplirse
## no hay ningún evento posible, reintenta pronto. Recibe el generador aleatorio
## de fuera para que, con la misma semilla, salga siempre lo mismo.

const MIN_WAIT: float = 240.0
const MAX_WAIT: float = 480.0
const RETRY_WAIT: float = 30.0
## Con la pecera así de sucia (o menos) no sale una plaga de algas.
const BLOOM_MIN_CLEANLINESS: float = 60.0
## Con todos los peces así de saciados (o más) no sale una lluvia de comida.
const FOOD_RAIN_MAX_HUNGER: float = 70.0

var _timer: float = 0.0


func _init(rng: RandomNumberGenerator = null) -> void:
	reset(rng)


## Vuelve a esperar un intervalo completo.
func reset(rng: RandomNumberGenerator) -> void:
	_timer = MAX_WAIT if rng == null else rng.randf_range(MIN_WAIT, MAX_WAIT)


## Segundos que faltan para el próximo intento.
func seconds_left() -> float:
	return _timer


## Avanza [param dt] segundos. Devuelve el evento que toca ahora, o null.
func step(dt: float, state: GameState, content: ContentDB, rng: RandomNumberGenerator) -> EventDef:
	_timer -= dt
	if _timer > 0.0:
		return null
	var candidates: Array[EventDef] = []
	for event_id: String in content.events.ids():
		var def: EventDef = content.events.get_event(event_id)
		if is_eligible(def, state, content):
			candidates.append(def)
	var chosen: EventDef = pick(candidates, rng)
	_timer = RETRY_WAIT if chosen == null else rng.randf_range(MIN_WAIT, MAX_WAIT)
	return chosen


## Si [param def] puede salir ahora en la pecera activa.
static func is_eligible(def: EventDef, state: GameState, content: ContentDB) -> bool:
	var tank: Tank = state.active()
	if tank.fish.size() < def.min_fish:
		return false
	if def.is_pickup():
		return not state.events.has_pickup() and _has_pickup_content(def, tank, content)
	match def.kind:
		EventDef.Kind.WARM_CURRENT:
			return state.events.warm_seconds <= 0.0
		EventDef.Kind.ALGAE_BLOOM:
			return not state.events.has_bloom() and tank.cleanliness > BLOOM_MIN_CLEANLINESS
		EventDef.Kind.FOOD_RAIN:
			for fish: Fish in tank.fish:
				if fish.hunger < FOOD_RAIN_MAX_HUNGER:
					return true
			return false
	return true


## Elige uno de [param defs] según su peso. Null si no hay ninguno.
static func pick(defs: Array[EventDef], rng: RandomNumberGenerator) -> EventDef:
	var total: float = 0.0
	for def: EventDef in defs:
		total += maxf(def.weight, 0.0)
	if defs.is_empty() or total <= 0.0:
		return null
	var roll: float = rng.randf() * total
	for def: EventDef in defs:
		roll -= maxf(def.weight, 0.0)
		if roll < 0.0:
			return def
	return defs.back()


static func _has_pickup_content(def: EventDef, tank: Tank, content: ContentDB) -> bool:
	if def.kind == EventDef.Kind.VISITOR:
		return not EventEffects.visitor_candidates(tank.biome_id, content).is_empty()
	if def.kind == EventDef.Kind.BOTTLE:
		return not content.decoration_ids().is_empty()
	return true
