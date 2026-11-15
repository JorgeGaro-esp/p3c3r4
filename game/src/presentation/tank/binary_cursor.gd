class_name BinaryCursor
extends AsciiDrawable
## Estela de unos y ceros que deja el puntero sobre la pecera (Fase 19). Solo sale
## al mover el ratón, se apaga en un instante y respeta «Reducir movimiento».
## Se dibuja en coordenadas de pantalla (capa 50 o más: no sigue a la cámara).

const SEED: int = 9917
const PEAK_ALPHA: float = 0.13
const COLOR: Color = Color(0.6, 0.78, 0.9)

var _drift: BinaryDrift = BinaryDrift.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = SEED


## Número de glifos de la estela vivos.
func count() -> int:
	return _drift.trail_count()


## El puntero está en la celda [param cell] (con decimales) y dentro de la pecera.
func move_to(cell: Vector2) -> void:
	if not Settings.data.binary_effect or MotionScale.is_reduced():
		return
	_drift.move_cursor(cell, _rng)


## El puntero salió de la pecera o se abrió un panel.
func leave() -> void:
	_drift.lose_cursor()


## Borra lo que quedara en pantalla.
func clear() -> void:
	_drift.clear_trail()


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_drift.update(delta, _rng)


func draw(canvas: AsciiCanvas) -> void:
	if not Settings.data.binary_effect:
		return
	for glyph: BinaryDrift.Glyph in _drift.trail():
		var tint: Color = COLOR
		tint.a = PEAK_ALPHA * BinaryDrift.fade(glyph)
		canvas.put_glyph(glyph.character, Vector2(glyph.x, glyph.y), tint, 0.8)
