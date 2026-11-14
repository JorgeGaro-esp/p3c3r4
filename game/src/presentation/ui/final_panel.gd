class_name FinalPanel
extends UiPanel
## Panel de la secuencia final (Fase 13): se abre al completar la Enciclopedia y
## desde la pestaña de la Gran marea. Se cierra con Esc, con el botón o con un clic.

signal close_requested

const CLOSE_BUTTON_WIDTH: int = 28

var _frame: AsciiFrame = AsciiFrame.new()
var _sequence: FinalSequence = FinalSequence.new()
var _close: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_add(_sequence)
	_close = _make_button("")
	_sequence.activated.connect(func() -> void: close_requested.emit())
	_close.activated.connect(func() -> void: close_requested.emit())
	refresh()


func set_active(value: bool) -> void:
	var was_active: bool = is_active
	super(value)
	if value and not was_active:
		_sequence.restart()


func layout(area: Rect2i) -> void:
	_frame.rect = area
	_sequence.rect = Rect2i(
		area.position.x + 1, area.position.y + 1, maxi(area.size.x - 2, 0), maxi(area.size.y - 3, 0)
	)
	var width: int = mini(CLOSE_BUTTON_WIDTH, maxi(area.size.x - 2, 0))
	var left: int = area.position.x + floori(float(area.size.x - width) / 2.0)
	_close.rect = Rect2i(left, area.end.y - 2, width, 1)


func refresh() -> void:
	_frame.title = _text("PRESTIGE_ROW_FINAL")
	_sequence.title = _text("FINAL_TITLE")
	_sequence.lines = PackedStringArray(
		[
			_text("FINAL_LINE_1"),
			_text("FINAL_LINE_2"),
			_text("FINAL_LINE_3"),
			_text("FINAL_LINE_4"),
			_text("FINAL_CLOSE"),
		]
	)
	_close.label = "[ %s ]" % _text("FINAL_HINT")
