extends GutTest
## Compra de equipo a través del autoload `Game`.


func before_each() -> void:
	Game.start_new_game(42)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func test_buying_equipment_spends_shells_and_raises_the_level() -> void:
	Game.state.wallet.add(1000.0)
	var before: float = Game.state.wallet.shells
	var cost: float = Game.equipment_cost("filter")
	assert_eq(Game.buy_equipment("filter"), GameService.EquipResult.OK)
	assert_almost_eq(Game.state.wallet.shells, before - cost, 0.0001)
	assert_eq(Game.state.tanks[0].level_of("filter"), 1)
	assert_gt(Game.equipment_cost("filter"), cost)


func test_not_enough_shells_changes_nothing() -> void:
	assert_eq(Game.buy_equipment("incubator"), GameService.EquipResult.NOT_ENOUGH_SHELLS)
	assert_eq(Game.state.tanks[0].level_of("incubator"), 0)


func test_unknown_and_maxed_equipment_are_refused() -> void:
	assert_eq(Game.buy_equipment("nope"), GameService.EquipResult.UNKNOWN)
	Game.state.wallet.add(1.0e9)
	for _level: int in range(5):
		Game.buy_equipment("aerator")
	assert_eq(Game.buy_equipment("aerator"), GameService.EquipResult.MAXED)
	assert_eq(Game.equipment_cost("aerator"), INF)


func test_buying_an_aerator_lets_more_fish_in() -> void:
	var tank: Tank = Game.state.tanks[0]
	tank.capacity = tank.fish.size()
	Game.state.wallet.add(1.0e6)
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.TANK_FULL)
	Game.buy_equipment("aerator")
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.OK)
