class_name PearlField
extends AsciiDrawable
## Perlas que sueltan los peces: caen hasta el fondo y esperan a que el jugador
## las recoja con un clic. Si hay demasiadas, la más antigua se recoge sola para
## que nunca se pierda nada.

const MAX_PEARLS: int = 12
const FALL_SPEED: float = 2.0
const SPARKLE_PERIOD: float = 0.9
## Azul clarito: destaca sobre el agua oscura y sobre la arena.
const COLOR: Color = Color(0.5, 0.82, 1.0)
const COLOR_SHINE: Color = Color(0.82, 0.95, 1.0)
## Siempre se dibuja el círculo grande; el brillo es un cambio de tono, no de
## glifo (el «◦» pequeño hacía que la perla casi desapareciera a ratos).
const GLYPH: String = "○"
## Margen del clic, en celdas, alrededor de la perla.
const HIT_MARGIN: float = 0.9

## Fila del fondo, donde las perlas se quedan.
var floor_row: float = 10.0

var _pearls: Array[Pearl] = []
var _clock: float = 0.0


## Añade una perla en [param cell]. Si ya había [constant MAX_PEARLS], devuelve el
## valor de la más antigua (que se retira); si no, devuelve 0.
func add(cell: Vector2, value: float) -> float:
	var evicted: float = 0.0
	if _pearls.size() >= MAX_PEARLS:
		evicted = _pearls[0].value
		_pearls.remove_at(0)
	var pearl: Pearl = Pearl.new()
	pearl.position = cell
	pearl.value = value
	_pearls.append(pearl)
	return evicted


func count() -> int:
	return _pearls.size()


## Retira todas las perlas y devuelve su valor (al cambiar de pecera).
func take_all() -> PackedFloat64Array:
	var values: PackedFloat64Array = PackedFloat64Array()
	for pearl: Pearl in _pearls:
		values.append(pearl.value)
	_pearls.clear()
	return values


## Índice de la perla en [param cell] (con un margen para que sea fácil acertar), o -1.
func pearl_at(cell: Vector2i) -> int:
	var point: Vector2 = Vector2(cell) + Vector2(0.5, 0.5)
	for index: int in range(_pearls.size() - 1, -1, -1):
		var center: Vector2 = _pearls[index].position + Vector2(0.5, 0.5)
		if absf(point.x - center.x) <= HIT_MARGIN and absf(point.y - center.y) <= HIT_MARGIN:
			return index
	return -1


func value_of(index: int) -> float:
	return _pearls[index].value


## Quita la perla [param index] y devuelve su valor.
func take(index: int) -> float:
	var value: float = _pearls[index].value
	_pearls.remove_at(index)
	return value


## Quita las perlas que llevan al menos [param delay] segundos en el suelo y
## devuelve sus valores (lo que hace el imán de perlas).
func take_ripe(delay: float) -> PackedFloat64Array:
	var values: PackedFloat64Array = PackedFloat64Array()
	var kept: Array[Pearl] = []
	for pearl: Pearl in _pearls:
		if pearl.resting_seconds >= delay:
			values.append(pearl.value)
		else:
			kept.append(pearl)
	_pearls = kept
	return values


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	for pearl: Pearl in _pearls:
		pearl.position.y = minf(pearl.position.y + FALL_SPEED * delta, floor_row)
		if pearl.position.y >= floor_row:
			pearl.resting_seconds += delta


func draw(canvas: AsciiCanvas) -> void:
	var shine: float = 0.5 + 0.5 * sin(_clock * TAU / SPARKLE_PERIOD) * MotionScale.factor()
	var color: Color = COLOR.lerp(COLOR_SHINE, shine)
	for pearl: Pearl in _pearls:
		canvas.put_char(GLYPH, pearl.position, color)


class Pearl:
	var position: Vector2 = Vector2.ZERO
	var value: float = 0.0
	## Segundos que lleva quieta en el suelo.
	var resting_seconds: float = 0.0
