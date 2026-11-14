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
		SwimMotion.Style.CRAWL
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
