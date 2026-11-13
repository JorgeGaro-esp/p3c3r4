extends GutTest
## Cuidados sobre la escena principal completa: comida, manchas, perlas y ficha.

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
	Game.start_new_game(Game.DEFAULT_SEED)
	_main.queue_free()
	await wait_frames(1)
	get_tree().root.size = _previous_size
	TranslationServer.set_locale(_previous_locale)


func _click_cell(cell: Vector2i) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = (Vector2(cell) + Vector2(0.5, 0.5)) * _canvas.cell_size
	Input.parse_input_event(event)
	await wait_frames(2)


func _visible_label_texts() -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for widget: AsciiWidget in _ui.all_widgets():
		var label: AsciiLabel = widget as AsciiLabel
		if label != null and label.is_shown:
			texts.append(label.text)
	return texts


func _water_cell() -> Vector2i:
	return Vector2i(floori(float(_canvas.columns) * 0.4), floori(float(_canvas.row_count) * 0.4))


func test_clicking_empty_water_drops_food() -> void:
	_canvas.process_mode = Node.PROCESS_MODE_DISABLED
	var cell: Vector2i = _water_cell()
	for fish: Fish in Game.state.tanks[0].fish:
		var position: Vector2 = _tank.fish_position(fish)
		assert_ne(_tank.fish_at(cell), fish, "la celda elegida no está sobre un pez %s" % position)
	await _click_cell(cell)
	assert_eq(_tank.food_count(), FoodField.FLAKES_PER_DROP)
	_canvas.process_mode = Node.PROCESS_MODE_INHERIT


func test_a_hungry_fish_eats_food_dropped_next_to_it() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	fish.hunger = 20.0
	var position: Vector2 = _tank.fish_position(fish)
	_canvas.process_mode = Node.PROCESS_MODE_DISABLED
	_tank.drop_food(Vector2i(floori(position.x) + 2, floori(position.y)))
	_canvas.process_mode = Node.PROCESS_MODE_INHERIT
	await wait_seconds(1.5)
	assert_gt(fish.hunger, 20.0, "el pez se comió algún copo")


func test_dirty_water_shows_spots_and_dragging_cleans_them() -> void:
	Game.state.tanks[0].cleanliness = 45.0
	await wait_frames(2)
	var spots: int = _tank.spot_count()
	assert_eq(spots, Care.spots_for(45.0))
	assert_gt(spots, 0)
	var before: float = Game.state.tanks[0].cleanliness
	var cleaned: int = 0
	for x: int in range(_canvas.columns):
		for y: int in range(_canvas.row_count):
			if _tank.clean_at(Vector2i(x, y)):
				cleaned += 1
				break
		if cleaned >= 1:
			break
	assert_eq(cleaned, 1)
	assert_gt(Game.state.tanks[0].cleanliness, before)
	assert_lt(_tank.spot_count(), spots)


func test_a_dropped_pearl_can_be_collected_with_a_click() -> void:
	_canvas.process_mode = Node.PROCESS_MODE_DISABLED
	var fish: Fish = Game.state.tanks[0].fish[0]
	EventBus.pearl_spawned.emit(0, fish, 9.0)
	assert_eq(_tank.pearl_count(), 1)
	var before: float = Game.state.wallet.shells
	var pos: Vector2 = _tank.fish_position(fish) + Vector2(1.0, float(1))
	var hit: bool = false
	for y: int in range(floori(pos.y), _canvas.row_count):
		if _tank.click_cell(Vector2i(floori(pos.x) + 3, y)) and _tank.pearl_count() == 0:
			hit = true
			break
	_canvas.process_mode = Node.PROCESS_MODE_INHERIT
	assert_true(hit, "se recogió la perla")
	assert_eq(Game.state.wallet.shells, before + 9.0)


func test_the_fish_card_shows_satiety() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	fish.hunger = 40.0
	_controller.show_card(fish)
	await wait_frames(2)
	var found: bool = false
	for text: String in _visible_label_texts():
		if text.begins_with("Saciedad 40"):
			found = true
	assert_true(found)


func test_real_clicks_remove_one_spot_each_even_while_dirt_keeps_growing() -> void:
	get_tree().root.size = Vector2i(960, 240)
	await wait_frames(3)
	Game.state.tanks[0].cleanliness = 0.0
	await wait_frames(2)
	_canvas.process_mode = Node.PROCESS_MODE_DISABLED
	for _round: int in range(Care.MAX_SPOTS):
		var spots: int = _tank.spot_count()
		var target: Vector2i = Vector2i(-1, -1)
		for x: int in range(_canvas.columns):
			for y: int in range(_canvas.row_count):
				if _tank.spot_cell_hit(Vector2i(x, y)):
					target = Vector2i(x, y)
		await _click_cell(target)
		assert_eq(_tank.spot_count(), spots - 1)
	_canvas.process_mode = Node.PROCESS_MODE_INHERIT


func test_the_sidebar_shows_the_tank_cleanliness() -> void:
	Game.state.tanks[0].cleanliness = 42.0
	await wait_frames(3)
	assert_true("Limpieza 42 %" in _visible_label_texts())
