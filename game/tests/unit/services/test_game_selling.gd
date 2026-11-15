extends GutTest
## Venta, cría y descubrimiento de variantes sobre el autoload `Game`.


func before_each() -> void:
	Game.start_new_game(42)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func _add_adult(species_id: String, variant_id: String = "normal") -> Fish:
	var fish: Fish = Fish.new(species_id)
	fish.variant_id = variant_id
	Game.state.tanks[0].add_fish(fish)
	EventBus.fish_added.emit(0, fish)
	return fish


func test_selling_a_fish_pays_its_value_and_removes_it() -> void:
	var fish: Fish = _add_adult("pond_wels", "golden")
	var expected: float = Selling.value_of(fish, Game.content)
	var before: float = Game.state.wallet.shells
	var count: int = Game.state.fish_total()
	watch_signals(EventBus)
	assert_eq(Game.sell_fish(fish), expected)
	assert_eq(Game.state.wallet.shells, before + expected)
	assert_eq(Game.state.fish_total(), count - 1)
	assert_signal_emitted(EventBus, "fish_removed")
	assert_signal_emitted(EventBus, "fish_sold")
	assert_eq(Game.sell_fish(fish), -1.0, "no se vende dos veces")


func test_selling_updates_the_production() -> void:
	var fish: Fish = _add_adult("pond_wels")
	Game.state.production_rate = Simulation.total_production(Game.state, Game.content)
	var with_koi: float = Game.state.production_rate
	Game.sell_fish(fish)
	assert_lt(Simulation.total_production(Game.state, Game.content), with_koi)
	assert_true(Game.state.production_dirty)


func test_selling_surplus_keeps_the_breeding_pair() -> void:
	for _index: int in range(4):
		_add_adult("pond_carp")
	var before: float = Game.state.wallet.shells
	var sold: float = Game.sell_surplus("pond_carp", "normal")
	assert_gt(sold, 0.0)
	assert_eq(Game.state.wallet.shells, before + sold)
	assert_eq(Game.state.tanks[0].count_of("pond_carp"), Selling.KEEP_BREEDERS)
	assert_eq(Game.sell_surplus("pond_carp", "normal"), 0.0, "ya no quedan sobrantes")


func test_the_first_rare_variant_is_announced_once() -> void:
	watch_signals(EventBus)
	var baby: Fish = Fish.new("pond_goldfish")
	baby.maturity = 0.0
	baby.variant_id = "albino"
	Game.state.tanks[0].fish.append(baby)
	Game.state.pending_hatched.append(HatchEvent.new(0, baby))
	await wait_frames(2)
	assert_signal_emit_count(EventBus, "variant_discovered", 1)
	assert_true(Game.state.is_discovered("pond_goldfish", "albino"))
	var twin: Fish = Fish.new("pond_goldfish")
	twin.variant_id = "albino"
	Game.state.tanks[0].fish.append(twin)
	Game.state.pending_hatched.append(HatchEvent.new(0, twin))
	await wait_frames(2)
	assert_signal_emit_count(EventBus, "variant_discovered", 1, "la segunda ya no es nueva")


func test_a_normal_hatchling_does_not_trigger_the_notice() -> void:
	watch_signals(EventBus)
	var baby: Fish = Fish.new("pond_goldfish")
	baby.maturity = 0.0
	Game.state.tanks[0].fish.append(baby)
	Game.state.pending_hatched.append(HatchEvent.new(0, baby))
	await wait_frames(2)
	assert_signal_not_emitted(EventBus, "variant_discovered")
	assert_true(Game.state.is_discovered("pond_goldfish", "normal"))


func test_starting_fish_are_registered_as_discovered() -> void:
	assert_true(Game.state.is_discovered("pond_guppy", "normal"))


func test_selling_all_fish_empties_the_tank_and_pays_their_value() -> void:
	_add_adult("pond_wels", "golden")
	Game.state.tanks[0].eggs.append(Egg.new("pond_guppy", "normal", 5.0))
	var expected: float = 0.0
	for fish: Fish in Game.state.tanks[0].fish:
		expected += Selling.value_of(fish, Game.content)
	var before: float = Game.state.wallet.shells
	watch_signals(EventBus)
	assert_eq(Game.sell_all_fish(), expected)
	assert_eq(Game.state.wallet.shells, before + expected)
	assert_eq(Game.state.tanks[0].fish.size(), 0)
	assert_eq(Game.state.tanks[0].eggs.size(), 0)
	assert_signal_emitted(EventBus, "fish_sold")
	assert_eq(Game.sell_all_fish(), 0.0, "una pecera vacía no da nada")


func test_a_favorite_cannot_be_sold() -> void:
	var fish: Fish = _add_adult("pond_wels")
	fish.favorite = true
	var count: int = Game.state.fish_total()
	assert_eq(Game.sell_fish(fish), -1.0)
	assert_eq(Game.state.fish_total(), count)
