extends GutTest
## Etapas de vida, crecimiento, puesta y eclosión.

var _content: ContentDB = null
var _rng: RandomNumberGenerator = null
var _state: GameState = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 11
	_state = GameState.new()


func _tank() -> Tank:
	return _state.tanks[0]


func _add(species_id: String, adult: bool = true, happiness: float = 100.0) -> Fish:
	var fish: Fish = Fish.new(species_id)
	fish.happiness = happiness
	if not adult:
		fish.maturity = 0.0
	_tank().add_fish(fish)
	return fish


## Avanza [param seconds] de simulación en pasos de 0,1 s. Los cuidados se saltan
## (llamamos directamente al ciclo de vida) para aislar lo que se prueba.
func _run(seconds: float) -> void:
	for _step: int in range(roundi(seconds / 0.1)):
		for fish: Fish in _tank().fish:
			fish.happiness = maxf(fish.happiness, 100.0)
		Lifecycle.step(_state, 0, 0.1, _content, _rng)


func test_stage_follows_maturity() -> void:
	assert_eq(LifeStage.from_maturity(0.0), LifeStage.Stage.FRY)
	assert_eq(LifeStage.from_maturity(LifeStage.JUVENILE_FROM - 0.01), LifeStage.Stage.FRY)
	assert_eq(LifeStage.from_maturity(LifeStage.JUVENILE_FROM), LifeStage.Stage.JUVENILE)
	assert_eq(LifeStage.from_maturity(0.99), LifeStage.Stage.JUVENILE)
	assert_eq(LifeStage.from_maturity(1.0), LifeStage.Stage.ADULT)


func test_younger_fish_sell_for_a_smaller_share() -> void:
	assert_lt(
		LifeStage.sale_factor(LifeStage.Stage.FRY), LifeStage.sale_factor(LifeStage.Stage.JUVENILE)
	)
	assert_eq(LifeStage.sale_factor(LifeStage.Stage.ADULT), 1.0)


func test_a_new_fish_is_an_adult_of_the_normal_variant() -> void:
	var fish: Fish = Fish.new("pond_guppy")
	assert_true(fish.is_adult())
	assert_eq(fish.variant_id, VariantDef.NORMAL_ID)


func test_a_fry_grows_into_an_adult_in_the_species_time() -> void:
	var fish: Fish = _add("pond_guppy", false)
	var seconds: float = _content.get_species("pond_guppy").growth_seconds
	_run(seconds * 0.5)
	assert_almost_eq(fish.maturity, 0.5, 0.02)
	assert_false(fish.is_adult())
	_run(seconds * 0.5 + 1.0)
	assert_true(fish.is_adult())
	assert_eq(fish.maturity, 1.0)


func test_only_adults_produce() -> void:
	_add("pond_guppy")
	var adult_rate: float = Simulation.total_production(_state, _content)
	_add("pond_guppy", false)
	assert_eq(Simulation.total_production(_state, _content), adult_rate)
	assert_gt(adult_rate, 0.0)


func test_growing_up_marks_production_dirty() -> void:
	var fish: Fish = _add("pond_guppy", false)
	_state.production_dirty = false
	fish.maturity = 0.9999
	_run(1.0)
	assert_true(_state.production_dirty)


func test_two_happy_adults_lay_an_egg_after_the_species_interval() -> void:
	_add("pond_guppy")
	_add("pond_guppy")
	var interval: float = _content.get_species("pond_guppy").breed_seconds
	_run(interval * 0.5)
	assert_eq(_tank().eggs.size(), 0, "todavía no")
	_run(interval * 0.5 + 1.0)
	assert_eq(_tank().eggs.size(), 1)


func test_one_adult_alone_never_breeds() -> void:
	_add("pond_guppy")
	_add("pond_minnow")
	_run(_content.get_species("pond_guppy").breed_seconds * 3.0)
	assert_eq(_tank().eggs.size(), 0)


func test_juveniles_do_not_count_as_a_pair() -> void:
	_add("pond_guppy")
	_add("pond_guppy", false)
	_run(_content.get_species("pond_guppy").breed_seconds * 1.5)
	assert_eq(_tank().eggs.size(), 0)


func test_unhappy_fish_do_not_breed() -> void:
	var first: Fish = _add("pond_guppy", true, 10.0)
	var second: Fish = _add("pond_guppy", true, 10.0)
	for _step: int in range(2000):
		Lifecycle.step(_state, 0, 0.1, _content, _rng)
		first.happiness = 10.0
		second.happiness = 10.0
	assert_eq(_tank().eggs.size(), 0)
	assert_false(Lifecycle.can_breed(_tank(), "pond_guppy"))


func test_no_egg_is_laid_when_the_tank_is_full() -> void:
	_tank().capacity = 2
	_add("pond_guppy")
	_add("pond_guppy")
	_run(_content.get_species("pond_guppy").breed_seconds * 2.0)
	assert_eq(_tank().eggs.size(), 0)
	assert_true(_tank().is_full())


func test_an_egg_takes_a_free_slot_until_it_hatches() -> void:
	_tank().capacity = 3
	_add("pond_guppy")
	_add("pond_guppy")
	_run(_content.get_species("pond_guppy").breed_seconds + 1.0)
	assert_eq(_tank().eggs.size(), 1)
	assert_true(_tank().is_full(), "el huevo ocupa el tercer hueco")
	assert_false(_tank().add_fish(Fish.new("pond_guppy")))


func test_an_egg_hatches_into_a_fry_with_the_rolled_variant() -> void:
	var egg: Egg = Egg.new("pond_koi", "golden", 0.5)
	_tank().eggs.append(egg)
	_run(1.0)
	assert_eq(_tank().eggs.size(), 0)
	assert_eq(_tank().fish.size(), 1)
	var baby: Fish = _tank().fish[0]
	assert_eq(baby.species_id, "pond_koi")
	assert_eq(baby.variant_id, "golden")
	assert_eq(baby.stage(), LifeStage.Stage.FRY)
	var hatched: Array[HatchEvent] = _state.take_hatched()
	assert_eq(hatched.size(), 1)
	assert_eq(hatched[0].fish, baby)
	assert_eq(_state.take_hatched().size(), 0, "la cola se vacía")


func test_hatching_does_not_change_the_number_of_used_slots() -> void:
	_tank().capacity = 4
	_tank().eggs.append(Egg.new("pond_guppy", "normal", 0.2))
	_add("pond_minnow")
	var before: int = _tank().occupied()
	_run(1.0)
	assert_eq(_tank().occupied(), before)


func test_more_pairs_lay_faster() -> void:
	var interval: float = _content.get_species("pond_guppy").breed_seconds
	for _index: int in range(4):
		_add("pond_guppy")
	_run(interval / 2.0 + 1.0)
	assert_gte(_tank().eggs.size(), 1, "dos parejas ponen en la mitad de tiempo")


func test_the_same_seed_gives_the_same_clutch() -> void:
	var first: Array[String] = _clutch(3)
	var second: Array[String] = _clutch(3)
	assert_eq(first, second)


func _clutch(seed_value: int) -> Array[String]:
	_rng.seed = seed_value
	_state = GameState.new()
	_tank().capacity = 40
	for _index: int in range(8):
		_add("pond_guppy")
	_run(_content.get_species("pond_guppy").breed_seconds * 2.0)
	var result: Array[String] = []
	for egg: Egg in _tank().eggs:
		result.append("%s:%.3f" % [egg.variant_id, egg.position_x])
	return result
