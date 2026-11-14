class_name TutorialHint
extends UiPanel
## Cuadro pequeño del tutorial: enseña el aviso del paso actual en una esquina
## de la pecera (la ficha de un pez va en la otra). No quita foco ni tapa clics.

const WIDTH: int = 44
const HEIGHT: int = 6
const MARGIN: int = 1

var _frame: AsciiFrame = AsciiFrame.new()
var _body: AsciiLabel = null
var _footer: AsciiLabel = null
var _step: int = -1


func _init(root: UiRoot) -> void:
	super(root)
	_add(_frame, UiRoot.LAYER_PANEL)
	_body = _make_label("", AsciiColors.TEXT)
	_body.wraps = true
	_footer = _make_label("", AsciiColors.AMBER)
	refresh()


## Paso que se enseña (−1 = ninguno).
func step() -> int:
	return _step


## Cambia el paso mostrado.
func show_step(step_index: int) -> void:
	_step = step_index
	refresh()


## Texto del aviso que se ve (vacío si no hay paso).
func body_text() -> String:
	return _body.text


## Dónde cabe el cuadro dentro de [param tank_area]: arriba a la derecha, o un
## rectángulo vacío si no cabe.
static func fit_in(tank_area: Rect2i) -> Rect2i:
	if tank_area.size.x < WIDTH * 2 or tank_area.size.y < HEIGHT + MARGIN:
		return Rect2i()
	var x: int = tank_area.end.x - WIDTH - MARGIN
	return Rect2i(Vector2i(x, tank_area.position.y + MARGIN), Vector2i(WIDTH, HEIGHT))


func layout(area: Rect2i) -> void:
	_frame.rect = area
	_body.rect = Rect2i(area.position + Vector2i(2, 1), Vector2i(area.size.x - 4, HEIGHT - 3))
	_footer.rect = Rect2i(area.position + Vector2i(2, HEIGHT - 2), Vector2i(area.size.x - 4, 1))


func refresh() -> void:
	if _step < 0:
		_frame.title = ""
		_body.text = ""
		_footer.text = ""
		return
	_frame.title = _text("TUTORIAL_TITLE") % [_step + 1, Tutorial.DONE]
	_body.text = _text(Tutorial.text_key(_step))
	_footer.text = _text("TUTORIAL_SKIP")
