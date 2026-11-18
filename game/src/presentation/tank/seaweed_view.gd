class_name SeaweedView
extends AsciiDrawable
## Plantas del fondo que se mecen, con desfase propio. Cada zona usa una sola forma
## (la primera de su lista, ver [WeedForm]) y sus dos colores: sin remates, sin
## compañeras ni paletas, para que el fondo sea sencillo. Como la arena, se generan
## con semilla fija. Es la capa más al fondo: la decoración las tapa ([member covers]).

const SEED: int = 777
const SWAY_SPEED: float = 1.6
const SWAY_AMPLITUDE: float = 0.65
## Segundo vaivén, más lento y más amplio, que hace la marea menos repetitiva.
const SWELL_SPEED: float = 0.55
const SWELL_AMPLITUDE: float = 0.35
const SWAY_SPREAD: float = 0.7
const MIN_GAP: int = 6
const MAX_GAP: int = 14

## Zonas (en celdas) ocupadas por decoración: ahí no se dibujan plantas.
var covers: Array[Rect2i] = []

var _weeds: Array[Weed] = []
var _base_row: int = 0
var _forms: Array[WeedForm] = []
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
	_forms = [WeedForm.stalk("()")]
	var gap_scale: float = 1.0
	if look != null:
		_forms = WeedForm.parse_all(look.weed_forms)
		if _forms.is_empty():
			_forms = [WeedForm.stalk(look.weed_chars)]
		_forms = [_forms[0]]
		_light = look.weed_light
		_dark = look.weed_dark
		gap_scale = look.weed_gap_scale
	if max_height < 1:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	var column: int = rng.randi_range(2, MIN_GAP)
	while column < new_columns - 2:
		var form: WeedForm = _forms[rng.randi_range(0, _forms.size() - 1)]
		var weed: Weed = _grow(form, column, max_height, rng)
		if weed != null:
			_weeds.append(weed)
		column += roundi(float(rng.randi_range(MIN_GAP, MAX_GAP)) * gap_scale) + form.half_width()


## Crea una planta de [param form] en [param column], o null si no cabe.
func _grow(form: WeedForm, column: int, max_height: int, rng: RandomNumberGenerator) -> Weed:
	if max_height < form.min_height():
		return null
	var weed: Weed = Weed.new()
	weed.form = form
	weed.column = column
	weed.height = mini(rng.randi_range(form.min_height(), form.max_height()), max_height)
	weed.phase = rng.randf_range(0.0, TAU)
	weed.is_dark = rng.randf() < 0.5
	weed.light = _light
	weed.dark = _dark
	return weed


## Cuántas plantas hay de cada tipo (para los tests).
func kind_counts() -> Dictionary[WeedForm.Kind, int]:
	var counts: Dictionary[WeedForm.Kind, int] = {}
	for weed: Weed in _weeds:
		counts[weed.form.kind] = counts.get(weed.form.kind, 0) + 1
	return counts


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	for weed: Weed in _weeds:
		match weed.form.kind:
			WeedForm.Kind.FERN:
				_draw_fern(canvas, weed)
			WeedForm.Kind.TUFT:
				_draw_tuft(canvas, weed)
			WeedForm.Kind.BUSH:
				_draw_bush(canvas, weed)
			_:
				_draw_stalk(canvas, weed)


## Cuánto se mece el segmento [param segment] de [param weed]; [param reach] (0 a 1)
## es lo arriba que está: la base no se mueve y la punta, lo máximo.
func _sway(weed: Weed, reach: float, segment: int) -> float:
	var ripple: float = sin(_clock * SWAY_SPEED + weed.phase + float(segment) * SWAY_SPREAD)
	var swell: float = sin(_clock * SWELL_SPEED + weed.phase * 0.5)
	var sway: float = (ripple * SWAY_AMPLITUDE + swell * SWELL_AMPLITUDE) * reach * reach
	return sway * MotionScale.factor()


func _row(segment: int) -> float:
	return float(_base_row - 1 - segment)


func _segment_color(weed: Weed, segment: int) -> Color:
	var color: Color = weed.light
	if weed.is_dark != (segment % 2 == 1):
		color = weed.dark
	return color


## Dibuja una planta salvo donde hay decoración encima.
func _put(canvas: AsciiCanvas, glyph: String, cell: Vector2, color: Color) -> void:
	var column: int = roundi(cell.x)
	var row: int = floori(cell.y)
	for area: Rect2i in covers:
		if area.has_point(Vector2i(column, row)):
			return
	canvas.put_char(glyph, cell, color)


func _draw_stalk(canvas: AsciiCanvas, weed: Weed) -> void:
	var glyphs: String = weed.form.glyphs
	for segment: int in range(weed.height):
		var reach: float = float(segment + 1) / float(weed.height)
		var x: float = float(weed.column) + _sway(weed, reach, segment)
		_put(canvas, glyphs[segment % 2], Vector2(x, _row(segment)), _segment_color(weed, segment))


## Tallo con una hoja a cada lado, alternando.
func _draw_fern(canvas: AsciiCanvas, weed: Weed) -> void:
	for segment: int in range(weed.height):
		var reach: float = float(segment + 1) / float(weed.height)
		var x: float = float(weed.column) + _sway(weed, reach, segment)
		var color: Color = _segment_color(weed, segment)
		_put(canvas, WeedForm.STEM, Vector2(x, _row(segment)), color)
		var leaf: int = segment % 2
		var side: float = -1.0 if leaf == 0 else 1.0
		_put(canvas, weed.form.glyphs[leaf], Vector2(x + side, _row(segment)), weed.light)


## Mata baja: tres caracteres lado a lado y, si crece, un tallo encima.
func _draw_tuft(canvas: AsciiCanvas, weed: Weed) -> void:
	var base_x: float = float(weed.column) + _sway(weed, 0.5, 0)
	for offset: int in range(3):
		_put(
			canvas,
			weed.form.glyphs[offset],
			Vector2(base_x + float(offset - 1), _row(0)),
			_segment_color(weed, offset)
		)
	if weed.height > 1:
		var top_x: float = float(weed.column) + _sway(weed, 1.0, 1)
		_put(canvas, weed.form.glyphs[1], Vector2(top_x, _row(1)), weed.light)


## Arbusto: los dos caracteres juntos en cada fila.
func _draw_bush(canvas: AsciiCanvas, weed: Weed) -> void:
	for segment: int in range(weed.height):
		var reach: float = float(segment + 1) / float(weed.height)
		var x: float = float(weed.column) + _sway(weed, reach, segment)
		var color: Color = _segment_color(weed, segment)
		_put(canvas, weed.form.glyphs[0], Vector2(x, _row(segment)), color)
		_put(canvas, weed.form.glyphs[1], Vector2(x + 1.0, _row(segment)), color)


## Una planta: su forma, dónde nace, cuánto mide y con qué desfase se mece.
class Weed:
	var form: WeedForm = null
	var column: int = 0
	var height: int = 0
	var phase: float = 0.0
	var is_dark: bool = false
	var light: Color = Color.WHITE
	var dark: Color = Color.GRAY
