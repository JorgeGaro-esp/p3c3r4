extends GutTest
## Día y noche y eventos aleatorios dentro de la partida.

var _phases: Array[int] = []
var _started: PackedStringArray = PackedStringArray()
var _rewards: Array[float] = []
var _finished: PackedStringArray = PackedStringArray()


func before_each() -> void:
	_phases = []
	_started = PackedStringArray()
	_rewards = []
	_finished = PackedStringArray()
	Game.daylight.clock = FixedDayClock.new(12.0)
	Game.start_new_game(Game.DEFAULT_SEED)
	EventBus.phase_changed.connect(_on_phase)
	EventBus.event_started.connect(_on_started)
	EventBus.event_rewarded.connect(_on_rewarded)
	EventBus.event_finished.connect(_on_finished)


func after_each() -> void:
	EventBus.phase_changed.disconnect(_on_phase)
	EventBus.event_started.disconnect(_on_started)
	EventBus.event_rewarded.disconnect(_on_rewarded)
	EventBus.event_finished.disconnect(_on_finished)
	Game.daylight.clock = DayClock.new()
	Game.start_new_game(Game.DEFAULT_SEED)


func _on_phase(phase: int) -> void:
	_phases.append(phase)


func _on_started(event_id: String, _species_id: String) -> void:
	_started.append(event_id)


func _on_rewarded(_event_id: String, shells: float, _decoration_id: String) -> void:
	_rewards.append(shells)


func _on_finished(event_id: String) -> void:
	_finished.append(event_id)


func test_the_darkness_follows_the_clock() -> void:
	assert_eq(Game.state.darkness, 0.0)
	(Game.daylight.clock as FixedDayClock).value = 23.0
	Game.daylight.refresh()
	assert_eq(Game.state.darkness, 1.0)


func test_a_phase_change_is_announced_once() -> void:
	(Game.daylight.clock as FixedDayClock).value = 19.0
	Game.daylight.refresh()
	Game.daylight.refresh()
	assert_eq(_phases, [DayCycle.Phase.DUSK])


func test_loading_a_game_does_not_announce_the_phase() -> void:
	(Game.daylight.clock as FixedDayClock).value = 2.0
	Game.start_new_game(Game.DEFAULT_SEED)
	assert_eq(_phases.size(), 0)
	assert_eq(Game.state.darkness, 1.0)


func test_the_debug_key_moves_the_clock_forward() -> void:
	Game.daylight.debug_advance()
	assert_eq(Game.daylight.hour(), 12.0 + DaylightDirector.DEBUG_STEP_HOURS)


func test_changing_the_system_hour_gives_no_free_shells() -> void:
	var before: float = Game.state.wallet.shells
	for hour: float in [3.0, 15.0, 22.0, 7.0]:
		(Game.daylight.clock as FixedDayClock).value = hour
		Game.daylight.refresh()
	assert_eq(Game.state.wallet.shells, before)
	assert_eq(Game.state.sim_time, 0.0)


func test_an_event_can_be_started_and_claimed_for_shells() -> void:
	assert_true(Game.events.start_by_id("golden_fish"))
	assert_eq(_started, PackedStringArray(["golden_fish"]))
	assert_true(Game.state.events.has_pickup())
	var before: float = Game.state.wallet.shells
	assert_true(Game.events.claim())
	assert_gt(Game.state.wallet.shells, before)
	assert_eq(_rewards.size(), 1)
	assert_eq(_finished, PackedStringArray(["golden_fish"]))
	assert_false(Game.events.claim())


func test_an_unclaimed_event_expires_without_penalty() -> void:
	Game.events.start_by_id("golden_fish")
	var before: float = Game.state.wallet.shells
	Game.events.advance(100.0)
	assert_false(Game.state.events.has_pickup())
	assert_eq(Game.state.wallet.shells, before)
	assert_eq(_rewards.size(), 0)
	assert_true(_finished.has("golden_fish"))


func test_the_bottle_adds_to_the_decoration_stock() -> void:
	Game.events.start_by_id("drifting_bottle")
	Game.events.claim()
	var total: int = 0
	for decoration_id: String in Game.state.decoration_stock:
		total += Game.state.decoration_stock[decoration_id]
	assert_eq(total, 1)


func test_the_warm_current_boosts_the_rate_and_ends() -> void:
	Game.events.start_by_id("warm_current")
	Simulation.refresh_production(Game.state, Game.content)
	var boosted: float = Game.state.production_rate
	Game.events.advance(Game.content.events.get_event("warm_current").duration + 1.0)
	Simulation.refresh_production(Game.state, Game.content)
	assert_almost_eq(Game.state.production_rate * EventState.WARM_MULTIPLIER, boosted, 0.0001)
	assert_true(_finished.has("warm_current"))


func test_the_bloom_pays_when_the_player_cleans_it() -> void:
	Game.events.start_by_id("algae_bloom")
	assert_true(Game.state.events.has_bloom())
	var before: float = Game.state.wallet.shells
	for _index: int in range(10):
		Game.clean_spot()
	assert_false(Game.state.events.has_bloom())
	assert_gt(Game.state.wallet.shells, before)
	assert_eq(_rewards.size(), 1)


func test_random_events_appear_over_time_with_a_fixed_seed() -> void:
	for _second: int in range(int(EventPlanner.MAX_WAIT) + 1):
		Game.events.advance(1.0)
	assert_gte(_started.size(), 1)


func test_two_games_with_the_same_seed_get_the_same_events() -> void:
	var first: PackedStringArray = _events_in_half_an_hour()
	var second: PackedStringArray = _events_in_half_an_hour()
	assert_eq(first, second)


func _events_in_half_an_hour() -> PackedStringArray:
	Game.start_new_game(Game.DEFAULT_SEED)
	_started = PackedStringArray()
	for _second: int in range(1800):
		Game.events.advance(1.0)
		if Game.state.events.has_pickup():
			Game.events.claim()
	return _started


func test_events_do_not_survive_a_new_game() -> void:
	Game.events.start_by_id("warm_current")
	Game.start_new_game(Game.DEFAULT_SEED)
	assert_eq(Game.state.events.warm_seconds, 0.0)
	assert_false(Game.state.events.has_pickup())
