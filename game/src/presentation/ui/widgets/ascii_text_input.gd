class_name AsciiTextInput
extends AsciiWidget
## Campo de texto de una fila para escribir un apodo con el teclado. Mientras se
## edita, se queda con TODAS las teclas (UiRoot le da prioridad): así las letras no
## disparan los atajos del juego. Intro guarda, Esc cancela y Retroceso borra.
##
## Solo se aceptan caracteres que la fuente del juego sabe dibujar.

## El jugador pulsó Intro: [param value] es el texto ya sin espacios sobrantes.
signal submitted(value: String)
## El jugador pulsó Esc.
signal cancelled

const DEFAULT_MAX_LENGTH: int = 12
const CARET: String = "_"
const BLINK_SECONDS: float = 0.5

var text: String = ""
var max_length: int = DEFAULT_MAX_LENGTH
var is_editing: bool = false
## Texto fijo que se dibuja antes de lo escrito.
var prefix: String = ""

var _clock: float = 0.0


## Empieza a editar con [param initial] ya escrito.
func begin(initial: String) -> void:
	text = initial.substr(0, max_length)
	is_editing = true
	_clock = 0.0


## Deja de editar sin avisar (el dueño lo usa al cerrarse).
func stop() -> void:
	is_editing = false


func captures_keys() -> bool:
	return is_editing and is_shown


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	if not is_editing or rect.size.x <= 0:
		return
	var show_caret: bool = MotionScale.is_reduced() or int(_clock / BLINK_SECONDS) % 2 == 0
	var line: String = prefix + text + (CARET if show_caret else " ")
	canvas.put_string(UiText.fit(line, rect.size.x), Vector2(rect.position), AsciiColors.AMBER)


func handle_key(event: InputEventKey) -> bool:
	if not is_editing:
		return false
	match event.keycode:
		KEY_ESCAPE:
			if not event.echo:
				is_editing = false
				cancelled.emit()
		KEY_ENTER, KEY_KP_ENTER:
			if not event.echo:
				is_editing = false
				submitted.emit(text.strip_edges())
		KEY_BACKSPACE:
			text = text.substr(0, maxi(text.length() - 1, 0))
		_:
			_type(event.unicode)
	return true


func _type(code: int) -> void:
	if code < 32 or text.length() >= max_length:
		return
	var character: String = String.chr(code)
	if AsciiCharset.is_allowed(character):
		text += character
