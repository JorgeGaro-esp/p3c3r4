class_name AsciiToast
extends AsciiLabel
## Aviso breve ("¡Nueva variante!"): aparece con un texto, se desvanece y se
## apaga solo. Con [member AsciiLabel.wraps] reparte el texto en varias filas.

const DEFAULT_SECONDS: float = 3.0
const FADE_SECONDS: float = 0.6
## Avisos que pueden esperar su turno mientras se ve otro.
const MAX_QUEUED: int = 4

var _remaining: float = 0.0
var _queue: PackedStringArray = PackedStringArray()


func _init() -> void:
	wraps = true
	color = AsciiColors.AMBER


## Muestra [param message] durante [param seconds] segundos. Si ya se ve otro
## aviso, este espera su turno (hasta [constant MAX_QUEUED]) en vez de taparlo.
func show_message(message: String, seconds: float = DEFAULT_SECONDS) -> void:
	if _remaining > 0.0 and message != text:
		if _queue.size() < MAX_QUEUED and not _queue.has(message):
			_queue.append(message)
		return
	text = message
	_remaining = seconds


## Indica si hay un aviso visible.
func is_active() -> bool:
	return _remaining > 0.0


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if _remaining > 0.0:
		_remaining = maxf(_remaining - delta, 0.0)
	if _remaining <= 0.0 and not _queue.is_empty():
		text = _queue[0]
		_queue.remove_at(0)
		_remaining = DEFAULT_SECONDS


func draw(canvas: AsciiCanvas) -> void:
	if _remaining <= 0.0:
		return
	var original: Color = color
	color = Color(original, clampf(_remaining / FADE_SECONDS, 0.0, 1.0))
	super.draw(canvas)
	color = original
