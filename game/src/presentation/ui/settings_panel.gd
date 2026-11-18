class_name SettingsPanel
extends UiPanel
## Panel de ajustes: altura de la franja (P01), monitor (P10), siempre visible,
## límite de fotogramas, arranque con Windows (P09) y el modo de paneles del
## prototipo (P02). Cada cambio pasa por el servicio `Settings`, que lo valida,
## lo guarda y avisa; el panel solo se redibuja cuando se le pide con [method refresh].

signal close_requested
## Pide abrir las Estadísticas (ahora viven dentro de Ajustes).
signal stats_requested
signal message(text: String)
## Pide salir al título; [param delete_slot] borra antes la ranura abierta.
signal title_requested(delete_slot: bool)

## Pasos de la confirmación de «Vender todos los peces».
enum SellStep { IDLE, ASKED, SURE }

const LABEL_X: int = 3
const LABEL_WIDTH: int = 28
const VALUE_WIDTH: int = 22
const ARROW_WIDTH: int = 3
const FIRST_ROW: int = 2
const CLOSE_BUTTON_WIDTH: int = 14
const SELL_ALL_WIDTH: int = 28
const DELETE_WIDTH: int = 30
const TITLE_BUTTON_WIDTH: int = 20
const STATS_BUTTON_WIDTH: int = 16
const FOOTER_GAP: int = 2

## Anchos que piden los textos: las columnas crecen para que nada se recorte.
var _label_width: int = LABEL_WIDTH
var _value_width: int = VALUE_WIDTH
var _frame: AsciiFrame = AsciiFrame.new()
var _close: AsciiButton = null
var _stats: AsciiButton = null
var _sell_all: AsciiButton = null
var _delete: AsciiButton = null
var _to_title: AsciiButton = null
var _delete_step: SellStep = SellStep.IDLE
var _sell_step: SellStep = SellStep.IDLE
var _rows: Array[Row] = []
var _strip: Row = null
var _screen: Row = null
var _on_top: Row = null
var _transparent: Row = null
var _fps: Row = null
var _autostart: Row = null
var _mode: Row = null
var _crt: Row = null
var _volume: Row = null
var _music: Row = null
var _motion: Row = null
var _text_size: Row = null
var _language: Row = null
var _tutorial: Row = null
var _binary: Row = null
var _currency: Row = null
var _scroll_bar: AsciiScrollBar = AsciiScrollBar.new()
## Zona del panel (para recolocarlo al desplazar) y reparto de las filas.
var _area: Rect2i = Rect2i()
var _per_column: int = 1
var _visible_rows: int = 1
var _scroll: int = 0


func _init(root: UiRoot) -> void:
	super(root)
	_frame.title = _text("SETTINGS_TITLE")
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_strip = _make_stepper("SETTINGS_STRIP_HEIGHT", _on_strip_less, _on_strip_more)
	_screen = _make_stepper("SETTINGS_MONITOR", _on_screen_less, _on_screen_more)
	_on_top = _make_toggle("SETTINGS_ALWAYS_ON_TOP", _on_top_toggled)
	_transparent = _make_toggle("SETTINGS_TRANSPARENT", _on_transparent_toggled)
	_fps = _make_stepper("SETTINGS_FPS", _on_fps_less, _on_fps_more)
	_autostart = _make_toggle("SETTINGS_AUTOSTART", _on_autostart_toggled)
	_mode = _make_stepper("SETTINGS_PANEL_MODE", _on_mode_toggled, _on_mode_toggled)
	_crt = _make_stepper("SETTINGS_CRT", _on_crt_less, _on_crt_more)
	_volume = _make_stepper("SETTINGS_VOLUME", _on_volume_less, _on_volume_more)
	_music = _make_stepper("SETTINGS_MUSIC", _on_music_less, _on_music_more)
	_motion = _make_toggle("SETTINGS_REDUCE_MOTION", _on_motion_toggled)
	_text_size = _make_stepper("SETTINGS_TEXT_SIZE", _on_text_less, _on_text_more)
	_language = _make_stepper("SETTINGS_LANGUAGE", _on_language_less, _on_language_more)
	_tutorial = _make_toggle("SETTINGS_TUTORIAL", _on_tutorial_toggled)
	_binary = _make_toggle("SETTINGS_BINARY", _on_binary_toggled)
	_currency = _make_stepper("SETTINGS_CURRENCY", _on_currency_less, _on_currency_more)
	_add(_scroll_bar, UiRoot.LAYER_PANEL + 1)
	_scroll_bar.scrolled.connect(_on_scrolled)
	_scroll_bar.tick = _follow_focus
	_close = _make_button(_text("UI_CLOSE_PANEL"))
	_close.activated.connect(func() -> void: close_requested.emit())
	_stats = _make_button(_text("UI_STATS"), _text("UI_STATS_KEY"))
	_stats.activated.connect(func() -> void: stats_requested.emit())
	_delete = _make_button("")
	_delete.activated.connect(_on_delete_pressed)
	_to_title = _make_button("")
	_to_title.activated.connect(func() -> void: title_requested.emit(false))
	_sell_all = _make_button("")
	_sell_all.activated.connect(_on_sell_all_pressed)
	EventBus.fish_removed.connect(func(_tank_index: int, _fish: Fish) -> void: _update_sell_all())
	EventBus.fish_added.connect(func(_tank_index: int, _fish: Fish) -> void: _update_sell_all())


