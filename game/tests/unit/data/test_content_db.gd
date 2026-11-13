extends GutTest

const SPRITE: String = "res://content/sprites/pond_guppy.txt"


func _valid(id: String = "pond_guppy") -> SpeciesDef:
	var species: SpeciesDef = SpeciesDef.new()
	species.id = id
	species.name_key = "SPECIES_X"
	species.base_cost = 10.0
	species.base_production = 0.1
	species.sprite_path = SPRITE
	return species


func test_valid_species_has_no_problems() -> void:
	assert_eq(ContentDB.validate_species(_valid()).size(), 0)


func test_invalid_ids_are_reported() -> void:
	for bad_id: String in ["", "Guppy", "1guppy", "pond guppy", "pond-guppy"]:
		var species: SpeciesDef = _valid(bad_id)
		assert_gt(ContentDB.validate_species(species).size(), 0, "'%s'" % bad_id)


func test_out_of_range_values_are_reported() -> void:
	var species: SpeciesDef = _valid()
	species.base_cost = 0.0
	assert_gt(ContentDB.validate_species(species).size(), 0)
	species = _valid()
	species.base_production = -1.0
	assert_gt(ContentDB.validate_species(species).size(), 0)
	species = _valid()
	species.speed = 0.0
	assert_gt(ContentDB.validate_species(species).size(), 0)


func test_missing_sprite_and_mismatched_palette_are_reported() -> void:
	var species: SpeciesDef = _valid()
	species.sprite_path = "res://content/sprites/nope.txt"
	assert_gt(ContentDB.validate_species(species).size(), 0)
	species = _valid()
	species.palette_roles = PackedStringArray(["b", "t"])
	species.palette_colors = PackedColorArray([Color.RED])
	assert_gt(ContentDB.validate_species(species).size(), 0)


func test_duplicate_ids_are_rejected() -> void:
	var content: ContentDB = ContentDB.new()
	assert_true(content.add_species(_valid("a")))
	assert_false(content.add_species(_valid("a")))
	assert_eq(content.species_ids().size(), 1)
	assert_eq(content.errors.size(), 1)


func test_lookup() -> void:
	var content: ContentDB = ContentDB.new()
	content.add_species(_valid("a"))
	assert_true(content.has_species("a"))
	assert_not_null(content.get_species("a"))
	assert_null(content.get_species("zzz"))


func test_rarity_symbols_are_distinct_and_drawable() -> void:
	var seen: Dictionary = {}
	for rarity: int in SpeciesDef.Rarity.values():
		var species: SpeciesDef = _valid()
		species.rarity = rarity as SpeciesDef.Rarity
		var symbol: String = species.rarity_symbol()
		assert_false(seen.has(symbol))
		seen[symbol] = true
		assert_eq(AsciiCharset.first_disallowed(symbol), "")


func test_real_content_loads_without_errors() -> void:
	var content: ContentDB = ContentDB.new()
	assert_true(content.load_species_dir(), str(content.errors))
	assert_gte(content.species_ids().size(), 3)


func test_every_species_name_key_exists_in_both_languages() -> void:
	var content: ContentDB = ContentDB.new()
	content.load_species_dir()
	var keys: Dictionary = {}
	var file: FileAccess = FileAccess.open("res://assets/i18n/strings.csv", FileAccess.READ)
	file.get_csv_line()
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() >= 3:
			keys[line[0]] = true
	for species_id: String in content.species_ids():
		var key: String = content.get_species(species_id).name_key
		assert_true(keys.has(key), "%s: falta %s en strings.csv" % [species_id, key])
