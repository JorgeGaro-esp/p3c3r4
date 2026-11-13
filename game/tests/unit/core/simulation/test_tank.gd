extends GutTest


func test_add_and_count() -> void:
	var tank: Tank = Tank.new()
	assert_true(tank.add_fish(Fish.new("a")))
	assert_true(tank.add_fish(Fish.new("a")))
	assert_true(tank.add_fish(Fish.new("b")))
	assert_eq(tank.count_of("a"), 2)
	assert_eq(tank.count_of("b"), 1)
	assert_eq(tank.count_of("c"), 0)


func test_capacity_is_enforced() -> void:
	var tank: Tank = Tank.new()
	tank.capacity = 2
	assert_true(tank.add_fish(Fish.new("a")))
	assert_true(tank.add_fish(Fish.new("a")))
	assert_true(tank.is_full())
	assert_false(tank.add_fish(Fish.new("a")))
	assert_eq(tank.fish.size(), 2)


func test_remove_fish() -> void:
	var tank: Tank = Tank.new()
	var fish: Fish = Fish.new("a")
	tank.add_fish(fish)
	assert_true(tank.remove_fish(fish))
	assert_false(tank.remove_fish(fish))
	assert_eq(tank.fish.size(), 0)


func test_game_state_counts_fish_in_every_tank() -> void:
	var state: GameState = GameState.new()
	state.tanks.append(Tank.new())
	state.tanks[0].add_fish(Fish.new("a"))
	state.tanks[1].add_fish(Fish.new("b"))
	state.tanks[1].add_fish(Fish.new("b"))
	assert_eq(state.fish_total(), 3)
