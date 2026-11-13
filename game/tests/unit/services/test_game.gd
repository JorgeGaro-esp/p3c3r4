extends GutTest
## Pruebas de las órdenes del jugador sobre el autoload `Game`.


func before_each() -> void:
	Game.start_new_game(42)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func test_new_game_starts_with_shells_and_a_few_fish() -> void:
	assert_eq(Game.state.wallet.shells, Game.START_SHELLS)
	assert_eq(Game.state.fish_total(), Game.START_FISH.size())
	assert_gt(Game.state.production_rate, 0.0)


func test_buy_fish_spends_shells_and_adds_the_fish() -> void:
	Game.state.wallet.add(100.0)
	var before: float = Game.state.wallet.shells
	var cost: float = Game.fish_cost("pond_guppy")
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.OK)
	assert_almost_eq(Game.state.wallet.shells, before - cost, 0.0001)
	assert_eq(Game.state.tanks[0].count_of("pond_guppy"), Game.START_FISH.count("pond_guppy") + 1)


func test_second_fish_of_a_species_costs_more() -> void:
	var first: float = Game.fish_cost("pond_guppy")
	Game.state.wallet.add(100.0)
	Game.buy_fish("pond_guppy")
	assert_gt(Game.fish_cost("pond_guppy"), first)


func test_buy_fails_without_enough_shells() -> void:
	Game.state.wallet.spend(Game.state.wallet.shells)
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.NOT_ENOUGH_SHELLS)
	assert_eq(Game.state.fish_total(), Game.START_FISH.size())


func test_buy_fails_for_unknown_species() -> void:
	assert_eq(Game.buy_fish("nope"), GameService.BuyResult.UNKNOWN_SPECIES)


func test_buy_fails_when_the_tank_is_full() -> void:
	Game.state.wallet.add(1.0e9)
	Game.state.tanks[0].capacity = Game.state.fish_total()
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.TANK_FULL)


func test_buying_announces_the_fish_and_the_new_production() -> void:
	Game.state.wallet.add(100.0)
	watch_signals(EventBus)
	Game.buy_fish("pond_minnow")
	assert_signal_emitted(EventBus, "fish_added")


func test_production_signal_follows_a_purchase() -> void:
	Game.state.wallet.add(100.0)
	var before: float = Game.state.production_rate
	Game.buy_fish("pond_minnow")
	Game._publish_changes()
	assert_gt(Game.state.production_rate, before)


func test_debug_fish_helpers_respect_capacity_and_emptiness() -> void:
	Game.debug_add_fish(500)
	assert_eq(Game.state.fish_total(), Game.state.tanks[0].capacity)
	Game.debug_remove_fish(500)
	assert_eq(Game.state.fish_total(), 0)


func test_pause_stops_the_loop() -> void:
	Game.set_paused(true)
	assert_eq(Game.process_mode, Node.PROCESS_MODE_DISABLED)
	Game.set_paused(false)
	assert_eq(Game.process_mode, Node.PROCESS_MODE_INHERIT)


func test_locked_species_cannot_be_bought_until_the_condition_is_met() -> void:
	Game.state.wallet.add(100000.0)
	assert_false(Game.state.is_unlocked("pond_tetra"))
	assert_eq(Game.buy_fish("pond_tetra"), GameService.BuyResult.LOCKED)
	Game._publish_changes()
	assert_true(Game.state.is_unlocked("pond_tetra"))
	assert_eq(Game.buy_fish("pond_tetra"), GameService.BuyResult.OK)


func test_unlocking_is_announced_once() -> void:
	watch_signals(EventBus)
	Game.state.wallet.add(100.0)
	Game._publish_changes()
	Game._publish_changes()
	assert_signal_emit_count(EventBus, "species_unlocked", 1)


func test_new_game_starts_with_only_the_basic_species_unlocked() -> void:
	assert_true(Game.state.is_unlocked("pond_guppy"))
	assert_true(Game.state.is_unlocked("pond_minnow"))
	assert_false(Game.state.is_unlocked("pond_koi"))


func test_a_species_stays_unlocked_after_selling_the_fish_that_unlocked_it() -> void:
	Game.state.wallet.add(100000.0)
	Game._publish_changes()
	Game.debug_remove_fish(500)
	Game._publish_changes()
	assert_true(Game.state.is_unlocked("pond_tetra"))


func test_feeding_a_full_fish_changes_nothing() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	assert_false(Game.feed_fish(fish))
	fish.hunger = 50.0
	assert_true(Game.feed_fish(fish))
	assert_almost_eq(fish.hunger, 50.0 + Care.HUNGER_PER_FLAKE, 0.0001)


func test_cleaning_raises_cleanliness_one_step_and_stops_at_clean() -> void:
	var tank: Tank = Game.state.tanks[0]
	assert_false(Game.clean_spot())
	tank.cleanliness = 50.0
	assert_true(Game.clean_spot())
	assert_almost_eq(tank.cleanliness, 50.0 + Care.SPOT_STEP, 0.0001)
	tank.cleanliness = 95.0
	Game.clean_spot()
	assert_eq(tank.cleanliness, Care.MAX_CLEANLINESS)


func test_collecting_a_pearl_adds_shells_and_announces_it() -> void:
	watch_signals(EventBus)
	var before: float = Game.state.wallet.shells
	Game.collect_pearl(12.0)
	assert_eq(Game.state.wallet.shells, before + 12.0)
	assert_signal_emitted_with_parameters(EventBus, "pearl_collected", [12.0])


func test_dropped_pearls_are_published_on_the_bus() -> void:
	watch_signals(EventBus)
	var fish: Fish = Game.state.tanks[0].fish[0]
	Game.state.pending_pearls.append(PearlSpawn.new(0, fish, 5.0))
	Game._process(0.0)
	assert_signal_emitted(EventBus, "pearl_spawned")
	assert_eq(Game.state.pending_pearls.size(), 0)
