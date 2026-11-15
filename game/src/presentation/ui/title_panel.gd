class_name TitlePanel
extends UiPanel
## Pantalla de título: un cuadro centrado sobre la pecera con el logo y tres
## botones (Continuar, Cargar, Nueva) más Salir. Cargar y Nueva enseñan las tres
## ranuras de guardado con su resumen.

## Se eligió una ranura: [param fresh] es verdadero si es una partida nueva.
signal slot_chosen(slot: int, fresh: bool)
signal quit_requested

enum View { MAIN, LOAD, NEW }

const BOX_WIDTH: int = 54
const BOX_ROWS: int = 10
const LOGO_ROW: int = 1
const TAGLINE_ROW: int = 6
const NOTE_ROW: int = 7
const BUTTON_ROW: int = 8
const HEADER_ROW: int = 2
const FIRST_SLOT_ROW: int = 4
const BACK_ROW: int = 8
const BUTTON_WIDTHS: Array[int] = [14, 10, 10, 8]
const BUTTON_GAP: int = 2

var _frame: AsciiFrame = AsciiFrame.new()
var _logo: AsciiBanner = AsciiBanner.new()
var _tagline: AsciiLabel = null
var _note: AsciiLabel = null
var _version: AsciiLabel = null
var _header: AsciiLabel = null
var _continue: AsciiButton = null
var _load: AsciiButton = null
var _new: AsciiButton = null
var _quit: AsciiButton = null
var _back: AsciiButton = null
var _slot_buttons: Array[AsciiButton] = []
var _infos: Array[Dictionary] = []
var _view: View = View.MAIN
var _confirm_slot: int = 0
var _box: Rect2i = Rect2i()


func _init(root: UiRoot) -> void:
	super(root)
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_logo.lines = AsciiBanner.build("P3C3R4")
	_logo.is_enabled = false
	_add(_logo)
	_tagline = _make_label("", AsciiColors.TEXT)
	_tagline.align = AsciiLabel.Align.CENTER
	_note = _make_label("", AsciiColors.TEXT_DIM)
	_note.align = AsciiLabel.Align.CENTER
	_version = _make_label("", AsciiColors.TEXT)
	_version.align = AsciiLabel.Align.RIGHT
	_header = _make_label("", AsciiColors.AMBER)
	_header.align = AsciiLabel.Align.CENTER
	_continue = _make_button("")
	_load = _make_button("")
	_new = _make_button("")
	_quit = _make_button("")
	_back = _make_button("")
	_continue.activated.connect(_on_continue_pressed)
	_load.activated.connect(_show_view.bind(View.LOAD))
	_new.activated.connect(_show_view.bind(View.NEW))
	_quit.activated.connect(func() -> void: quit_requested.emit())
	_back.activated.connect(_show_view.bind(View.MAIN))
	for index: int in range(SettingsData.SLOT_COUNT):
		var button: AsciiButton = _make_button("")
		button.align = AsciiLabel.Align.LEFT
		button.activated.connect(_on_slot_pressed.bind(index + 1))
		_slot_buttons.append(button)
	refresh()


## Vuelve a la vista principal y lee de disco el resumen de las ranuras.
func open() -> void:
	_view = View.MAIN
	_confirm_slot = 0
	_infos.clear()
	for slot: int in range(1, SettingsData.SLOT_COUNT + 1):
		_infos.append(SaveService.slot_info(slot))
	refresh()


## Esc: de una lista de ranuras vuelve a la vista principal. Devuelve si lo atendió.
func escape() -> bool:
	if _view == View.MAIN:
		return false
	_show_view(View.MAIN)
	return true


func current_view() -> View:
	return _view


func set_active(value: bool) -> void:
	super(value)
	if value:
		_apply_view()


func layout(area: Rect2i) -> void:
	var width: int = mini(BOX_WIDTH, area.size.x)
	var rows: int = mini(BOX_ROWS, area.size.y)
	var left: int = area.position.x + (area.size.x - width) / 2
	var top: int = area.position.y + (area.size.y - rows) / 2
	_box = Rect2i(left, top, width, rows)
	_frame.rect = _box
	var inner: Rect2i = Rect2i(left + 2, top, width - 4, rows)
	_logo.rect = Rect2i(inner.position.x, top + LOGO_ROW, inner.size.x, AsciiBanner.GLYPH_HEIGHT)
	_tagline.rect = Rect2i(inner.position.x, top + TAGLINE_ROW, inner.size.x, 1)
	_note.rect = Rect2i(inner.position.x, top + NOTE_ROW, inner.size.x, 1)
	var version_width: int = _version.text.length() + 1
	_version.rect = Rect2i(
		area.end.x - version_width, area.end.y - 1, mini(version_width, area.size.x), 1
	)
	_header.rect = Rect2i(inner.position.x, top + HEADER_ROW, inner.size.x, 1)
	_layout_main_buttons(inner, top)
	for index: int in range(_slot_buttons.size()):
		_slot_buttons[index].rect = Rect2i(
			inner.position.x, top + FIRST_SLOT_ROW + index, inner.size.x, 1
		)
	_back.rect = Rect2i(
		inner.position.x + (inner.size.x - BUTTON_WIDTHS[1]) / 2,
		top + BACK_ROW,
		BUTTON_WIDTHS[1],
		1
	)
	refresh()


