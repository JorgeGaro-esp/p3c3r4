extends GutTest
## Los unos y ceros del fondo y de la estela del puntero (Fase 19).

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _canvas: AsciiCanvas = null
var _tank: TankView = null
var _controller: StripController = null
var _previous_size: Vector2i = Vector2i.ZERO
var _previous_effect: bool = true
var _previous_reduce: bool = false


func before_each() -> void:
	_previous_effect = Settings.data.binary_effect
	_previous_reduce = Settings.data.reduce_motion
	Settings.data.binary_effect = true
	Settings.data.reduce_motion = false
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_frames(1)
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	(_main.get_node("StripController") as StripController).uses_saves = false
	add_child(_main)
	_canvas = _main.get_node("AsciiCanvas") as AsciiCanvas
	_tank = _main.get_node("TankView") as TankView
	_controller = _main.get_node("StripController") as StripController
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)
	Settings.data.binary_effect = _previous_effect
	Settings.data.reduce_motion = _previous_reduce
	get_tree().root.size = _previous_size


func _move_mouse(cell: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = cell * _canvas.cell_size
	_tank._input(event)


func test_every_tank_has_floating_digits() -> void:
	assert_gt(_tank._binary.count(), 0)


func test_cursor_trail_appears_only_when_moving_over_the_tank() -> void:
	var area: Rect2i = _tank.get("_view_area")
	var start: Vector2 = Vector2(area.position) + Vector2(5.0, 3.0)
	_move_mouse(start)
	assert_eq(_tank._cursor.count(), 0)
	_move_mouse(start + Vector2(12.0, 0.0))
	assert_gt(_tank._cursor.count(), 0)


func test_no_trail_while_a_panel_is_open() -> void:
	var area: Rect2i = _tank.get("_view_area")
	var start: Vector2 = Vector2(area.position) + Vector2(5.0, 3.0)
	_move_mouse(start)
	_move_mouse(start + Vector2(10.0, 0.0))
	assert_gt(_tank._cursor.count(), 0)
	_controller.open_panel(StripController.Kind.SHOP)
	assert_eq(_tank._cursor.count(), 0)
	_move_mouse(start + Vector2(20.0, 0.0))
	assert_eq(_tank._cursor.count(), 0)


func test_switching_the_effect_off_stops_the_trail() -> void:
	Settings.data.binary_effect = false
	var area: Rect2i = _tank.get("_view_area")
	var start: Vector2 = Vector2(area.position) + Vector2(5.0, 3.0)
	_move_mouse(start)
	_move_mouse(start + Vector2(15.0, 0.0))
	assert_eq(_tank._cursor.count(), 0)


func test_reduce_motion_stops_the_trail() -> void:
	Settings.data.reduce_motion = true
	var area: Rect2i = _tank.get("_view_area")
	var start: Vector2 = Vector2(area.position) + Vector2(5.0, 3.0)
	_move_mouse(start)
	_move_mouse(start + Vector2(15.0, 0.0))
	assert_eq(_tank._cursor.count(), 0)
