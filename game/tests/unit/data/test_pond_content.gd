extends GutTest
## Comprueba el contenido real del estanque: las 8 especies, sus textos y su arte.

const CSV_PATH: String = "res://assets/i18n/strings.csv"

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_species_dir(), str(_content.errors))


func _csv_keys() -> Dictionary:
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if not line[0].is_empty():
			keys[line[0]] = true
	return keys


func test_the_pond_has_eight_species_one_of_each_rarity_step() -> void:
	assert_eq(_content.species_ids().size(), 8)
	var rarities: Dictionary = {}
	for species_id: String in _content.species_ids():
		rarities[_content.get_species(species_id).rarity] = true
	assert_eq(rarities.size(), SpeciesDef.Rarity.size(), "las cinco rarezas están representadas")


func test_every_species_has_name_and_description_texts() -> void:
	var keys: Dictionary = _csv_keys()
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		assert_true(keys.has(def.name_key), def.name_key)
		assert_true(keys.has(def.description_key), def.description_key)


func test_every_sprite_loads_and_only_uses_allowed_characters() -> void:
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		assert_true(sprite.is_valid(), "%s: %s" % [species_id, sprite.errors])
		for frame: PackedStringArray in sprite.frames:
			for line: String in frame:
				assert_eq(AsciiCharset.first_disallowed(line), "", species_id)


func test_cost_and_production_grow_with_rarity() -> void:
	var previous_cost: float = 0.0
	var previous_rate: float = 0.0
	var ids: Array[SpeciesDef] = []
	for species_id: String in _content.species_ids():
		ids.append(_content.get_species(species_id))
	ids.sort_custom(func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost)
	for def: SpeciesDef in ids:
		assert_gt(def.base_cost, previous_cost, def.id)
		assert_gt(def.base_production, previous_rate, def.id)
		previous_cost = def.base_cost
		previous_rate = def.base_production


func test_the_starting_game_can_afford_a_second_guppy() -> void:
	var guppy: SpeciesDef = _content.get_species("pond_guppy")
	assert_gte(GameService.START_SHELLS, guppy.base_cost)


func test_every_stage_sprite_loads_and_stays_in_the_charset() -> void:
	var paths: Array[String] = [TankView.GENERIC_FRY, TankView.GENERIC_JUVENILE]
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		for extra: String in [def.fry_sprite_path, def.juvenile_sprite_path]:
			if not extra.is_empty():
				paths.append(extra)
	for path: String in paths:
		var sprite: AsciiSprite = SpriteLoader.load_file(path)
		assert_true(sprite.is_valid(), "%s: %s" % [path, sprite.errors])
		for frame: PackedStringArray in sprite.frames:
			for line: String in frame:
				assert_eq(AsciiCharset.first_disallowed(line), "", path)


func test_growth_breeding_and_hatching_times_grow_with_rarity() -> void:
	var ids: Array[SpeciesDef] = []
	for species_id: String in _content.species_ids():
		ids.append(_content.get_species(species_id))
	ids.sort_custom(func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost)
	var previous: SpeciesDef = null
	for def: SpeciesDef in ids:
		assert_gt(def.breed_seconds, def.hatch_seconds, def.id)
		if previous != null:
			assert_gt(def.growth_seconds, previous.growth_seconds, def.id)
			assert_gt(def.breed_seconds, previous.breed_seconds, def.id)
		previous = def


func test_every_stage_and_variant_has_text_in_both_languages() -> void:
	var keys: Dictionary = _csv_keys()
	for stage: LifeStage.Stage in LifeStage.Stage.values():
		assert_true(keys.has(LifeStage.name_key(stage)), LifeStage.name_key(stage))
	var variants: ContentDB = ContentDB.new()
	assert_true(variants.load_variants_dir(), str(variants.errors))
	for id: String in variants.variant_ids():
		assert_true(keys.has(variants.get_variant(id).name_key), id)
