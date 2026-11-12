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
