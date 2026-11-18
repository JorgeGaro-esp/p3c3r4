class_name DayCycle
extends RefCounted
## El ciclo del día (GDD §12): cuatro franjas según la hora y una "oscuridad" de 0
## (pleno día) a 1 (noche cerrada) que cambia poco a poco entre franjas.
##
## Todo son funciones puras de la hora (0 a 24): el reloj que la da se inyecta desde
## fuera ([DayClock]), así los tests pueden fijar la hora.
##
## La hora no cambia el comportamiento ni la producción de los peces: el ciclo solo
## afecta a la luz de la pecera.

enum Phase { DAWN, DAY, DUSK, NIGHT }

const DAWN_START: float = 6.0
const DAY_START: float = 8.0
const DUSK_START: float = 18.0
const NIGHT_START: float = 21.0


## Pone [param hour] dentro de [0, 24).
static func normalize(hour: float) -> float:
	return fposmod(hour, 24.0)


## Franja del día a la hora [param hour].
static func phase_at(hour: float) -> Phase:
	var h: float = normalize(hour)
	if h >= NIGHT_START or h < DAWN_START:
		return Phase.NIGHT
	if h < DAY_START:
		return Phase.DAWN
	if h < DUSK_START:
		return Phase.DAY
	return Phase.DUSK


## Oscuridad de 0 (día) a 1 (noche), con transición suave en el amanecer y el
## atardecer.
static func darkness(hour: float) -> float:
	var h: float = normalize(hour)
	if h >= NIGHT_START or h < DAWN_START:
		return 1.0
	if h < DAY_START:
		return 1.0 - _smooth((h - DAWN_START) / (DAY_START - DAWN_START))
	if h < DUSK_START:
		return 0.0
	return _smooth((h - DUSK_START) / (NIGHT_START - DUSK_START))


static func _smooth(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
