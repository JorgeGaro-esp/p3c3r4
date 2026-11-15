class_name AsciiLabel
extends AsciiWidget
## Texto fijo en una o varias filas.

enum Align { LEFT, CENTER, RIGHT }

## Lo que hay que subir los símbolos geométricos para que queden a la altura de las cifras.
const ICON_LIFT: float = 0.11
## Hueco (en celdas) entre el símbolo y el texto que le sigue: el espacio que los
## separaba era una celda entera, demasiado.
const ICON_GAP: float = 0.2

var text: String = ""
var color: Color = AsciiColors.TEXT
var align: Align = Align.LEFT
## Si es verdadero, el texto se reparte en las filas del rectángulo.
var wraps: bool = false
## Si es verdadero, el primer carácter (un símbolo geométrico) se centra en su casilla.
var centered_icon: bool = false


func draw(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	if width <= 0 or text.is_empty():
		return
	if centered_icon and not wraps and text.length() > 1:
		canvas.put_glyph(text[0], Vector2(rect.position), color, 1.0, ICON_LIFT)
		var rest: String = text.substr(1).strip_edges(true, false)
		canvas.put_string(
			_align_line(rest, width - 1),
			Vector2(float(rect.position.x) + 1.0 + ICON_GAP, float(rect.position.y)),
			color
		)
		return
	if not wraps:
		canvas.put_string(_align_line(text, width), Vector2(rect.position), color)
		return
	var lines: PackedStringArray = UiText.wrap(text, width)
	for row: int in range(mini(lines.size(), rect.size.y)):
		canvas.put_string(
			_align_line(lines[row], width), Vector2(rect.position + Vector2i(0, row)), color
		)


func _align_line(line: String, width: int) -> String:
	match align:
		Align.CENTER:
			return UiText.center(line, width)
		Align.RIGHT:
			return UiText.pad_left(line, width)
	return UiText.fit(line, width)
