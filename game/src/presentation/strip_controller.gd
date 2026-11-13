class_name StripController
extends Node
## Director de la franja: junta los ajustes, la plataforma, la pecera y los
## paneles.
##
## Decide el tamaño de fuente según la escala de Windows, pide a `Platform` que
## coloque la ventana, reparte el espacio entre pecera, barra lateral y panel
## abierto, y reacciona a los cambios de ajustes, de monitor y de minimizado.

enum Kind { NONE, SHOP, SETTINGS }

## Tamaño de fuente a 100 % de escala; con 125 % o 150 % crece en proporción.
const BASE_FONT_PX: int = 17
## Filas que se suponen disponibles cuando aún no hay pantalla que medir.
const UNLIMITED_ROWS: int = 1000

@export var canvas_path: NodePath
@export var tank_path: NodePath
@export var ui_path: NodePath

var _canvas: AsciiCanvas
var _tank: TankView
var _ui: UiRoot
var _sidebar: SidebarPanel
var _shop: ShopPanel
var _settings_panel: SettingsPanel
var _open: Kind = Kind.NONE
var _available_rows: int = UNLIMITED_ROWS


func _ready() -> void:
	_canvas = get_node(canvas_path) as AsciiCanvas
	_tank = get_node(tank_path) as TankView
	_ui = get_node(ui_path) as UiRoot
	assert(_canvas != null and _tank != null and _ui != null, "StripController needs its nodes")
	_build_panels()
	_canvas.grid_changed.connect(_apply_layout)
	_ui.escape_pressed.connect(close_panel)
	_ui.pointer_pressed.connect(Platform.enable_keyboard_focus)
	Settings.changed.connect(_on_settings_changed)
	Platform.display_changed.connect(_apply_window)
	Platform.minimized_changed.connect(_on_minimized_changed)
	_on_settings_changed()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.ctrl_pressed and key.keycode == KEY_Q:
		Platform.request_quit()


## Abre [param kind], o lo cierra si ya estaba abierto.
func toggle_panel(kind: Kind) -> void:
	if _open == kind:
		close_panel()
	else:
		open_panel(kind)


func open_panel(kind: Kind) -> void:
	_open = kind
	_apply_window()
	_apply_layout()


func close_panel() -> void:
	if _open == Kind.NONE:
		return
	_open = Kind.NONE
	_apply_window()
	_apply_layout()


## Panel abierto ahora.
func open_kind() -> Kind:
	return _open


func _build_panels() -> void:
	_sidebar = SidebarPanel.new(_ui)
	_shop = ShopPanel.new(_ui)
	_settings_panel = SettingsPanel.new(_ui)
	_sidebar.set_active(true)
	_sidebar.shop_pressed.connect(toggle_panel.bind(Kind.SHOP))
	_sidebar.settings_pressed.connect(toggle_panel.bind(Kind.SETTINGS))
	_sidebar.dex_pressed.connect(func() -> void: _sidebar.show_toast(tr("TOAST_DEX_SOON")))
	_sidebar.minimize_pressed.connect(Platform.minimize)
	_sidebar.close_pressed.connect(Platform.request_quit)
	_shop.close_requested.connect(close_panel)
	_settings_panel.close_requested.connect(close_panel)
	_shop.message.connect(_sidebar.show_toast)
	_settings_panel.message.connect(_sidebar.show_toast)


func _on_settings_changed() -> void:
	Platform.set_always_on_top(Settings.data.always_on_top)
	_apply_window()
	_apply_layout()
	_settings_panel.refresh()


## Calcula el tamaño de fuente y las filas totales y coloca la ventana.
func _apply_window() -> void:
	var data: SettingsData = Settings.data
	var screen: int = Platform.target_screen(data.screen_index)
	var scale: float = StripLayout.scale_from_dpi(Platform.screen_dpi(screen))
	var font_px: int = StripLayout.scaled_font_px(BASE_FONT_PX, scale)
	if font_px != _canvas.font_size:
		_canvas.set_font_size(font_px)
	var usable: Rect2i = Platform.usable_rect(screen)
	_available_rows = StripLayout.fit_rows(UNLIMITED_ROWS, usable.size.y, _canvas.cell_size.y)
	var rows: int = PanelLayout.total_rows(
		data.strip_rows, data.panel_mode, _open != Kind.NONE, _available_rows
	)
	Platform.place_strip(data.screen_index, rows, _canvas.cell_size.y)


## Reparte las celdas de la ventana entre pecera, barra lateral y panel.
func _apply_layout() -> void:
	var data: SettingsData = Settings.data
	var is_open: bool = _open != Kind.NONE
	var wanted: int = PanelLayout.total_rows(
		data.strip_rows, data.panel_mode, is_open, _available_rows
	)
	var mode: SettingsData.PanelMode = PanelLayout.effective_mode(
		data.panel_mode, data.strip_rows, wanted, is_open
	)
	var layout: PanelLayout = PanelLayout.compute(
		_canvas.columns, _canvas.row_count, data.strip_rows, mode, is_open
	)
	_tank.set_area(layout.tank_rect)
	_sidebar.layout(layout.sidebar_rect)
	_place_panel(_shop, Kind.SHOP, layout.panel_rect)
	_place_panel(_settings_panel, Kind.SETTINGS, layout.panel_rect)


func _place_panel(panel: UiPanel, kind: Kind, area: Rect2i) -> void:
	panel.set_active(_open == kind and area.has_area())
	if panel.is_active:
		panel.layout(area)


func _on_minimized_changed(is_minimized: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
	if is_minimized:
		mode = Node.PROCESS_MODE_DISABLED
	_canvas.process_mode = mode
	_tank.process_mode = mode
