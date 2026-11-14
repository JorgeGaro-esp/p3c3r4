extends GutTest
## Logros y estadísticas en la franja: tecla L, pestañas de la tienda y aviso.

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


func _press(keycode: Key) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	Input.parse_input_event(key)
	await wait_frames(1)
	# Sin soltar la tecla, la segunda pulsación contaría como eco.
	var release: InputEventKey = InputEventKey.new()
	release.keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)
	await wait_frames(1)


func test_l_opens_the_achievements_tab_and_closes_it() -> void:
	await _press(KEY_L)
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	var shop: ShopPanel = _controller._shop
	assert_eq(shop.current_tab(), ShopPanel.ACHIEVEMENTS_TAB)
	await _press(KEY_L)
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_the_list_has_every_achievement() -> void:
	_controller.open_achievements()
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	assert_eq(shop.achievement_ids().size(), Game.content.achievements.ids().size())


func test_selecting_a_completed_one_shows_it_as_achieved() -> void:
	Game.state.achievements["first_fish"] = true
	_controller.open_achievements()
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_achievement("first_fish")
	await wait_frames(1)
	assert_string_contains(shop._rarity.text, "Conseguido")


func test_the_stats_tab_lists_rows() -> void:
	_controller.open_shop_tab(ShopPanel.STATS_TAB)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	assert_eq(shop.current_tab(), ShopPanel.STATS_TAB)
	assert_gt(shop._stat_rows.size(), 12)


func test_unlocking_shows_a_toast() -> void:
	Game.state.stats.add(GameStats.FISH_BOUGHT, 1.0)
	await wait_seconds(0.8)
	var sidebar: SidebarPanel = _controller._sidebar
	assert_true(Game.state.achievements.has("first_fish"))
	assert_true(sidebar.toast_text().find("Primer pez") >= 0)


func test_all_the_shop_tabs_fit_in_the_panel() -> void:
	_controller.open_achievements()
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	var width: int = 0
	for index: int in range(shop._tabs.titles.size()):
		width += shop._tabs._segment(index).length()
	assert_lte(width, shop._tabs.rect.size.x, "las pestañas no caben")
