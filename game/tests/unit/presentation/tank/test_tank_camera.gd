extends GutTest
## Cámara horizontal de la pecera: límites, arrastre y centrado.

var _camera: TankCamera = null


func before_each() -> void:
	_camera = TankCamera.new()
	_camera.configure(100, 250)


func test_it_scrolls_only_when_the_world_is_wider_than_the_view() -> void:
	assert_true(_camera.is_scrollable())
	assert_eq(_camera.max_x(), 150.0)
	_camera.configure(100, 100)
	assert_false(_camera.is_scrollable())
	assert_eq(_camera.max_x(), 0.0)


func test_a_world_narrower_than_the_view_is_made_as_wide_as_the_view() -> void:
	_camera.configure(100, 40)
	assert_eq(_camera.world_columns, 100)


func test_pan_stays_inside_the_world() -> void:
	_camera.pan_by(-30.0)
	assert_eq(_camera.x, 0.0)
	_camera.pan_by(1000.0)
	assert_eq(_camera.x, 150.0)


func test_resizing_pulls_the_camera_back_inside() -> void:
	_camera.pan_by(150.0)
	_camera.configure(100, 180)
	assert_eq(_camera.x, 80.0)


func test_dragging_right_moves_the_world_right_so_the_camera_goes_left() -> void:
	_camera.pan_by(50.0)
	_camera.begin_pan()
	_camera.drag(20.0, 10.0)
	assert_eq(_camera.x, 48.0)
	_camera.drag(-60.0, 10.0)
	assert_eq(_camera.x, 54.0)


func test_drag_does_nothing_without_begin() -> void:
	_camera.drag(20.0, 10.0)
	assert_eq(_camera.x, 0.0)


func test_a_tiny_movement_is_a_click_not_a_drag() -> void:
	_camera.begin_pan()
	_camera.drag(2.0, 10.0)
	assert_false(_camera.end_pan())
	assert_false(_camera.is_panning)


func test_a_long_movement_is_a_drag() -> void:
	_camera.begin_pan()
	_camera.drag(-30.0, 10.0)
	assert_true(_camera.end_pan())


func test_center_on_puts_the_column_in_the_middle_and_clamps() -> void:
	_camera.center_on(120.0)
	assert_eq(_camera.x, 70.0)
	_camera.center_on(5.0)
	assert_eq(_camera.x, 0.0)
	_camera.center_on(400.0)
	assert_eq(_camera.x, 150.0)


func test_fraction_goes_from_zero_to_one() -> void:
	assert_eq(_camera.fraction(), 0.0)
	_camera.pan_by(75.0)
	assert_almost_eq(_camera.fraction(), 0.5, 0.0001)
	_camera.pan_by(75.0)
	assert_eq(_camera.fraction(), 1.0)
