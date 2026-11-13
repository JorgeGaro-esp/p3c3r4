class_name FocusRing
extends RefCounted
## Orden de foco del teclado: recorre los elementos activables, saltándose los
## que no lo están, y da la vuelta al llegar al final.
##
## Solo maneja índices; no sabe qué elementos hay. Así se prueba sin interfaz.

## Índice con foco, o -1 si no hay ninguno.
var current: int = -1

var _enabled: Array[bool] = []


## Define qué elementos pueden recibir foco. Si el actual deja de poder, se
## pierde el foco.
func rebuild(enabled: Array[bool]) -> void:
	_enabled = enabled.duplicate()
	if current >= _enabled.size() or (current >= 0 and not _enabled[current]):
		current = -1


## Cuántos elementos pueden recibir foco.
func enabled_count() -> int:
	var total: int = 0
	for is_enabled: bool in _enabled:
		if is_enabled:
			total += 1
	return total


## Pone el foco en el primer elemento posible. Devuelve el índice o -1.
func focus_first() -> int:
	current = -1
	return move(1)


## Mueve el foco [param step] elementos (1 = siguiente, -1 = anterior),
## saltando los desactivados y dando la vuelta. Devuelve el nuevo índice o -1 si
## no hay ningún elemento posible.
func move(step: int) -> int:
	var size: int = _enabled.size()
	if size == 0 or enabled_count() == 0:
		current = -1
		return current
	var direction: int = 1 if step >= 0 else -1
	var index: int = current
	if index < 0:
		index = -1 if direction > 0 else size
	for _attempt: int in range(size):
		index = posmod(index + direction, size)
		if _enabled[index]:
			current = index
			return current
	return current


## Pone el foco en [param index] si puede recibirlo; si no, lo quita.
func set_current(index: int) -> void:
	current = index if index >= 0 and index < _enabled.size() and _enabled[index] else -1
