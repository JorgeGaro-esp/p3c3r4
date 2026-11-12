class_name BubbleField
extends AsciiDrawable
## Todas las burbujas de la pecera. Suben con vaivén y crecen (`.` `°` `o` `O`)
## hasta llegar a la superficie, donde desaparecen.

const MAX_BUBBLES: int = 48
const CHARACTERS: String = ".°oO"
const MIN_RISE_SPEED: float = 2.5
const MAX_RISE_SPEED: float = 5.0
const WOBBLE_AMPLITUDE: float = 0.35
const WOBBLE_SPEED: float = 2.5

## Fila de la superficie: las burbujas desaparecen al llegar.
var surface_row: float = 1.0

var _bubbles: Array[Bubble] = []
var _clock: float = 0.0


## Crea una burbuja en [param cell] si hay sitio. El generador aleatorio llega de
## fuera para que el resultado sea reproducible.
func spawn(cell: Vector2, rng: RandomNumberGenerator) -> void:
	if _bubbles.size() >= MAX_BUBBLES:
		return
	var bubble: Bubble = Bubble.new()
	bubble.x = cell.x
	bubble.y = cell.y
	bubble.start_y = cell.y
	bubble.speed = rng.randf_range(MIN_RISE_SPEED, MAX_RISE_SPEED)
	bubble.phase = rng.randf_range(0.0, TAU)
	_bubbles.append(bubble)


## Número de burbujas vivas.
func count() -> int:
	return _bubbles.size()


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	var index: int = _bubbles.size() - 1
	while index >= 0:
		var bubble: Bubble = _bubbles[index]
		bubble.y -= bubble.speed * delta
		if bubble.y <= surface_row:
			_bubbles[index] = _bubbles[_bubbles.size() - 1]
			_bubbles.pop_back()
		index -= 1


func draw(canvas: AsciiCanvas) -> void:
	for bubble: Bubble in _bubbles:
		var travel: float = maxf(bubble.start_y - surface_row, 0.001)
		var progress: float = (bubble.start_y - bubble.y) / travel
		var size_index: int = clampi(int(progress * float(CHARACTERS.length())), 0, 3)
		var wobble: float = sin(_clock * WOBBLE_SPEED + bubble.phase) * WOBBLE_AMPLITUDE
		canvas.put_char(
			CHARACTERS[size_index], Vector2(bubble.x + wobble, bubble.y), AsciiColors.BUBBLE
		)


## Una burbuja: posición, desde dónde subió, velocidad y desfase del vaivén.
class Bubble:
	var x: float = 0.0
	var y: float = 0.0
	var start_y: float = 0.0
	var speed: float = 0.0
	var phase: float = 0.0
