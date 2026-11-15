class_name AsciiTabs
extends AsciiWidget
## Pestañas en una fila: ` Peces [Equipo] `. La activa lleva corchetes (así no
## depende solo del color). Izquierda y derecha cambian de pestaña con el foco.

signal tab_changed(index: int)

var titles: PackedStringArray = PackedStringArray()
var selected: int = 0
## Posiciones de las pestañas que se ven (vacío: todas). Las demás no se pintan
## ni se pueden elegir con el teclado o el ratón.
var visible_tabs: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	is_focusable = true
	focus_on_click = true


## Cambia las pestañas y deja la primera seleccionada.
func set_titles(new_titles: PackedStringArray) -> void:
	titles = new_titles
	selected = 0


## Deja a la vista solo las pestañas [param indices] (vacío: todas).
func set_visible_tabs(indices: PackedInt32Array) -> void:
	visible_tabs = indices


## Posiciones de las pestañas que se ven ahora.
func shown_tabs() -> PackedInt32Array:
	if not visible_tabs.is_empty():
		return visible_tabs
	var all: PackedInt32Array = PackedInt32Array()
	for index: int in range(titles.size()):
		all.append(index)
	return all


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
	for index: int in shown_tabs():
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
		return _step(-1)
	if event.keycode == KEY_RIGHT:
		return _step(1)
	return false


func handle_click(cell: Vector2i, _is_double: bool) -> bool:
	var column: int = rect.position.x
	for index: int in shown_tabs():
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


## Pasa a la pestaña visible anterior o siguiente (sin salirse de las visibles).
func _step(direction: int) -> bool:
	var shown: PackedInt32Array = shown_tabs()
	var at: int = shown.find(selected)
	if at < 0:
		return false
	var target: int = clampi(at + direction, 0, shown.size() - 1)
	select(shown[target])
	return true
