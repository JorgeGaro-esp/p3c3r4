extends GutTest
## Comida, manchas de cristal, perlas y ánimo de los peces (solo la parte visual).

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 7


func test_food_drops_in_small_groups_and_is_capped() -> void:
	var food: FoodField = FoodField.new()
	food.drop(Vector2(10, 3), _rng)
	assert_eq(food.count(), FoodField.FLAKES_PER_DROP)
	for _index: int in range(30):
		food.drop(Vector2(10, 3), _rng)
	assert_eq(food.count(), FoodField.MAX_FLAKES)


func test_food_falls_and_dissolves_at_the_floor() -> void:
	var food: FoodField = FoodField.new()
	food.floor_row = 8.0
	food.drop(Vector2(10, 3), _rng)
	var start: float = food.position_of(0).y
	food.update(0.5, null)
	assert_gt(food.position_of(0).y, start)
	food.update(10.0, null)
	assert_eq(food.count(), 0)


func test_nearest_flake_is_found_within_range_only() -> void:
	var food: FoodField = FoodField.new()
	food.floor_row = 100.0
	food.drop(Vector2(50, 3), _rng)
	assert_eq(food.nearest_to(Vector2(0, 0), 5.0), -1)
	assert_gte(food.nearest_to(Vector2(50, 3), 5.0), 0)


func test_glass_spots_follow_the_count_and_are_found_by_cell() -> void:
	var spots: GlassSpots = GlassSpots.new()
	spots.configure(Rect2i(0, 1, 80, 8))
	assert_eq(spots.spot_at(Vector2i(5, 3)), -1, "sin manchas no hay nada que limpiar")
	spots.set_count(4)
	assert_eq(spots.count(), 4)
	spots.set_count(99)
	assert_eq(spots.count(), Care.MAX_SPOTS)


func test_the_cleaned_spot_is_the_one_that_disappears() -> void:
	var spots: GlassSpots = GlassSpots.new()
	spots.configure(Rect2i(0, 1, 120, 10))
	spots.set_count(5)
	var target: int = -1
	var cell: Vector2i = Vector2i.ZERO
	for x: int in range(120):
		for y: int in range(1, 11):
			var found: int = spots.spot_at(Vector2i(x, y))
			if found == 1:
				target = found
				cell = Vector2i(x, y)
	assert_eq(target, 1)
	spots.mark_for_removal(1)
	spots.set_count(4)
	assert_eq(spots.spot_at(cell), -1, "la mancha limpiada ya no está donde estaba")


func test_pearls_fall_rest_on_the_floor_and_are_collected_by_value() -> void:
	var pearls: PearlField = PearlField.new()
	pearls.floor_row = 9.0
	pearls.add(Vector2(20, 2), 7.0)
	pearls.update(10.0, null)
	assert_eq(pearls.count(), 1)
	var index: int = pearls.pearl_at(Vector2i(20, 9))
	assert_eq(index, 0)
	assert_eq(pearls.take(index), 7.0)
	assert_eq(pearls.count(), 0)


func test_too_many_pearls_return_the_oldest_value_so_nothing_is_lost() -> void:
	var pearls: PearlField = PearlField.new()
	var evicted_total: float = 0.0
	for index: int in range(PearlField.MAX_PEARLS + 3):
		evicted_total += pearls.add(Vector2(float(index) * 3.0, 2.0), 10.0)
	assert_eq(pearls.count(), PearlField.MAX_PEARLS)
	assert_eq(evicted_total, 30.0)


func test_a_sad_fish_swims_slower_and_loses_color() -> void:
	var sprite: AsciiSprite = SpriteLoader.load_file("res://content/sprites/pond_guppy.txt")
	var def: SpeciesDef = load("res://content/species/pond_guppy.tres") as SpeciesDef
	var motion: SwimMotion = SwimMotion.new(_rng, SwimMotion.Style.GLIDE, 6.0, 0.1, 1.0)
	var view: FishView = FishView.new(sprite, def.build_palette(), motion, 0.4)
	view.set_mood(100.0)
	assert_eq(motion.speed_scale, 1.0)
	assert_eq(view.desaturation(), 0.0)
	view.set_mood(0.0)
	assert_lt(motion.speed_scale, 0.5)
	assert_gt(view.desaturation(), 0.5)
	view.set_mood(100.0)
	assert_eq(view.desaturation(), 0.0, "al recuperarse vuelve el color")


func test_seeking_points_the_fish_toward_the_target() -> void:
	var motion: SwimMotion = SwimMotion.new(_rng, SwimMotion.Style.GLIDE, 6.0, 0.1, 1.0)
	motion.set_bounds(Rect2(0, 0, 100, 20))
	motion.position = Vector2(10, 5)
	for _frame: int in range(120):
		motion.seek(Vector2(80, 5))
		motion.step(1.0 / 60.0)
	assert_gt(motion.position.x, 15.0)
