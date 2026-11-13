extends GutTest
## Consultas de la Enciclopedia sobre las partidas.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.biomes.load_dir())


func test_species_of_a_biome_are_sorted_by_cost() -> void:
	var ids: PackedStringArray = Encyclopedia.species_of(_content, "reef")
	assert_eq(ids.size(), 8)
	var previous: float = 0.0
	for species_id: String in ids:
		var cost: float = _content.get_species(species_id).base_cost
		assert_gt(cost, previous)
		previous = cost


func test_all_species_when_no_biome_is_given() -> void:
	assert_eq(Encyclopedia.species_of(_content).size(), _content.species_ids().size())


func test_a_new_state_has_nothing_found() -> void:
	var state: GameState = GameState.new()
	assert_eq(Encyclopedia.species_progress(state, _content).x, 0)
	assert_eq(Encyclopedia.variant_progress(state, _content).x, 0)
	assert_false(Encyclopedia.is_complete(state, _content))


func test_discoveries_count_species_and_variants() -> void:
	var state: GameState = GameState.new()
	state.discover("pond_guppy", "normal")
	state.discover("pond_guppy", "golden")
	state.discover("reef_clownfish", "normal")
	assert_eq(Encyclopedia.variants_found(state, _content, "pond_guppy"), 2)
	assert_true(Encyclopedia.is_species_found(state, _content, "reef_clownfish"))
	assert_false(Encyclopedia.is_species_found(state, _content, "reef_ray"))
	assert_eq(Encyclopedia.species_progress(state, _content).x, 2)
	assert_eq(Encyclopedia.species_progress(state, _content, "pond").x, 1)
	assert_eq(Encyclopedia.variant_progress(state, _content, "pond").x, 2)
	assert_eq(
		Encyclopedia.variant_progress(state, _content, "pond").y, 8 * _content.variant_ids().size()
	)


func test_totals_cover_every_species_and_variant() -> void:
	var state: GameState = GameState.new()
	var progress: Vector2i = Encyclopedia.variant_progress(state, _content)
	assert_eq(progress.y, _content.species_ids().size() * _content.variant_ids().size())


func test_complete_only_with_every_variant_of_every_species() -> void:
	var state: GameState = GameState.new()
	for species_id: String in _content.species_ids():
		for variant_id: String in _content.variant_ids():
			state.discover(species_id, variant_id)
	assert_true(Encyclopedia.is_complete(state, _content))
	state.discovered.erase(GameState.discovery_key("abyss_giant_squid", "prismatic"))
	assert_false(Encyclopedia.is_complete(state, _content))
