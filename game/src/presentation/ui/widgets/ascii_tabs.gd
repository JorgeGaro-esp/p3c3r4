class_name AsciiTabs
extends AsciiWidget
## Pestañas en una fila: ` Peces [Equipo] `. La activa lleva corchetes (así no
## depende solo del color). Izquierda y derecha cambian de pestaña con el foco.

signal tab_changed(index: int)

var titles: PackedStringArray = PackedStringArray()
var selected: int = 0


func _init() -> void:
	is_focusable = true
	focus_on_click = true


## Cambia las pestañas y deja la primera seleccionada.
func set_titles(new_titles: PackedStringArray) -> void:
	titles = new_titles
	selected = 0


## Selecciona la pestaña [param index] y avisa si cambió.
func select(index: int) -> void:
	if titles.is_empty():
		return
	var value: int = clampi(index, 0, titles.size() - 1)
	if value != selected:
		selected = value
		tab_changed.emit(selected)


func draw(canvas: AsciiCanvas) -> void:
	var column: int = rect.position.x
	for index: int in range(titles.size()):
		var segment: String = _segment(index)
		var color: Color = AsciiColors.TEXT_DIM
		if index == selected:
			color = AsciiColors.AMBER
			if is_focused:
				canvas.fill_rect_cells(Rect2i(column, rect.position.y, segment.length(), 1), color)
				color = Color.BLACK
		elif is_hovered:
			color = AsciiColors.TEXT
		canvas.put_string(segment, Vector2(float(column), float(rect.position.y)), color)
		column += segment.length()


func handle_key(event: InputEventKey) -> bool:
	if event.keycode == KEY_LEFT:
		select(selected - 1)
		return true
	if event.keycode == KEY_RIGHT:
		select(selected + 1)
		return true
	return false


func handle_click(cell: Vector2i, _is_double: bool) -> bool:
	var column: int = rect.position.x
	for index: int in range(titles.size()):
		var end: int = column + _segment(index).length()
		if cell.x >= column and cell.x < end:
			select(index)
			break
		column = end
	return true


func _segment(index: int) -> String:
	if index == selected:
		return "[%s]" % titles[index]
	return " %s " % titles[index]
