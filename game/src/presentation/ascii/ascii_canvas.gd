class_name AsciiCanvas
extends Node2D
## Lienzo único donde se dibuja todo el arte ASCII con la fuente del juego (T06).
##
## Convierte celdas de la rejilla en píxeles y ajusta el tamaño de la fuente al
## tamaño de la ventana, de modo que la pecera ocupa siempre [member target_rows]
## filas. No hay un nodo por pez ni por carácter: cada elemento es un
## [AsciiDrawable] que dibuja con [method put_char] dentro de [method _draw].

## Se emite cuando cambia la rejilla (tamaño de ventana o de fuente).
signal grid_changed

const DEFAULT_FONT_PATH: String = "res://assets/fonts/DejaVuSansMono.ttf"
const MIN_FONT_SIZE: int = 8
const MAX_DELTA: float = 0.1
const _REFERENCE_SIZE: int = 100
const _WIDEST_CHARACTER: int = 77  # "M"

@export var font: Font
## Filas de la rejilla que caben en la altura de la ventana.
@export_range(4, 40) var target_rows: int = 12

## Tamaño en píxeles de una celda (un carácter).
var cell_size: Vector2 = Vector2(10.0, 20.0)
var font_size: int = 16
## Columnas y filas completas que caben en la ventana.
var columns: int = 0
var row_count: int = 0
## Medidas de depuración del último fotograma.
var glyph_count: int = 0
var last_update_usec: int = 0
var last_draw_usec: int = 0

var _drawables: Array[AsciiDrawable] = []
var _needs_sort: bool = false
var _ascent: float = 0.0


func _ready() -> void:
	if font == null:
		font = load(DEFAULT_FONT_PATH) as Font
	assert(font != null, "AsciiCanvas needs a font")
	get_viewport().size_changed.connect(_recompute_grid)
	_recompute_grid()


func _process(delta: float) -> void:
	var started: int = Time.get_ticks_usec()
	var step: float = minf(delta, MAX_DELTA)
	for drawable: AsciiDrawable in _drawables:
		drawable.update(step, self)
	last_update_usec = Time.get_ticks_usec() - started
	queue_redraw()


func _draw() -> void:
	var started: int = Time.get_ticks_usec()
	glyph_count = 0
	if _needs_sort:
		_drawables.sort_custom(_is_behind)
		_needs_sort = false
	for drawable: AsciiDrawable in _drawables:
		if drawable.is_shown:
			drawable.draw(self)
	last_draw_usec = Time.get_ticks_usec() - started


## Añade un elemento al lienzo.
func add_drawable(drawable: AsciiDrawable) -> void:
	_drawables.append(drawable)
	_needs_sort = true


## Quita un elemento del lienzo.
func remove_drawable(drawable: AsciiDrawable) -> void:
	_drawables.erase(drawable)


## Dibuja un carácter en la celda [param cell] (admite decimales).
func put_char(character: String, cell: Vector2, color: Color) -> void:
	var origin: Vector2 = Vector2(cell.x * cell_size.x, cell.y * cell_size.y + _ascent)
	draw_char(font, origin, character, font_size, color)
	glyph_count += 1


## Dibuja una cadena que empieza en la celda [param cell].
func put_string(text: String, cell: Vector2, color: Color) -> void:
	var origin: Vector2 = Vector2(cell.x * cell_size.x, cell.y * cell_size.y + _ascent)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
	glyph_count += text.length()


## Rellena una celda con un color liso (para huecos opacos).
func fill_cell(cell: Vector2, color: Color) -> void:
	draw_rect(Rect2(cell * cell_size, cell_size), color)


func _recompute_grid() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var line_ratio: float = font.get_height(_REFERENCE_SIZE) / float(_REFERENCE_SIZE)
	font_size = maxi(MIN_FONT_SIZE, int(viewport_size.y / (float(target_rows) * line_ratio)))
	cell_size = Vector2(
		font.get_char_size(_WIDEST_CHARACTER, font_size).x, font.get_height(font_size)
	)
	_ascent = font.get_ascent(font_size)
	columns = int(viewport_size.x / cell_size.x)
	row_count = int(viewport_size.y / cell_size.y)
	grid_changed.emit()
	queue_redraw()


func _is_behind(first: AsciiDrawable, second: AsciiDrawable) -> bool:
	return first.layer < second.layer
