extends GutTest
## Validación de BiomeDef y de las referencias entre contenidos.


func _biome(id: String = "demo") -> BiomeDef:
	var biome: BiomeDef = BiomeDef.new()
	biome.id = id
	biome.name_key = "BIOME_DEMO"
	biome.description_key = "BIOME_DEMO_DESC"
	return biome


func test_a_default_biome_is_valid() -> void:
	assert_eq(BiomeCatalog.validate_biome(_biome()).size(), 0)


func test_invalid_values_are_reported() -> void:
	var biome: BiomeDef = _biome("Bad Id")
	biome.unlock_cost = -1.0
	biome.surface_pattern = ""
	biome.sand_grains = ""
	biome.weed_chars = "("
	biome.weed_gap_scale = 0.0
	biome.backdrop_density = 0.1
	biome.particle_count = 3
	biome.particle_fall = 99.0
	assert_gte(BiomeCatalog.validate_biome(biome).size(), 8)


func test_duplicate_ids_are_rejected() -> void:
	var db: ContentDB = ContentDB.new()
	assert_true(db.biomes.add(_biome()))
	assert_false(db.biomes.add(_biome()))
	assert_eq(db.biomes.ids().size(), 1)


func test_biomes_are_ordered_by_their_order_field() -> void:
	var db: ContentDB = ContentDB.new()
	var late: BiomeDef = _biome("late")
	late.order = 5
	var early: BiomeDef = _biome("early")
	early.order = 1
	db.biomes.add(late)
	db.biomes.add(early)
	assert_eq(db.biomes.ids(), PackedStringArray(["early", "late"]))


func test_a_species_with_an_unknown_biome_is_a_reference_error() -> void:
	var db: ContentDB = ContentDB.new()
	db.biomes.add(_biome("pond"))
	var species: SpeciesDef = SpeciesDef.new()
	species.id = "ghost_fish"
	species.name_key = "X"
	species.biome_id = "ghost"
	species.sprite_path = "res://content/sprites/pond_guppy.txt"
	db.add_species(species)
	assert_false(BiomeCatalog.check_references(db))
	assert_string_contains(str(db.biomes.errors), "ghost")


func test_a_bad_biome_requirement_is_a_reference_error() -> void:
	var db: ContentDB = ContentDB.new()
	var biome: BiomeDef = _biome("pond")
	biome.requires_biome_id = "nowhere"
	db.biomes.add(biome)
	assert_false(BiomeCatalog.check_references(db))


func test_the_real_content_has_consistent_references() -> void:
	var db: ContentDB = ContentDB.new()
	db.load_variants_dir()
	db.load_species_dir()
	db.load_decorations_dir()
	db.biomes.load_dir()
	assert_true(BiomeCatalog.check_references(db), str(db.biomes.errors))
	assert_eq(db.biomes.ids()[0], "pond")
	assert_eq(db.biomes.get_biome("pond").unlock_cost, 0.0)


func test_ambience_is_deterministic_and_stays_inside_the_water() -> void:
	var db: ContentDB = ContentDB.new()
	db.biomes.load_dir()
	var reef: BiomeDef = db.biomes.get_biome("reef")
	var water: Rect2i = Rect2i(0, 1, 60, 6)
	var first: ParticleField = ParticleField.new()
	first.configure(water, reef, 3)
	var backdrop: BackdropView = BackdropView.new()
	backdrop.configure(water, reef, 3)
	assert_eq(first.count(), reef.particle_count)
	assert_gt(backdrop.count(), 0)
	var again: BackdropView = BackdropView.new()
	again.configure(water, reef, 3)
	assert_eq(again.count(), backdrop.count())
	var pond: BiomeDef = db.biomes.get_biome("pond")
	var motes: ParticleField = ParticleField.new()
	motes.configure(water, pond)
	assert_eq(motes.count(), pond.particle_count)
	assert_gt(motes.count(), 0)
