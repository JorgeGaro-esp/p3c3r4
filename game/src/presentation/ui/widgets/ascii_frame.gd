class_name AsciiFrame
extends AsciiWidget
## Marco de caja con título. Rellena su interior de negro, así que tapa lo que
## haya detrás (sirve de fondo de panel). Un clic dentro se consume para no
## llegar a lo que queda debajo.

var title: String = ""
var is_double: bool = false
var border_color: Color = AsciiColors.TEXT_DIM
var title_color: Color = AsciiColors.AMBER


func draw(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	var height: int = rect.size.y
	if width < 2 or height < 2:
		return
	canvas.fill_rect_cells(rect, Color.BLACK)
	var origin: Vector2 = Vector2(rect.position)
	# Cada pieza se coloca por su columna y su fila, nunca como parte de una cadena:
	# así las esquinas coinciden siempre con los lados.
	var chars: String = BoxDrawing.DOUBLE if is_double else BoxDrawing.SINGLE
	var last_x: int = width - 1
	var last_y: int = height - 1
	for column: int in range(width):
		var top_char: String = chars[4]
		var bottom_char: String = chars[4]
		if column == 0:
			top_char = chars[0]
			bottom_char = chars[2]
		elif column == last_x:
			top_char = chars[1]
			bottom_char = chars[3]
		canvas.put_char(top_char, origin + Vector2(float(column), 0.0), border_color)
		canvas.put_char(bottom_char, origin + Vector2(float(column), float(last_y)), border_color)
	var side: String = chars[5]
	for row: int in range(1, last_y):
		canvas.put_char(side, origin + Vector2(0.0, float(row)), border_color)
		canvas.put_char(side, origin + Vector2(float(last_x), float(row)), border_color)
	var room: int = width - BoxDrawing.TITLE_LEAD - BoxDrawing.TITLE_TAIL
	if not title.is_empty() and room >= 1:
		var shown: String = UiText.fit(title, room)
		# Un hueco a cada lado del título, como en ` Título `.
		canvas.fill_rect_cells(
			Rect2i(
				rect.position + Vector2i(BoxDrawing.TITLE_LEAD - 1, 0),
				Vector2i(shown.length() + 2, 1)
			),
			Color.BLACK
		)
		canvas.put_string(shown, origin + Vector2(float(BoxDrawing.TITLE_LEAD), 0.0), title_color)


func handle_click(_cell: Vector2i, _is_double: bool) -> bool:
	return true


func handle_wheel(_cell: Vector2i, _direction: int) -> bool:
	return false
