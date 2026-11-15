class_name DexBook
extends AsciiWidget
## Adornos de «libro» de la Enciclopedia: el lomo entre las dos páginas, el paso de
## página al cambiar de especie y la lista de variantes de la página derecha.
##
## No recibe clics (su [member rect] está vacío): solo dibuja. Va por encima del
## resto de componentes para que el paso de página pueda tapar la página nueva.

## Lo que dura el paso de página.
const FLIP_SECONDS: float = 0.32
const SPINE_CHARACTER: String = "│"
const SPINE_TOP: String = "┬"
const SPINE_BOTTOM: String = "┴"
const EDGE_CHARACTER: String = "▓"
const SHADE_CHARACTER: String = "▒"

## Lomo: columna de la izquierda y número de columnas; filas desde el borde superior
## del marco hasta el inferior (ambos incluidos).
var spine: Rect2i = Rect2i()
## Página derecha (donde se pasa la hoja).
var page: Rect2i = Rect2i()
## Zona de la lista de variantes (vacía si no cabe).
var checklist: Rect2i = Rect2i()
var heading: String = ""
var spine_color: Color = AsciiColors.TEXT_DIM
var heading_color: Color = AsciiColors.AMBER

var _names: PackedStringArray = PackedStringArray()
var _found: Array[bool] = []
## Avance del paso de página (0 empieza, 1 termina); -1 si no hay ninguno.
var _flip: float = -1.0


## Escribe las variantes: [param names] y si cada una [param found] ya se tuvo.
func set_variants(names: PackedStringArray, found: Array[bool]) -> void:
	_names = names
	_found = found


## Empieza a pasar la página (no hace nada con «Reducir movimiento»).
func flip() -> void:
	if MotionScale.is_reduced() or page.size.x < 4 or page.size.y < 1:
		return
	_flip = 0.0


## Si se está pasando la página.
func is_flipping() -> bool:
	return _flip >= 0.0


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if _flip < 0.0:
		return
	_flip += delta / FLIP_SECONDS
	if _flip >= 1.0:
		_flip = -1.0


func draw(canvas: AsciiCanvas) -> void:
	_draw_spine(canvas)
	_draw_checklist(canvas)
	_draw_flip(canvas)


func _draw_spine(canvas: AsciiCanvas) -> void:
	if spine.size.x <= 0 or spine.size.y < 3:
		return
	for column: int in range(spine.size.x):
		var x: float = float(spine.position.x + column)
		canvas.put_char(SPINE_TOP, Vector2(x, float(spine.position.y)), spine_color)
		canvas.put_char(SPINE_BOTTOM, Vector2(x, float(spine.end.y - 1)), spine_color)
		for row: int in range(1, spine.size.y - 1):
			canvas.put_char(SPINE_CHARACTER, Vector2(x, float(spine.position.y + row)), spine_color)


func _draw_checklist(canvas: AsciiCanvas) -> void:
	if checklist.size.x < 6 or checklist.size.y < 1:
		return
	var row: int = checklist.position.y
	if not heading.is_empty():
		canvas.put_string(
			UiText.fit(heading, checklist.size.x), Vector2(checklist.position.x, row), heading_color
		)
		row += 1
	for index: int in range(_names.size()):
		if row >= checklist.end.y:
			return
		var found: bool = index < _found.size() and _found[index]
		var line: String = "[%s]%s" % ["x" if found else " ", _names[index]]
		var color: Color = AsciiColors.TEXT if found else AsciiColors.TEXT_DIM
		canvas.put_string(
			UiText.fit(line, checklist.size.x), Vector2(checklist.position.x, row), color
		)
		row += 1


## La hoja nueva se descubre de izquierda a derecha detrás de un borde de página.
func _draw_flip(canvas: AsciiCanvas) -> void:
	if _flip < 0.0:
		return
	var edge: int = page.position.x + int(_flip * float(page.size.x))
	var covered: int = page.end.x - edge - 1
	if covered > 0:
		canvas.fill_rect_cells(Rect2i(edge + 1, page.position.y, covered, page.size.y), Color.BLACK)
	for row: int in range(page.size.y):
		var y: float = float(page.position.y + row)
		canvas.put_char(EDGE_CHARACTER, Vector2(float(edge), y), AsciiColors.TEXT)
		if edge > page.position.x:
			canvas.put_char(SHADE_CHARACTER, Vector2(float(edge - 1), y), AsciiColors.TEXT_DIM)
