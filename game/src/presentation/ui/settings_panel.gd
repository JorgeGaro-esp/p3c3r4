class_name SettingsPanel
extends UiPanel
## Panel de ajustes: altura de la franja (P01), monitor (P10), siempre visible,
## límite de fotogramas, arranque con Windows (P09) y el modo de paneles del
## prototipo (P02). Cada cambio pasa por el servicio `Settings`, que lo valida,
## lo guarda y avisa; el panel solo se redibuja cuando se le pide con [method refresh].

signal close_requested
signal message(text: String)

const LABEL_X: int = 3
const LABEL_WIDTH: int = 32
const VALUE_WIDTH: int = 28
const ARROW_WIDTH: int = 3
const FIRST_ROW: int = 2
const CLOSE_BUTTON_WIDTH: int = 16

var _frame: AsciiFrame = AsciiFrame.new()
var _close: AsciiButton = null
var _rows: Array[Row] = []
var _strip: Row = null
var _screen: Row = null
var _on_top: Row = null
var _fps: Row = null
var _autostart: Row = null
var _mode: Row = null


func _init(root: UiRoot) -> void:
	super(root)
	_frame.title = _text("SETTINGS_TITLE")
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_strip = _make_stepper("SETTINGS_STRIP_HEIGHT", _on_strip_less, _on_strip_more)
	_screen = _make_stepper("SETTINGS_MONITOR", _on_screen_less, _on_screen_more)
	_on_top = _make_toggle("SETTINGS_ALWAYS_ON_TOP", _on_top_toggled)
	_fps = _make_stepper("SETTINGS_FPS", _on_fps_less, _on_fps_more)
	_autostart = _make_toggle("SETTINGS_AUTOSTART", _on_autostart_toggled)
	_mode = _make_stepper("SETTINGS_PANEL_MODE", _on_mode_toggled, _on_mode_toggled)
	_close = _make_button(_text("UI_CLOSE_PANEL"))
	_close.activated.connect(func() -> void: close_requested.emit())


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var value_x: int = area.position.x + LABEL_X + LABEL_WIDTH
	for index: int in range(_rows.size()):
		var row: Row = _rows[index]
		var y: int = area.position.y + FIRST_ROW + index
		row.title.rect = Rect2i(area.position.x + LABEL_X, y, LABEL_WIDTH - 1, 1)
		if row.toggle != null:
			row.toggle.rect = Rect2i(value_x, y, ARROW_WIDTH + 3, 1)
		else:
			row.less.rect = Rect2i(value_x, y, ARROW_WIDTH, 1)
			row.value.rect = Rect2i(value_x + ARROW_WIDTH + 1, y, VALUE_WIDTH, 1)
			row.more.rect = Rect2i(value_x + ARROW_WIDTH + VALUE_WIDTH + 2, y, ARROW_WIDTH, 1)
	_close.rect = Rect2i(
		area.position.x + LABEL_X, area.position.y + area.size.y - 2, CLOSE_BUTTON_WIDTH, 1
	)
	refresh()


func refresh() -> void:
	var data: SettingsData = Settings.data
	_strip.value.text = "%d" % data.strip_rows
	_strip.less.is_enabled = data.strip_rows > SettingsData.MIN_STRIP_ROWS
	_strip.more.is_enabled = data.strip_rows < SettingsData.MAX_STRIP_ROWS
	_screen.value.text = _screen_text(data.screen_index)
	_on_top.toggle.label = _toggle_text(data.always_on_top)
	_fps.value.text = "%d" % data.fps_limit
	_fps.less.is_enabled = data.fps_limit > SettingsData.FPS_CHOICES[0]
	_fps.more.is_enabled = data.fps_limit < SettingsData.FPS_CHOICES[-1]
	_autostart.toggle.label = _toggle_text(data.launch_with_windows)
	var is_grow: bool = data.panel_mode == SettingsData.PanelMode.GROW_UP
	_mode.value.text = _text("SETTINGS_PANEL_GROW" if is_grow else "SETTINGS_PANEL_REPLACE")


func _screen_text(index: int) -> String:
	if index == SettingsData.PRIMARY_SCREEN or index >= Platform.screen_count():
		return _text("SETTINGS_MONITOR_AUTO") % (Platform.primary_screen() + 1)
	var size: Vector2i = Platform.screen_size(index)
	return _text("SETTINGS_MONITOR_N") % [index + 1, size.x, size.y]


func _toggle_text(is_on: bool) -> String:
	return "[ %s ]" % _text("UI_YES" if is_on else "UI_NO")


func _make_stepper(title_key: String, less: Callable, more: Callable) -> Row:
	var row: Row = Row.new()
	row.title = _make_label(_text(title_key))
	row.less = _make_button("[-]")
	row.value = _make_label("", AsciiColors.AMBER)
	row.value.align = AsciiLabel.Align.CENTER
	row.more = _make_button("[+]")
	row.less.activated.connect(less)
	row.more.activated.connect(more)
	_rows.append(row)
	return row


func _make_toggle(title_key: String, toggled: Callable) -> Row:
	var row: Row = Row.new()
	row.title = _make_label(_text(title_key))
	row.toggle = _make_button("")
	row.toggle.activated.connect(toggled)
	_rows.append(row)
	return row


func _on_strip_less() -> void:
	Settings.set_strip_rows(Settings.data.strip_rows - 1)


func _on_strip_more() -> void:
	Settings.set_strip_rows(Settings.data.strip_rows + 1)


func _on_screen_less() -> void:
	_step_screen(-1)


func _on_screen_more() -> void:
	_step_screen(1)


func _step_screen(step: int) -> void:
	var next: int = StripLayout.cycle_screen(
		Settings.data.screen_index, step, Platform.screen_count()
	)
	Settings.set_screen_index(next)


func _on_top_toggled() -> void:
	Settings.set_always_on_top(not Settings.data.always_on_top)


func _on_fps_less() -> void:
	Settings.set_fps_limit(SettingsData.next_fps(Settings.data.fps_limit, -1))


func _on_fps_more() -> void:
	Settings.set_fps_limit(SettingsData.next_fps(Settings.data.fps_limit, 1))


func _on_autostart_toggled() -> void:
	if Settings.set_launch_with_windows(not Settings.data.launch_with_windows):
		return
	var key: String = "SETTINGS_AUTOSTART_UNAVAILABLE"
	if not OS.has_feature("editor"):
		key = "SETTINGS_AUTOSTART_FAILED"
	message.emit(_text(key))


func _on_mode_toggled() -> void:
	var is_grow: bool = Settings.data.panel_mode == SettingsData.PanelMode.GROW_UP
	Settings.set_panel_mode(
		SettingsData.PanelMode.REPLACE if is_grow else SettingsData.PanelMode.GROW_UP
	)


## Una fila del panel: título y, o bien un selector (`less`, `value`, `more`), o
## bien un interruptor (`toggle`).
class Row:
	var title: AsciiLabel = null
	var less: AsciiButton = null
	var value: AsciiLabel = null
	var more: AsciiButton = null
	var toggle: AsciiButton = null
