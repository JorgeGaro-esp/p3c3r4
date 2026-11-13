class_name SeaweedView
extends AsciiDrawable
## Algas que se mecen: columnas de `(` y `)` alternados con desfase propio.
## Como la arena, se generan con semilla fija.

const SEED: int = 777
const SWAY_SPEED: float = 1.6
const SWAY_AMPLITUDE: float = 0.4
const SWAY_SPREAD: float = 0.7
const MIN_HEIGHT: int = 3
const MAX_HEIGHT: int = 5
const MIN_GAP: int = 6
const MAX_GAP: int = 14

var _weeds: Array[Weed] = []
var _base_row: int = 0
var _chars: String = "()"
var _light: Color = AsciiColors.SEAWEED_LIGHT
var _dark: Color = AsciiColors.SEAWEED_DARK
var _clock: float = 0.0


## Rehace las algas. [param base_row] es la primera fila de arena y
## [param max_height] la altura máxima que cabe sin tocar la superficie.
func configure(
	new_columns: int, base_row: int, max_height: int, look: BiomeDef = null, seed_offset: int = 0
) -> void:
	_base_row = base_row
	_weeds.clear()
	var gap_scale: float = 1.0
	if look != null:
		_chars = look.weed_chars
		_light = look.weed_light
		_dark = look.weed_dark
		gap_scale = look.weed_gap_scale
	if max_height < MIN_HEIGHT:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	var column: int = rng.randi_range(2, MIN_GAP)
	while column < new_columns - 1:
		var weed: Weed = Weed.new()
		weed.column = column
		weed.height = mini(rng.randi_range(MIN_HEIGHT, MAX_HEIGHT), max_height)
		weed.phase = rng.randf_range(0.0, TAU)
		weed.is_dark = rng.randf() < 0.5
		_weeds.append(weed)
		column += roundi(float(rng.randi_range(MIN_GAP, MAX_GAP)) * gap_scale)


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	for weed: Weed in _weeds:
		for segment: int in range(weed.height):
			var reach: float = float(segment + 1) / float(weed.height)
			var sway: float = (
				sin(_clock * SWAY_SPEED + weed.phase + float(segment) * SWAY_SPREAD)
				* SWAY_AMPLITUDE
				* reach
			)
			var color: Color = _light
			if weed.is_dark != (segment % 2 == 1):
				color = _dark
			var character: String = _chars[segment % 2]
			canvas.put_char(
				character, Vector2(float(weed.column) + sway, float(_base_row - 1 - segment)), color
			)


## Una alga: dónde nace, cuánto mide y con qué desfase se mece.
class Weed:
	var column: int = 0
	var height: int = 0
	var phase: float = 0.0
	var is_dark: bool = false
