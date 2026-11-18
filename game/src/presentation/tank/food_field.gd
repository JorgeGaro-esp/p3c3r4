class_name FoodField
extends AsciiDrawable
## Copos de comida que caen desde donde el jugador hace clic. Los peces
## hambrientos los buscan y se los comen; los que llegan al fondo se quedan unos
## segundos en el suelo (se pueden comer todavía) y luego se disuelven.

const MAX_FLAKES: int = 40
const FLAKES_PER_DROP: int = 3
const FALL_MIN: float = 2.5
const FALL_MAX: float = 3.5
const SPREAD: float = 1.5
const SWAY_AMPLITUDE: float = 0.25
const SWAY_SPEED: float = 3.0
## Segundos que un copo se queda en el suelo antes de disolverse.
const REST_SECONDS: float = 6.0
## Con cuánto tiempo de reposo restante empieza a apagarse.
const FADE_SECONDS: float = 2.0
const COLOR: Color = Color(0.93, 0.78, 0.42)
const GLYPH: String = "•"
## Colores de los copos: cada uno sale de uno al azar.
const PALETTE: Array[Color] = [
	Color(1.0, 0.45, 0.45),
	Color(1.0, 0.7, 0.3),
	Color(1.0, 0.92, 0.4),
	Color(0.5, 0.9, 0.5),
	Color(0.4, 0.85, 1.0),
	Color(0.7, 0.6, 1.0),
	Color(1.0, 0.6, 0.85),
]
## Tamaño del copo respecto a la letra.
const FLAKE_SCALE: float = 1.0

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
		flake.color = PALETTE[rng.randi_range(0, PALETTE.size() - 1)]
		_flakes.append(flake)


func count() -> int:
	return _flakes.size()


## Quita todos los copos (al cambiar de pecera).
func clear() -> void:
	_flakes.clear()


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
		if not flake.landed:
			var fall: float = flake.speed * delta
			if flake.y + fall < floor_row:
				flake.y += fall
				continue
			# Llega al suelo: lo que sobra del paso cuenta ya como reposo.
			var spare: float = delta - maxf(floor_row - flake.y, 0.0) / maxf(flake.speed, 0.001)
			flake.y = floor_row
			flake.landed = true
			flake.rest = maxf(spare, 0.0)
		else:
			flake.rest += delta
		if flake.rest >= REST_SECONDS:
			_flakes.remove_at(index)


func draw(canvas: AsciiCanvas) -> void:
	for flake: Flake in _flakes:
		var sway: float = sin(_clock * SWAY_SPEED + flake.phase) * SWAY_AMPLITUDE
		var color: Color = flake.color
		if flake.landed:
			# En el suelo no se mece, y se apaga poco a poco antes de desaparecer.
			sway = 0.0
			color.a = clampf((REST_SECONDS - flake.rest) / FADE_SECONDS, 0.0, 1.0)
		canvas.put_glyph(GLYPH, Vector2(flake.x + sway, flake.y), color, FLAKE_SCALE)


class Flake:
	var x: float = 0.0
	var y: float = 0.0
	var speed: float = 3.0
	var phase: float = 0.0
	var color: Color = COLOR
	## Si ya ha llegado al suelo, y segundos que lleva ahí.
	var landed: bool = false
	var rest: float = 0.0
