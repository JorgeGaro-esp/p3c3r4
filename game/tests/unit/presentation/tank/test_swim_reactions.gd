extends GutTest
## Pruebas del sueño y de las reacciones al cursor y a los clics.

const BOUNDS: Rect2 = Rect2(0.0, 2.0, 60.0, 8.0)
const STEP: float = 1.0 / 30.0


func _make(style: SwimMotion.Style, seed_value: int = 1) -> SwimMotion:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var motion: SwimMotion = SwimMotion.new(rng, style, 6.0, 0.2, 1.4)
	motion.set_bounds(BOUNDS)
	motion.scatter()
	return motion


func test_sleepiness_follows_activity_and_darkness() -> void:
	assert_eq(SwimMotion.sleepiness_for(1, 0.0), 0.0, "diurnal awake by day")
	assert_eq(SwimMotion.sleepiness_for(1, 1.0), 1.0, "diurnal asleep at night")
	assert_eq(SwimMotion.sleepiness_for(2, 0.0), 1.0, "nocturnal asleep by day")
	assert_eq(SwimMotion.sleepiness_for(2, 1.0), 0.0, "nocturnal awake at night")
	assert_almost_eq(SwimMotion.sleepiness_for(0, 1.0), 0.4, 0.001)


func test_sleeping_fish_is_slower_and_rests_more() -> void:
	var awake: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	var asleep: SwimMotion = _make(SwimMotion.Style.GLIDE, 3)
	asleep.set_sleepiness(1.0)
	var awake_distance: float = 0.0
	var asleep_distance: float = 0.0
	for _i: int in range(1500):
		var before_a: Vector2 = awake.position
		var before_s: Vector2 = asleep.position
		awake.step(STEP)
		asleep.step(STEP)
		awake_distance += before_a.distance_to(awake.position)
		asleep_distance += before_s.distance_to(asleep.position)
	assert_lt(asleep_distance, awake_distance * 0.7, "sleepy fish covers less ground")


func test_shy_fish_moves_away_from_cursor() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 5)
	motion.temperament = -0.9
	motion.position = Vector2(30.0, 5.0)
	var cursor: Vector2 = Vector2(28.0, 5.0)
	var start_gap: float = motion.position.distance_to(cursor)
	for _i: int in range(90):
		motion.react_to_cursor(cursor, motion.position)
		motion.step(STEP)
	assert_gt(motion.position.distance_to(cursor), start_gap, "shy fish backs off")


func test_curious_fish_approaches_cursor_but_keeps_distance() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 5)
	motion.temperament = 0.9
	motion.position = Vector2(10.0, 5.0)
	var cursor: Vector2 = Vector2(22.0, 5.0)
	var start_gap: float = motion.position.distance_to(cursor)
	for _i: int in range(240):
		motion.react_to_cursor(cursor, motion.position)
		motion.step(STEP)
	assert_lt(motion.position.distance_to(cursor), start_gap, "curious fish comes closer")


func test_neutral_fish_ignores_cursor_and_click() -> void:
	var motion: SwimMotion = _make(SwimMotion.Style.GLIDE, 5)
	motion.temperament = 0.0
	motion.startle(motion.position, motion.position)
	assert_false(motion.is_startled())


func test_click_startles_nearby_shy_fish_only() -> void:
	var shy: SwimMotion = _make(SwimMotion.Style.DART, 2)
	shy.temperament = -0.6
	shy.startle(shy.position + Vector2(2.0, 0.0), shy.position)
	assert_true(shy.is_startled())
	var far: SwimMotion = _make(SwimMotion.Style.DART, 2)
	far.temperament = -0.6
	far.startle(far.position + Vector2(40.0, 0.0), far.position)
	assert_false(far.is_startled(), "too far to notice")
	var curious: SwimMotion = _make(SwimMotion.Style.DART, 2)
	curious.temperament = 0.9
	curious.startle(curious.position, curious.position)
	assert_false(curious.is_startled())


func test_reactions_keep_fish_in_bounds() -> void:
	for style: SwimMotion.Style in [
		SwimMotion.Style.DART, SwimMotion.Style.HOP, SwimMotion.Style.CRAWL
	]:
		var motion: SwimMotion = _make(style, 9)
		motion.temperament = -1.0
		motion.set_sleepiness(0.5)
		for i: int in range(2000):
			motion.react_to_cursor(Vector2(float(i % 60), 5.0), motion.position)
			if i % 200 == 0:
				motion.startle(motion.position, motion.position)
			motion.step(STEP)
			assert_true(BOUNDS.grow(0.001).has_point(motion.position))
