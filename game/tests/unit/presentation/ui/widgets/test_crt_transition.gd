extends GutTest
## La transición de tele de tubo al abrir y cerrar paneles.


func test_it_plays_and_ends() -> void:
	var crt: CrtTransition = CrtTransition.new()
	assert_false(crt.is_playing())
	crt.play(Rect2i(0, 0, 60, 10))
	assert_true(crt.is_playing())
	crt.update(CrtTransition.SECONDS * 0.5, null)
	assert_true(crt.is_playing())
	crt.update(CrtTransition.SECONDS, null)
	assert_false(crt.is_playing())


func test_a_tiny_area_has_no_transition() -> void:
	var crt: CrtTransition = CrtTransition.new()
	crt.play(Rect2i(0, 0, 2, 1))
	assert_false(crt.is_playing())


func test_reduced_motion_skips_it() -> void:
	var previous: bool = Settings.data.reduce_motion
	Settings.data.reduce_motion = true
	var crt: CrtTransition = CrtTransition.new()
	crt.play(Rect2i(0, 0, 60, 10))
	assert_false(crt.is_playing())
	Settings.data.reduce_motion = previous


func test_it_never_takes_clicks() -> void:
	var crt: CrtTransition = CrtTransition.new()
	crt.is_shown = true
	assert_false(crt.contains_cell(Vector2i(3, 3)))
