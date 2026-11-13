class_name Care
extends RefCounted
## Reglas de cuidados (GDD §4.4 y §5): hambre, limpieza y felicidad. Funciones y
## constantes puras; el estado vive en [Fish] y [Tank].
##
## Principio de diseño: descuidar la pecera frena la producción pero nunca la
## anula (la felicidad mínima sigue dando ×0,25) y no se pierde nada.

## Saciedad al máximo: el pez acaba de comer.
const MAX_HUNGER: float = 100.0
const MAX_CLEANLINESS: float = 100.0
## Segundos desde el estómago lleno hasta vacío.
const SECONDS_TO_STARVE: float = 600.0
## Saciedad que da un copo de comida.
const HUNGER_PER_FLAKE: float = 12.0
## Limpieza que pierde la pecera por segundo y por pez.
const DIRT_PER_FISH_PER_SECOND: float = 0.003
## Limpieza que recupera cada mancha de alga que se limpia.
const SPOT_STEP: float = 10.0
const MAX_SPOTS: int = 10
## Pesos de la felicidad; sumarán 1 cuando llegue la comodidad (decoración).
const HUNGER_WEIGHT: float = 0.55
const CLEANLINESS_WEIGHT: float = 0.45
## Segundos medios entre perlas de una pecera con peces.
const PEARL_MIN_SECONDS: float = 40.0
const PEARL_MAX_SECONDS: float = 90.0
## Una perla vale lo que produce el pez que la suelta durante este tiempo.
const PEARL_SECONDS_OF_PRODUCTION: float = 30.0
## Por debajo de esta saciedad un pez busca comida.
const HUNGRY_BELOW: float = 90.0


## Saciedad tras [param dt] segundos sin comer.
static func hunger_after(hunger: float, dt: float) -> float:
	return clampf(hunger - MAX_HUNGER / SECONDS_TO_STARVE * dt, 0.0, MAX_HUNGER)


## Limpieza de una pecera con [param fish_count] peces tras [param dt] segundos.
static func cleanliness_after(cleanliness: float, fish_count: int, dt: float) -> float:
	var lost: float = DIRT_PER_FISH_PER_SECOND * float(fish_count) * dt
	return clampf(cleanliness - lost, 0.0, MAX_CLEANLINESS)


## Felicidad de 0 a 100 a partir de saciedad y limpieza.
static func happiness(hunger: float, cleanliness: float) -> float:
	var fed: float = clampf(hunger / MAX_HUNGER, 0.0, 1.0)
	var clean: float = clampf(cleanliness / MAX_CLEANLINESS, 0.0, 1.0)
	return 100.0 * (HUNGER_WEIGHT * fed + CLEANLINESS_WEIGHT * clean)


## Manchas de alga que se ven con esa limpieza: una por cada [constant SPOT_STEP]
## puntos de suciedad completos. Así limpiar una mancha (que devuelve exactamente
## SPOT_STEP puntos) quita siempre una, aunque la suciedad vuelva a subir un poco.
static func spots_for(cleanliness: float) -> int:
	var dirt: float = MAX_CLEANLINESS - clampf(cleanliness, 0.0, MAX_CLEANLINESS)
	return clampi(floori(dirt / SPOT_STEP), 0, MAX_SPOTS)


## Conchas que da una perla soltada por un pez que produce [param fish_rate].
static func pearl_value(fish_rate: float) -> float:
	return maxf(1.0, ceilf(fish_rate * PEARL_SECONDS_OF_PRODUCTION))


## Multiplicador de velocidad de nado según la felicidad: de ×0,45 a ×1.
static func speed_factor(happiness_value: float) -> float:
	return lerpf(0.45, 1.0, clampf(happiness_value / 100.0, 0.0, 1.0))


## Cuánto se apaga el color (0 a 0,8): nada con felicidad alta, mucho con tristeza.
static func desaturation(happiness_value: float) -> float:
	var sad: float = 1.0 - clampf(happiness_value / 80.0, 0.0, 1.0)
	return 0.8 * sad
