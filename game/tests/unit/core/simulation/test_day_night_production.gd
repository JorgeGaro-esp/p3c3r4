extends GutTest
## La hora del día no cambia la producción: todos los peces rinden igual de día y de
## noche, y la lámpara no cambia eso.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.load_equipment_dir())
	assert_true(_content.load_decorations_dir())
	assert_true(_content.biomes.load_dir())
	assert_true(_content.achievements.load_dir())


func _rate(species_id: String, darkness: float, lamp_level: int = 0) -> float:
	var state: GameState = GameState.new()
	state.tanks[0].add_fish(Fish.new(species_id))
	if lamp_level > 0:
		state.tanks[0].set_level("lamp", lamp_level, _content)
	state.set_darkness(darkness)
	return Simulation.total_production(state, _content)


func test_every_species_produces_the_same_at_any_hour() -> void:
	for species_id: String in _content.species_ids():
		var noon: float = _rate(species_id, 0.0)
		for hour: int in range(0, 24):
			assert_almost_eq(
				_rate(species_id, DayCycle.darkness(float(hour))), noon, 0.000001, species_id
			)


func test_the_lamp_does_not_change_production_at_night() -> void:
	for species_id: String in ["pond_guppy", "pond_catfish", "pond_salmon"]:
		assert_almost_eq(_rate(species_id, 1.0, 5), _rate(species_id, 1.0), 0.000001, species_id)


func test_the_darkness_update_marks_production_dirty() -> void:
	var state: GameState = GameState.new()
	state.production_dirty = false
	state.set_darkness(0.005)
	assert_false(state.production_dirty, "un cambio mínimo no recalcula")
	state.set_darkness(0.5)
	assert_true(state.production_dirty)
