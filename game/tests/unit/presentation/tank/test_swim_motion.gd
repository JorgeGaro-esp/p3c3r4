extends GutTest
## Pruebas del movimiento de nado.

const BOUNDS: Rect2 = Rect2(0.0, 2.0, 60.0, 8.0)
const STEP: float = 1.0 / 30.0
const STEPS: int = 6000


func _make(style: SwimMotion.Style, seed_value: int = 1) -> SwimMotion:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var motion: SwimMotion = SwimMotion.new(rng, style, 6.0, 0.2, 1.4)
	motion.set_bounds(BOUNDS)
	motion.scatter()
	return motion


func test_stays_in_bounds_for_every_style() -> void:
	for style: SwimMotion.Style in [
		SwimMotion.Style.DART,
		SwimMotion.Style.GLIDE,
		SwimMotion.Style.DRIFT,
		SwimMotion.Style.CRAWL,
		SwimMotion.Style.HOP
	]:
		var motion: SwimMotion = _make(style)
		for _i: int in range(STEPS):
			motion.step(STEP)
			assert_true(
				BOUNDS.grow(0.001).has_point(motion.position), "out of bounds: %s" % motion.position
			)


func test_same_seed_same_path() -> void:
	var first: SwimMotion = _make(SwimMotion.Style.DART, 7)
	var second: SwimMotion = _make(SwimMotion.Style.DART, 7)
	for _i: int in range(500):
		first.step(STEP)
		second.step(STEP)
	assert_eq(first.position, second.position)


func test_facing_flips_only_when_slow() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	var previous: int = motion.facing
	for _i: int in range(STEPS):
		motion.step(STEP)
		if motion.facing != previous:
			assert_lt(absf(motion.velocity.x), SwimMotion.TURN_SPEED + 0.01)
			previous = motion.facing


func test_speed_is_capped() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.DART)
	for _i: int in range(STEPS):
		motion.step(STEP)
		assert_lte(motion.velocity.length(), motion.speed * 1.85)


func test_body_offset_zero_at_head_and_bounded() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	motion.step(STEP)
	motion.facing = 1
	assert_eq(motion.body_offset(5, 6), 0.0)
	motion.facing = -1
	assert_eq(motion.body_offset(0, 6), 0.0)
	for column: int in range(6):
		assert_lte(absf(motion.body_offset(column, 6)), motion.amplitude + 0.0001)


func test_a_fish_never_swims_backwards() -> void:
	for style: SwimMotion.Style in [
		SwimMotion.Style.DART, SwimMotion.Style.GLIDE, SwimMotion.Style.DRIFT
	]:
		var motion: SwimMotion = _make(style, 3)
		for _i: int in range(STEPS):
			motion.step(STEP)
			assert_gte(motion.velocity.x * float(motion.facing), -0.0001, "marcha atrás")


func test_turning_flattens_the_fish_and_flips_it_at_the_flattest_point() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 5)
	var turns: int = 0
	var was_turning: bool = false
	var flattest: float = 1.0
	var facing_before: int = motion.facing
	for _i: int in range(STEPS):
		motion.step(STEP)
		if motion.is_turning():
			if not was_turning:
				facing_before = motion.facing
				flattest = 1.0
			flattest = minf(flattest, motion.turn_scale())
		elif was_turning:
			turns += 1
			assert_lt(flattest, 0.2, "el giro no llega a ponerse de canto")
			assert_ne(motion.facing, facing_before, "el giro no cambia el sentido")
		was_turning = motion.is_turning()
	assert_gt(turns, 3, "no hay giros")


func test_the_scale_is_one_when_not_turning() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	assert_eq(motion.turn_scale(), 1.0)
	assert_false(motion.is_turning())


func test_a_crawler_stays_on_the_floor_and_does_not_wave() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.CRAWL, 9)
	assert_eq(motion.position.y, BOUNDS.end.y)
	var moved: float = 0.0
	var start: float = motion.position.x
	for _i: int in range(STEPS):
		motion.step(STEP)
		assert_eq(motion.position.y, BOUNDS.end.y)
		assert_eq(motion.body_offset(3, 8), 0.0)
		assert_eq(motion.tilt_offset(3, 8), 0.0)
		moved = maxf(moved, absf(motion.position.x - start))
	assert_gt(moved, 3.0, "el bicho de fondo no se mueve")


