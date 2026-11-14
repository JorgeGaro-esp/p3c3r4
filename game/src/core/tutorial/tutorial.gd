class_name Tutorial
extends RefCounted
## Tutorial breve de los primeros minutos: una lista de pasos, cada uno con el
## aviso que se enseña y la acción del jugador que lo da por cumplido.
##
## Datos puros: no sabe nada de nodos. El progreso (el paso actual) vive en los
## ajustes del usuario, no en la partida, para que no se repita en cada partida nueva.

## Acciones que el jugador puede hacer (las que cumplen un paso).
enum Action { FEED, PEARL, BUY, CARD, SHORTCUTS }

## Pasos en orden: la acción que lo cumple. La clave del texto es `TUTORIAL_<n>`.
const STEPS: Array[Action] = [Action.FEED, Action.PEARL, Action.BUY, Action.CARD, Action.SHORTCUTS]
## Pasos tras los que el tutorial termina (= cantidad de pasos).
const DONE: int = 5
## Segundos que se enseña el último aviso (el de atajos) antes de darse por visto.
const LAST_STEP_SECONDS: float = 14.0


## Verdadero si el paso [param step] existe (no se ha terminado el tutorial).
static func is_active_step(step: int) -> bool:
	return step >= 0 and step < STEPS.size()


## Verdadero si [param action] cumple el paso [param step].
static func completes(step: int, action: Action) -> bool:
	return is_active_step(step) and STEPS[step] == action


## Clave de traducción del aviso del paso [param step].
static func text_key(step: int) -> String:
	return "TUTORIAL_%d" % step
