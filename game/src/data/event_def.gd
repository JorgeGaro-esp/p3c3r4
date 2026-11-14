class_name EventDef
extends Resource
## Definición de un evento aleatorio (GDD §12). Añadir uno consiste en crear un
## recurso de este tipo en `content/events/` y sus claves en `strings.csv`; el
## efecto lo decide [member kind] (ver [EventEffects]).
##
## Principio: ningún evento quita nada de forma permanente.

enum Kind { VISITOR, FOOD_RAIN, GOLDEN_FISH, WARM_CURRENT, BOTTLE, ALGAE_BLOOM }

@export var id: String = ""
@export var name_key: String = ""
## Aviso que sale al empezar. Admite un `%s` (el pez visitante, en su caso).
@export var message_key: String = ""
@export var kind: Kind = Kind.FOOD_RAIN
## Probabilidad relativa de que salga frente a los demás.
@export var weight: float = 1.0
## Peces mínimos en la pecera para que pueda salir.
@export var min_fish: int = 1
## Segundos que dura (la corriente cálida) o que se puede cobrar (los clicables).
@export var duration: float = 0.0
## La recompensa vale esos segundos de producción actual...
@export var reward_seconds: float = 0.0
## ...pero nunca menos de estas conchas (para que valga la pena al empezar).
@export var reward_min: float = 0.0


## Si hay que hacer clic en algo que aparece en la pecera.
func is_pickup() -> bool:
	return kind == Kind.VISITOR or kind == Kind.GOLDEN_FISH or kind == Kind.BOTTLE
