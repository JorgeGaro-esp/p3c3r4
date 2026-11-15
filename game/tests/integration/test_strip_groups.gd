extends GutTest
## Cada acceso de la barra lateral abre solo sus pestañas (tienda, enciclopedia,
## logros, estadísticas), y F12 llama al pájaro del bioma.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _controller: StripController = null
var _previous_locale: String = ""
var _previous_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_frames(1)
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	(_main.get_node("StripController") as StripController).uses_saves = false
	add_child(_main)
	_controller = _main.get_node("StripController") as StripController
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)
	TranslationServer.set_locale(_previous_locale)
	get_tree().root.size = _previous_size


func _shop() -> ShopPanel:
	return _controller._shop


func test_the_shop_shows_only_its_own_tabs() -> void:
	_controller._sidebar.shop_pressed.emit()
	await wait_frames(2)
	assert_eq(_shop().group(), ShopPanel.Group.SHOP)
	assert_eq(_shop()._tabs.shown_tabs(), ShopPanel.SHOP_TABS)
	assert_eq(_shop()._frame.title, "Tienda")


func test_the_dex_shows_only_the_dex() -> void:
	_controller._sidebar.dex_pressed.emit()
	await wait_frames(2)
	assert_eq(_shop().group(), ShopPanel.Group.DEX)
	assert_eq(_shop()._tabs.shown_tabs(), PackedInt32Array([ShopPanel.DEX_TAB]))
	assert_eq(_shop()._frame.title, "Enciclopedia")
	assert_false(_shop()._tabs.is_shown, "una sola pestaña: no hace falta la fila")


func test_the_achievements_show_only_the_achievements() -> void:
	_controller._sidebar.achievements_pressed.emit()
	await wait_frames(2)
	assert_eq(_shop().group(), ShopPanel.Group.ACHIEVEMENTS)
	assert_eq(_shop()._frame.title, "Logros")


func test_the_stats_button_opens_only_the_stats_and_toggles() -> void:
	_controller._settings_panel.stats_requested.emit()
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	assert_eq(_shop().current_tab(), ShopPanel.STATS_TAB)
	assert_eq(_shop().group(), ShopPanel.Group.STATS)
	assert_eq(_shop()._frame.title, "Estadísticas")
	_controller._settings_panel.stats_requested.emit()
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_going_from_one_panel_to_another_changes_the_group() -> void:
	_controller._sidebar.dex_pressed.emit()
	await wait_frames(2)
	_controller._sidebar.shop_pressed.emit()
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	assert_eq(_shop().group(), ShopPanel.Group.SHOP)
	assert_eq(_shop().current_tab(), 0)
	_controller._sidebar.shop_pressed.emit()
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_arrow_keys_do_not_leave_the_group() -> void:
	_controller._sidebar.achievements_pressed.emit()
	await wait_frames(2)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_RIGHT
	_shop()._tabs.handle_key(key)
	key.keycode = KEY_LEFT
	_shop()._tabs.handle_key(key)
	assert_eq(_shop().current_tab(), ShopPanel.ACHIEVEMENTS_TAB)


func test_the_tank_tab_order_inside_the_shop_skips_the_other_groups() -> void:
	_controller._sidebar.shop_pressed.emit()
	await wait_frames(2)
	_shop().select_tab(3)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_RIGHT
	_shop()._tabs.handle_key(key)
	assert_eq(_shop().current_tab(), ShopPanel.PRESTIGE_TAB, "tras Biomas viene la Gran marea")


func test_the_dex_page_flips_when_the_species_changes() -> void:
	_controller.open_dex()
	await wait_frames(3)
	await wait_seconds(DexBook.FLIP_SECONDS + 0.2)
	assert_false(_shop()._book.is_flipping())
	var down: InputEventKey = InputEventKey.new()
	down.keycode = KEY_DOWN
	down.pressed = true
	_shop()._list.handle_key(down)
	assert_true(_shop()._book.is_flipping())


func test_f12_calls_the_bird_of_the_biome() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_F12
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await wait_frames(4)
	assert_true(_controller._tank._bird.visit.is_visible())


func test_f12_with_a_bird_already_there_does_nothing_more() -> void:
	assert_true(_controller._tank.summon_bird())
	assert_false(_controller._tank.summon_bird())


func test_opening_and_closing_a_panel_plays_the_crt_transition() -> void:
	_controller._sidebar.dex_pressed.emit()
	await wait_frames(2)
	assert_true(_controller._crt.is_playing())
	await wait_seconds(CrtTransition.SECONDS + 0.2)
	assert_false(_controller._crt.is_playing())
	_controller.close_panel()
	assert_true(_controller._crt.is_playing())


func test_the_stats_button_has_its_hotkey() -> void:
	assert_eq(_controller._settings_panel._stats.hotkey, KEY_I)


func test_the_transparent_setting_clears_the_solid_background() -> void:
	assert_true(_controller._canvas.solid_background)
	assert_true(_controller._canvas.sky.has_area(), "el cielo es transparente")
	Settings.set_transparent_background(true)
	await wait_frames(2)
	assert_false(_controller._canvas.solid_background)
	Settings.set_transparent_background(false)
