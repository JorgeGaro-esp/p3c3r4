class_name SurfaceView
extends AsciiDrawable
## Superficie del agua: una fila de olas `~^~^` que se desplaza y se mece.

const PATTERN: String = "~^~^"
## Celdas por segundo que avanza el dibujo de las olas.
const SCROLL_SPEED: float = 2.2
const BOB_AMPLITUDE: float = 0.12
const BOB_SPEED: float = 2.0
const BOB_SPREAD: float = 0.7

var _columns: int = 0
var _top_row: int = 0
var _pattern: String = PATTERN
var _color: Color = AsciiColors.WATER
var _clock: float = 0.0


## Fija cuántas columnas tiene la superficie y en qué fila va.
func configure(
	new_columns: int, top_row: int, pattern: String = PATTERN, color: Color = AsciiColors.WATER
) -> void:
	_columns = new_columns
	_top_row = top_row
	_pattern = pattern
	_color = color


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	var scroll: float = _clock * SCROLL_SPEED
	var whole: int = int(floorf(scroll))
	var fraction: float = scroll - floorf(scroll)
	for column: int in range(-1, _columns):
		var index: int = posmod(column - whole, _pattern.length())
		var bob: float = sin(_clock * BOB_SPEED + float(column) * BOB_SPREAD) * BOB_AMPLITUDE
		canvas.put_char(
			_pattern[index], Vector2(float(column) + fraction, float(_top_row) + bob), _color
		)
