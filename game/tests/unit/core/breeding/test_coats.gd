extends GutTest
## Los pelajes de color son solo estéticos: no son variantes raras ni se pierden al
## guardar.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())


func test_the_guppy_has_several_coats() -> void:
	var guppy: SpeciesDef = _content.get_species("pond_guppy")
	assert_gt(guppy.coat_count(), 3)
	assert_eq(guppy.coat_bodies.size(), guppy.coat_tails.size())


func test_each_coat_changes_the_body_and_tail_colours() -> void:
	var guppy: SpeciesDef = _content.get_species("pond_guppy")
	for coat: int in range(guppy.coat_count()):
		var palette: AsciiPalette = guppy.build_palette(coat)
		assert_eq(palette.color_for("b"), guppy.coat_bodies[coat])
		assert_eq(palette.color_for("t"), guppy.coat_tails[coat])
		assert_eq(palette.color_for("e"), Color(1, 1, 1, 1), "el ojo no cambia")


func test_species_without_coats_keep_their_palette() -> void:
	var carp: SpeciesDef = _content.get_species("pond_carp")
	assert_eq(carp.coat_count(), 0)
	assert_eq(carp.random_coat(RandomNumberGenerator.new()), 0)
	assert_eq(carp.build_palette(3).color_for("b"), carp.build_palette().color_for("b"))


func test_a_coat_is_not_a_rare_variant() -> void:
	var fish: Fish = Fish.new("pond_guppy")
	fish.coat = 3
	assert_eq(fish.variant_id, VariantDef.NORMAL_ID)


func test_the_coat_survives_saving() -> void:
	var fish: Fish = Fish.new("pond_guppy")
	fish.coat = 4
	var warnings: PackedStringArray = PackedStringArray()
	var back: Fish = Fish.from_dict(fish.to_dict(), _content, warnings)
	assert_eq(back.coat, 4)
	assert_true(warnings.is_empty())


func test_an_out_of_range_coat_is_clamped() -> void:
	var data: Dictionary = Fish.new("pond_guppy").to_dict()
	data["coat"] = 99
	var back: Fish = Fish.from_dict(data, _content, PackedStringArray())
	assert_eq(back.coat, _content.get_species("pond_guppy").coat_count() - 1)


func test_random_coats_cover_the_range() -> void:
	var guppy: SpeciesDef = _content.get_species("pond_guppy")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Dictionary[int, bool] = {}
	for _i: int in range(200):
		seen[guppy.random_coat(rng)] = true
	assert_eq(seen.size(), guppy.coat_count())
