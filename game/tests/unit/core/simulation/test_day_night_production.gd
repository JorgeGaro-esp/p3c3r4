extends GutTest
## La noche y el día frente a la producción: efecto suave, lámpara y sin ventajas
## por cambiar la hora.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.load_equipment_dir())
	assert_true(_content.load_decorations_dir())
	assert_true(_content.biomes.load_dir())
	assert_true(_content.achievements.load_dir())


func _state_with(species_id: String, darkness: float, lamp_level: int = 0) -> GameState:
	var state: GameState = GameState.new()
	state.tanks[0].add_fish(Fish.new(species_id))
	if lamp_level > 0:
		state.tanks[0].set_level("lamp", lamp_level, _content)
	state.set_darkness(darkness)
	return state


func _rate(species_id: String, darkness: float, lamp_level: int = 0) -> float:
	return Simulation.total_production(_state_with(species_id, darkness, lamp_level), _content)


func test_the_starter_fish_is_neutral() -> void:
	assert_eq(_rate("pond_guppy", 0.0), _rate("pond_guppy", 1.0))


func test_a_nocturnal_fish_produces_more_at_night() -> void:
	var day: float = _rate("pond_catfish", 0.0)
	var night: float = _rate("pond_catfish", 1.0)
	assert_gt(night, day)
	assert_almost_eq(
		night / day, (1.0 + DayCycle.NIGHT_EFFECT) / (1.0 - DayCycle.NIGHT_EFFECT), 0.001
	)


func test_a_diurnal_fish_produces_more_by_day() -> void:
	assert_gt(_rate("pond_salmon", 0.0), _rate("pond_salmon", 1.0))


func test_the_lamp_softens_the_night_for_a_diurnal_fish() -> void:
	var dark: float = _rate("pond_salmon", 1.0)
	var lit: float = _rate("pond_salmon", 1.0, 5)
	assert_gt(lit, dark)
	assert_almost_eq(lit, _rate("pond_salmon", 0.0) / (1.0 + DayCycle.NIGHT_EFFECT), 0.001)


func test_the_lamp_never_hurts_a_nocturnal_fish_at_night() -> void:
	assert_almost_eq(_rate("pond_catfish", 1.0, 5), _rate("pond_catfish", 1.0), 0.0001)


func test_one_lamp_level_gives_a_partial_shield() -> void:
	var dark: float = _rate("pond_salmon", 1.0)
	var one: float = _rate("pond_salmon", 1.0, 1)
	var five: float = _rate("pond_salmon", 1.0, 5)
	assert_gt(one, dark)
	assert_lt(one, five)


func test_every_species_stays_within_the_limit_at_any_hour() -> void:
	for species_id: String in _content.species_ids():
		var noon: float = _rate(species_id, 0.0)
		for hour: int in range(0, 24):
			var rate: float = _rate(species_id, DayCycle.darkness(float(hour)))
			assert_between(
				rate / noon,
				(1.0 - DayCycle.NIGHT_EFFECT) / (1.0 + DayCycle.NIGHT_EFFECT) - 0.001,
				(1.0 + DayCycle.NIGHT_EFFECT) / (1.0 - DayCycle.NIGHT_EFFECT) + 0.001,
				species_id
			)


func test_a_mixed_tank_swings_less_than_a_single_nocturnal_one() -> void:
	var mixed: GameState = GameState.new()
	for species_id: String in ["pond_catfish", "pond_catfish", "pond_salmon", "pond_salmon"]:
		mixed.tanks[0].add_fish(Fish.new(species_id))
	var swing: float = _swing(mixed)
	assert_lt(swing, _swing(_state_with("pond_catfish", 0.0)))


func _swing(state: GameState) -> float:
	var rates: PackedFloat64Array = PackedFloat64Array()
	for dark: float in [0.0, 1.0]:
		state.set_darkness(dark)
		rates.append(Simulation.total_production(state, _content))
	return maxf(rates[0], rates[1]) / minf(rates[0], rates[1])


func test_the_darkness_update_marks_production_dirty() -> void:
	var state: GameState = GameState.new()
	state.production_dirty = false
	state.set_darkness(0.005)
	assert_false(state.production_dirty, "un cambio mínimo no recalcula")
	state.set_darkness(0.5)
	assert_true(state.production_dirty)
