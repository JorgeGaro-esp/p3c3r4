extends GutTest
## Los logros dentro de la partida: desbloqueo con aviso, carga en silencio y bonus.

var _unlocked: PackedStringArray = PackedStringArray()


func before_each() -> void:
	_unlocked = PackedStringArray()
	Game.start_new_game(Game.DEFAULT_SEED)
	EventBus.achievement_unlocked.connect(_on_unlocked)


func after_each() -> void:
	EventBus.achievement_unlocked.disconnect(_on_unlocked)
	Game.start_new_game(Game.DEFAULT_SEED)


func _on_unlocked(achievement_id: String) -> void:
	_unlocked.append(achievement_id)


func test_a_new_game_starts_with_no_achievements() -> void:
	assert_true(Game.state.achievements.is_empty())


func test_buying_a_fish_unlocks_the_first_one_with_a_notice() -> void:
	Game.state.wallet.add(1000.0)
	assert_eq(Game.buy_fish("pond_guppy"), GameService.BuyResult.OK)
	await wait_seconds(0.8)
	assert_true(Game.state.achievements.has("first_fish"))
	assert_true(_unlocked.has("first_fish"))


func test_unlocking_does_not_repeat() -> void:
	Game.state.wallet.add(1000.0)
	Game.buy_fish("pond_guppy")
	await wait_seconds(1.2)
	assert_eq(_unlocked.count("first_fish"), 1)


func test_the_bonus_raises_the_production_rate() -> void:
	var before: float = Game.state.production_rate
	Game.state.stats.add(GameStats.FISH_BOUGHT, 500.0)
	await wait_seconds(0.8)
	assert_gt(Game.state.achievements.size(), 0)
	assert_gt(Game.state.production_rate, before)


func test_loading_a_game_grants_the_met_ones_silently() -> void:
	var loaded: GameState = GameState.new()
	loaded.stats.add(GameStats.FISH_BOUGHT, 10.0)
	loaded.tanks[0].add_fish(Fish.new("pond_guppy"))
	Game.adopt_state(loaded)
	assert_true(Game.state.achievements.has("first_fish"))
	assert_true(Game.state.achievements.has("fish_bought_10"))
	assert_true(_unlocked.is_empty())
