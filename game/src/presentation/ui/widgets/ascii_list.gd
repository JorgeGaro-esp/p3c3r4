class_name AsciiList
extends AsciiWidget
## Lista de filas seleccionables con una segunda columna a la derecha (precios) y
## barra de desplazamiento cuando hay más elementos que filas.

signal selection_changed(index: int)
## Se emite con doble clic o con Intro sobre un elemento.
signal chosen(index: int)

const MARKER: String = "►"
const _SCROLL_TRACK: String = "░"
const _SCROLL_THUMB: String = "█"

var names: PackedStringArray = PackedStringArray()
var extras: PackedStringArray = PackedStringArray()
var model: ListModel = ListModel.new()


func _init() -> void:
	is_focusable = true
	focus_on_click = true
	wheel_fallback = true


## Cambia el rectángulo y reajusta las filas visibles.
func set_rect(new_rect: Rect2i) -> void:
	rect = new_rect
	model.configure(names.size(), rect.size.y)


## Sustituye el contenido. [param new_extras] puede ser más corto que los nombres.
func set_items(new_names: PackedStringArray, new_extras: PackedStringArray) -> void:
	names = new_names
	extras = new_extras
	model.selected = 0
	model.scroll = 0
	model.configure(names.size(), rect.size.y)


## Elemento seleccionado (-1 si no hay).
func selected_index() -> int:
	return model.selected


func draw(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	if width < 3:
		return
	var has_bar: bool = model.max_scroll() > 0
	var text_width: int = width - 1 - (1 if has_bar else 0)
	for row: int in range(rect.size.y):
		var index: int = model.index_at_row(row)
		if index < 0:
			break
		var extra: String = extras[index] if index < extras.size() else ""
		var line: String = UiText.join_ends(names[index], extra, text_width)
		var origin: Vector2 = Vector2(rect.position + Vector2i(0, row))
		var is_selected: bool = index == model.selected
		var color: Color = AsciiColors.TEXT
		if is_selected and is_focused:
			canvas.fill_rect_cells(
				Rect2i(rect.position + Vector2i(0, row), Vector2i(width, 1)), AsciiColors.AMBER
			)
			color = Color.BLACK
		elif is_selected:
			color = AsciiColors.AMBER
		canvas.put_string((MARKER if is_selected else " ") + line, origin, color)
	if has_bar:
		_draw_scroll_bar(canvas)


func handle_key(event: InputEventKey) -> bool:
	var before: int = model.selected
	match event.keycode:
		KEY_UP:
			model.move(-1)
		KEY_DOWN:
			model.move(1)
		KEY_PAGEUP:
			model.page(-1)
		KEY_PAGEDOWN:
			model.page(1)
		KEY_HOME:
			model.select(0)
		KEY_END:
			model.select(names.size() - 1)
		_:
			if is_confirm_key(event) and model.selected >= 0:
				chosen.emit(model.selected)
				return true
			return false
	if model.selected != before:
		selection_changed.emit(model.selected)
	return true


func handle_click(cell: Vector2i, is_double: bool) -> bool:
	var index: int = model.index_at_row(cell.y - rect.position.y)
	if index < 0:
		return true
	var changed: bool = index != model.selected
	model.select(index)
	if changed:
		selection_changed.emit(index)
	if is_double:
		chosen.emit(index)
	return true


func handle_wheel(_cell: Vector2i, direction: int) -> bool:
	model.scroll_by(direction)
	return true


func _draw_scroll_bar(canvas: AsciiCanvas) -> void:
	var column: float = float(rect.end.x - 1)
	var thumb: int = 0
	if model.max_scroll() > 0:
		thumb = roundi(float(model.scroll) * float(rect.size.y - 1) / float(model.max_scroll()))
	for row: int in range(rect.size.y):
		var character: String = _SCROLL_THUMB if row == thumb else _SCROLL_TRACK
		var color: Color = AsciiColors.AMBER if row == thumb else AsciiColors.TEXT_DIM
		canvas.put_char(character, Vector2(column, float(rect.position.y + row)), color)
