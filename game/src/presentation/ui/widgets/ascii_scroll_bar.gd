class_name AsciiScrollBar
extends AsciiWidget
## Barra de desplazamiento vertical que se puede usar de verdad: clic en la pista,
## arrastrar el tirador y rueda del ratón (en cualquier parte, porque es un
## `wheel_fallback`). No mueve nada por sí sola: avisa con [signal scrolled] y
## quien la usa recoloca su contenido.

signal scrolled(position: int)

const TRACK: String = "░"
const THUMB: String = "█"

## Posición actual (0 = arriba).
var position: int = 0
## Mayor posición posible (0 = no hace falta barra).
var max_position: int = 0
## Se llama en cada fotograma; sirve para que el dueño la mantenga al día.
var tick: Callable = Callable()


func _init() -> void:
	wheel_fallback = true


## Fija el recorrido y la posición (recortada al rango).
func configure(new_max: int, new_position: int) -> void:
	max_position = maxi(new_max, 0)
	position = clampi(new_position, 0, max_position)


func update(_delta: float, _canvas: AsciiCanvas) -> void:
	if tick.is_valid():
		tick.call()


func draw(canvas: AsciiCanvas) -> void:
	if max_position <= 0 or rect.size.y < 2 or rect.size.x < 1:
		return
	var thumb: int = _thumb_row()
	for row: int in range(rect.size.y):
		var is_thumb: bool = row == thumb
		canvas.put_char(
			THUMB if is_thumb else TRACK,
			Vector2(float(rect.position.x), float(rect.position.y + row)),
			AsciiColors.AMBER if is_thumb else AsciiColors.TEXT_DIM
		)


func handle_click(cell: Vector2i, _is_double: bool) -> bool:
	_move_to_row(cell.y - rect.position.y)
	return true


func begins_drag(_cell: Vector2i) -> bool:
	return max_position > 0


func handle_drag(cell: Vector2i) -> void:
	_move_to_row(cell.y - rect.position.y)


func handle_wheel(_cell: Vector2i, direction: int) -> bool:
	if max_position <= 0:
		return false
	_set_position(position + direction)
	return true


## Fila de la pista donde se dibuja el tirador.
func _thumb_row() -> int:
	return roundi(float(position) * float(rect.size.y - 1) / float(maxi(max_position, 1)))


func _move_to_row(row: int) -> void:
	var span: int = maxi(rect.size.y - 1, 1)
	var fraction: float = clampf(float(row) / float(span), 0.0, 1.0)
	_set_position(roundi(fraction * float(max_position)))


func _set_position(value: int) -> void:
	var next: int = clampi(value, 0, max_position)
	if next == position:
		return
	position = next
	scrolled.emit(position)