func refresh() -> void:
	var locale: String = TranslationServer.get_locale()
	_frame.title = ""
	_tagline.text = _text("TITLE_TAGLINE")
	_version.text = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
	_continue.label = _text("TITLE_CONTINUE")
	_load.label = _text("TITLE_LOAD")
	_new.label = _text("TITLE_NEW")
	_quit.label = _text("TITLE_QUIT")
	_back.label = _text("TITLE_BACK")
	_header.text = _text("TITLE_LOAD_HEADER" if _view == View.LOAD else "TITLE_NEW_HEADER")
	var last: int = Settings.data.last_slot
	var has_last: bool = last >= 1 and last <= _infos.size() and _slot_exists(last)
	_continue.is_enabled = has_last
	_note.text = ""
	if has_last:
		_note.text = _text("TITLE_LAST") % last
	var any_save: bool = false
	for slot: int in range(1, SettingsData.SLOT_COUNT + 1):
		any_save = any_save or _slot_exists(slot)
	_load.is_enabled = any_save
	_refresh_slots(locale)
	if is_active:
		_apply_view()


func _layout_main_buttons(inner: Rect2i, top: int) -> void:
	var total: int = BUTTON_GAP * (BUTTON_WIDTHS.size() - 1)
	for width: int in BUTTON_WIDTHS:
		total += width
	var x: int = inner.position.x + maxi((inner.size.x - total) / 2, 0)
	var buttons: Array[AsciiButton] = [_continue, _load, _new, _quit]
	for index: int in range(buttons.size()):
		buttons[index].rect = Rect2i(x, top + BUTTON_ROW, BUTTON_WIDTHS[index], 1)
		x += BUTTON_WIDTHS[index] + BUTTON_GAP


func _refresh_slots(locale: String) -> void:
	for index: int in range(_slot_buttons.size()):
		var info: Dictionary = _infos[index] if index < _infos.size() else {"exists": false}
		var slot: int = index + 1
		var exists: bool = _slot_exists(slot)
		var button: AsciiButton = _slot_buttons[index]
		button.label = TitleText.slot_line(slot, info, locale)
		button.is_enabled = exists or _view == View.NEW
		if _view == View.NEW and _confirm_slot == slot:
			button.label = _text("TITLE_OVERWRITE") % slot


func _slot_exists(slot: int) -> bool:
	if slot < 1 or slot > _infos.size():
		return false
	var exists: bool = _infos[slot - 1].get("exists", false)
	return exists


func _show_view(view: View) -> void:
	_view = view
	_confirm_slot = 0
	refresh()
	_focus_first()


func _apply_view() -> void:
	var main: bool = _view == View.MAIN
	for widget: AsciiWidget in [_logo, _tagline, _note, _continue, _load, _new, _quit]:
		widget.is_shown = main
	_header.is_shown = not main
	_back.is_shown = not main
	for button: AsciiButton in _slot_buttons:
		button.is_shown = not main


func _focus_first() -> void:
	var order: Array[AsciiWidget] = []
	if _view == View.MAIN:
		order = [_continue, _new, _load, _quit]
	else:
		for button: AsciiButton in _slot_buttons:
			order.append(button)
		order.append(_back)
	for widget: AsciiWidget in order:
		if widget.can_focus():
			_root.focus_widget(widget)
			return


func _on_continue_pressed() -> void:
	var last: int = Settings.data.last_slot
	if last >= 1 and last <= SettingsData.SLOT_COUNT:
		slot_chosen.emit(last, false)


func _on_slot_pressed(slot: int) -> void:
	var exists: bool = _slot_exists(slot)
	if _view == View.LOAD:
		slot_chosen.emit(slot, false)
	elif not exists:
		slot_chosen.emit(slot, true)
	elif _confirm_slot == slot:
		slot_chosen.emit(slot, true)
	else:
		_confirm_slot = slot
		refresh()
