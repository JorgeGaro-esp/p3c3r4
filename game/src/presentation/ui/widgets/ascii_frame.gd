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
	canvas.put_string(BoxDrawing.top_line(width, title, is_double), origin, border_color)
	canvas.put_string(
		BoxDrawing.bottom_line(width, is_double),
		origin + Vector2(0.0, float(height - 1)),
		border_color
	)
	var side: String = BoxDrawing.side(is_double)
	for row: int in range(1, height - 1):
		canvas.put_char(side, origin + Vector2(0.0, float(row)), border_color)
		canvas.put_char(side, origin + Vector2(float(width - 1), float(row)), border_color)
	var room: int = width - BoxDrawing.TITLE_LEAD - BoxDrawing.TITLE_TAIL
	if not title.is_empty() and room >= 1:
		canvas.put_string(
			UiText.fit(title, room),
			origin + Vector2(float(BoxDrawing.TITLE_LEAD), 0.0),
			title_color
		)


func handle_click(_cell: Vector2i, _is_double: bool) -> bool:
	return true


func handle_wheel(_cell: Vector2i, _direction: int) -> bool:
	return false
