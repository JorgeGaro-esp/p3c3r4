extends GutTest

var _content: ContentDB


func before_all() -> void:
	_content = ContentDB.new()
	_content.add_species(_species("guppy", 0.2))
	_content.add_species(_species("angel", 0.6))


func _species(id: String, production: float) -> SpeciesDef:
	var species: SpeciesDef = SpeciesDef.new()
	species.id = id
	species.name_key = "SPECIES_" + id.to_upper()
	species.base_cost = 10.0
	species.base_production = production
	species.sprite_path = "res://content/sprites/pond_guppy.txt"
	return species


func _state_with(ids: Array[String]) -> GameState:
	var state: GameState = GameState.new()
	for id: String in ids:
		state.tanks[0].add_fish(Fish.new(id))
	return state


func _run(state: GameState, steps: int, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for _index: int in range(steps):
		Simulation.step(state, FixedStepper.STEP_SECONDS, _content, rng)


func test_empty_tank_produces_nothing() -> void:
	var state: GameState = GameState.new()
	_run(state, 100, 1)
	assert_eq(state.wallet.shells, 0.0)


func test_production_matches_the_formula() -> void:
	var state: GameState = _state_with(["guppy", "angel"])
	assert_almost_eq(Simulation.total_production(state, _content), 1.0, 0.0001)
	_run(state, 100, 1)
	# Tolerancia: en 10 s el hambre ya baja un poco y con ella la felicidad.
	assert_almost_eq(state.wallet.shells, 10.0, 0.05, "10 s a 1,0 conchas/s")
	assert_almost_eq(state.sim_time, 10.0, 0.0001)


func test_unhappy_fish_produce_less() -> void:
	var state: GameState = _state_with(["angel"])
	state.tanks[0].fish[0].happiness = 0.0
	assert_almost_eq(Simulation.total_production(state, _content), 0.15, 0.0001)


func test_unknown_species_are_ignored() -> void:
	var state: GameState = _state_with(["guppy", "ghost"])
	assert_almost_eq(Simulation.total_production(state, _content), 0.25, 0.0001)


func test_production_is_recalculated_only_when_marked_dirty() -> void:
	var state: GameState = _state_with(["guppy"])
	_run(state, 1, 1)
	assert_almost_eq(state.production_rate, 0.25, 0.0001)
	state.tanks[0].add_fish(Fish.new("angel"))
	_run(state, 1, 1)
	assert_almost_eq(state.production_rate, 0.25, 0.0001, "sin aviso, no se recalcula")
	state.mark_production_dirty()
	_run(state, 1, 1)
	assert_almost_eq(state.production_rate, 1.0, 0.0001)


func test_same_seed_gives_identical_state_after_a_thousand_steps() -> void:
	var first: GameState = _state_with(["guppy", "angel", "guppy"])
	var second: GameState = _state_with(["guppy", "angel", "guppy"])
	_run(first, 1000, 777)
	_run(second, 1000, 777)
	assert_eq(first.wallet.shells, second.wallet.shells)
	assert_eq(first.wallet.total_earned, second.wallet.total_earned)
	assert_eq(first.sim_time, second.sim_time)
	assert_eq(first.production_rate, second.production_rate)
	assert_gt(first.wallet.shells, 0.0)


func test_values_stay_finite_over_a_long_run() -> void:
	var state: GameState = _state_with(["guppy", "angel"])
	_run(state, 20000, 3)
	assert_false(is_nan(state.wallet.shells) or is_inf(state.wallet.shells))
	assert_gte(state.wallet.shells, 0.0)


func test_neglect_lowers_production_but_never_to_zero() -> void:
	var state: GameState = _state_with(["guppy", "angel"])
	var full: float = Simulation.total_production(state, _content)
	_run(state, 36000, 1)
	assert_eq(state.tanks[0].fish[0].hunger, 0.0)

	var starving: float = Simulation.total_production(state, _content)
	assert_gt(starving, 0.0)
	assert_lt(starving, full)
	assert_gt(state.wallet.shells, 0.0, "no se pierde nada: se sigue ganando")


func test_fed_fish_keep_their_happiness() -> void:
	var state: GameState = _state_with(["guppy"])
	for _second: int in range(30):
		_run(state, 10, 1)
		for fish: Fish in state.tanks[0].fish:
			fish.hunger = Care.MAX_HUNGER
	assert_almost_eq(state.tanks[0].fish[0].hunger, Care.MAX_HUNGER, 0.0001)


func test_a_pearl_is_dropped_sooner_or_later_and_the_queue_empties() -> void:
	var state: GameState = _state_with(["guppy", "angel"])
	_run(state, int(Care.PEARL_MAX_SECONDS * 10.0) + 50, 3)
	var pearls: Array[PearlSpawn] = state.take_pearls()
	assert_gte(pearls.size(), 1)
	assert_gt(pearls[0].value, 0.0)
	assert_true(state.tanks[0].fish.has(pearls[0].fish))
	assert_eq(state.take_pearls().size(), 0)


func test_empty_tanks_drop_no_pearls_and_do_not_get_dirty() -> void:
	var state: GameState = GameState.new()
	_run(state, 20000, 1)
	assert_eq(state.take_pearls().size(), 0)
	assert_eq(state.tanks[0].cleanliness, Care.MAX_CLEANLINESS)


func test_pending_pearls_are_capped() -> void:
	var state: GameState = _state_with(["guppy"])
	for _index: int in range(GameState.MAX_PENDING_PEARLS + 5):
		state.tanks[0].pearl_timer = 0.0
		_run(state, 1, 4)
	assert_lte(state.pending_pearls.size(), GameState.MAX_PENDING_PEARLS)
