extends GutTest
## Los peces se apartan cuando algo los empuja.


func _motion() -> SwimMotion:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var motion: SwimMotion = SwimMotion.new(rng, SwimMotion.Style.GLIDE, 4.5, 0.15, 0.7)
	motion.set_bounds(Rect2(0.0, 0.0, 100.0, 20.0))
	motion.position = Vector2(50.0, 10.0)
	return motion


func test_push_moves_the_fish_in_that_direction() -> void:
	var pushed: SwimMotion = _motion()
	var plain: SwimMotion = _motion()
	for _i: int in range(10):
		pushed.push(Vector2(6.0, 0.0), 0.05)
		pushed.step(0.05)
		plain.step(0.05)
	assert_gt(pushed.position.x, plain.position.x + 0.3)


func test_push_is_capped() -> void:
	var motion: SwimMotion = _motion()
	for _i: int in range(100):
		motion.push(Vector2(100.0, 0.0), 0.05)
	motion.step(0.1)
	assert_lt(motion.position.x - 50.0, SwimMotion.PUSH_MAX * 0.1 + motion.speed * 0.1 + 0.01)
