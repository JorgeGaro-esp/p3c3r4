extends GutTest
## Lo que hace cada evento sobre el estado, y que nunca quita nada para siempre.

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
	_rng.seed = 77
	_state = GameState.new()
	for _index: int in range(4):
		_state.tanks[0].add_fish(Fish.new("pond_guppy"))
	_state.production_rate = 2.0


func _event(kind: EventDef.Kind) -> EventDef:
	return _content.events.first_of_kind(kind)


func test_the_food_rain_fills_every_stomach() -> void:
	for fish: Fish in _state.tanks[0].fish:
		fish.hunger = 5.0
	assert_true(EventEffects.start(_event(EventDef.Kind.FOOD_RAIN), _state, _content, _rng))
	for fish: Fish in _state.tanks[0].fish:
		assert_eq(fish.hunger, Care.MAX_HUNGER)


func test_the_warm_current_doubles_production_and_then_fades() -> void:
	var warm: EventDef = _event(EventDef.Kind.WARM_CURRENT)
	var before: float = Simulation.total_production(_state, _content)
	EventEffects.start(warm, _state, _content, _rng)
	var during: float = Simulation.total_production(_state, _content)
	assert_almost_eq(during, before * EventState.WARM_MULTIPLIER, 0.0001)
	var ended: Array[EventDef] = _state.events.tick(warm.duration + 1.0)
	assert_eq(ended, [warm])
	assert_almost_eq(Simulation.total_production(_state, _content), before, 0.0001)


func test_a_pickup_expires_without_a_reward() -> void:
	var golden: EventDef = _event(EventDef.Kind.GOLDEN_FISH)
	EventEffects.start(golden, _state, _content, _rng)
	assert_true(_state.events.has_pickup())
	assert_eq(_state.events.tick(golden.duration - 1.0).size(), 0)
	assert_eq(_state.events.tick(2.0), [golden])
	assert_false(_state.events.has_pickup())
	assert_null(EventEffects.claim(_state, _content, _rng))


func test_claiming_a_golden_fish_pays_at_least_the_minimum() -> void:
	var golden: EventDef = _event(EventDef.Kind.GOLDEN_FISH)
	EventEffects.start(golden, _state, _content, _rng)
	var reward: EventReward = EventEffects.claim(_state, _content, _rng)
	assert_not_null(reward)
	assert_gte(reward.shells, golden.reward_min)
	assert_almost_eq(reward.shells, maxf(golden.reward_min, 2.0 * golden.reward_seconds), 0.001)
	assert_false(_state.events.has_pickup())


func test_the_reward_grows_with_production() -> void:
	var golden: EventDef = _event(EventDef.Kind.GOLDEN_FISH)
	_state.production_rate = 1000.0
	assert_almost_eq(EventEffects.shells_for(golden, _state), 1000.0 * golden.reward_seconds, 0.01)


func test_the_visitor_is_a_rare_species_of_the_tank_biome() -> void:
	var visitor: EventDef = _event(EventDef.Kind.VISITOR)
	EventEffects.start(visitor, _state, _content, _rng)
	var species: SpeciesDef = _content.get_species(_state.events.pickup_species_id)
	assert_not_null(species)
	assert_eq(species.biome_id, "pond")
	assert_gte(species.rarity, EventEffects.VISITOR_MIN_RARITY)


func test_the_visitor_never_changes_the_collection() -> void:
	var discovered_before: int = _state.discovered.size()
	EventEffects.start(_event(EventDef.Kind.VISITOR), _state, _content, _rng)
	EventEffects.claim(_state, _content, _rng)
	assert_eq(_state.discovered.size(), discovered_before)
	assert_eq(_state.tanks[0].fish.size(), 4)


func test_the_bottle_gives_a_decoration() -> void:
	EventEffects.start(_event(EventDef.Kind.BOTTLE), _state, _content, _rng)
	var reward: EventReward = EventEffects.claim(_state, _content, _rng)
	assert_eq(reward.shells, 0.0)
	assert_true(_content.has_decoration(reward.decoration_id))
	assert_eq(_state.decoration_stock[reward.decoration_id], 1)


func test_a_full_stock_turns_the_bottle_into_shells() -> void:
	for decoration_id: String in _content.decoration_ids():
		_state.decoration_stock[decoration_id] = GameState.MAX_STOCK
	EventEffects.start(_event(EventDef.Kind.BOTTLE), _state, _content, _rng)
	var reward: EventReward = EventEffects.claim(_state, _content, _rng)
	assert_true(reward.decoration_id.is_empty())
	assert_gt(reward.shells, 0.0)


func test_the_bloom_dirties_the_water_but_only_down_to_a_floor() -> void:
	_state.tanks[0].cleanliness = 100.0
	EventEffects.start(_event(EventDef.Kind.ALGAE_BLOOM), _state, _content, _rng)
	assert_eq(_state.tanks[0].cleanliness, EventEffects.BLOOM_CLEANLINESS)
	assert_true(_state.events.has_bloom())


func test_cleaning_the_bloom_by_hand_pays_a_reward() -> void:
	EventEffects.start(_event(EventDef.Kind.ALGAE_BLOOM), _state, _content, _rng)
	var paid: EventReward = null
	while _state.events.has_bloom():
		_state.tanks[0].cleanliness += Care.SPOT_STEP
		paid = EventEffects.bloom_progress(_state, true)
	assert_not_null(paid)
	assert_gt(paid.shells, 0.0)


func test_a_bloom_cleaned_by_the_filter_ends_without_a_reward() -> void:
	EventEffects.start(_event(EventDef.Kind.ALGAE_BLOOM), _state, _content, _rng)
	_state.tanks[0].cleanliness = 95.0
	var result: EventReward = EventEffects.bloom_progress(_state, false)
	assert_not_null(result)
	assert_eq(result.shells, 0.0)
	assert_false(_state.events.has_bloom())


func test_a_running_bloom_gives_nothing_yet() -> void:
	EventEffects.start(_event(EventDef.Kind.ALGAE_BLOOM), _state, _content, _rng)
	assert_null(EventEffects.bloom_progress(_state, true))
	assert_true(_state.events.has_bloom())


func test_no_event_removes_fish_or_shells() -> void:
	_state.wallet.add(500.0)
	for kind: EventDef.Kind in EventDef.Kind.values():
		EventEffects.start(_event(kind), _state, _content, _rng)
		EventEffects.claim(_state, _content, _rng)
	assert_eq(_state.tanks[0].fish.size(), 4)
	assert_gte(_state.wallet.shells, 500.0)


func test_events_are_not_saved() -> void:
	EventEffects.start(_event(EventDef.Kind.WARM_CURRENT), _state, _content, _rng)
	EventEffects.start(_event(EventDef.Kind.GOLDEN_FISH), _state, _content, _rng)
	var data: Dictionary = _state.to_dict()
	assert_false(data.has("events"))
	assert_false(data.has("darkness"))
