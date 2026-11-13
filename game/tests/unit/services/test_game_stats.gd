extends GutTest
## `Game` anota en las estadísticas lo que hace el jugador.


func before_each() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)
	Game.state.wallet.add(1.0e6)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func _value(id: String) -> float:
	return Game.state.stats.value(id)


func test_buying_a_fish_counts_only_successful_purchases() -> void:
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.OK)
	assert_eq(Game.buy_fish("nope"), GameService.BuyResult.UNKNOWN_SPECIES)
	assert_eq(_value(GameStats.FISH_BOUGHT), 1.0)


func test_selling_counts_each_fish() -> void:
	Game.buy_fish("pond_guppy")
	Game.sell_fish(Game.state.active().fish[0])
	assert_eq(_value(GameStats.FISH_SOLD), 1.0)
	Game.sell_all_fish()
	assert_eq(_value(GameStats.FISH_SOLD), 1.0 + 2.0)


func test_feeding_and_cleaning_only_count_when_they_do_something() -> void:
	var fish: Fish = Game.state.active().fish[0]
	fish.hunger = Care.MAX_HUNGER
	assert_false(Game.feed_fish(fish))
	assert_eq(_value(GameStats.FISH_FED), 0.0)
	fish.hunger = 10.0
	assert_true(Game.feed_fish(fish))
	assert_eq(_value(GameStats.FISH_FED), 1.0)
	Game.state.active().cleanliness = Care.MAX_CLEANLINESS
	assert_false(Game.clean_spot())
	Game.state.active().cleanliness = 50.0
	assert_true(Game.clean_spot())
	assert_eq(_value(GameStats.SPOTS_CLEANED), 1.0)


func test_pearls_equipment_and_decoration_are_counted() -> void:
	Game.collect_pearl(5.0)
	assert_eq(_value(GameStats.PEARLS_COLLECTED), 1.0)
	assert_eq(Game.buy_equipment("filter"), GameService.EquipResult.OK)
	assert_eq(_value(GameStats.EQUIPMENT_BOUGHT), 1.0)
	assert_eq(Game.buy_decoration("big_rock"), GameService.DecorResult.OK)
	assert_eq(_value(GameStats.DECORATIONS_BOUGHT), 1.0)


func test_a_new_game_resets_the_stats() -> void:
	Game.buy_fish("pond_guppy")
	Game.start_new_game(Game.DEFAULT_SEED)
	assert_eq(_value(GameStats.FISH_BOUGHT), 0.0)


func test_loading_a_game_registers_its_fish_in_the_dex() -> void:
	var loaded: GameState = GameState.new()
	loaded.tanks[0].add_fish(Fish.new("pond_angelfish"))
	Game.adopt_state(loaded)
	assert_true(Game.state.is_discovered("pond_angelfish", "normal"))