## Al cerrar el panel se cancela una venta a medias.
func set_active(value: bool) -> void:
	super(value)
	if not value:
		_sell_step = SellStep.IDLE
		_delete_step = SellStep.IDLE
		_update_delete()


func layout(area: Rect2i) -> void:
	_area = area
	_frame.rect = area
	refresh()
	_measure_columns()
	# Con sitio para dos columnas se reparten las filas; si no, van en una.
	var two_columns: bool = area.size.x >= LABEL_X + 2 * _column_width()
	var per_column: int = ceili(float(_rows.size()) / 2.0) if two_columns else _rows.size()
	# Los botones de abajo pasan a otra fila si no caben en una.
	var footer_rows: int = _flow_footer(area, false)
	# Con la franja más baja las filas se pegan al marco para que quepan todas.
	var first_row: int = FIRST_ROW if area.size.y >= per_column + FIRST_ROW + 2 + footer_rows else 1
	var bottom: int = area.position.y + area.size.y - 2
	var footer_top: int = bottom - footer_rows + 1
	var top_row: int = area.position.y + first_row
	# Si no caben todas las filas, se ven unas cuantas y el resto se desplaza.
	_per_column = per_column
	_visible_rows = clampi(footer_top - 1 - top_row, 1, per_column)
	_scroll = clampi(_scroll, 0, maxi(per_column - _visible_rows, 0))
	for index: int in range(_rows.size()):
		var column: int = index / per_column
		var slot: int = index % per_column
		var left: int = area.position.x + LABEL_X + column * _column_width()
		if slot < _scroll or slot >= _scroll + _visible_rows:
			_hide_row(_rows[index])
			continue
		_place_row(_rows[index], left, top_row + slot - _scroll)
	_scroll_bar.configure(per_column - _visible_rows, _scroll)
	var has_bar: bool = per_column > _visible_rows
	_scroll_bar.rect = (Rect2i(area.end.x - 2, top_row, 1, _visible_rows) if has_bar else Rect2i())
	_flow_footer(area, true)


## Ancho de una columna de ajustes; con sitio para dos se reparten en dos columnas.
func _column_width() -> int:
	return _label_width + ARROW_WIDTH + 1 + _value_width + 2 + ARROW_WIDTH + 2


## Calcula el ancho de títulos y valores a partir de los textos actuales.
func _measure_columns() -> void:
	_label_width = LABEL_WIDTH
	_value_width = VALUE_WIDTH
	for row: Row in _rows:
		_label_width = maxi(_label_width, row.title.text.length() + 2)
		if row.value != null:
			_value_width = maxi(_value_width, row.value.text.length())


## Reparte los botones de abajo en una o más filas según el ancho. Con
## [param place] los coloca; devuelve cuántas filas ocupan.
func _flow_footer(area: Rect2i, place: bool) -> int:
	var start_x: int = area.position.x + LABEL_X
	var limit: int = area.end.x - 2
	var x: int = start_x
	var row: int = 0
	var placed: Array[Vector3i] = []
	for button: AsciiButton in _footer_buttons():
		var width: int = maxi(_footer_width(button), button.label.length() + 2)
		width = mini(width, maxi(limit - start_x, 1))
		if x > start_x and x + width > limit:
			x = start_x
			row += 1
		placed.append(Vector3i(x, row, width))
		x += width + FOOTER_GAP
	if place:
		var last_y: int = area.end.y - 2
		for index: int in range(placed.size()):
			var spot: Vector3i = placed[index]
			_footer_buttons()[index].rect = Rect2i(spot.x, last_y - row + spot.y, spot.z, 1)
	return row + 1


func _footer_buttons() -> Array[AsciiButton]:
	return [_close, _stats, _sell_all, _delete, _to_title]


