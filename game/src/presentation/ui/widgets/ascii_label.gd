class_name AsciiLabel
extends AsciiWidget
## Texto fijo en una o varias filas.

enum Align { LEFT, CENTER, RIGHT }

var text: String = ""
var color: Color = AsciiColors.TEXT
var align: Align = Align.LEFT
## Si es verdadero, el texto se reparte en las filas del rectángulo.
var wraps: bool = false


func draw(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	if width <= 0 or text.is_empty():
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
