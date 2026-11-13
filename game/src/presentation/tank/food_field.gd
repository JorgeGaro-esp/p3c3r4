class_name FoodField
extends AsciiDrawable
## Copos de comida que caen desde donde el jugador hace clic. Los peces
## hambrientos los buscan y se los comen; los que llegan al fondo se disuelven.

const MAX_FLAKES: int = 40
const FLAKES_PER_DROP: int = 3
const FALL_MIN: float = 2.5
const FALL_MAX: float = 3.5
const SPREAD: float = 1.5
const SWAY_AMPLITUDE: float = 0.25
const SWAY_SPEED: float = 3.0
const COLOR: Color = Color(0.93, 0.78, 0.42)
const GLYPH: String = "·"

## Fila del fondo: los copos desaparecen al llegar.
var floor_row: float = 10.0

var _flakes: Array[Flake] = []
var _clock: float = 0.0


## Suelta unos copos alrededor de [param cell]. El generador llega de fuera.
func drop(cell: Vector2, rng: RandomNumberGenerator) -> void:
	for index: int in range(FLAKES_PER_DROP):
		if _flakes.size() >= MAX_FLAKES:
			return
		var flake: Flake = Flake.new()
		flake.x = cell.x + rng.randf_range(-SPREAD, SPREAD)
		flake.y = cell.y - float(index) * 0.6
		flake.speed = rng.randf_range(FALL_MIN, FALL_MAX)
		flake.phase = rng.randf_range(0.0, TAU)
		_flakes.append(flake)


func count() -> int:
	return _flakes.size()


## Posición del copo [param index].
func position_of(index: int) -> Vector2:
	return Vector2(_flakes[index].x, _flakes[index].y)


## Se come (quita) el copo [param index].
func remove_at(index: int) -> void:
	_flakes.remove_at(index)


## Índice del copo más cercano a [param point] dentro de [param max_distance], o -1.
func nearest_to(point: Vector2, max_distance: float) -> int:
	var best: int = -1
	var best_distance: float = max_distance
	for index: int in range(_flakes.size()):
		var distance: float = point.distance_to(position_of(index))
		if distance <= best_distance:
			best = index
			best_distance = distance
	return best


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	for index: int in range(_flakes.size() - 1, -1, -1):
		var flake: Flake = _flakes[index]
		flake.y += flake.speed * delta
		if flake.y >= floor_row:
			_flakes.remove_at(index)


func draw(canvas: AsciiCanvas) -> void:
	for flake: Flake in _flakes:
		var sway: float = sin(_clock * SWAY_SPEED + flake.phase) * SWAY_AMPLITUDE
		canvas.put_char(GLYPH, Vector2(flake.x + sway, flake.y), COLOR)


class Flake:
	var x: float = 0.0
	var y: float = 0.0
	var speed: float = 3.0
	var phase: float = 0.0
