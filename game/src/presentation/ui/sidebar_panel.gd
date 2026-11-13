class_name SidebarPanel
extends UiPanel
## Barra lateral derecha: accesos a los paneles, avisos y botones de ventana
## (minimizar y cerrar), más el contador de conchas y la producción por segundo.

signal shop_pressed
signal dex_pressed
signal settings_pressed
signal minimize_pressed
signal close_pressed

const TOAST_ROWS: int = 2
const WINDOW_BUTTON_WIDTH: int = 3
## Filas mínimas del panel para que quepa la fila de limpieza (la última es el borde).
const ROWS_FOR_CLEANLINESS: int = 11
const CLEAN_GOOD: int = 60
const CLEAN_OK: int = 30

var _frame: AsciiFrame = AsciiFrame.new()
var _toast: AsciiToast = AsciiToast.new()
var _shells: AsciiLabel = null
var _rate: AsciiLabel = null
var _cleanliness: AsciiLabel = null
var _shop: AsciiButton = null
var _dex: AsciiButton = null
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
	_cleanliness = _make_label("", AsciiColors.SEAWEED_LIGHT)
	_add(_toast)
	_shop = _make_button(_text("UI_SHOP"), _text("UI_SHOP_KEY"))
	_dex = _make_button(_text("UI_DEX"), _text("UI_DEX_KEY"))
	_settings = _make_button(_text("UI_SETTINGS"), _text("UI_SETTINGS_KEY"))
	_minimize = _make_button(_text("UI_MINIMIZE"))
	_close = _make_button(_text("UI_CLOSE"))
	_shop.activated.connect(func() -> void: shop_pressed.emit())
	_dex.activated.connect(func() -> void: dex_pressed.emit())
	_settings.activated.connect(func() -> void: settings_pressed.emit())
	_minimize.activated.connect(func() -> void: minimize_pressed.emit())
	_close.activated.connect(func() -> void: close_pressed.emit())


## Muestra un aviso breve en la barra.
func show_toast(message: String) -> void:
	_toast.show_message(message)


## Escribe el contador de conchas (ya abreviado, por ejemplo `12,4K`).
func set_shells(text: String) -> void:
	_shells.text = _text("UI_SHELLS") % text


## Escribe la producción por segundo (ya abreviada, por ejemplo `+1,2/s`).
func set_rate(text: String) -> void:
	_rate.text = text


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
	_shells.rect = Rect2i(left, top + 2, inner, 1)
	_rate.rect = Rect2i(left, top + 3, inner, 1)
	_toast.rect = Rect2i(left, top + 4, inner, TOAST_ROWS)
	_shop.rect = Rect2i(left, top + 6, inner, 1)
	_dex.rect = Rect2i(left, top + 7, inner, 1)
	_settings.rect = Rect2i(left, top + 8, inner, 1)
	var has_room: bool = area.size.y >= ROWS_FOR_CLEANLINESS
	_cleanliness.rect = Rect2i(left, top + 9, inner if has_room else 0, 1)
