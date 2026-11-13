extends GutTest
## Comprueba el contenido real de cada bioma: 8 especies, sus textos y su arte.

const CSV_PATH: String = "res://assets/i18n/strings.csv"
const BIOMES: PackedStringArray = ["pond", "reef"]

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_species_dir(), str(_content.errors))
	assert_true(_content.biomes.load_dir(), str(_content.biomes.errors))
	assert_true(_content.load_decorations_dir(), str(_content.errors))
	assert_true(BiomeCatalog.check_references(_content), str(_content.biomes.errors))


func _csv_keys() -> Dictionary:
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if not line[0].is_empty():
			keys[line[0]] = true
	return keys


func _species_of(biome_id: String) -> Array[SpeciesDef]:
	var found: Array[SpeciesDef] = []
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		if def.biome_id == biome_id:
			found.append(def)
	found.sort_custom(func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost)
	return found


func test_each_biome_has_eight_species_of_every_rarity() -> void:
	for biome_id: String in BIOMES:
		var defs: Array[SpeciesDef] = _species_of(biome_id)
		assert_eq(defs.size(), 8, biome_id)
		var rarities: Dictionary = {}
		for def: SpeciesDef in defs:
			rarities[def.rarity] = true
		assert_eq(rarities.size(), SpeciesDef.Rarity.size(), "%s: cinco rarezas" % biome_id)


func test_species_ids_start_with_their_biome_id() -> void:
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		assert_true(species_id.begins_with(def.biome_id + "_"), species_id)


func test_every_species_has_name_and_description_texts() -> void:
	var keys: Dictionary = _csv_keys()
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		assert_true(keys.has(def.name_key), def.name_key)
		assert_true(keys.has(def.description_key), def.description_key)


func test_every_biome_and_decoration_has_texts() -> void:
	var keys: Dictionary = _csv_keys()
	for biome_id: String in _content.biomes.ids():
		var biome: BiomeDef = _content.biomes.get_biome(biome_id)
		assert_true(keys.has(biome.name_key), biome.name_key)
		assert_true(keys.has(biome.description_key), biome.description_key)
	for decoration_id: String in _content.decoration_ids():
		var def: DecorationDef = _content.get_decoration(decoration_id)
		assert_true(keys.has(def.name_key), def.name_key)
		assert_true(keys.has(def.description_key), def.description_key)
		if not def.tag.is_empty():
			assert_true(keys.has("TAG_%s" % def.tag.to_upper()), def.tag)


func test_every_sprite_loads_and_only_uses_allowed_characters() -> void:
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		assert_true(sprite.is_valid(), "%s: %s" % [species_id, sprite.errors])
		assert_true(sprite.anchors.has("eye"), "%s: falta el ancla eye" % species_id)
		for frame: PackedStringArray in sprite.frames:
			for line: String in frame:
				assert_eq(AsciiCharset.first_disallowed(line), "", species_id)


func test_biome_surface_sand_and_weeds_use_allowed_characters() -> void:
	for biome_id: String in _content.biomes.ids():
		var biome: BiomeDef = _content.biomes.get_biome(biome_id)
		for text: String in [
			biome.surface_pattern,
			biome.sand_grains,
			biome.weed_chars,
			biome.backdrop_char,
			biome.particle_chars
		]:
			assert_eq(AsciiCharset.first_disallowed(text), "", "%s: %s" % [biome_id, text])


func test_cost_and_production_grow_with_rarity() -> void:
	for biome_id: String in BIOMES:
		var previous_cost: float = 0.0
		var previous_rate: float = 0.0
		for def: SpeciesDef in _species_of(biome_id):
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
	for biome_id: String in BIOMES:
		var previous: SpeciesDef = null
		for def: SpeciesDef in _species_of(biome_id):
			assert_gt(def.breed_seconds, def.hatch_seconds, def.id)
			if previous != null:
				assert_gt(def.growth_seconds, previous.growth_seconds, def.id)
				assert_gt(def.breed_seconds, previous.breed_seconds, def.id)
			previous = def


func test_unlock_requirements_point_to_species_of_the_same_biome() -> void:
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		if def.unlock_kind != SpeciesDef.UnlockKind.SPECIES_COUNT:
			continue
		var needed: SpeciesDef = _content.get_species(def.unlock_species_id)
		if needed == null:
			continue
		assert_eq(needed.biome_id, def.biome_id, species_id)


func test_every_species_can_be_unlocked_by_a_decoration_tag_that_exists() -> void:
	var tags: Dictionary = {}
	for decoration_id: String in _content.decoration_ids():
		tags[_content.get_decoration(decoration_id).tag] = true
	for species_id: String in _content.species_ids():
		var def: SpeciesDef = _content.get_species(species_id)
		if def.unlock_kind == SpeciesDef.UnlockKind.DECORATION_TAG:
			assert_true(tags.has(def.unlock_tag), "%s: etiqueta %s" % [species_id, def.unlock_tag])


func test_every_stage_and_variant_has_text_in_both_languages() -> void:
	var keys: Dictionary = _csv_keys()
	for stage: LifeStage.Stage in LifeStage.Stage.values():
		assert_true(keys.has(LifeStage.name_key(stage)), LifeStage.name_key(stage))
	var variants: ContentDB = ContentDB.new()
	assert_true(variants.load_variants_dir(), str(variants.errors))
	for id: String in variants.variant_ids():
		assert_true(keys.has(variants.get_variant(id).name_key), id)
