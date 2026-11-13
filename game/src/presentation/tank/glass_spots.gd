class_name GlassSpots
extends AsciiDrawable
## Manchas de alga en el cristal. Cuantas más haya, más sucia está el agua
## ([method Care.spots_for]). Se limpian pasando el ratón con el botón pulsado.
##
## Las posiciones son fijas (salen de una semilla), de modo que la pecera no
## «baila» al ensuciarse; lo que cambia es cuántas se ven.

const SEED: int = 20261114
const WIDTH: int = 3
const HEIGHT: int = 2
const COLOR: Color = Color(0.16, 0.52, 0.3)
const TOP_ROW: String = "▓▒░"
const BOTTOM_ROW: String = "░▒"

var _fractions: Array[Vector2] = []
var _positions: Array[Vector2i] = []
var _shown: int = 0


func _init() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	for _index: int in range(Care.MAX_SPOTS):
		_fractions.append(Vector2(rng.randf(), rng.randf()))
		_positions.append(Vector2i.ZERO)


## Reparte las manchas dentro de [param area] (la zona de agua, en celdas).
func configure(area: Rect2i) -> void:
	var room_x: int = maxi(area.size.x - WIDTH - 2, 1)
	var room_y: int = maxi(area.size.y - HEIGHT - 2, 1)
	for index: int in range(_fractions.size()):
		_positions[index] = Vector2i(
			area.position.x + 1 + floori(_fractions[index].x * float(room_x)),
			area.position.y + 1 + floori(_fractions[index].y * float(room_y))
		)


## Cuántas manchas se ven.
func set_count(count: int) -> void:
	_shown = clampi(count, 0, _positions.size())


func count() -> int:
	return _shown


## Índice de la mancha visible que cubre [param cell], o -1.
func spot_at(cell: Vector2i) -> int:
	for index: int in range(_shown):
		var origin: Vector2i = _positions[index]
		if Rect2i(origin, Vector2i(WIDTH, HEIGHT)).has_point(cell):
			return index
	return -1


## Prepara que la mancha [param index] sea la próxima en desaparecer: la pasa al
## final de las visibles, que es la que se quita al bajar el contador.
func mark_for_removal(index: int) -> void:
	if index < 0 or index >= _shown:
		return
	var last: int = _shown - 1
	var swap: Vector2i = _positions[index]
	_positions[index] = _positions[last]
	_positions[last] = swap


func draw(canvas: AsciiCanvas) -> void:
	for index: int in range(_shown):
		var origin: Vector2 = Vector2(_positions[index])
		canvas.put_string(TOP_ROW, origin, COLOR)
		canvas.put_string(BOTTOM_ROW, origin + Vector2(0.5, 1.0), COLOR)
