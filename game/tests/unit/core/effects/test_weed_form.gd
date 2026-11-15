extends GutTest
## Las formas de planta de cada bioma.


func test_parses_every_kind() -> void:
	assert_eq(WeedForm.parse("stalk|()").kind, WeedForm.Kind.STALK)
	assert_eq(WeedForm.parse("reed||o").kind, WeedForm.Kind.REED)
	assert_eq(WeedForm.parse("fern|\\/").kind, WeedForm.Kind.FERN)
	assert_eq(WeedForm.parse("tuft|\\|/").kind, WeedForm.Kind.TUFT)
	assert_eq(WeedForm.parse("bush|{}").kind, WeedForm.Kind.BUSH)


func test_the_characters_come_after_the_first_bar() -> void:
	assert_eq(WeedForm.parse("reed||o").glyphs, "|o")
	assert_eq(WeedForm.parse("tuft|\\|/").glyphs, "\\|/")


func test_rejects_unknown_kinds_and_missing_characters() -> void:
	assert_null(WeedForm.parse("tree|()"))
	assert_null(WeedForm.parse("stalk"))
	assert_null(WeedForm.parse("stalk|("))
	assert_null(WeedForm.parse("tuft|\\|"))
	assert_null(WeedForm.parse("|()"))


func test_parse_all_skips_the_invalid_ones() -> void:
	var forms: Array[WeedForm] = WeedForm.parse_all(
		PackedStringArray(["stalk|()", "nope", "bush|{}"])
	)
	assert_eq(forms.size(), 2)


func test_only_the_reed_has_its_own_tip() -> void:
	assert_true(WeedForm.parse("reed||o").has_own_tip())
	assert_false(WeedForm.parse("stalk|()").has_own_tip())


func test_heights_make_sense_for_every_kind() -> void:
	for text: String in ["stalk|()", "reed||o", "fern|()", "tuft|abc", "bush|()"]:
		var form: WeedForm = WeedForm.parse(text)
		assert_gte(form.min_height(), 1, text)
		assert_gte(form.max_height(), form.min_height(), text)


func test_every_biome_form_is_valid_and_has_variety() -> void:
	for id: String in ["pond", "reef", "mangrove", "abyss"]:
		var look: BiomeDef = load("res://content/biomes/%s.tres" % id) as BiomeDef
		assert_eq(WeedForm.parse_all(look.weed_forms).size(), look.weed_forms.size(), id)
		var kinds: Dictionary[int, bool] = {}
		for form: WeedForm in WeedForm.parse_all(look.weed_forms):
			kinds[form.kind] = true
		assert_gte(kinds.size(), 4, "%s tiene al menos cuatro formas distintas" % id)


func test_the_characters_are_all_allowed() -> void:
	for id: String in ["pond", "reef", "mangrove", "abyss"]:
		var look: BiomeDef = load("res://content/biomes/%s.tres" % id) as BiomeDef
		for form: WeedForm in WeedForm.parse_all(look.weed_forms):
			assert_eq(AsciiCharset.first_disallowed(form.glyphs), "", "%s %s" % [id, form.glyphs])
