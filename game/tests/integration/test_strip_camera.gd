extends GutTest
## La pecera es más ancha que la ventana: el botón derecho la arrastra, los peces
## nuevos aparecen a la vista y el lienzo traduce los clics al mundo.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _canvas: AsciiCanvas = null
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


func _right_button(pixel: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = pressed
	event.position = pixel
	_tank._handle_pan(event)


func _drag(pixels: float) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.relative = Vector2(pixels, 0.0)
	event.button_mask = MOUSE_BUTTON_MASK_RIGHT
	_tank._handle_pan(event)


func _inside_tank() -> Vector2:
	return Vector2(5.0, 3.0) * _canvas.cell_size


func test_the_world_is_wider_than_the_window() -> void:
	assert_true(_tank.camera.is_scrollable())
	assert_eq(_tank.camera.world_columns, _canvas.columns * StripController.WORLD_SCREENS)


func test_the_sidebar_stays_where_it_is_when_the_camera_moves() -> void:
	_tank.camera.x = 0.0
	_tank.camera.pan_by(40.0)
	_canvas.camera_x = _tank.camera.x
	var cell: Vector2i = _canvas.world_cell_at(Vector2(0.0, 0.0))
	assert_eq(cell.x, int(_tank.camera.x))
	assert_eq(_canvas.cell_at(Vector2(0.0, 0.0)).x, 0)


func test_right_drag_moves_the_camera() -> void:
	_tank.camera.x = 20.0
	var start: float = _tank.camera.x
	_right_button(_inside_tank(), true)
	_drag(-100.0)
	_right_button(_inside_tank(), false)
	assert_almost_eq(_tank.camera.x, start + 100.0 / _canvas.cell_size.x, 0.01)
	assert_eq(_canvas.camera_x, _tank.camera.x)


func test_dragging_the_other_way_goes_back_and_stops_at_the_edge() -> void:
	_right_button(_inside_tank(), true)
	_drag(100000.0)
	_right_button(_inside_tank(), false)
	assert_eq(_tank.camera.x, 0.0)
	_right_button(_inside_tank(), true)
	_drag(-100000.0)
	_right_button(_inside_tank(), false)
	assert_eq(_tank.camera.x, _tank.camera.max_x())


func test_right_press_over_the_sidebar_does_not_grab_the_camera() -> void:
	var over_sidebar: Vector2 = Vector2(float(_canvas.columns - 3), 3.0) * _canvas.cell_size
	_right_button(over_sidebar, true)
	assert_false(_tank.camera.is_panning)


func test_no_dragging_while_a_panel_is_open() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	var start: float = _tank.camera.x
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = _inside_tank()
	_tank._input(press)
	assert_false(_tank.camera.is_panning)
	assert_eq(_tank.camera.x, start)


func test_new_fish_appear_inside_what_the_camera_shows() -> void:
	_tank.camera.pan_by(1000.0)
	_canvas.camera_x = _tank.camera.x
	Game.state.wallet.add(1.0e6)
	for _count: int in range(5):
		Game.buy_fish("pond_guppy")
	await wait_frames(2)
	var left: float = _tank.camera.x
	var right: float = left + float(_tank._view_area.size.x)
	var last: FishView = _tank._fish[_tank._fish.size() - 1]
	assert_gte(last.motion.position.x, left - 1.0)
	assert_lte(last.motion.position.x, right + 1.0)


func test_a_right_click_without_dragging_does_not_move_the_camera() -> void:
	var start: float = _tank.camera.x
	_right_button(_inside_tank(), true)
	_right_button(_inside_tank(), false)
	assert_false(_tank.camera.is_panning)
	assert_eq(_tank.camera.x, start)
