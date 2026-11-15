extends GutTest
## Compra, colocación y recogida de decoración a través del autoload `Game`.

const WIDTH: int = 80
const WATER: int = 12


func before_each() -> void:
	Game.start_new_game(42)
	Game.state.wallet.add(100000.0)


func after_all() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func test_buying_puts_the_object_in_the_stock() -> void:
	var before: float = Game.state.wallet.shells
	var cost: float = Game.decoration_cost("big_rock")
	assert_eq(Game.buy_decoration("big_rock"), GameService.DecorResult.OK)
	assert_almost_eq(Game.state.wallet.shells, before - cost, 0.0001)
	assert_eq(Game.state.decoration_stock["big_rock"], 1)
	assert_gt(Game.decoration_cost("big_rock"), cost)


func test_not_enough_shells_and_unknown_ids() -> void:
	Game.state.wallet.spend(Game.state.wallet.shells)
	assert_eq(Game.buy_decoration("cave"), GameService.DecorResult.NOT_ENOUGH_SHELLS)
	assert_eq(Game.buy_decoration("nope"), GameService.DecorResult.UNKNOWN)


func test_placing_needs_stock_and_consumes_it() -> void:
	assert_eq(
		Game.place_decoration("big_rock", 500, 0, WIDTH, WATER), GameService.DecorResult.NO_STOCK
	)
	Game.buy_decoration("big_rock")
	assert_eq(Game.place_decoration("big_rock", 500, 0, WIDTH, WATER), GameService.DecorResult.OK)
	assert_false(Game.state.decoration_stock.has("big_rock"))
	assert_eq(Game.state.tanks[0].decorations.size(), 1)


func test_overlap_is_refused_and_keeps_the_stock() -> void:
	Game.buy_decoration("big_rock")
	Game.buy_decoration("big_rock")
	Game.place_decoration("big_rock", 500, 0, WIDTH, WATER)
	assert_eq(
		Game.place_decoration("big_rock", 505, 0, WIDTH, WATER), GameService.DecorResult.OVERLAP
	)
	assert_eq(Game.state.decoration_stock["big_rock"], 1)


func test_storing_returns_the_object_to_the_stock() -> void:
	Game.buy_decoration("big_rock")
	Game.place_decoration("big_rock", 500, 0, WIDTH, WATER)
	var placed: PlacedDecoration = Game.state.tanks[0].decorations[0]
	assert_true(Game.remove_decoration(placed))
	assert_eq(Game.state.decoration_stock["big_rock"], 1)
	assert_eq(Game.state.tanks[0].decorations.size(), 0)
	assert_false(Game.remove_decoration(placed))


func test_cost_counts_placed_and_stored_objects() -> void:
	Game.buy_decoration("big_rock")
	Game.place_decoration("big_rock", 500, 0, WIDTH, WATER)
	Game.buy_decoration("big_rock")
	assert_eq(Game.state.decoration_owned("big_rock"), 2)
	assert_eq(
		Game.decoration_cost("big_rock"),
		ceilf(Game.content.get_decoration("big_rock").base_cost * 1.69 - 1.0e-9)
	)


func test_placing_a_cave_unlocks_the_loach() -> void:
	assert_false(Game.state.is_unlocked("pond_catfish"))
	Game.buy_decoration("cave")
	Game.place_decoration("cave", 300, 0, WIDTH, WATER)
	await wait_process_frames(2)
	assert_true(Game.state.is_unlocked("pond_catfish"))


func test_placing_a_production_object_updates_the_rate() -> void:
	var before: float = Game.state.production_rate
	Game.buy_decoration("statue")
	Game.place_decoration("statue", 100, 0, WIDTH, WATER)
	await wait_process_frames(2)
	assert_gt(Game.state.production_rate, before)
