extends GutTest
## Monta la escena principal entera y la maneja como lo haría el jugador:
## ratón, teclado, paneles y dibujo.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
## Tamaño de ventana de la franja por defecto (la de pruebas sin pantalla mide 64×64).
const WINDOW_SIZE: Vector2i = Vector2i(1200, 400)

var _main: Node = null
var _canvas: AsciiCanvas = null
var _ui: UiRoot = null
var _controller: StripController = null
var _tank: TankView = null
var _previous_locale: String = ""
var _previous_mode: SettingsData.PanelMode = SettingsData.PanelMode.REPLACE
var _previous_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_previous_mode = Settings.data.panel_mode
	Settings.data.panel_mode = SettingsData.PanelMode.REPLACE
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_frames(1)
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	(_main.get_node("StripController") as StripController).uses_saves = false
	add_child(_main)
	_canvas = _main.get_node("AsciiCanvas") as AsciiCanvas
	_ui = _main.get_node("UiRoot") as UiRoot
	_controller = _main.get_node("StripController") as StripController
	_tank = _main.get_node("TankView") as TankView
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)
	_main.queue_free()
	await wait_frames(1)
	Settings.data.panel_mode = _previous_mode
	get_tree().root.size = _previous_size
	TranslationServer.set_locale(_previous_locale)


func _click_cell(cell: Vector2i) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = (Vector2(cell) + Vector2(0.5, 0.5)) * _canvas.cell_size
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await wait_frames(3)


func _press(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await wait_frames(3)


func _find_button(label_text: String) -> AsciiButton:
	for widget: AsciiWidget in _ui.all_widgets():
		var button: AsciiButton = widget as AsciiButton
		if button != null and button.label == label_text:
			return button
	return null


func test_scene_draws_pecera_and_sidebar_without_errors() -> void:
	assert_gt(_canvas.columns, PanelLayout.SIDEBAR_WIDTH)
	assert_gt(_canvas.glyph_count, 100, "se dibujan peces, arena, algas y la barra lateral")


func test_sidebar_sits_on_the_right_and_every_visible_widget_fits_the_window() -> void:
	var grid: Rect2i = Rect2i(0, 0, _canvas.columns, _canvas.row_count)
	var visible: int = 0
	for widget: AsciiWidget in _ui.all_widgets():
		if widget.is_shown and widget.rect.has_area():
			visible += 1
			assert_true(grid.encloses(widget.rect), "fuera de la ventana: %s" % widget.rect)
	assert_gt(visible, 5)
	var shop: AsciiButton = _find_button(TranslationServer.translate("UI_SHOP"))
	assert_not_null(shop)
	assert_gte(shop.rect.position.x, _canvas.columns - PanelLayout.SIDEBAR_WIDTH)


func test_clicking_shop_opens_the_panel_and_escape_closes_it() -> void:
	var shop: AsciiButton = _find_button(TranslationServer.translate("UI_SHOP"))
	await _click_cell(shop.rect.position)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	await _press(KEY_ESCAPE)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_clicking_the_open_panel_button_again_closes_it() -> void:
	var settings: AsciiButton = _find_button(TranslationServer.translate("UI_SETTINGS"))
	await _click_cell(settings.rect.position)
	assert_eq(_controller.open_kind(), StripController.Kind.SETTINGS)
	await _click_cell(settings.rect.position)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_hotkeys_open_panels() -> void:
	await _press(KEY_T)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	await _press(KEY_A)
	assert_eq(_controller.open_kind(), StripController.Kind.SETTINGS)


func test_an_open_panel_covers_the_tank_and_fits_the_window() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var grid: Rect2i = Rect2i(0, 0, _canvas.columns, _canvas.row_count)
	var inside_panel: int = 0
	for widget: AsciiWidget in _ui.all_widgets():
		if widget.is_shown and widget.rect.has_area():
			assert_true(grid.encloses(widget.rect), "fuera de la ventana: %s" % widget.rect)
			if widget.rect.position.x < _canvas.columns - PanelLayout.SIDEBAR_WIDTH:
				inside_panel += 1
	assert_gt(inside_panel, 8, "la tienda tiene pestañas, lista, ficha y botones")


func test_shop_list_keyboard_navigation_changes_the_detail() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	await _press(KEY_TAB)
	await _press(KEY_TAB)
	var focused: AsciiWidget = _ui.focused_widget()
	assert_true(focused is AsciiList, "Tab, Tab llega a la lista tras las pestañas")
	await _press(KEY_DOWN)
	assert_eq((focused as AsciiList).selected_index(), 1)


func test_tab_moves_focus_only_among_visible_widgets() -> void:
	await _press(KEY_TAB)
	var first: AsciiWidget = _ui.focused_widget()
	assert_not_null(first)
	assert_true(first.is_shown)
	for _step: int in range(12):
		await _press(KEY_TAB)
		var focused: AsciiWidget = _ui.focused_widget()
		assert_not_null(focused)
		assert_true(focused.can_focus(), "el foco nunca cae en algo oculto")


func test_settings_buttons_change_settings_and_the_label_follows() -> void:
	var before: int = Settings.data.strip_rows
	_controller.open_panel(StripController.Kind.SETTINGS)
	await wait_frames(2)
	var plus: AsciiButton = null
	for widget: AsciiWidget in _ui.all_widgets():
		var button: AsciiButton = widget as AsciiButton
		if button != null and button.is_shown and button.label == "[+]":
			plus = button
			break
	assert_not_null(plus)
	await _click_cell(plus.rect.position)
	assert_eq(Settings.data.strip_rows, before + 1)
	Settings.set_strip_rows(before)


func test_dex_button_opens_the_dex_tab_of_the_shop() -> void:
	var dex: AsciiButton = _find_button(TranslationServer.translate("UI_DEX"))
	await _click_cell(dex.rect.position)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	assert_eq(_controller._shop.current_tab(), ShopPanel.DEX_TAB)


func test_clicks_on_the_open_panel_do_not_reach_what_is_underneath() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var handled_before: int = _ui.all_widgets().size()
	await _click_cell(Vector2i(2, 5))
	assert_eq(_ui.all_widgets().size(), handled_before)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)