func _footer_width(button: AsciiButton) -> int:
	if button == _close:
		return CLOSE_BUTTON_WIDTH
	if button == _stats:
		return STATS_BUTTON_WIDTH
	if button == _sell_all:
		return SELL_ALL_WIDTH
	if button == _delete:
		return DELETE_WIDTH
	return TITLE_BUTTON_WIDTH


## Esconde una fila que queda fuera de la parte visible (sigue existiendo para el
## teclado: al enfocarla, el panel se desplaza hasta ella).
func _hide_row(row: Row) -> void:
	row.title.rect = Rect2i()
	if row.toggle != null:
		row.toggle.rect = Rect2i()
		return
	row.less.rect = Rect2i()
	row.value.rect = Rect2i()
	row.more.rect = Rect2i()


func _on_scrolled(position: int) -> void:
	_scroll = position
	layout(_area)


## Si el foco del teclado cae en una fila escondida, desplaza el panel hasta ella.
func _follow_focus() -> void:
	if not is_active or not _area.has_area():
		return
	var focused: AsciiWidget = _root.focused_widget()
	if focused == null:
		return
	for index: int in range(_rows.size()):
		var row: Row = _rows[index]
		if focused != row.toggle and focused != row.less and focused != row.more:
			continue
		var slot: int = index % _per_column
		if slot < _scroll:
			_scroll = slot
			layout(_area)
		elif slot >= _scroll + _visible_rows:
			_scroll = slot - _visible_rows + 1
			layout(_area)
		return


func _place_row(row: Row, left: int, y: int) -> void:
	var value_x: int = left + _label_width
	row.title.rect = Rect2i(left, y, _label_width - 1, 1)
	if row.toggle != null:
		row.toggle.rect = Rect2i(value_x, y, ARROW_WIDTH + 3, 1)
		return
	row.less.rect = Rect2i(value_x, y, ARROW_WIDTH, 1)
	row.value.rect = Rect2i(value_x + ARROW_WIDTH + 1, y, _value_width, 1)
	row.more.rect = Rect2i(value_x + ARROW_WIDTH + _value_width + 2, y, ARROW_WIDTH, 1)


func refresh() -> void:
	var data: SettingsData = Settings.data
	_strip.value.text = "%d" % data.strip_rows
	_strip.less.is_enabled = data.strip_rows > SettingsData.MIN_STRIP_ROWS
	_strip.more.is_enabled = data.strip_rows < SettingsData.MAX_STRIP_ROWS
	_screen.value.text = _screen_text(data.screen_index)
	_on_top.toggle.label = _toggle_text(data.always_on_top)
	_transparent.toggle.label = _toggle_text(data.transparent_background)
	_fps.value.text = "%d" % data.fps_limit
	_fps.less.is_enabled = data.fps_limit > SettingsData.FPS_CHOICES[0]
	_fps.more.is_enabled = data.fps_limit < SettingsData.FPS_CHOICES[-1]
	_autostart.toggle.label = _toggle_text(data.launch_with_windows)
	var is_grow: bool = data.panel_mode == SettingsData.PanelMode.GROW_UP
	_mode.value.text = _text("SETTINGS_PANEL_GROW" if is_grow else "SETTINGS_PANEL_REPLACE")
	_crt.value.text = _text("SETTINGS_CRT_%d" % data.crt_level)
	_crt.less.is_enabled = data.crt_level > 0
	_crt.more.is_enabled = data.crt_level < SettingsData.CRT_LEVELS - 1
	var volume_text: String = "%d %%" % data.master_volume
	if data.muted:
		volume_text = _text("SETTINGS_MUTED")
	_volume.value.text = volume_text
	_volume.less.is_enabled = data.master_volume > 0
	_volume.more.is_enabled = data.master_volume < SettingsData.MAX_VOLUME
	_music.value.text = "%d %%" % data.music_volume
	_music.less.is_enabled = data.music_volume > 0
	_music.more.is_enabled = data.music_volume < SettingsData.MAX_VOLUME
	_motion.toggle.label = _toggle_text(data.reduce_motion)
	_text_size.value.text = _text("SETTINGS_TEXT_SIZE_%d" % data.text_size)
	_text_size.less.is_enabled = data.text_size > 0
	_text_size.more.is_enabled = data.text_size < SettingsData.TEXT_SIZE_SCALES.size() - 1
	_language.value.text = _text("SETTINGS_LANGUAGE_%d" % data.language)
	_language.less.is_enabled = data.language > 0
	_language.more.is_enabled = data.language < SettingsData.Language.size() - 1
	_tutorial.toggle.label = _toggle_text(data.tutorial_enabled)
	_binary.toggle.label = _toggle_text(data.binary_effect)
	_currency.value.text = Currency.SYMBOLS[data.currency]
	_currency.less.is_enabled = data.currency > 0
	_currency.more.is_enabled = data.currency < Currency.SYMBOLS.size() - 1
	_to_title.label = _text("SETTINGS_TO_TITLE")
	_update_sell_all()
	_update_delete()


