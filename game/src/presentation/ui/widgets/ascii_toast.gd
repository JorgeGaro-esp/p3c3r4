class_name AsciiToast
extends AsciiLabel
## Aviso breve ("¡Nueva variante!"): aparece con un texto, se desvanece y se
## apaga solo. Con [member AsciiLabel.wraps] reparte el texto en varias filas.

const DEFAULT_SECONDS: float = 3.0
const FADE_SECONDS: float = 0.6

var _remaining: float = 0.0


func _init() -> void:
	wraps = true
	color = AsciiColors.AMBER


## Muestra [param message] durante [param seconds] segundos.
func show_message(message: String, seconds: float = DEFAULT_SECONDS) -> void:
	text = message
	_remaining = seconds


## Indica si hay un aviso visible.
func is_active() -> bool:
	return _remaining > 0.0


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if _remaining > 0.0:
		_remaining = maxf(_remaining - delta, 0.0)


func draw(canvas: AsciiCanvas) -> void:
	if _remaining <= 0.0:
		return
	var original: Color = color
	color = Color(original, clampf(_remaining / FADE_SECONDS, 0.0, 1.0))
	super.draw(canvas)
	color = original