func _find_label_starting_with(prefix: String) -> AsciiLabel:
	for widget: AsciiWidget in _ui.all_widgets():
		var label: AsciiLabel = widget as AsciiLabel
		if label != null and label.text.begins_with(prefix):
			return label
	return null


func test_fish_in_the_tank_match_the_model() -> void:
	assert_eq(_tank.fish_count(), Game.state.fish_total())
	Game.state.wallet.add(100.0)
	Game.buy_fish("pond_carp")
	await wait_frames(2)
	assert_eq(_tank.fish_count(), Game.state.fish_total())
	Game.debug_remove_fish(2)
	await wait_frames(2)
	assert_eq(_tank.fish_count(), Game.state.fish_total())


func test_sidebar_shows_shells_and_production_and_they_rise() -> void:
	var shells: AsciiLabel = _find_label_starting_with("Conchas")
	assert_not_null(shells)
	assert_eq(shells.text, "Conchas 20")
	var rate: AsciiLabel = _find_label_starting_with("+")
	assert_not_null(rate)
	assert_true(rate.text.ends_with("/s"), rate.text)
	var before: float = Game.state.wallet.shells
	await wait_seconds(1.2)
	assert_gt(Game.state.wallet.shells, before, "las conchas suben con el tiempo")
	assert_ne(shells.text, "Conchas 20", "el contador se actualiza")


func test_minimizing_pauses_the_simulation() -> void:
	var before: float = Game.state.sim_time
	Game.set_paused(true)
	await wait_seconds(0.5)
	assert_eq(Game.state.sim_time, before)
	Game.set_paused(false)


func _visible_label_texts() -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for widget: AsciiWidget in _ui.all_widgets():
		var label: AsciiLabel = widget as AsciiLabel
		if label != null and label.is_shown:
			texts.append(label.text)
	return texts


func test_shop_lists_the_real_species_and_hides_locked_names() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var found: bool = false
	for widget: AsciiWidget in _ui.all_widgets():
		var list: AsciiList = widget as AsciiList
		if list != null and list.is_shown:
			found = true
			assert_eq(list.names.size(), 10)
			assert_true(list.names[0].contains("Guppy"), list.names[0])
			assert_true(list.names[8].contains("???"), "la koi empieza bloqueada")
	assert_true(found)


func test_buying_from_the_shop_adds_a_fish_to_the_tank() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var before: int = Game.state.fish_total()
	var buy: AsciiButton = _find_button("[ Comprar ]")
	assert_not_null(buy)
	await _click_cell(buy.rect.position)
	await wait_frames(2)
	assert_eq(Game.state.fish_total(), before + 1)
	assert_eq(_tank.fish_count(), before + 1)


func test_clicking_a_fish_opens_its_card_and_escape_closes_it() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	_canvas.process_mode = Node.PROCESS_MODE_DISABLED  # los peces se quedan quietos
	var position: Vector2 = _tank.fish_position(fish)
	var cell: Vector2i = Vector2i(floori(position.x) + 1, floori(position.y))
	assert_eq(_tank.fish_at(cell), fish, "hit test %s %s" % [position, cell])
	# La pecera es más ancha que la ventana: la cámara se coloca para ver al pez.
	_tank.camera.x = float(clampi(cell.x - 10, 0, int(_tank.camera.max_x())))
	_canvas.camera_x = _tank.camera.x
	await _click_cell(cell - Vector2i(int(_tank.camera.x), 0))
	_canvas.process_mode = Node.PROCESS_MODE_INHERIT
	assert_eq(_controller.card_fish(), fish)
	assert_true("Guppy" in _visible_label_texts())
	await _press(KEY_ESCAPE)
	assert_null(_controller.card_fish())


func test_the_fish_card_disappears_when_its_fish_does() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	_controller.show_card(fish)
	Game.debug_remove_fish(500)
	await wait_frames(2)
	assert_null(_controller.card_fish())
