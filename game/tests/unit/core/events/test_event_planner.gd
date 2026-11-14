extends GutTest
## El planificador de eventos: esperas, elegibilidad y reparto por pesos.

var _content: ContentDB = ContentDB.new()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _state: GameState = GameState.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.load_equipment_dir())
	assert_true(_content.load_decorations_dir())
	assert_true(_content.events.load_dir())


func before_each() -> void:
	_rng.seed = 1234
	_state = GameState.new()
	for _index: int in range(4):
		_state.tanks[0].add_fish(Fish.new("pond_guppy"))
		_state.tanks[0].fish.back().hunger = 40.0


func _event(kind: EventDef.Kind) -> EventDef:
	return _content.events.first_of_kind(kind)


func test_the_content_has_the_six_events_with_valid_data() -> void:
	assert_eq(_content.events.ids().size(), 6)
	for kind: EventDef.Kind in EventDef.Kind.values():
		assert_not_null(_event(kind), "falta un evento del tipo %d" % kind)
	assert_true(_content.events.errors.is_empty())


func test_the_first_wait_is_between_the_limits() -> void:
	for seed_value: int in range(20):
		_rng.seed = seed_value
		var planner: EventPlanner = EventPlanner.new(_rng)
		assert_between(planner.seconds_left(), EventPlanner.MIN_WAIT, EventPlanner.MAX_WAIT)


func test_nothing_happens_before_the_wait_is_over() -> void:
	var planner: EventPlanner = EventPlanner.new(_rng)
	var wait: float = planner.seconds_left()
	assert_null(planner.step(wait - 1.0, _state, _content, _rng))
	assert_almost_eq(planner.seconds_left(), 1.0, 0.001)


func test_an_event_comes_when_the_wait_is_over_and_the_timer_restarts() -> void:
	var planner: EventPlanner = EventPlanner.new(_rng)
	var def: EventDef = planner.step(planner.seconds_left() + 0.1, _state, _content, _rng)
	assert_not_null(def)
	assert_between(planner.seconds_left(), EventPlanner.MIN_WAIT, EventPlanner.MAX_WAIT)


func test_the_same_seed_gives_the_same_events() -> void:
	var first: PackedStringArray = _run_sequence(99)
	var second: PackedStringArray = _run_sequence(99)
	assert_eq(first, second)
	assert_eq(first.size(), 10)


func _run_sequence(seed_value: int) -> PackedStringArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var state: GameState = GameState.new()
	for _index: int in range(4):
		state.tanks[0].add_fish(Fish.new("pond_guppy"))
		state.tanks[0].fish.back().hunger = 10.0
	var planner: EventPlanner = EventPlanner.new(rng)
	var ids: PackedStringArray = PackedStringArray()
	while ids.size() < 10:
		var def: EventDef = planner.step(EventPlanner.MAX_WAIT, state, _content, rng)
		if def != null:
			ids.append(def.id)
			state.events.clear_pickup()
			state.events.warm_seconds = 0.0
			state.events.clear_bloom()
	return ids


func test_with_no_fish_no_event_is_possible() -> void:
	_state = GameState.new()
	var planner: EventPlanner = EventPlanner.new(_rng)
	assert_null(planner.step(EventPlanner.MAX_WAIT, _state, _content, _rng))
	assert_eq(planner.seconds_left(), EventPlanner.RETRY_WAIT)


func test_only_one_clickable_event_at_a_time() -> void:
	var golden: EventDef = _event(EventDef.Kind.GOLDEN_FISH)
	assert_true(EventPlanner.is_eligible(golden, _state, _content))
	assert_true(EventEffects.start(golden, _state, _content, _rng))
	assert_false(EventPlanner.is_eligible(golden, _state, _content))
	assert_false(EventPlanner.is_eligible(_event(EventDef.Kind.VISITOR), _state, _content))
	assert_false(EventEffects.start(golden, _state, _content, _rng))


func test_a_warm_current_cannot_stack() -> void:
	var warm: EventDef = _event(EventDef.Kind.WARM_CURRENT)
	assert_true(EventPlanner.is_eligible(warm, _state, _content))
	EventEffects.start(warm, _state, _content, _rng)
	assert_false(EventPlanner.is_eligible(warm, _state, _content))


func test_the_food_rain_needs_a_hungry_fish() -> void:
	var rain: EventDef = _event(EventDef.Kind.FOOD_RAIN)
	assert_true(EventPlanner.is_eligible(rain, _state, _content))
	for fish: Fish in _state.tanks[0].fish:
		fish.hunger = 100.0
	assert_false(EventPlanner.is_eligible(rain, _state, _content))


func test_the_bloom_needs_a_clean_tank_and_enough_fish() -> void:
	var bloom: EventDef = _event(EventDef.Kind.ALGAE_BLOOM)
	assert_true(EventPlanner.is_eligible(bloom, _state, _content))
	_state.tanks[0].cleanliness = 30.0
	assert_false(EventPlanner.is_eligible(bloom, _state, _content))
	_state.tanks[0].cleanliness = 100.0
	_state.tanks[0].fish.resize(bloom.min_fish - 1)
	assert_false(EventPlanner.is_eligible(bloom, _state, _content))


func test_picking_follows_the_weights() -> void:
	var heavy: EventDef = EventDef.new()
	heavy.id = "heavy"
	heavy.weight = 9.0
	var light: EventDef = EventDef.new()
	light.id = "light"
	light.weight = 1.0
	var defs: Array[EventDef] = [heavy, light]
	var heavy_count: int = 0
	for _index: int in range(1000):
		if EventPlanner.pick(defs, _rng) == heavy:
			heavy_count += 1
	assert_between(heavy_count, 840, 960)


func test_picking_from_nothing_returns_null() -> void:
	var none: Array[EventDef] = []
	assert_null(EventPlanner.pick(none, _rng))


func test_the_catalog_rejects_bad_events() -> void:
	var bad: EventDef = EventDef.new()
	bad.id = "Bad Id"
	bad.weight = 0.0
	bad.kind = EventDef.Kind.GOLDEN_FISH
	var problems: PackedStringArray = EventCatalog.validate_event(bad)
	assert_gt(problems.size(), 3)
	var catalog: EventCatalog = EventCatalog.new()
	assert_false(catalog.add(bad))
	assert_true(catalog.ids().is_empty())
