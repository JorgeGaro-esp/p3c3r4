extends GutTest
## Reglas de la Gran marea: perlas negras, mejoras y qué se conserva al reiniciar.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.load_equipment_dir())
	assert_true(_content.load_decorations_dir())
	assert_true(_content.biomes.load_dir())
	assert_true(_content.achievements.load_dir())
	assert_true(_content.prestige.load_dir())


func _state_with_run(earned: float) -> GameState:
	var state: GameState = GameState.new()
	state.wallet.add(earned)
	return state


func _upgrade(upgrade_id: String) -> PrestigeUpgradeDef:
	return _content.prestige.get_upgrade(upgrade_id)


func test_pearls_grow_with_the_square_root_of_the_shells() -> void:
	assert_eq(Prestige.pearls_for(0.0), 0)
	assert_eq(Prestige.pearls_for(Prestige.SHELLS_PER_PEARL_SQUARED), 1)
	assert_eq(Prestige.pearls_for(Prestige.SHELLS_PER_PEARL_SQUARED * 100.0), 10)
	assert_eq(Prestige.pearls_for(Prestige.SHELLS_PER_PEARL_SQUARED * 10000.0), 100)
	assert_eq(Prestige.pearls_for(NAN), 0)
	assert_eq(Prestige.pearls_for(-5.0), 0)


func test_only_the_shells_of_the_current_run_count() -> void:
	var state: GameState = _state_with_run(1.0e7)
	state.prestige.run_start_earned = 9.0e6
	assert_almost_eq(Prestige.run_earned(state), 1.0e6, 1.0)
	assert_eq(Prestige.pending_pearls(state), 3)


func test_you_need_one_pearl_to_reset() -> void:
	assert_false(Prestige.can_reset(_state_with_run(1.0e4)))
	assert_true(Prestige.can_reset(_state_with_run(2.0e5)))


func test_upgrade_costs_grow_and_stop_at_the_maximum() -> void:
	var def: PrestigeUpgradeDef = _upgrade("tide_production")
	assert_eq(Prestige.upgrade_cost(def, 0), def.base_cost)
	assert_gt(Prestige.upgrade_cost(def, 5), Prestige.upgrade_cost(def, 1))
	assert_eq(Prestige.upgrade_cost(def, def.max_level), -1)


func test_buying_spends_pearls_and_raises_the_level() -> void:
	var state: GameState = GameState.new()
	var def: PrestigeUpgradeDef = _upgrade("tide_production")
	assert_false(Prestige.buy(state, def))
	state.prestige.add_pearls(100)
	assert_true(Prestige.buy(state, def))
	assert_eq(state.prestige.level_of(def.id), 1)
	assert_eq(state.prestige.pearls, 100 - def.base_cost)


func test_the_maximum_level_cannot_be_exceeded() -> void:
	var state: GameState = GameState.new()
	var def: PrestigeUpgradeDef = _upgrade("pearl_value")
	state.prestige.add_pearls(PrestigeState.MAX_PEARLS)
	for _i: int in range(def.max_level + 5):
		Prestige.buy(state, def)
	assert_eq(state.prestige.level_of(def.id), def.max_level)


func test_the_effects_of_the_upgrades() -> void:
	var state: GameState = GameState.new()
	assert_eq(Prestige.production_multiplier(state, _content), 1.0)
	assert_eq(Prestige.variant_multiplier(state, _content), 1.0)
	assert_eq(Prestige.pearl_multiplier(state, _content), 1.0)
	assert_eq(Prestige.head_start_shells(state, _content), 0.0)
	state.prestige.levels["tide_production"] = 3
	state.prestige.levels["variant_luck"] = 2
	state.prestige.levels["pearl_value"] = 1
	state.prestige.levels["head_start"] = 2
	assert_almost_eq(Prestige.production_multiplier(state, _content), 1.3, 0.0001)
	assert_gt(Prestige.variant_multiplier(state, _content), 1.3)
	assert_gt(Prestige.pearl_multiplier(state, _content), 1.2)
	assert_eq(Prestige.head_start_shells(state, _content), 300.0)


func test_production_follows_the_upgrade() -> void:
	var state: GameState = GameState.new()
	state.tanks[0].add_fish(Fish.new("pond_guppy"))
	var base: float = Simulation.total_production(state, _content)
	state.prestige.levels["tide_production"] = 5
	assert_almost_eq(Simulation.total_production(state, _content), base * 1.5, base * 0.001)


func _rich_state() -> GameState:
	var state: GameState = GameState.new()
	state.wallet.add(5.0e6)
	state.wallet.spend(1.0e6)
	var tank: Tank = state.tanks[0]
	tank.add_fish(Fish.new("pond_guppy"))
	tank.equipment["filter"] = 3
	tank.cleanliness = 10.0
	state.decoration_stock["statue"] = 2
	state.unlocked["pond_wels"] = true
	state.discover("pond_guppy", "normal")
	state.stats.add(GameStats.FISH_BOUGHT, 7.0)
	state.achievements["first_fish"] = true
	state.prestige.levels["tide_production"] = 2
	return state


