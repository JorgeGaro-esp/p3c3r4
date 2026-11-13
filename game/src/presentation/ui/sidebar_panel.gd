class_name SidebarPanel
extends UiPanel
## Barra lateral derecha: accesos a los paneles, avisos y botones de ventana
## (minimizar y cerrar). Las conchas y la producción llegarán en la Fase 3.

signal shop_pressed
signal dex_pressed
signal settings_pressed
signal minimize_pressed
signal close_pressed

const TOAST_ROWS: int = 2
const WINDOW_BUTTON_WIDTH: int = 3

var _frame: AsciiFrame = AsciiFrame.new()
var _toast: AsciiToast = AsciiToast.new()
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


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 1
	var inner: int = area.size.x - 2
	var top: int = area.position.y
	_close.rect = Rect2i(area.end.x - 1 - WINDOW_BUTTON_WIDTH, top + 1, WINDOW_BUTTON_WIDTH, 1)
	_minimize.rect = Rect2i(
		area.end.x - 2 - 2 * WINDOW_BUTTON_WIDTH, top + 1, WINDOW_BUTTON_WIDTH, 1
	)
	_toast.rect = Rect2i(left, top + 2, inner, TOAST_ROWS)
	_shop.rect = Rect2i(left, top + 5, inner, 1)
	_dex.rect = Rect2i(left, top + 6, inner, 1)
	_settings.rect = Rect2i(left, top + 7, inner, 1)
