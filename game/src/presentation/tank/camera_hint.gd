class_name CameraHint
extends AsciiDrawable
## Avisa de que la pecera es más ancha que la ventana: dos flechas en los bordes
## por donde queda más mundo y, tras mover la cámara, una barra con su posición.
## Va encima del mundo, fija en la ventana.

const LAYER: int = 70
const BAR_COLUMNS: int = 24
const BAR_SECONDS: float = 2.0
const FADE_SECONDS: float = 0.6
const ARROW_LEFT: String = "◄"
const ARROW_RIGHT: String = "►"
const TRACK: String = "─"
const THUMB: String = "█"
const THUMB_COLUMNS: int = 3
const ARROW_ALPHA: float = 0.55
const ARROW_PULSE: float = 0.25

var _camera: TankCamera = null
var _view: Rect2i = Rect2i()
var _bar_left: float = 0.0
var _time: float = 0.0


func _init(camera: TankCamera = null) -> void:
	_camera = camera
	layer = LAYER


## Zona visible de la pecera (en celdas de la ventana).
func set_view(view: Rect2i) -> void:
	_view = view


## Enseña la barra de posición unos segundos.
func flash() -> void:
	_bar_left = BAR_SECONDS


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_time += delta
	_bar_left = maxf(_bar_left - delta, 0.0)


func draw(canvas: AsciiCanvas) -> void:
	if _camera == null or not _camera.is_scrollable() or not _view.has_area():
		return
	_draw_arrows(canvas)
	if _bar_left > 0.0 or _camera.is_panning:
		_draw_bar(canvas)


func _draw_arrows(canvas: AsciiCanvas) -> void:
	var pulse: float = ARROW_ALPHA + ARROW_PULSE * sin(_time * 3.0) * MotionScale.factor()
	var color: Color = AsciiColors.AMBER
	color.a = clampf(pulse, 0.0, 1.0)
	var row: float = float(_view.position.y + _view.size.y / 2)
	if _camera.x > 0.5:
		canvas.put_char(ARROW_LEFT, Vector2(float(_view.position.x), row), color)
	if _camera.x < _camera.max_x() - 0.5:
		canvas.put_char(ARROW_RIGHT, Vector2(float(_view.end.x - 1), row), color)


func _draw_bar(canvas: AsciiCanvas) -> void:
	var width: int = mini(BAR_COLUMNS, _view.size.x)
	var left: int = _view.position.x + (_view.size.x - width) / 2
	var row: float = float(_view.end.y - 1)
	var alpha: float = 1.0
	if not _camera.is_panning:
		alpha = clampf(_bar_left / FADE_SECONDS, 0.0, 1.0)
	var track: Color = AsciiColors.TEXT_DIM
	track.a = alpha
	var thumb: Color = AsciiColors.AMBER
	thumb.a = alpha
	var thumb_start: int = roundi(_camera.fraction() * float(width - THUMB_COLUMNS))
	for column: int in range(width):
		var is_thumb: bool = column >= thumb_start and column < thumb_start + THUMB_COLUMNS
		canvas.put_char(
			THUMB if is_thumb else TRACK,
			Vector2(float(left + column), row),
			thumb if is_thumb else track
		)
