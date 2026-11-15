extends GutTest
## Decoración: pestaña de la tienda, modo decorar, colocar, recoger y guardar.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _canvas: AsciiCanvas = null
var _ui: UiRoot = null
var _controller: StripController = null
var _tank: TankView = null
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
	_canvas = _main.get_node("AsciiCanvas") as AsciiCanvas
	_ui = _main.get_node("UiRoot") as UiRoot
	_controller = _main.get_node("StripController") as StripController
	_tank = _main.get_node("TankView") as TankView
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)


func _shop() -> ShopPanel:
	return _controller._shop


func _floor_cell(offset: int) -> Vector2i:
	var area: Rect2i = _tank._current_area()
	return Vector2i(area.position.x + offset, area.end.y - TankView.SAND_ROWS - 1)


func test_shop_has_a_decoration_tab_with_every_object() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	_shop().select_tab(2)
	await wait_frames(2)
	assert_gte(_shop().decoration_ids().size(), 20)


func test_buying_decoration_from_the_shop_fills_the_stock() -> void:
	Game.state.wallet.add(10000.0)
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	_shop().select_decoration("big_rock")
	_shop().buy_selected()
	await wait_frames(2)
	assert_eq(Game.state.decoration_stock["big_rock"], 1)


func test_decorate_button_enters_the_mode_and_closes_the_panel() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	_shop().select_tab(2)
	_shop().decorate_requested.emit()
	await wait_frames(2)
	assert_true(_tank.is_decorating())
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_clicking_in_decorate_mode_places_the_held_object() -> void:
	Game.state.decoration_stock["big_rock"] = 1
	_tank.set_decorating(true)
	assert_eq(_tank.held_id(), "big_rock")
	assert_true(_tank.decor_click(_floor_cell(20)))
	await wait_frames(2)
	assert_eq(Game.state.tanks[0].decorations.size(), 1)
	assert_eq(_tank.decoration_count(), 1)
	assert_false(Game.state.decoration_stock.has("big_rock"))


func test_clicking_a_placed_object_picks_it_up_and_moves_it() -> void:
	Game.state.decoration_stock["big_rock"] = 1
	_tank.set_decorating(true)
	_tank.decor_click(_floor_cell(20))
	_tank.set_decorating(true)
	var placed: PlacedDecoration = Game.state.tanks[0].decorations[0]
	var cell: Vector2i = _floor_cell(20)
	assert_eq(_tank.decoration_at(cell), placed)
	_tank.decor_click(cell)
	assert_eq(Game.state.tanks[0].decorations.size(), 0)
	assert_eq(_tank.held_id(), "big_rock")
	_tank.decor_click(_floor_cell(50))
	assert_eq(Game.state.tanks[0].decorations.size(), 1)


func test_right_click_stores_the_object() -> void:
	Game.state.decoration_stock["small_rock"] = 1
	_tank.set_decorating(true)
	_tank.decor_click(_floor_cell(20))
	var placed: PlacedDecoration = Game.state.tanks[0].decorations[0]
	assert_true(_tank._store_at(_floor_cell(20)))
	assert_eq(Game.state.decoration_stock["small_rock"], 1)


func test_overlapping_placement_is_refused_with_a_message() -> void:
	Game.state.decoration_stock["big_rock"] = 2
	_tank.set_decorating(true)
	_tank.decor_click(_floor_cell(20))
	var messages: PackedStringArray = PackedStringArray()
	_tank.decor_message.connect(func(text: String) -> void: messages.append(text))
	_tank.decor_click(_floor_cell(26))
	assert_eq(Game.state.tanks[0].decorations.size(), 1)
	assert_true(messages.has(tr("TOAST_DECOR_OVERLAP")))


func test_escape_leaves_decorate_mode() -> void:
	_tank.set_decorating(true)
	_controller._on_escape()
	assert_false(_tank.is_decorating())


func test_the_d_key_toggles_decorate_mode() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_D
	key.pressed = true
	_controller._unhandled_key_input(key)
	assert_true(_tank.is_decorating())
	_controller._unhandled_key_input(key)
	assert_false(_tank.is_decorating())


func test_placed_objects_are_drawn_and_survive_a_save_round_trip() -> void:
	Game.state.decoration_stock["cave"] = 1
	_tank.set_decorating(true)
	_tank.decor_click(_floor_cell(30))
	await wait_frames(2)
	var data: Dictionary = Game.state.to_dict()
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(data, Game.content, warnings)
	assert_eq(loaded.tanks[0].decorations.size(), 1)
	assert_eq(loaded.tanks[0].decorations[0].def.id, "cave")
	assert_eq(
		loaded.tanks[0].decorations[0].x_permille, Game.state.tanks[0].decorations[0].x_permille
	)