## Texto del botón de borrar la partida según el paso de la confirmación.
func _update_delete() -> void:
	_set_delete_label()
	if _area.has_area():
		_flow_footer(_area, true)


func _set_delete_label() -> void:
	match _delete_step:
		SellStep.ASKED:
			_delete.label = _text("SETTINGS_DELETE_ASK")
		SellStep.SURE:
			_delete.label = _text("SETTINGS_DELETE_SURE")
		_:
			_delete.label = _text("SETTINGS_DELETE")


## Borrar la partida exige tres pulsaciones (pedir, confirmar y borrar). Se guarda
## ya la partida nueva; la anterior queda como la última copia de seguridad.
func _on_delete_pressed() -> void:
	match _delete_step:
		SellStep.IDLE:
			_delete_step = SellStep.ASKED
		SellStep.ASKED:
			_delete_step = SellStep.SURE
		_:
			_delete_step = SellStep.IDLE
			title_requested.emit(true)
	_update_delete()


## Texto y estado del botón de vender todo según el paso de la confirmación.
func _update_sell_all() -> void:
	var tank: Tank = Game.state.active()
	var count: int = tank.fish.size()
	_sell_all.is_enabled = count > 0 or not tank.eggs.is_empty()
	_set_sell_all_label(tank, count)
	if _area.has_area():
		_flow_footer(_area, true)


func _set_sell_all_label(tank: Tank, count: int) -> void:
	if not _sell_all.is_enabled:
		_sell_step = SellStep.IDLE
	match _sell_step:
		SellStep.ASKED:
			var total: float = 0.0
			for fish: Fish in tank.fish:
				total += Selling.value_of(fish, Game.content)
			var shown: String = NumberFormat.compact(total, TranslationServer.get_locale())
			_sell_all.label = _text("SETTINGS_SELL_ALL_ASK") % [count, shown]
		SellStep.SURE:
			_sell_all.label = _text("SETTINGS_SELL_ALL_SURE")
		_:
			_sell_all.label = _text("SETTINGS_SELL_ALL")


## Vender todo exige tres pulsaciones: pedir, confirmar y, por último, vender.
func _on_sell_all_pressed() -> void:
	match _sell_step:
		SellStep.IDLE:
			_sell_step = SellStep.ASKED
		SellStep.ASKED:
			_sell_step = SellStep.SURE
		_:
			_sell_step = SellStep.IDLE
			Game.sell_all_fish()
	_update_sell_all()


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


func _on_transparent_toggled() -> void:
	Settings.set_transparent_background(not Settings.data.transparent_background)


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


func _on_crt_less() -> void:
	Settings.set_crt_level(Settings.data.crt_level - 1)


func _on_crt_more() -> void:
	Settings.set_crt_level(Settings.data.crt_level + 1)


func _on_volume_less() -> void:
	Settings.set_muted(false)
	Settings.set_master_volume(Settings.data.master_volume - SettingsData.VOLUME_STEP)


func _on_volume_more() -> void:
	Settings.set_muted(false)
	Settings.set_master_volume(Settings.data.master_volume + SettingsData.VOLUME_STEP)


func _on_music_less() -> void:
	Settings.set_music_volume(Settings.data.music_volume - SettingsData.VOLUME_STEP)


func _on_music_more() -> void:
	Settings.set_music_volume(Settings.data.music_volume + SettingsData.VOLUME_STEP)


func _on_motion_toggled() -> void:
	Settings.set_reduce_motion(not Settings.data.reduce_motion)


func _on_text_less() -> void:
	Settings.set_text_size(Settings.data.text_size - 1)


func _on_text_more() -> void:
	Settings.set_text_size(Settings.data.text_size + 1)


func _on_language_less() -> void:
	Settings.set_language((Settings.data.language - 1) as SettingsData.Language)


func _on_language_more() -> void:
	Settings.set_language((Settings.data.language + 1) as SettingsData.Language)


func _on_currency_less() -> void:
	Settings.set_currency(Settings.data.currency - 1)


func _on_currency_more() -> void:
	Settings.set_currency(Settings.data.currency + 1)


func _on_binary_toggled() -> void:
	Settings.set_binary_effect(not Settings.data.binary_effect)


func _on_tutorial_toggled() -> void:
	Settings.set_tutorial_enabled(not Settings.data.tutorial_enabled)


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
