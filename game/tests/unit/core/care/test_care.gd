extends GutTest
## Reglas de cuidados: hambre, limpieza, felicidad y perlas.


func test_hunger_empties_in_ten_minutes_and_never_goes_negative() -> void:
	assert_almost_eq(Care.hunger_after(100.0, 300.0), 50.0, 0.001)
	assert_eq(Care.hunger_after(100.0, 600.0), 0.0)
	assert_eq(Care.hunger_after(5.0, 10000.0), 0.0)


func test_cleanliness_drops_with_more_fish_and_stays_in_range() -> void:
	var few: float = Care.cleanliness_after(100.0, 2, 600.0)
	var many: float = Care.cleanliness_after(100.0, 20, 600.0)
	assert_lt(many, few)
	assert_eq(Care.cleanliness_after(100.0, 0, 600.0), 100.0)
	assert_eq(Care.cleanliness_after(100.0, 200, 1.0e9), 0.0)


func test_happiness_spans_zero_to_one_hundred() -> void:
	assert_eq(Care.happiness(100.0, 100.0), 100.0)
	assert_eq(Care.happiness(0.0, 0.0), 0.0)
	assert_almost_eq(Care.happiness(100.0, 0.0), 55.0, 0.001)
	assert_almost_eq(Care.happiness(0.0, 100.0), 45.0, 0.001)


func test_production_multiplier_stays_between_quarter_and_one_and_a_quarter() -> void:
	assert_almost_eq(Economy.happiness_factor(Care.happiness(0.0, 0.0)), 0.25, 0.0001)
	assert_almost_eq(Economy.happiness_factor(Care.happiness(100.0, 100.0)), 1.25, 0.0001)
	for hunger: int in range(0, 101, 10):
		for clean: int in range(0, 101, 10):
			var factor: float = Economy.happiness_factor(Care.happiness(hunger, clean))
			assert_between(factor, 0.25, 1.25)


func test_spots_follow_dirt_in_steps_of_ten() -> void:
	assert_eq(Care.spots_for(100.0), 0)
	assert_eq(Care.spots_for(95.0), 1)
	assert_eq(Care.spots_for(90.0), 1)
	assert_eq(Care.spots_for(89.0), 2)
	assert_eq(Care.spots_for(0.0), Care.MAX_SPOTS)
	assert_eq(Care.spots_for(-50.0), Care.MAX_SPOTS)


func test_pearl_value_is_at_least_one_and_scales_with_production() -> void:
	assert_eq(Care.pearl_value(0.0), 1.0)
	assert_gt(Care.pearl_value(10.0), Care.pearl_value(1.0))


func test_sad_fish_are_slower_and_duller_but_never_stopped_or_gray() -> void:
	assert_eq(Care.speed_factor(100.0), 1.0)
	assert_almost_eq(Care.speed_factor(0.0), 0.45, 0.0001)
	assert_eq(Care.desaturation(100.0), 0.0)
	assert_eq(Care.desaturation(80.0), 0.0)
	assert_almost_eq(Care.desaturation(0.0), 0.8, 0.0001)
	assert_lt(Care.desaturation(0.0), 1.0)


func test_fish_feed_is_clamped() -> void:
	var fish: Fish = Fish.new("pond_guppy")
	fish.hunger = 95.0
	fish.feed(Care.HUNGER_PER_FLAKE)
	assert_eq(fish.hunger, Care.MAX_HUNGER)
