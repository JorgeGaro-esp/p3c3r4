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
## Si es falso, la partida no se carga ni se guarda (los tests de integración).
@export var uses_saves: bool = true

var _canvas: AsciiCanvas
var _tank: TankView
var _ui: UiRoot
var _sidebar: SidebarPanel
var _shop: ShopPanel
var _settings_panel: SettingsPanel
var _card: FishCard
var _tank_tabs: TankTabs
var _open: Kind = Kind.NONE
var _available_rows: int = UNLIMITED_ROWS


func _ready() -> void:
	_canvas = get_node(canvas_path) as AsciiCanvas
	_tank = get_node(tank_path) as TankView
	_ui = get_node(ui_path) as UiRoot
	assert(_canvas != null and _tank != null and _ui != null, "StripController needs its nodes")
	_build_panels()
	_canvas.grid_changed.connect(_apply_layout)
	_ui.escape_pressed.connect(_on_escape)
	_tank.fish_clicked.connect(_on_fish_clicked)
	_tank.decor_message.connect(_sidebar.show_toast)
	_ui.pointer_pressed.connect(Platform.enable_keyboard_focus)
	Settings.changed.connect(_on_settings_changed)
	Platform.display_changed.connect(_apply_window)
	Platform.minimized_changed.connect(_on_minimized_changed)
	EventBus.shells_changed.connect(_on_shells_changed)
	EventBus.species_unlocked.connect(_on_species_unlocked)
	EventBus.tank_unlocked.connect(_on_tank_unlocked)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.tank_unlocked.connect(func(_index: int) -> void: _apply_layout())
	EventBus.active_tank_changed.connect(func(_index: int) -> void: _apply_layout())
	EventBus.pearl_collected.connect(_on_pearl_collected)
	EventBus.fish_sold.connect(_on_fish_sold)
	EventBus.variant_discovered.connect(_on_variant_discovered)
	EventBus.production_changed.connect(_on_production_changed)
	_on_shells_changed(Game.state.wallet.shells)
	_on_production_changed(Game.state.production_rate)
	_on_settings_changed()
	EventBus.notice_requested.connect(_on_notice_requested)
	if uses_saves:
		_on_notice_requested(SaveService.start())


func _process(_delta: float) -> void:
	_sidebar.set_cleanliness(roundi(Game.state.active().cleanliness))


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.ctrl_pressed and key.keycode == KEY_Q:
		Platform.request_quit()
	elif key.keycode == KEY_D and not key.ctrl_pressed:
		toggle_decorating()
	elif key.keycode == KEY_L and not key.ctrl_pressed:
		open_achievements()
	elif key.keycode >= KEY_1 and key.keycode <= KEY_8 and not key.ctrl_pressed:
		Game.biomes.set_active(key.keycode - KEY_1)


## Entra o sale del modo decorar (cierra los paneles al entrar).
func toggle_decorating() -> void:
	var entering: bool = not _tank.is_decorating()
	if entering:
		close_card()
		close_panel()
	_tank.set_decorating(entering)


## Abre la Enciclopedia (pestaña de la tienda), o lo cierra si ya estaba a la vista.
func open_dex() -> void:
	open_shop_tab(ShopPanel.DEX_TAB)


## Abre los Logros (pestaña de la tienda), o lo cierra si ya estaba a la vista.
func open_achievements() -> void:
	open_shop_tab(ShopPanel.ACHIEVEMENTS_TAB)


## Abre la tienda en la pestaña [param tab], o la cierra si ya estaba a la vista.
func open_shop_tab(tab: int) -> void:
	if _open == Kind.SHOP and _shop.current_tab() == tab:
		close_panel()
		return
	if _tank.is_decorating():
		_tank.set_decorating(false)
	open_panel(Kind.SHOP)
	_shop.select_tab(tab)


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


## Muestra la ficha del pez [param fish] sobre la pecera.
func show_card(fish: Fish) -> void:
	_card.show_fish(fish)
	_apply_layout()


func close_card() -> void:
	_card.show_fish(null)
	_apply_layout()


## Pez cuya ficha está abierta, o null.
func card_fish() -> Fish:
	return _card.fish()


