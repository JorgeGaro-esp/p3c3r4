extends GutTest


func test_fish_cost_grows_by_fifteen_percent() -> void:
	assert_eq(Economy.fish_cost(10.0, 0), 10.0)
	assert_eq(Economy.fish_cost(10.0, 1), 12.0)
	assert_eq(Economy.fish_cost(100.0, 2), 133.0)
	assert_eq(Economy.fish_cost(10.0, -3), 10.0, "negativos cuentan como 0")


func test_fish_cost_never_decreases() -> void:
	var previous: float = 0.0
	for owned: int in range(60):
		var cost: float = Economy.fish_cost(7.0, owned)
		assert_gte(cost, previous)
		previous = cost


func test_equipment_cost_grows_by_sixty_percent() -> void:
	assert_eq(Economy.equipment_cost(50.0, 0), 50.0)
	assert_eq(Economy.equipment_cost(50.0, 1), 80.0)
	assert_eq(Economy.equipment_cost(50.0, 2), 128.0)


func test_sale_value_is_half_the_cost_times_the_variant() -> void:
	assert_eq(Economy.sale_value(40.0), 20.0)
	assert_eq(Economy.sale_value(40.0, 3.0), 60.0)


func test_happiness_factor_range() -> void:
	assert_almost_eq(Economy.happiness_factor(0.0), 0.25, 0.0001)
	assert_almost_eq(Economy.happiness_factor(100.0), 1.25, 0.0001)
	assert_almost_eq(Economy.happiness_factor(50.0), 0.75, 0.0001)
	assert_almost_eq(Economy.happiness_factor(-20.0), 0.25, 0.0001)
	assert_almost_eq(Economy.happiness_factor(500.0), 1.25, 0.0001)


func test_fish_rate_multiplies_base_happiness_and_bonus() -> void:
	assert_almost_eq(Economy.fish_rate(2.0, 100.0), 2.5, 0.0001)
	assert_almost_eq(Economy.fish_rate(2.0, 100.0, 2.0), 5.0, 0.0001)
	assert_almost_eq(Economy.fish_rate(2.0, 0.0), 0.5, 0.0001)
