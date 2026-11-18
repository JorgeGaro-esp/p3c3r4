class_name SurfaceView
extends AsciiDrawable
## Superficie del agua: la fila de olas `~^~^` como imagen ASCII (generada con la
## fuente del juego), cortada en tiras finas que avanzan sin saltos y suben y
## bajan siguiendo una onda irregular (varias superpuestas) que no se repite.
## La imagen es blanca sobre transparente y se tiñe con el color del bioma.
## Sin ella se dibuja la fila de texto, carácter a carácter.

const PATTERN: String = "~^~^"
const TEXT_SCROLL_SPEED: float = 2.2
const TEXT_BOB_AMPLITUDE: float = 0.12
const TEXT_BOB_SPEED: float = 2.0
const TEXT_BOB_SPREAD: float = 0.7

const WAVE_PATH: String = "res://content/sprites_png/surface_wave.png"
## Alto de la imagen en píxeles; se ajusta a una fila de la rejilla.
const TEX_HEIGHT: float = 38.0
## Ancho, en píxeles de imagen, del tramo que se repite (4 caracteres; la imagen
## mide el doble).
const PERIOD_PX: float = 77.0625
## Ancho de cada tira en pantalla, en píxeles.
const STRIP_PX: float = 3.0
## Avance de la ola, en celdas por segundo (como el de las olas de texto).
const SCROLL_SPEED: float = 2.2
## Altura total de la onda (fracción de fila).
const WAVE_AMPLITUDE: float = 0.34
## Tres ondas superpuestas: longitud en celdas, velocidad (rad/s) y fase. Sus
## longitudes no son múltiplos entre sí, así que el conjunto nunca se repite.
const WAVE_LENGTHS: PackedFloat32Array = [23.0, 13.0, 37.0]
const WAVE_SPEEDS: PackedFloat32Array = [1.1, -1.7, 0.6]
const WAVE_PHASES: PackedFloat32Array = [0.0, 1.7, 3.1]
const WAVE_WEIGHTS: PackedFloat32Array = [0.5, 0.3, 0.2]

var _columns: int = 0
var _top_row: int = 0
var _color: Color = AsciiColors.WATER
var _text_pattern: String = PATTERN
var _clock: float = 0.0
var _wave: Texture2D = null


func _init() -> void:
	if ResourceLoader.exists(WAVE_PATH):
		_wave = load(WAVE_PATH) as Texture2D


## Fija cuántas columnas tiene la superficie y en qué fila va. El patrón de
## texto solo se usa si falta la imagen.
func configure(
	new_columns: int, top_row: int, pattern: String = PATTERN, color: Color = AsciiColors.WATER
) -> void:
	_columns = new_columns
	_top_row = top_row
	_text_pattern = pattern
	_color = color


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	if _wave == null:
		_draw_text(canvas)
		return
	var cell: Vector2 = canvas.cell_size
	var px_scale: float = cell.y / TEX_HEIGHT
	var width: float = float(_columns) * cell.x
	var motion: float = MotionScale.factor()
	var scroll_px: float = _clock * SCROLL_SPEED * cell.x
	var source_width: float = STRIP_PX / px_scale
	var x: float = 0.0
	while x < width:
		var u: float = fposmod((x + scroll_px) / px_scale, PERIOD_PX)
		var lift: float = _lift_at(x / cell.x) * WAVE_AMPLITUDE * cell.y * motion
		var dest: Rect2 = Rect2(x, float(_top_row) * cell.y + lift, STRIP_PX + 1.0, cell.y)
		var source: Rect2 = Rect2(u, 0.0, source_width, TEX_HEIGHT)
		canvas.draw_texture_rect_region(_wave, dest, source, _color)
		x += STRIP_PX


## Desplazamiento vertical (entre -1 y 1) en la columna [param column], mezcla de
## las ondas de [constant WAVE_LENGTHS].
func _lift_at(column: float) -> float:
	var total: float = 0.0
	for i: int in range(WAVE_LENGTHS.size()):
		var angle: float = TAU * column / WAVE_LENGTHS[i] + _clock * WAVE_SPEEDS[i] + WAVE_PHASES[i]
		total += sin(angle) * WAVE_WEIGHTS[i]
	return total


func _draw_text(canvas: AsciiCanvas) -> void:
	var scroll: float = _clock * TEXT_SCROLL_SPEED
	var whole: int = int(floorf(scroll))
	var fraction: float = scroll - floorf(scroll)
	for column: int in range(-1, _columns):
		var index: int = posmod(column - whole, _text_pattern.length())
		var bob: float = (
			sin(_clock * TEXT_BOB_SPEED + float(column) * TEXT_BOB_SPREAD) * TEXT_BOB_AMPLITUDE
		)
		bob *= MotionScale.factor()
		canvas.put_char(
			_text_pattern[index], Vector2(float(column) + fraction, float(_top_row) + bob), _color
		)
