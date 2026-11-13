extends GutTest
## Efectos del equipo en la simulación: cuidados, crecimiento y eclosión.

var _content: ContentDB = null
var _rng: RandomNumberGenerator = null
var _state: GameState = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()
	_content.load_equipment_dir()


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 5
	_state = GameState.new()


func _tank() -> Tank:
	return _state.tanks[0]


func _fill(count: int) -> void:
	for _index: int in range(count):
		_tank().add_fish(Fish.new("pond_guppy"))


func _run(seconds: float) -> void:
	for _step: int in range(roundi(seconds / 0.1)):
		Simulation.step(_state, 0.1, _content, _rng)


func test_aerator_adds_capacity() -> void:
	_tank().capacity = 4
	_fill(4)
	assert_true(_tank().is_full())
	_tank().set_level("aerator", 1, _content)
	assert_eq(_tank().total_capacity(), 8)
	assert_false(_tank().is_full())


func test_heater_lifts_happiness_without_passing_100() -> void:
	var base: float = Care.happiness(40.0, 40.0)
	var warm: float = Care.happiness(40.0, 40.0, 0.5)
	assert_gt(warm, base)
	assert_almost_eq(warm, base + (100.0 - base) * 0.5, 0.0001)
	assert_almost_eq(Care.happiness(40.0, 40.0, 5.0), 100.0, 0.0001)


func test_filter_slows_dirt_and_regenerates() -> void:
	var plain: float = Care.cleanliness_after(100.0, 10, 100.0)
	var slow: float = Care.cleanliness_after(100.0, 10, 100.0, 0.6)
	assert_gt(slow, plain)
	var healing: float = Care.cleanliness_after(50.0, 10, 10.0, 0.2, 0.05)
	assert_gt(healing, 50.0)


func test_feeder_feeds_the_fish_on_its_own() -> void:
	_fill(3)
	_tank().set_level("feeder", 5, _content)
	for fish: Fish in _tank().fish:
		fish.hunger = 10.0
	_run(70.0)
	for fish: Fish in _tank().fish:
		assert_gt(fish.hunger, 10.0)


func test_without_a_feeder_fish_only_get_hungrier() -> void:
	_fill(3)
	for fish: Fish in _tank().fish:
		fish.hunger = 50.0
	_run(60.0)
	for fish: Fish in _tank().fish:
		assert_lt(fish.hunger, 50.0)


func test_filter_and_feeder_keep_a_full_tank_happy_alone() -> void:
	_fill(40)
	_tank().set_level("filter", 5, _content)
	_tank().set_level("feeder", 3, _content)
	_run(900.0)
	assert_gt(_tank().cleanliness, 95.0)
	var lowest: float = 100.0
	for fish: Fish in _tank().fish:
		lowest = minf(lowest, fish.happiness)
	assert_gt(lowest, 80.0)


func test_a_full_tank_without_equipment_gets_dirty() -> void:
	_fill(40)
	_run(900.0)
	assert_lt(_tank().cleanliness, 90.0)


func test_lamp_makes_fry_grow_faster() -> void:
	var plain: Fish = Fish.new("pond_guppy")
	plain.maturity = 0.0
	_tank().add_fish(plain)
	var lit_state: GameState = GameState.new()
	var lit: Fish = Fish.new("pond_guppy")
	lit.maturity = 0.0
	lit_state.tanks[0].add_fish(lit)
	lit_state.tanks[0].set_level("lamp", 4, _content)
	for _step: int in range(100):
		plain.happiness = 100.0
		lit.happiness = 100.0
		Lifecycle.step(_state, 0, 0.1, _content, _rng)
		Lifecycle.step(lit_state, 0, 0.1, _content, _rng)
	assert_gt(lit.maturity, plain.maturity * 1.5)


func test_incubator_hatches_eggs_sooner() -> void:
	_tank().eggs.append(Egg.new("pond_guppy", VariantDef.NORMAL_ID, 20.0, 0.5))
	_tank().set_level("incubator", 5, _content)
	for _step: int in range(81):
		Lifecycle.step(_state, 0, 0.1, _content, _rng)
	assert_eq(_tank().eggs.size(), 0)
	assert_eq(_tank().fish.size(), 1)


func test_incubator_raises_the_chance_of_rare_variants() -> void:
	var plain: int = _rare_count(1.0)
	var boosted: int = _rare_count(3.0)
	assert_gt(boosted, plain)


func _rare_count(multiplier: float) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	var count: int = 0
	for _index: int in range(4000):
		if VariantRoll.pick(_content, rng, multiplier) != VariantDef.NORMAL_ID:
			count += 1
	return count
