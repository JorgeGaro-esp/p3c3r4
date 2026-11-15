extends GutTest
## Con un panel abierto la pecera no recibe clics ni enseña la ficha de un pez, y
## la rueda del ratón desplaza las listas aunque el cursor no esté sobre ellas.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _canvas: AsciiCanvas = null
var _ui: UiRoot = null
var _controller: StripController = null
var _tank: TankView = null
var _previous_mode: SettingsData.PanelMode = SettingsData.PanelMode.REPLACE
var _previous_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
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
	_main.queue_free()
	await wait_process_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)
	Settings.data.panel_mode = _previous_mode
	get_tree().root.size = _previous_size


func _visible_lists() -> Array[AsciiList]:
	var found: Array[AsciiList] = []
	for widget: AsciiWidget in _ui.all_widgets():
		var list: AsciiList = widget as AsciiList
		if list != null and list.is_shown:
			found.append(list)
	return found


func test_tank_ignores_input_while_a_panel_is_open() -> void:
	assert_true(_tank.input_enabled)
	_controller.open_panel(StripController.Kind.SHOP)
	assert_false(_tank.input_enabled)
	_controller.open_panel(StripController.Kind.SETTINGS)
	assert_false(_tank.input_enabled)
	_controller.close_panel()
	assert_true(_tank.input_enabled)


func test_opening_a_panel_closes_the_fish_card() -> void:
	var fish: Fish = Game.state.active().fish[0]
	_controller.show_card(fish)
	assert_not_null(_controller.card_fish())
	_controller.open_panel(StripController.Kind.SHOP)
	assert_null(_controller.card_fish())


func test_wheel_scrolls_the_open_list_from_anywhere_in_the_panel() -> void:
	_controller.open_shop_tab(ShopPanel.DEX_TAB)
	await wait_frames(2)
	var lists: Array[AsciiList] = _visible_lists()
	assert_eq(lists.size(), 1)
	var list: AsciiList = lists[0]
	if list.model.max_scroll() == 0:
		pending("la lista cabe entera en esta ventana")
		return
	var before: int = list.model.scroll
	# Un extremo del marco de la tienda, lejos de la lista.
	var corner: Vector2i = Vector2i(list.rect.end.x + 1, list.rect.position.y)
	assert_true(_ui.dispatch_wheel(corner, 1))
	assert_gt(list.model.scroll, before)


func test_wheel_over_the_list_scrolls_it_and_back_up() -> void:
	_controller.open_shop_tab(ShopPanel.DEX_TAB)
	await wait_frames(2)
	var list: AsciiList = _visible_lists()[0]
	if list.model.max_scroll() == 0:
		pending("la lista cabe entera en esta ventana")
		return
	var inside: Vector2i = list.rect.position + Vector2i(1, 1)
	_ui.dispatch_wheel(inside, 1)
	_ui.dispatch_wheel(inside, 1)
	var down: int = list.model.scroll
	assert_gt(down, 0)
	_ui.dispatch_wheel(inside, -1)
	assert_lt(list.model.scroll, down)


func test_scroll_survives_a_refresh_of_the_list() -> void:
	_controller.open_shop_tab(ShopPanel.DEX_TAB)
	await wait_frames(2)
	var list: AsciiList = _visible_lists()[0]
	if list.model.max_scroll() == 0:
		pending("la lista cabe entera en esta ventana")
		return
	var inside: Vector2i = list.rect.position + Vector2i(1, 1)
	_ui.dispatch_wheel(inside, 1)
	_ui.dispatch_wheel(inside, 1)
	var scrolled: int = list.model.scroll
	assert_gt(scrolled, 0)
	EventBus.shells_changed.emit(0.0)
	await wait_frames(2)
	assert_eq(list.model.scroll, scrolled)


func test_scroll_holds_for_seconds_on_every_tab() -> void:
	for tab: int in range(8):
		_controller.open_shop_tab(tab)
		await wait_frames(2)
		var lists: Array[AsciiList] = _visible_lists()
		if lists.is_empty() or lists[0].model.max_scroll() < 3:
			continue
		var list: AsciiList = lists[0]
		var inside: Vector2i = list.rect.position + Vector2i(1, 1)
		_ui.dispatch_wheel(inside, 1)
		_ui.dispatch_wheel(inside, 1)
		var scrolled: int = list.model.scroll
		await wait_seconds(1.5)
		assert_eq(list.model.scroll, scrolled, "pestaña %d" % tab)


func test_real_wheel_events_scroll_and_stay() -> void:
	_controller.open_shop_tab(ShopPanel.ACHIEVEMENTS_TAB)
	await wait_frames(2)
	var list: AsciiList = _visible_lists()[0]
	var cell: Vector2i = list.rect.position + Vector2i(2, 2)
	var offsets: PackedInt32Array = PackedInt32Array()
	for step: int in range(3):
		for pressed: bool in [true, false]:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
			event.pressed = pressed
			event.position = (Vector2(cell) + Vector2(0.5, 0.5)) * _canvas.cell_size
			Input.parse_input_event(event)
			Input.flush_buffered_events()
		await wait_frames(3)
		offsets.append(list.model.scroll)
	await wait_seconds(1.0)
	offsets.append(list.model.scroll)
	assert_eq(offsets[3], 3)


func test_wheel_does_nothing_when_no_panel_is_open() -> void:
	assert_false(_ui.dispatch_wheel(Vector2i(5, 5), 1))
