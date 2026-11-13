class_name AsciiProgress
extends AsciiWidget
## Barra de progreso de una fila: bloques llenos y huecos (`████░░░░`).

## Valor entre 0 y 1.
var value: float = 0.0
var fill_color: Color = AsciiColors.SEAWEED_LIGHT
var empty_color: Color = AsciiColors.TEXT_DIM


func draw(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	if width <= 0:
		return
	var bar: String = UiText.bar(value, width)
	var filled: int = bar.count(UiText.FULL_BLOCK)
	canvas.put_string(bar.substr(0, filled), Vector2(rect.position), fill_color)
	canvas.put_string(bar.substr(filled), Vector2(rect.position + Vector2i(filled, 0)), empty_color)
