class_name BinaryBackdrop
extends AsciiDrawable
## Unos y ceros muy tenues que suben despacio por el agua de la pecera (Fase 19).
## Cada pecera tiene su densidad y velocidad según su bioma. Se apaga en Ajustes.

const SEED: int = 8801
const PEAK_ALPHA: float = 0.34
const BASE_COLOR: Color = Color(0.55, 0.62, 0.66)

var _drift: BinaryDrift = BinaryDrift.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _tint: Color = BASE_COLOR


## Reparte los glifos por el agua [param water] (celdas); el bioma da la variación.
func configure(water: Rect2i, biome: BiomeDef, seed_offset: int = 0) -> void:
	_rng.seed = SEED + seed_offset
	var variety: float = 0.8 + 0.4 * float(seed_offset % 7) / 6.0
	_tint = BASE_COLOR
	if biome != null:
		_tint = BASE_COLOR.lerp(biome.bubble_color, 0.35)
	_drift.configure(Rect2(water), BinaryDrift.DEFAULT_DENSITY * variety, _rng)


## Glifos de fondo vivos.
func count() -> int:
	return _drift.count()


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if not Settings.data.binary_effect:
		return
	_drift.speed_scale = MotionScale.factor()
	_drift.update(delta, _rng)


func draw(canvas: AsciiCanvas) -> void:
	if not Settings.data.binary_effect:
		return
	for glyph: BinaryDrift.Glyph in _drift.glyphs():
		var tint: Color = _tint
		tint.a = PEAK_ALPHA * glyph.bright * BinaryDrift.fade(glyph)
		canvas.put_glyph(glyph.character, Vector2(glyph.x, glyph.y), tint, glyph.scale)
