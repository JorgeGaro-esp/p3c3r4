extends GutTest
## Una pecera que no se ve se simula igual que una visible (Fase 10.6).

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())


func _fish_tank(biome_id: String, species_id: String, count: int) -> Tank:
	var tank: Tank = Tank.new()
	tank.biome_id = biome_id
	for _index: int in range(count):
		tank.add_fish(Fish.new(species_id))
	tank.refresh_bonuses(_content)
	return tank


func _state(active: int) -> GameState:
	var state: GameState = GameState.new()
	state.tanks.clear()
	state.tanks.append(_fish_tank("pond", "pond_guppy", 6))
	state.tanks.append(_fish_tank("reef", "reef_krill", 6))
	state.active_tank = active
	return state


func _run(state: GameState, steps: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	for _index: int in range(steps):
		Simulation.step(state, FixedStepper.STEP_SECONDS, _content, rng)
		state.take_pearls()
		state.take_hatched()


func test_production_does_not_depend_on_which_tank_is_visible() -> void:
	var viewing_pond: GameState = _state(0)
	var viewing_reef: GameState = _state(1)
	_run(viewing_pond, 3000)
	_run(viewing_reef, 3000)
	assert_almost_eq(viewing_pond.wallet.shells, viewing_reef.wallet.shells, 0.0001)
	assert_almost_eq(viewing_pond.production_rate, viewing_reef.production_rate, 0.0001)
	assert_gt(viewing_pond.wallet.shells, 0.0)


func test_total_production_is_the_sum_of_what_each_tank_produces_alone() -> void:
	var together: GameState = _state(0)
	_run(together, 2000)
	var sum: float = 0.0
	for tank: Tank in together.tanks:
		var alone: GameState = GameState.new()
		alone.tanks.clear()
		alone.tanks.append(tank)
		sum += Simulation.total_production(alone, _content)
	assert_almost_eq(Simulation.total_production(together, _content), sum, 0.0001)
	assert_gt(sum, 0.0)


func test_care_runs_in_every_tank_whether_it_is_seen_or_not() -> void:
	var state: GameState = _state(0)
	_run(state, 3000)
	for tank: Tank in state.tanks:
		assert_lt(tank.cleanliness, Care.MAX_CLEANLINESS, tank.biome_id)
		for fish: Fish in tank.fish:
			assert_lt(fish.hunger, Care.MAX_HUNGER, tank.biome_id)


func test_eggs_hatch_in_a_hidden_tank() -> void:
	var state: GameState = _state(0)
	state.tanks[1].eggs.append(Egg.new("reef_krill", VariantDef.NORMAL_ID, 1.0))
	var before: int = state.tanks[1].fish.size()
	var hatched: int = 0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for _index: int in range(200):
		Simulation.step(state, FixedStepper.STEP_SECONDS, _content, rng)
		for event: HatchEvent in state.take_hatched():
			assert_eq(event.tank_index, 1)
			hatched += 1
	assert_gte(hatched, 1)
	assert_gt(state.tanks[1].fish.size(), before)


func test_pearls_carry_the_index_of_their_tank() -> void:
	var state: GameState = _state(0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var seen: Dictionary = {}
	for _index: int in range(6000):
		Simulation.step(state, FixedStepper.STEP_SECONDS, _content, rng)
		for spawn: PearlSpawn in state.take_pearls():
			seen[spawn.tank_index] = true
			assert_true(state.tanks[spawn.tank_index].fish.has(spawn.fish))
	assert_true(seen.has(0) and seen.has(1), "perlas de las dos peceras")
