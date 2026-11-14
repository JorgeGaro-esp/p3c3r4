class_name EventState
extends RefCounted
## Lo que está pasando ahora mismo por un evento. Vive en [GameState] pero no se
## guarda: un evento no sobrevive a cerrar el juego (D11), y como las recompensas
## se pagan al momento no se pierde nada.

## Producción que multiplica la corriente cálida.
const WARM_MULTIPLIER: float = 2.0

## Corriente cálida: segundos que le quedan (0 si no hay).
var warm_seconds: float = 0.0
var warm_def: EventDef = null
## Evento que espera un clic (visitante, pez dorado o botella) y su tiempo.
var pickup: EventDef = null
var pickup_seconds: float = 0.0
var pickup_tank: int = -1
## Especie del visitante (solo con el visitante raro).
var pickup_species_id: String = ""
## Pecera con plaga de algas (-1 si ninguna) y manchas limpiadas desde que empezó.
var bloom_tank: int = -1
var bloom_cleans: int = 0
var bloom_def: EventDef = null


## Multiplicador de producción por eventos.
func production_multiplier() -> float:
	return WARM_MULTIPLIER if warm_seconds > 0.0 else 1.0


func has_pickup() -> bool:
	return pickup != null


func has_bloom() -> bool:
	return bloom_tank >= 0


## Avanza el reloj de los eventos [param dt] segundos. Devuelve los que acaban de
## terminar (una corriente que se apaga o un clicable que no se cobró).
func tick(dt: float) -> Array[EventDef]:
	var ended: Array[EventDef] = []
	if warm_seconds > 0.0:
		warm_seconds = maxf(warm_seconds - dt, 0.0)
		if warm_seconds <= 0.0:
			ended.append(warm_def)
			warm_def = null
	if pickup != null:
		pickup_seconds -= dt
		if pickup_seconds <= 0.0:
			ended.append(pickup)
			clear_pickup()
	return ended


func clear_pickup() -> void:
	pickup = null
	pickup_seconds = 0.0
	pickup_tank = -1
	pickup_species_id = ""


func clear_bloom() -> void:
	bloom_tank = -1
	bloom_cleans = 0
	bloom_def = null
