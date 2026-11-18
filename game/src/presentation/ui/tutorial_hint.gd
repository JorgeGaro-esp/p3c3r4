class_name TutorialHint
extends UiPanel
## Cuadro pequeño del tutorial: enseña el aviso del paso actual en una esquina
## de la pecera (la ficha de un pez va en la otra). No quita foco ni tapa clics.
## Se puede minimizar a una tira de una fila ([_]) o cerrar del todo ([X]).

## Se emite al pulsar [X]: el jugador no quiere más tutorial.
signal close_requested

const WIDTH: int = 40
const HEIGHT: int = 6
## Alto del cuadro minimizado: marco y una fila con los botones.
const COLLAPSED_HEIGHT: int = 3
const MARGIN: int = 1
const BUTTON_WIDTH: int = 3
## Columnas que ocupan los dos botones y su hueco, a la derecha del cuadro.
const BUTTONS_WIDTH: int = 2 * BUTTON_WIDTH + 2

var _frame: AsciiFrame = AsciiFrame.new()
var _body: AsciiLabel = null
var _footer: AsciiLabel = null
var _toggle: AsciiButton = null
var _close: AsciiButton = null
var _area: Rect2i = Rect2i()
var _collapsed: bool = false
var _step: int = -1


func _init(root: UiRoot) -> void:
	super(root)
	_add(_frame, UiRoot.LAYER_PANEL)
	_body = _make_label("", AsciiColors.TEXT)
	_body.wraps = true
	_footer = _make_label("", AsciiColors.AMBER)
	_toggle = _make_button("[_]")
	_toggle.activated.connect(_on_toggle_pressed)
	_close = _make_button("[X]")
	_close.activated.connect(func() -> void: close_requested.emit())
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


## Si el cuadro está minimizado a una tira.
func is_collapsed() -> bool:
	return _collapsed


## Minimiza o restaura el cuadro (lo mismo que pulsar [_]).
func set_collapsed(value: bool) -> void:
	_collapsed = value
	if _area.has_area():
		layout(_area)
	refresh()


func layout(area: Rect2i) -> void:
	_area = area
	var button_row: int = area.position.y + HEIGHT - 2
	if _collapsed:
		_frame.rect = Rect2i(area.position, Vector2i(area.size.x, COLLAPSED_HEIGHT))
		_body.rect = Rect2i()
		_footer.rect = Rect2i()
		button_row = area.position.y + 1
	else:
		_frame.rect = area
		_body.rect = Rect2i(area.position + Vector2i(2, 1), Vector2i(area.size.x - 4, HEIGHT - 3))
		_footer.rect = Rect2i(
			area.position + Vector2i(2, HEIGHT - 2), Vector2i(area.size.x - 4 - BUTTONS_WIDTH, 1)
		)
	var close_x: int = area.end.x - 2 - BUTTON_WIDTH
	_close.rect = Rect2i(close_x, button_row, BUTTON_WIDTH, 1)
	_toggle.rect = Rect2i(close_x - 1 - BUTTON_WIDTH, button_row, BUTTON_WIDTH, 1)


func _on_toggle_pressed() -> void:
	set_collapsed(not _collapsed)


func refresh() -> void:
	_toggle.label = "[+]" if _collapsed else "[_]"
	if _step < 0:
		_frame.title = ""
		_body.text = ""
		_footer.text = ""
		return
	_frame.title = _text("TUTORIAL_TITLE") % [_step + 1, Tutorial.DONE]
	_body.text = _text(Tutorial.text_key(_step))
	_footer.text = _text("TUTORIAL_SKIP")