func test_a_schooling_fish_stays_near_the_centre_of_its_school() -> void:
	var centre: Vector2 = Vector2(30.0, 6.0)
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	motion.school_pull = 1.0
	var near: int = 0
	for _i: int in range(STEPS):
		motion.set_school_center(centre)
		motion.step(STEP)
		if motion.position.distance_to(centre) < 12.0:
			near += 1
	assert_gt(near, STEPS * 8 / 10, "casi siempre cerca del banco")


func test_a_loner_ignores_the_school() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	motion.set_school_center(Vector2(58.0, 9.0))
	var far: int = 0
	for _i: int in range(STEPS):
		motion.step(STEP)
		if motion.position.distance_to(Vector2(58.0, 9.0)) > 20.0:
			far += 1
	assert_gt(far, 0, "sin banco nada se queda siempre pegado a un punto")


func test_a_longer_turn_takes_longer() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 5)
	motion.turn_seconds = 0.9
	var longest: float = 0.0
	var turning: float = 0.0
	for _i: int in range(STEPS):
		motion.step(STEP)
		if motion.is_turning():
			turning += STEP
			longest = maxf(longest, turning)
		else:
			turning = 0.0
	assert_gt(longest, 0.6)
	assert_lte(longest, 0.9 + STEP * 2.0)


func test_the_wave_number_changes_how_much_the_tail_curls() -> void:
	var stiff: SwimMotion = _make(SwimMotion.Style.GLIDE)
	var snake: SwimMotion = _make(SwimMotion.Style.GLIDE)
	stiff.wave_number = 1.5
	snake.wave_number = 9.0
	stiff.phase = 1.0
	snake.phase = 1.0
	stiff.facing = 1
	snake.facing = 1
	assert_ne(stiff.body_offset(0, 10), snake.body_offset(0, 10))


func test_a_hopper_sits_on_the_floor_and_jumps_in_arcs() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.HOP)
	motion.rest_seconds = 1.0
	var jumped: bool = false
	var sat: bool = false
	for _i: int in range(STEPS):
		motion.step(STEP)
		assert_true(BOUNDS.grow(0.001).has_point(motion.position), "fuera: %s" % motion.position)
		if is_equal_approx(motion.position.y, BOUNDS.end.y):
			sat = true
		elif motion.position.y < BOUNDS.end.y - 0.2:
			jumped = true
	assert_true(jumped, "nunca salta")
	assert_true(sat, "nunca se posa")


func test_a_resting_fish_spends_time_without_moving() -> void:
	var lazy: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	lazy.rest_chance = 1.0
	lazy.rest_seconds = 4.0
	var busy: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	var lazy_travel: float = 0.0
	var busy_travel: float = 0.0
	for _i: int in range(STEPS):
		var before_lazy: Vector2 = lazy.position
		var before_busy: Vector2 = busy.position
		lazy.step(STEP)
		busy.step(STEP)
		lazy_travel += before_lazy.distance_to(lazy.position)
		busy_travel += before_busy.distance_to(busy.position)
	assert_lt(lazy_travel, busy_travel * 0.8)


func test_food_wakes_a_resting_fish() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	motion.rest_chance = 1.0
	motion.rest_seconds = 20.0
	for _i: int in range(30):
		motion.step(STEP)
	motion.seek(Vector2(BOUNDS.end.x, BOUNDS.position.y))
	var start: Vector2 = motion.position
	for _i: int in range(90):
		motion.seek(Vector2(BOUNDS.end.x, BOUNDS.position.y))
		motion.step(STEP)
	assert_gt(motion.position.distance_to(start), 1.0)


func test_the_depth_band_keeps_the_fish_in_its_slice_of_the_water() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	motion.depth_min = 0.5
	motion.depth_max = 1.0
	var band: Rect2 = motion.band_of(BOUNDS)
	assert_almost_eq(band.position.y, BOUNDS.position.y + BOUNDS.size.y * 0.5, 0.001)
	assert_almost_eq(band.end.y, BOUNDS.end.y, 0.001)
	motion.set_bounds(band)
	for _i: int in range(STEPS):
		motion.step(STEP)
		assert_true(band.grow(0.001).has_point(motion.position))


func test_the_default_band_is_the_whole_water() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE)
	assert_eq(motion.band_of(BOUNDS), BOUNDS)
