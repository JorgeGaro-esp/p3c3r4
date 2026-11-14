class_name DayCycle
extends RefCounted
## El ciclo del día (GDD §12): cuatro franjas según la hora y una "oscuridad" de 0
## (pleno día) a 1 (noche cerrada) que cambia poco a poco entre franjas.
##
## Todo son funciones puras de la hora (0 a 24): el reloj que la da se inyecta desde
## fuera ([DayClock]), así los tests pueden fijar la hora.
##
## Efecto sobre la producción: las especies nocturnas producen algo más de noche y
## algo menos de día; las diurnas, al revés. Es un efecto suave ([constant NIGHT_EFFECT])
## que se compensa en un día completo y que la lámpara reduce en lo malo (nunca
## quita lo bueno).

enum Phase { DAWN, DAY, DUSK, NIGHT }

const DAWN_START: float = 6.0
const DAY_START: float = 8.0
const DUSK_START: float = 18.0
const NIGHT_START: float = 21.0
## Variación máxima de la producción de una especie nocturna o diurna (±15 %).
const NIGHT_EFFECT: float = 0.15


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


## Cuánto multiplica la producción de una especie con [param activity] cuando la
## oscuridad es [param dark]. [param shield] (0 a 1, de la lámpara) recorta la
## parte negativa.
static func activity_factor(activity: SpeciesDef.Activity, dark: float, shield: float) -> float:
	var lean: float = 0.0
	if activity == SpeciesDef.Activity.NOCTURNAL:
		lean = 2.0 * dark - 1.0
	elif activity == SpeciesDef.Activity.DIURNAL:
		lean = 1.0 - 2.0 * dark
	var effect: float = NIGHT_EFFECT * lean
	if effect < 0.0:
		effect *= 1.0 - clampf(shield, 0.0, 1.0)
	return 1.0 + effect


static func _smooth(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
