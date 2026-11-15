class_name SidebarPanel
extends UiPanel
## Barra lateral derecha: accesos a los paneles, avisos y botones de ventana
## (minimizar y cerrar), más el contador de conchas y la producción por segundo.

signal shop_pressed
signal dex_pressed
signal achievements_pressed
signal settings_pressed
signal minimize_pressed
signal close_pressed

const TOAST_ROWS: int = 2
const WINDOW_BUTTON_WIDTH: int = 3
## Filas mínimas del panel para que quepa la fila de limpieza (la última es el borde).
const ROWS_FOR_CLEANLINESS: int = 13
## Filas mínimas para dejar una fila en blanco entre las conchas y el reloj.
const ROWS_FOR_SPACING: int = 11
const CLEAN_GOOD: int = 60
const CLEAN_OK: int = 30
## Símbolo de cada franja del día (amanecer, día, atardecer, noche).
const PHASE_SYMBOLS: PackedStringArray = ["▲", "○", "▼", "●"]

var _frame: AsciiFrame = AsciiFrame.new()
var _toast: AsciiToast = AsciiToast.new()
var _shells: AsciiLabel = null
var _rate: AsciiLabel = null
var _clock: AsciiLabel = null
var _inner_left: int = 0
var _inner_width: int = 0
var _top_row: int = 0
var _cleanliness: AsciiLabel = null
var _shop: AsciiButton = null
var _dex: AsciiButton = null
var _achievements: AsciiButton = null
var _settings: AsciiButton = null
var _minimize: AsciiButton = null
var _close: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	focus_group = 1
	_frame.title = _text("GAME_TITLE")
	_add(_frame, UiRoot.LAYER_PANEL)
	_shells = _make_label("", AsciiColors.AMBER)
	_rate = _make_label("", AsciiColors.TEXT_DIM)
	_clock = _make_label("", AsciiColors.WATER)
	_clock.centered_icon = true
	_cleanliness = _make_label("", AsciiColors.SEAWEED_LIGHT)
	_add(_toast)
	_shop = _make_button(_text("UI_SHOP"), _text("UI_SHOP_KEY"))
	_dex = _make_button(_text("UI_DEX"), _text("UI_DEX_KEY"))
	_achievements = _make_button(_text("UI_ACHIEVEMENTS"))
	_settings = _make_button(_text("UI_SETTINGS"), _text("UI_SETTINGS_KEY"))
	_minimize = _make_button(_text("UI_MINIMIZE"))
	_close = _make_button(_text("UI_CLOSE"))
	_shop.activated.connect(func() -> void: shop_pressed.emit())
	_dex.activated.connect(func() -> void: dex_pressed.emit())
	_achievements.activated.connect(func() -> void: achievements_pressed.emit())
	for button: AsciiButton in [_shop, _dex, _achievements, _settings]:
		button.align = AsciiLabel.Align.LEFT
	_settings.activated.connect(func() -> void: settings_pressed.emit())
	_minimize.activated.connect(func() -> void: minimize_pressed.emit())
	_close.activated.connect(func() -> void: close_pressed.emit())


## Muestra un aviso breve en la barra.
func show_toast(message: String) -> void:
	_toast.show_message(message)


## Texto del aviso que se ve ahora (vacío si no hay ninguno).
func toast_text() -> String:
	return _toast.text if _toast.is_active() else ""


## Escribe el contador de conchas (ya abreviado, por ejemplo `12,4K`).
func set_shells(text: String) -> void:
	_shells.text = _text("UI_SHELLS") % text
	_place_rate()


## Escribe la producción por segundo (ya abreviada, por ejemplo `+1,2/s`).
func set_rate(text: String) -> void:
	_rate.text = text
	_place_rate()


## Escribe la hora del juego (0 a 24) con el símbolo de su franja, por ejemplo `☾ 23:15`.
func set_clock(hour: float, phase: int) -> void:
	var minutes: int = int(hour * 60.0) % 1440
	var symbol: String = PHASE_SYMBOLS[clampi(phase, 0, PHASE_SYMBOLS.size() - 1)]
	var hours: int = floori(float(minutes) / 60.0)
	_clock.text = "%s %02d:%02d" % [symbol, hours, minutes % 60]
	_clock.color = ClockPalette.color_at(hour)


## Escribe la limpieza de la pecera (0-100) y la colorea según lo sucia que esté.
func set_cleanliness(percent: int) -> void:
	_cleanliness.text = _text("UI_CLEANLINESS") % percent
	if percent >= CLEAN_GOOD:
		_cleanliness.color = AsciiColors.SEAWEED_LIGHT
	elif percent >= CLEAN_OK:
		_cleanliness.color = AsciiColors.AMBER
	else:
		_cleanliness.color = AsciiColors.WARNING


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 1
	var inner: int = area.size.x - 2
	var top: int = area.position.y
	_close.rect = Rect2i(area.end.x - 1 - WINDOW_BUTTON_WIDTH, top + 1, WINDOW_BUTTON_WIDTH, 1)
	_minimize.rect = Rect2i(
		area.end.x - 2 - 2 * WINDOW_BUTTON_WIDTH, top + 1, WINDOW_BUTTON_WIDTH, 1
	)
	_inner_left = left
	_inner_width = inner
	_top_row = top + 2
	_shells.rect = Rect2i(left, top + 2, inner, 1)
	_place_rate()
	var gap: int = 1 if area.size.y >= ROWS_FOR_SPACING else 0
	_clock.rect = Rect2i(left, top + 3 + gap, inner, 1)
	var first_button: int = top + 4 + gap
	_shop.rect = Rect2i(left, first_button, inner, 1)
	_dex.rect = Rect2i(left, first_button + 1, inner, 1)
	_achievements.rect = Rect2i(left, first_button + 2, inner, 1)
	_settings.rect = Rect2i(left, first_button + 3, inner, 1)
	var has_room: bool = area.size.y >= ROWS_FOR_CLEANLINESS
	var after_buttons: int = first_button + 4
	_cleanliness.rect = Rect2i(left, after_buttons, inner if has_room else 0, 1)
	var toast_top: int = after_buttons + (1 if has_room else 0)
	var toast_rows: int = clampi(area.end.y - 1 - toast_top, 0, TOAST_ROWS)
	_toast.rect = Rect2i(left, toast_top, inner, toast_rows)


## Coloca la producción por segundo a la derecha de las conchas, en su misma fila.
func _place_rate() -> void:
	var start: int = _inner_left + _shells.text.length() + 1
	var width: int = maxi(_inner_left + _inner_width - start, 0)
	_rate.rect = Rect2i(start, _top_row, width, 1)