func test_a_new_run_resets_shells_fish_and_equipment() -> void:
	var fresh: GameState = Prestige.next_run(_rich_state(), _content, 20.0, ["pond_guppy"], 7)
	assert_eq(fresh.wallet.shells, 20.0)
	assert_eq(fresh.fish_total(), 1)
	assert_true(fresh.tanks[0].equipment.is_empty())
	assert_eq(fresh.tanks[0].cleanliness, Care.MAX_CLEANLINESS)
	assert_true(fresh.tanks[0].eggs.is_empty())


func test_a_new_run_keeps_what_was_agreed() -> void:
	var fresh: GameState = Prestige.next_run(_rich_state(), _content, 20.0, [], 7)
	var statues: int = fresh.decoration_stock.get("statue", 0)
	assert_eq(statues, 2)
	assert_true(fresh.is_unlocked("pond_wels"))
	assert_true(fresh.is_discovered("pond_guppy", "normal"))
	assert_eq(fresh.stats.value(GameStats.FISH_BOUGHT), 7.0)
	assert_true(fresh.achievements.has("first_fish"))
	assert_eq(fresh.tanks.size(), 1)
	assert_eq(fresh.prestige.level_of("tide_production"), 2)
	assert_eq(fresh.wallet.total_earned, 5.0e6)


func test_a_new_run_gives_pearls_and_counts_the_cycle() -> void:
	var fresh: GameState = Prestige.next_run(_rich_state(), _content, 20.0, [], 7)
	assert_eq(fresh.prestige.pearls, 7)
	assert_eq(fresh.prestige.pearls_earned, 7)
	assert_eq(fresh.prestige.count, 1)
	assert_eq(fresh.prestige.run_start_earned, 5.0e6)
	assert_eq(Prestige.pending_pearls(fresh), 0)


func test_the_head_start_adds_shells() -> void:
	var state: GameState = _rich_state()
	state.prestige.levels["head_start"] = 1
	var fresh: GameState = Prestige.next_run(state, _content, 20.0, [], 1)
	assert_eq(fresh.wallet.shells, 120.0)


func test_a_second_run_is_faster_with_upgrades() -> void:
	var state: GameState = _rich_state()
	var before: float = Simulation.total_production(
		Prestige.next_run(state, _content, 20.0, ["pond_guppy", "pond_guppy"], 0), _content
	)
	state.prestige.levels["tide_production"] = 10
	var after: float = Simulation.total_production(
		Prestige.next_run(state, _content, 20.0, ["pond_guppy", "pond_guppy"], 0), _content
	)
	assert_gt(after, before * 1.5)


func test_the_collection_is_complete_only_with_every_combination() -> void:
	var state: GameState = GameState.new()
	assert_false(Prestige.is_collection_complete(state, _content))
	for species_id: String in _content.species_ids():
		for variant_id: String in _content.variant_ids():
			state.discover(species_id, variant_id)
	assert_true(Prestige.is_collection_complete(state, _content))


func test_the_prestige_state_survives_a_round_trip() -> void:
	var state: PrestigeState = PrestigeState.new()
	state.add_pearls(12)
	state.count = 3
	state.run_start_earned = 1234.0
	state.levels["head_start"] = 2
	state.final_reached = true
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: PrestigeState = PrestigeState.from_dict(state.to_dict(), _content, warnings)
	assert_eq(warnings, PackedStringArray())
	assert_eq(loaded.pearls, 12)
	assert_eq(loaded.count, 3)
	assert_eq(loaded.run_start_earned, 1234.0)
	assert_eq(loaded.level_of("head_start"), 2)
	assert_true(loaded.final_reached)


func test_loading_discards_unknown_upgrades_and_clamps_levels() -> void:
	var warnings: PackedStringArray = PackedStringArray()
	var data: Dictionary = {
		"pearls": -5, "levels": {"nope": 3, "pearl_value": 999, "head_start": "x"}
	}
	var loaded: PrestigeState = PrestigeState.from_dict(data, _content, warnings)
	assert_eq(loaded.pearls, 0)
	assert_false(loaded.levels.has("nope"))
	assert_eq(loaded.level_of("pearl_value"), _upgrade("pearl_value").max_level)
	assert_eq(loaded.level_of("head_start"), 0)
	assert_false(warnings.is_empty())


func test_missing_data_gives_the_initial_state() -> void:
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: PrestigeState = PrestigeState.from_dict(null, _content, warnings)
	assert_eq(loaded.pearls, 0)
	assert_eq(warnings, PackedStringArray())


func test_the_content_is_valid() -> void:
	assert_eq(_content.prestige.errors, PackedStringArray())
	assert_gte(_content.prestige.ids().size(), 4)
	assert_true(_content.has_decoration(PrestigeDirector.FINAL_REWARD_DECORATION))
	assert_true(_content.get_decoration(PrestigeDirector.FINAL_REWARD_DECORATION).is_reward)


func test_the_old_format_is_migrated_with_an_empty_prestige() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_8_to_9({"wallet": {}})
	assert_true(migrated.has("prestige"))
