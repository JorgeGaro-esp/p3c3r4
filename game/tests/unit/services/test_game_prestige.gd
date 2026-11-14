extends GutTest
## La Gran marea y el final dentro de la partida.

var _gained: Array[int] = []
var _finals: int = 0


func before_each() -> void:
	_gained = []
	_finals = 0
	Game.start_new_game(Game.DEFAULT_SEED)
	EventBus.prestiged.connect(_on_prestiged)
	EventBus.final_reached.connect(_on_final)


func after_each() -> void:
	EventBus.prestiged.disconnect(_on_prestiged)
	EventBus.final_reached.disconnect(_on_final)
	Game.start_new_game(Game.DEFAULT_SEED)


func _on_prestiged(pearls: int) -> void:
	_gained.append(pearls)


func _on_final() -> void:
	_finals += 1


func _earn(amount: float) -> void:
	Game.state.wallet.add(amount)


func test_it_cannot_be_done_without_earnings() -> void:
	assert_eq(Game.prestige.reset(), -1)
	assert_eq(Game.state.prestige.count, 0)


func test_prestige_gives_pearls_and_restarts_the_run() -> void:
	_earn(1.0e7)
	Game.state.wallet.spend(Game.state.wallet.shells - 5.0)
	var expected: int = Game.prestige.pending_pearls()
	assert_gt(expected, 0)
	var gained: int = Game.prestige.reset()
	assert_eq(gained, expected)
	assert_eq(_gained, [expected])
	assert_eq(Game.state.prestige.pearls, expected)
	assert_eq(Game.state.wallet.shells, Game.START_SHELLS)
	assert_eq(Game.state.fish_total(), Game.START_FISH.size())
	assert_eq(Game.prestige.pending_pearls(), 0)


func test_prestige_keeps_the_collection_and_the_tanks() -> void:
	Game.state.discover("pond_koi", "normal")
	Game.state.achievements["first_fish"] = true
	_earn(1.0e7)
	Game.prestige.reset()
	assert_true(Game.state.is_discovered("pond_koi", "normal"))
	assert_true(Game.state.achievements.has("first_fish"))


func test_a_second_prestige_needs_a_new_run() -> void:
	_earn(1.0e7)
	assert_gt(Game.prestige.reset(), 0)
	assert_eq(Game.prestige.reset(), -1)


func test_buying_an_upgrade_with_pearls_changes_production() -> void:
	_earn(1.0e7)
	Game.prestige.reset()
	var before: float = Simulation.total_production(Game.state, Game.content)
	assert_true(Game.prestige.buy_upgrade("tide_production"))
	assert_gt(Simulation.total_production(Game.state, Game.content), before)
	assert_false(Game.prestige.buy_upgrade("nope"))


func test_an_upgrade_cannot_be_bought_without_pearls() -> void:
	assert_false(Game.prestige.buy_upgrade("tide_production"))


func test_the_final_is_reached_once_and_gives_the_trophy() -> void:
	Game.prestige.debug_complete_collection()
	await wait_seconds(Game.ACHIEVEMENT_CHECK_SECONDS + 0.3)
	assert_eq(_finals, 1)
	assert_true(Game.state.prestige.final_reached)
	var trophies: int = Game.state.decoration_stock.get(PrestigeDirector.FINAL_REWARD_DECORATION, 0)
	assert_eq(trophies, 1)
	await wait_seconds(Game.ACHIEVEMENT_CHECK_SECONDS + 0.3)
	assert_eq(_finals, 1)


func test_the_game_goes_on_after_the_final() -> void:
	Game.prestige.debug_complete_collection()
	await wait_seconds(Game.ACHIEVEMENT_CHECK_SECONDS + 0.3)
	_earn(1.0e7)
	assert_gt(Game.prestige.reset(), 0)
	assert_true(Game.state.prestige.final_reached)


func test_the_prestige_is_saved_with_the_game() -> void:
	_earn(1.0e7)
	Game.prestige.reset()
	Game.prestige.buy_upgrade("tide_production")
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(Game.state.to_dict(), Game.content, warnings)
	assert_not_null(loaded)
	assert_eq(loaded.prestige.count, 1)
	assert_eq(loaded.prestige.level_of("tide_production"), 1)
	assert_eq(loaded.prestige.run_start_earned, Game.state.prestige.run_start_earned)
	assert_eq(Prestige.pending_pearls(loaded), 0)
