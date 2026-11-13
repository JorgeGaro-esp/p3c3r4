class_name ListModel
extends RefCounted
## Selección y desplazamiento de una lista con más elementos que filas visibles.

var count: int = 0
var visible_rows: int = 1
## Elemento seleccionado, o -1 si la lista está vacía.
var selected: int = -1
## Primer elemento visible.
var scroll: int = 0


## Fija el tamaño de la lista y de la ventana visible, y corrige selección y
## desplazamiento para que sigan siendo válidos.
func configure(new_count: int, new_visible_rows: int) -> void:
	count = maxi(new_count, 0)
	visible_rows = maxi(new_visible_rows, 1)
	selected = clampi(selected, 0, count - 1) if count > 0 else -1
	if count > 0 and selected < 0:
		selected = 0
	scroll = clampi(scroll, 0, max_scroll())
	_ensure_visible()


## Mayor desplazamiento posible.
func max_scroll() -> int:
	return maxi(count - visible_rows, 0)


## Selecciona [param index] (recortado a los límites).
func select(index: int) -> void:
	if count == 0:
		selected = -1
		return
	selected = clampi(index, 0, count - 1)
	_ensure_visible()


## Mueve la selección [param delta] elementos, sin dar la vuelta.
func move(delta: int) -> void:
	select(maxi(selected, 0) + delta)


## Mueve la selección una página.
func page(direction: int) -> void:
	move(direction * maxi(visible_rows - 1, 1))


## Desplaza la vista [param delta] filas sin cambiar la selección.
func scroll_by(delta: int) -> void:
	scroll = clampi(scroll + delta, 0, max_scroll())


## Elemento que está en la fila visible [param row], o -1 si no hay.
func index_at_row(row: int) -> int:
	var index: int = scroll + row
	if row < 0 or row >= visible_rows or index >= count:
		return -1
	return index


func _ensure_visible() -> void:
	if selected < 0:
		return
	if selected < scroll:
		scroll = selected
	elif selected >= scroll + visible_rows:
		scroll = selected - visible_rows + 1
