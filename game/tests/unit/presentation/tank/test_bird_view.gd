extends GutTest
## El dibujo del pájaro de cada bioma.


func _look() -> BiomeDef:
	var look: BiomeDef = BiomeDef.new()
	look.bird_perch_a = "  ,o>|(___/ "
	look.bird_color = Color.WHITE
	return look


func test_biome_without_bird_never_shows_one() -> void:
	var view: BirdView = BirdView.new()
	view.configure(BiomeDef.new(), 0.0, 200.0, 0)
	assert_false(view.has_bird())


func test_biome_with_bird_has_one() -> void:
	var view: BirdView = BirdView.new()
	view.configure(_look(), 0.0, 200.0, 0)
	assert_true(view.has_bird())


func test_mirror_flips_the_picture_and_its_brackets() -> void:
	assert_eq(BirdView._mirror("(___/ "), " \\___)")
	assert_eq(BirdView._mirror(",o>"), "<o,")


func test_rows_are_padded_to_the_same_width() -> void:
	var rows: PackedStringArray = BirdView._rows("ab|abcd")
	assert_eq(rows[0], "ab  ")
	assert_eq(rows[1], "abcd")


func test_every_biome_defines_a_bird_with_two_rows() -> void:
	for id: String in ["pond", "reef", "mangrove", "abyss"]:
		var look: BiomeDef = load("res://content/biomes/%s.tres" % id) as BiomeDef
		assert_not_null(look, id)
		assert_false(look.bird_perch_a.is_empty(), id)
		assert_eq(look.bird_perch_a.split("|").size(), 2, id)
		assert_false(look.weed_palette.is_empty(), id)
