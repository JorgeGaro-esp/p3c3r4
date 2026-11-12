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
var _clock: float = 0.0


## Fija cuántas columnas tiene la rejilla.
func configure(new_columns: int) -> void:
	_columns = new_columns


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	var scroll: float = _clock * SCROLL_SPEED
	var whole: int = int(floorf(scroll))
	var fraction: float = scroll - floorf(scroll)
	for column: int in range(-1, _columns):
		var index: int = posmod(column - whole, PATTERN.length())
		var bob: float = sin(_clock * BOB_SPEED + float(column) * BOB_SPREAD) * BOB_AMPLITUDE
		canvas.put_char(PATTERN[index], Vector2(float(column) + fraction, bob), AsciiColors.WATER)
