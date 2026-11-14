class_name MotionScale
extends RefCounted
## Cuánto se mueven las ondulaciones y los adornos de la pecera. Con «Reducir
## movimiento» (accesibilidad) se quedan en un tercio y los parpadeos se apagan.

const REDUCED: float = 0.3


## Verdadero si el jugador ha pedido menos movimiento.
static func is_reduced() -> bool:
	return Settings.data.reduce_motion


## Factor para multiplicar amplitudes de ondulación (1 normal, [constant REDUCED]).
static func factor() -> float:
	return REDUCED if Settings.data.reduce_motion else 1.0
