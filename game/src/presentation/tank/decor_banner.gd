class_name DecorBanner
extends AsciiDrawable
## Franja fija del modo decorar: una barra ámbar a todo lo ancho de la zona visible
## de la pecera con las instrucciones. Va por encima del mundo y no se mueve con la
## cámara (la ayuda de antes se dibujaba en el mundo y, al recorrer la pecera, se
## quedaba fuera de la vista).

const LAYER: int = 71
## Fila de la zona visible donde va la franja (la 0 es la de las pestañas).
const ROW: int = 1
const BACKGROUND: Color = Color(0.95, 0.72, 0.2)
const TEXT: Color = Color.BLACK
const MARK: String = "● "

## Texto de la franja (vacío = no se dibuja).
var text: String = ""

var _view: Rect2i = Rect2i()


func _init() -> void:
	layer = LAYER


## Zona visible de la pecera (en celdas de la ventana).
func set_view(view: Rect2i) -> void:
	_view = view


## Verdadero si la franja se ve ahora.
func is_visible_now() -> bool:
	return is_shown and not text.is_empty() and _view.size.y > ROW and _view.size.x > 4


func draw(canvas: AsciiCanvas) -> void:
	if not is_visible_now():
		return
	var bar: Rect2i = Rect2i(_view.position + Vector2i(0, ROW), Vector2i(_view.size.x, 1))
	canvas.fill_rect_cells(bar, BACKGROUND)
	var line: String = UiText.center(UiText.fit(MARK + text, bar.size.x - 2), bar.size.x)
	canvas.put_string(line, Vector2(bar.position), TEXT)
