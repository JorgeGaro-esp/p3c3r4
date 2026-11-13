class_name LifeStage
extends RefCounted
## Etapas de vida de un pez (GDD §4.3): alevín, juvenil y adulto. El huevo no es un
## pez: vive aparte, en [Egg]. Los peces no envejecen ni mueren (D08).
##
## La madurez va de 0 a 1 y la etapa sale de ella, así que cambiar los tiempos de
## una especie no obliga a tocar nada más.

enum Stage { FRY, JUVENILE, ADULT }

## Madurez a partir de la cual el alevín pasa a juvenil.
const JUVENILE_FROM: float = 0.3
## Madurez a la que el pez es adulto (produce y cría).
const ADULT_FROM: float = 1.0


static func from_maturity(maturity: float) -> Stage:
	if maturity >= ADULT_FROM:
		return Stage.ADULT
	if maturity >= JUVENILE_FROM:
		return Stage.JUVENILE
	return Stage.FRY


## Fracción del valor de venta de un adulto que se paga por un pez en [param stage].
static func sale_factor(stage: Stage) -> float:
	match stage:
		Stage.FRY:
			return 0.2
		Stage.JUVENILE:
			return 0.5
		_:
			return 1.0


## Clave de traducción del nombre de la etapa.
static func name_key(stage: Stage) -> String:
	match stage:
		Stage.FRY:
			return "STAGE_FRY"
		Stage.JUVENILE:
			return "STAGE_JUVENILE"
		_:
			return "STAGE_ADULT"
