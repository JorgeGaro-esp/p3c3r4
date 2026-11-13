extends GutTest
## Abrir biomas, cambiar de pecera y que las acciones vayan a la pecera activa.

var _fish_events: Array[int] = []


func before_each() -> void:
	Game.start_new_game(42)
	Game.state.wallet.add(1.0e7)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func _record_fish(tank_index: int, _fish: Fish) -> void:
	_fish_events.append(tank_index)


func test_a_new_game_has_only_the_pond() -> void:
	assert_eq(Game.state.tanks.size(), 1)
	assert_eq(Game.state.active().biome_id, "pond")


func test_unknown_biome_and_not_enough_shells() -> void:
	assert_eq(Game.biomes.unlock("nope"), BiomeDirector.Result.UNKNOWN)
	Game.state.wallet.spend(Game.state.wallet.shells)
	assert_eq(Game.biomes.unlock("reef"), BiomeDirector.Result.NOT_ENOUGH_SHELLS)
	assert_eq(Game.state.tanks.size(), 1)


func test_unlocking_the_reef_spends_shells_opens_a_tank_and_switches_to_it() -> void:
	var before: float = Game.state.wallet.shells
	var cost: float = Game.biomes.cost("reef")
	assert_eq(Game.biomes.unlock("reef"), BiomeDirector.Result.OK)
	assert_almost_eq(Game.state.wallet.shells, before - cost, 0.0001)
	assert_eq(Game.state.tanks.size(), 2)
	assert_eq(Game.state.active_tank, 1)
	assert_eq(Game.state.active().biome_id, "reef")
	assert_eq(Game.biomes.unlock("reef"), BiomeDirector.Result.ALREADY_OPEN)


func test_unlocking_announces_the_new_tank_and_the_switch() -> void:
	watch_signals(EventBus)
	Game.biomes.unlock("reef")
	assert_signal_emitted_with_parameters(EventBus, "tank_unlocked", [1])
	assert_signal_emitted_with_parameters(EventBus, "active_tank_changed", [1])


func test_switching_tanks_validates_the_index() -> void:
	Game.biomes.unlock("reef")
	assert_true(Game.biomes.set_active(0))
	assert_eq(Game.state.active_tank, 0)
	assert_false(Game.biomes.set_active(5))
	assert_false(Game.biomes.set_active(-1))
	assert_eq(Game.state.active_tank, 0)


func test_species_can_only_be_bought_in_their_own_biome() -> void:
	Game.biomes.unlock("reef")
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.WRONG_BIOME)
	assert_eq(Game.buy_fish("reef_clownfish"), GameService.BuyResult.OK)
	assert_eq(Game.state.tanks[1].count_of("reef_clownfish"), 1)
	assert_eq(Game.state.tanks[0].count_of("reef_clownfish"), 0)
	Game.biomes.set_active(0)
	assert_eq(Game.buy_fish("reef_clownfish"), GameService.BuyResult.WRONG_BIOME)
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.OK)


func test_fish_cost_counts_only_the_active_tank() -> void:
	Game.biomes.unlock("reef")
	var first: float = Game.fish_cost("reef_clownfish")
	Game.buy_fish("reef_clownfish")
	assert_gt(Game.fish_cost("reef_clownfish"), first)
	Game.biomes.set_active(0)
	assert_eq(Game.fish_cost("pond_guppy"), Economy.fish_cost(10.0, 2))


func test_equipment_goes_to_the_active_tank() -> void:
	Game.biomes.unlock("reef")
	assert_eq(Game.buy_equipment("filter"), GameService.EquipResult.OK)
	assert_eq(Game.state.tanks[1].level_of("filter"), 1)
	assert_eq(Game.state.tanks[0].level_of("filter"), 0)
	assert_eq(Game.equipment_cost("filter"), Economy.equipment_cost(200.0, 1))
	Game.biomes.set_active(0)
	assert_eq(Game.equipment_cost("filter"), Economy.equipment_cost(200.0, 0))


func test_decoration_is_placed_in_the_active_tank() -> void:
	Game.biomes.unlock("reef")
	Game.buy_decoration("brain_coral")
	var result: GameService.DecorResult = Game.place_decoration("brain_coral", 400, 0, 80, 12)
	assert_eq(result, GameService.DecorResult.OK)
	assert_eq(Game.state.tanks[1].decorations.size(), 1)
	assert_eq(Game.state.tanks[0].decorations.size(), 0)
	assert_eq(Game.state.count_tag("coral"), 1)


func test_selling_works_on_the_active_tank() -> void:
	Game.biomes.unlock("reef")
	Game.buy_fish("reef_clownfish")
	var fish: Fish = Game.state.tanks[1].fish[0]
	assert_gt(Game.sell_fish(fish), 0.0)
	assert_eq(Game.state.tanks[1].fish.size(), 0)
	assert_eq(Game.state.tanks[0].fish.size(), 2)


func test_sell_all_defaults_to_the_active_tank() -> void:
	Game.biomes.unlock("reef")
	Game.buy_fish("reef_clownfish")
	Game.sell_all_fish()
	assert_eq(Game.state.tanks[1].fish.size(), 0)
	assert_eq(Game.state.tanks[0].fish.size(), 2)


func test_debug_fish_come_from_the_active_biome() -> void:
	Game.biomes.unlock("reef")
	Game.debug_add_fish(5)
	for fish: Fish in Game.state.tanks[1].fish:
		assert_string_starts_with(fish.species_id, "reef_")


func test_fish_hatched_in_a_hidden_tank_are_announced_with_their_index() -> void:
	Game.biomes.unlock("reef")
	Game.biomes.set_active(0)
	_fish_events.clear()
	EventBus.fish_added.connect(_record_fish)
	Game.biomes.set_active(1)
	Game.buy_fish("reef_clownfish")
	Game.biomes.set_active(0)
	_fish_events.clear()
	var reef: Tank = Game.state.tanks[1]
	var egg: Egg = Egg.new("reef_clownfish", VariantDef.NORMAL_ID, 0.0)
	reef.eggs.append(egg)
	await wait_process_frames(3)
	EventBus.fish_added.disconnect(_record_fish)
	assert_true(_fish_events.has(1), "la eclosión de la pecera oculta se anuncia")
	assert_eq(reef.fish.size(), 2)


func test_pearls_from_a_hidden_tank_are_collected_automatically() -> void:
	Game.biomes.unlock("reef")
	Game.buy_fish("reef_clownfish")
	var fish: Fish = Game.state.tanks[1].fish[0]
	Game.biomes.set_active(0)
	var before: float = Game.state.wallet.shells
	Game.state.pending_pearls.append(PearlSpawn.new(1, fish, 77.0))
	watch_signals(EventBus)
	await wait_process_frames(2)
	assert_signal_not_emitted(EventBus, "pearl_spawned")
	assert_signal_emitted(EventBus, "pearl_collected")
	assert_gte(Game.state.wallet.shells, before + 77.0)


func test_adopting_a_state_restores_its_active_tank() -> void:
	var loaded: GameState = GameState.new()
	var reef: Tank = Tank.new()
	reef.biome_id = "reef"
	loaded.tanks.append(reef)
	loaded.active_tank = 1
	watch_signals(EventBus)
	Game.adopt_state(loaded)
	assert_eq(Game.state.active().biome_id, "reef")
	assert_signal_emitted_with_parameters(EventBus, "active_tank_changed", [1])
