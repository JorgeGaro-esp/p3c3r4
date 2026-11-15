class_name CrtTransition
extends AsciiWidget
## Transición de televisión de tubo al encender, en tres tiempos:
## 1. Pantalla negra: un punto blanco se estira en una línea brillante con halo.
## 2. La línea se abre hacia arriba y abajo con un destello blanco azulado que se
##    apaga, descubriendo la imagen.
## 3. La imagen se asienta: líneas de barrido que se desvanecen y una banda de
##    refresco que baja por la pantalla.
## Se usa al abrir, cerrar o cambiar de panel. Solo dibuja: no recibe clics.

const SECONDS: float = 0.65
## Reparto del tiempo: fin de la línea, fin de la apertura (el resto es el asentado).
const LINE_END: float = 0.3
const OPEN_END: float = 0.72
const LINE_CHARACTER: String = "█"
const EDGE_TOP: String = "▄"
const EDGE_BOTTOM: String = "▀"
const BEAM: Color = Color(0.92, 0.97, 1.0)
const GLOW: Color = Color(0.55, 0.75, 1.0)
const MAX_FLASH: float = 0.6
const MAX_SCANLINE: float = 0.5
const SWEEP_ROWS: int = 2
const SWEEP_ALPHA: float = 0.14

var _area: Rect2i = Rect2i()
## Avance (0 a 1); -1 si no hay transición en marcha.
var _progress: float = -1.0


## Empieza la transición sobre [param area] (no hace nada con «Reducir movimiento»).
func play(area: Rect2i) -> void:
	if MotionScale.is_reduced() or area.size.x < 4 or area.size.y < 2:
		return
	_area = area
	_progress = 0.0


## Si hay una transición en marcha.
func is_playing() -> bool:
	return _progress >= 0.0


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if _progress < 0.0:
		return
	_progress += delta / SECONDS
	if _progress >= 1.0:
		_progress = -1.0


func draw(canvas: AsciiCanvas) -> void:
	if _progress < 0.0:
		return
	if _progress < LINE_END:
		_draw_line(canvas, _progress / LINE_END)
	elif _progress < OPEN_END:
		_draw_opening(canvas, (_progress - LINE_END) / (OPEN_END - LINE_END))
	else:
		_draw_settling(canvas, (_progress - OPEN_END) / (1.0 - OPEN_END))


func _center_row() -> int:
	return _area.position.y + _area.size.y / 2


## Tiempo 1: pantalla negra con un punto que se estira hasta ser una línea.
func _draw_line(canvas: AsciiCanvas, step: float) -> void:
	canvas.fill_rect_cells(_area, Color.BLACK)
	var grow: float = 1.0 - pow(1.0 - step, 3.0)
	var half: int = maxi(roundi(grow * float(_area.size.x) / 2.0), 1)
	var center_x: int = _area.position.x + _area.size.x / 2
	var row: int = _center_row()
	var halo: Color = Color(GLOW.r, GLOW.g, GLOW.b, 0.22 * grow)
	var halo_rect: Rect2i = Rect2i(center_x - half, row - 1, half * 2, 3)
	canvas.fill_rect_cells(halo_rect.intersection(_area), halo)
	canvas.put_string(LINE_CHARACTER.repeat(half * 2), Vector2(center_x - half, row), BEAM)


## Tiempo 2: la línea se abre en vertical con un destello que se apaga.
func _draw_opening(canvas: AsciiCanvas, step: float) -> void:
	var open: float = 1.0 - pow(1.0 - step, 3.0)
	var band: int = clampi(roundi(open * float(_area.size.y)), 1, _area.size.y)
	var top: int = clampi(_center_row() - band / 2, _area.position.y, _area.end.y - 1)
	var bottom: int = mini(top + band, _area.end.y)
	var above: Rect2i = Rect2i(
		_area.position.x, _area.position.y, _area.size.x, top - _area.position.y
	)
	var below: Rect2i = Rect2i(_area.position.x, bottom, _area.size.x, _area.end.y - bottom)
	canvas.fill_rect_cells(above, Color.BLACK)
	canvas.fill_rect_cells(below, Color.BLACK)
	var flash: float = MAX_FLASH * (1.0 - step)
	var lit: Rect2i = Rect2i(_area.position.x, top, _area.size.x, bottom - top)
	canvas.fill_rect_cells(lit, Color(BEAM.r, BEAM.g, BEAM.b, flash))
	if band < _area.size.y:
		canvas.put_string(EDGE_BOTTOM.repeat(_area.size.x), Vector2(_area.position.x, top), BEAM)
		canvas.put_string(
			EDGE_TOP.repeat(_area.size.x), Vector2(_area.position.x, bottom - 1), BEAM
		)


## Tiempo 3: líneas de barrido que se desvanecen y una banda de refresco que baja.
func _draw_settling(canvas: AsciiCanvas, step: float) -> void:
	var fade: float = 1.0 - step
	var scan: Color = Color(0.0, 0.0, 0.0, MAX_SCANLINE * fade)
	for row: int in range(_area.position.y + 1, _area.end.y, 2):
		canvas.fill_rect_cells(Rect2i(_area.position.x, row, _area.size.x, 1), scan)
	var sweep_row: int = _area.position.y + roundi(step * float(_area.size.y))
	var sweep: Rect2i = Rect2i(_area.position.x, sweep_row, _area.size.x, SWEEP_ROWS)
	canvas.fill_rect_cells(
		sweep.intersection(_area), Color(BEAM.r, BEAM.g, BEAM.b, SWEEP_ALPHA * fade)
	)