func _on_fish_clicked(fish: Fish) -> void:
	show_card(fish)


func _on_escape() -> void:
	if _tank.is_decorating():
		_tank.set_decorating(false)
	elif _card.fish() != null:
		close_card()
	else:
		close_panel()


func _on_pearl_collected(value: float) -> void:
	_sidebar.show_toast(
		tr("TOAST_PEARL") % NumberFormat.compact(value, TranslationServer.get_locale())
	)


func _on_fish_sold(value: float) -> void:
	_sidebar.show_toast(
		tr("TOAST_SOLD") % NumberFormat.compact(value, TranslationServer.get_locale())
	)


func _on_variant_discovered(species_id: String, variant_id: String) -> void:
	var species: SpeciesDef = Game.content.get_species(species_id)
	var variant: VariantDef = Game.content.get_variant(variant_id)
	if species != null and variant != null:
		_sidebar.show_toast(tr("TOAST_VARIANT_NEW") % [tr(variant.name_key), tr(species.name_key)])


func _on_species_unlocked(species_id: String) -> void:
	var def: SpeciesDef = Game.content.get_species(species_id)
	if def != null:
		_sidebar.show_toast(tr("TOAST_UNLOCKED") % tr(def.name_key))


func _on_achievement_unlocked(achievement_id: String) -> void:
	var def: AchievementDef = Game.content.achievements.get_achievement(achievement_id)
	if def != null:
		_sidebar.show_toast(tr("TOAST_ACHIEVEMENT") % tr(def.name_key))


func _on_tank_unlocked(tank_index: int) -> void:
	var biome: BiomeDef = Game.content.biomes.get_biome(Game.state.tanks[tank_index].biome_id)
	if biome != null:
		_sidebar.show_toast(tr("TOAST_BIOME_OPENED") % tr(biome.name_key))


func _build_panels() -> void:
	_sidebar = SidebarPanel.new(_ui)
	_shop = ShopPanel.new(_ui)
	_settings_panel = SettingsPanel.new(_ui)
	_card = FishCard.new(_ui)
	_tank_tabs = TankTabs.new(_ui)
	_card.close_requested.connect(close_card)
	_sidebar.set_active(true)
	_sidebar.shop_pressed.connect(toggle_panel.bind(Kind.SHOP))
	_sidebar.settings_pressed.connect(toggle_panel.bind(Kind.SETTINGS))
	_sidebar.dex_pressed.connect(open_dex)
	_sidebar.minimize_pressed.connect(Platform.minimize)
	_sidebar.close_pressed.connect(Platform.request_quit)
	_shop.close_requested.connect(close_panel)
	_shop.decorate_requested.connect(toggle_decorating)
	_settings_panel.close_requested.connect(close_panel)
	_shop.message.connect(_sidebar.show_toast)
	_settings_panel.message.connect(_sidebar.show_toast)


func _on_notice_requested(key: String) -> void:
	if not key.is_empty():
		_sidebar.show_toast(tr(key))


func _on_shells_changed(shells: float) -> void:
	_sidebar.set_shells(NumberFormat.compact(shells, TranslationServer.get_locale()))


func _on_production_changed(rate: float) -> void:
	_sidebar.set_rate("+" + NumberFormat.per_second(rate, TranslationServer.get_locale()))


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
	_place_card(layout.tank_rect)
	_tank_tabs.layout(layout.tank_rect)
	var covered: bool = (
		layout.panel_rect.has_area() and layout.panel_rect.intersects(layout.tank_rect)
	)
	_tank_tabs.update_visibility(not covered)


func _place_panel(panel: UiPanel, kind: Kind, area: Rect2i) -> void:
	panel.set_active(_open == kind and area.has_area())
	if panel.is_active:
		panel.layout(area)


func _place_card(tank_area: Rect2i) -> void:
	var area: Rect2i = FishCard.fit_in(tank_area)
	_card.set_active(_card.fish() != null and area.has_area())
	if _card.is_active:
		_card.layout(area)


func _on_minimized_changed(is_minimized: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
	if is_minimized:
		mode = Node.PROCESS_MODE_DISABLED
	_canvas.process_mode = mode
	_tank.process_mode = mode
	Game.set_paused(is_minimized)
