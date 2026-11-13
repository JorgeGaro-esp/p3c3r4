class_name FixedStepper
extends RefCounted
## Convierte el tiempo de cada fotograma en un número entero de pasos fijos.
##
## La simulación avanza en pasos de [constant STEP_SECONDS] (10 por segundo, T05).
## Si un fotograma tarda mucho (pausa, arrastre de la ventana), se ejecutan como
## máximo [constant MAX_STEPS_PER_FRAME] pasos y el resto del tiempo se descarta:
## no se "recupera" tiempo perdido (D11).

const STEP_SECONDS: float = 0.1
const MAX_STEPS_PER_FRAME: int = 5
## Tolerancia para que 0,0999999… cuente como 0,1 (errores de coma flotante).
const EPSILON: float = 1.0e-9

var _accumulator: float = 0.0


## Añade [param delta] segundos y devuelve cuántos pasos hay que ejecutar.
func advance(delta: float) -> int:
	if is_nan(delta) or delta <= 0.0:
		return 0
	_accumulator += delta
	var steps: int = int((_accumulator + EPSILON) / STEP_SECONDS)
	if steps > MAX_STEPS_PER_FRAME:
		steps = MAX_STEPS_PER_FRAME
		_accumulator = 0.0
	else:
		_accumulator = maxf(_accumulator - float(steps) * STEP_SECONDS, 0.0)
	return steps


func reset() -> void:
	_accumulator = 0.0
