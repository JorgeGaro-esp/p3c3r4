class_name AsciiCanvas
extends Node2D
## Lienzo único donde se dibuja todo el arte ASCII con la fuente del juego (T06).
##
## Convierte celdas de la rejilla en píxeles. El tamaño de la fuente lo fija
## quien manda sobre la ventana con [method set_font_size] (así la altura de una
## fila no cambia cuando la ventana crece), y las columnas y filas salen de
## dividir el tamaño de la ventana entre el de una celda. No hay un nodo por pez
## ni por carácter: cada elemento es un [AsciiDrawable] que dibuja con
## [method put_char] dentro de [method _draw].

## Se emite cuando cambia la rejilla (tamaño de ventana o de fuente).
signal grid_changed

const DEFAULT_FONT_PATH: String = "res://assets/fonts/DejaVuSansMono.ttf"
const MIN_FONT_SIZE: int = 8
const DEFAULT_FONT_SIZE: int = 17
const MAX_DELTA: float = 0.1
## Los elementos de capa menor que esta forman el mundo y siguen a la cámara; los
## de capa igual o mayor (la interfaz) se quedan fijos en la ventana.
const WORLD_LAYER_LIMIT: int = 50
const _WIDEST_CHARACTER: int = 77  # "M"
## Altura (en tamaños de letra) del centro de una cifra sobre su línea de base.
const GLYPH_CENTER: float = 0.37

@export var font: Font

## Tamaño en píxeles de una celda (un carácter).
var cell_size: Vector2 = Vector2(10.0, 20.0)
var font_size: int = DEFAULT_FONT_SIZE
## Columnas y filas completas que caben en la ventana.
var columns: int = 0
var row_count: int = 0
## Posición horizontal de la cámara, en celdas: cuánto se ha desplazado el mundo.
var camera_x: float = 0.0
## Si es verdadero, el fondo se pinta de negro; si no, queda transparente.
var solid_background: bool = true
## Zona de celdas que siempre es transparente (el cielo sobre el agua).
var sky: Rect2i = Rect2i()
## Medidas de depuración del último fotograma.
var glyph_count: int = 0
var last_update_usec: int = 0
var last_draw_usec: int = 0

var _drawables: Array[AsciiDrawable] = []
var _needs_sort: bool = false
var _ascent: float = 0.0
## Zona horizontal visible (en píxeles del mundo) mientras se dibuja un elemento del
## mundo; fuera de ella no se pintan los caracteres.
var _culling: bool = false
var _visible_left: float = 0.0
var _visible_right: float = 0.0


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
	_draw_backdrop()
	var shift: float = camera_x * cell_size.x
	var width: float = get_viewport_rect().size.x
	for drawable: AsciiDrawable in _drawables:
		if not drawable.is_shown:
			continue
		_culling = drawable.layer < WORLD_LAYER_LIMIT
		if _culling:
			_visible_left = shift - cell_size.x
			_visible_right = shift + width
			draw_set_transform(Vector2(-shift, 0.0))
		else:
			draw_set_transform(Vector2.ZERO)
		drawable.draw(self)
	_culling = false
	draw_set_transform(Vector2.ZERO)
	last_draw_usec = Time.get_ticks_usec() - started


## Añade un elemento al lienzo.
func add_drawable(drawable: AsciiDrawable) -> void:
	_drawables.append(drawable)
	_needs_sort = true


## Quita un elemento del lienzo.
func remove_drawable(drawable: AsciiDrawable) -> void:
	_drawables.erase(drawable)


## Cambia el tamaño de la fuente y rehace la rejilla.
func set_font_size(new_size: int) -> void:
	font_size = maxi(MIN_FONT_SIZE, new_size)
	_recompute_grid()


## Celda de la rejilla que contiene el punto [param pixel] de la ventana.
func cell_at(pixel: Vector2) -> Vector2i:
	return Vector2i(floori(pixel.x / cell_size.x), floori(pixel.y / cell_size.y))


## Celda del mundo bajo el punto [param pixel] de la ventana (cuenta la cámara).
func world_cell_at(pixel: Vector2) -> Vector2i:
	return cell_at(pixel + Vector2(camera_x * cell_size.x, 0.0))


## Dibuja un carácter en la celda [param cell] (admite decimales).
func put_char(character: String, cell: Vector2, color: Color) -> void:
	var origin: Vector2 = Vector2(cell.x * cell_size.x, cell.y * cell_size.y + _ascent)
	if _culling and (origin.x < _visible_left or origin.x > _visible_right):
		return
	draw_char(font, origin, character, font_size, color)
	glyph_count += 1


## Dibuja un carácter a otro tamaño ([param size_scale], 1 = normal) manteniendo
## su centro en la celda; [param lift] lo sube esa fracción de la altura de letra.
func put_glyph(
	character: String, cell: Vector2, color: Color, size_scale: float = 1.0, lift: float = 0.0
) -> void:
	var origin: Vector2 = Vector2(cell.x * cell_size.x, cell.y * cell_size.y + _ascent)
	if _culling and (origin.x < _visible_left or origin.x > _visible_right):
		return
	origin.x += cell_size.x * (1.0 - size_scale) * 0.5
	origin.y -= GLYPH_CENTER * float(font_size) * (1.0 - size_scale)
	origin.y -= lift * float(font_size)
	draw_char(font, origin, character, maxi(roundi(float(font_size) * size_scale), 4), color)
	glyph_count += 1


## Dibuja una cadena que empieza en la celda [param cell].
func put_string(text: String, cell: Vector2, color: Color) -> void:
	var origin: Vector2 = Vector2(cell.x * cell_size.x, cell.y * cell_size.y + _ascent)
	var text_width: float = float(text.length()) * cell_size.x
	if _culling and (origin.x + text_width < _visible_left or origin.x > _visible_right):
		return
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
	glyph_count += text.length()


## Fondo negro de toda la ventana salvo el cielo (que se ve transparente).
func _draw_backdrop() -> void:
	if not solid_background:
		return
	var size: Vector2 = get_viewport_rect().size
	if not sky.has_area():
		draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
		return
	var top: float = sky.position.y * cell_size.y
	var bottom: float = sky.end.y * cell_size.y
	var left: float = sky.position.x * cell_size.x
	var right: float = sky.end.x * cell_size.x
	draw_rect(Rect2(0.0, 0.0, size.x, top), Color.BLACK)
	draw_rect(Rect2(0.0, bottom, size.x, size.y - bottom), Color.BLACK)
	draw_rect(Rect2(0.0, top, left, bottom - top), Color.BLACK)
	draw_rect(Rect2(right, top, size.x - right, bottom - top), Color.BLACK)


## Rellena una celda con un color liso (para huecos opacos).
func fill_cell(cell: Vector2, color: Color) -> void:
	draw_rect(Rect2(cell * cell_size, cell_size), color)


## Rellena un rectángulo de celdas con un color liso (para paneles opacos).
func fill_rect_cells(rect: Rect2i, color: Color) -> void:
	draw_rect(Rect2(Vector2(rect.position) * cell_size, Vector2(rect.size) * cell_size), color)


func _recompute_grid() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
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
