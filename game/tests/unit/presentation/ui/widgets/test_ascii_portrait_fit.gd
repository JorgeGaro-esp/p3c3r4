extends GutTest
## El retrato enseña siempre algo: el pez grande se ve entero si cabe y, si no, su
## juvenil o su cría.

const GIANT: String = "res://content/species/pond_wels.tres"
## Un grande que se dibuja con caracteres (sin imágenes): ahí sí cambia de sprite.
const ASCII_GIANT: String = "res://content/species/abyss_sperm_whale.tres"


func _portrait(width: int, height: int) -> AsciiPortrait:
	return _portrait_of(load(GIANT) as SpeciesDef, width, height)


func _portrait_of(def: SpeciesDef, width: int, height: int) -> AsciiPortrait:
	var portrait: AsciiPortrait = AsciiPortrait.new()
	portrait.rect = Rect2i(0, 0, width, height)
	var looks: Array[VariantDef.Look] = [VariantDef.Look.NONE]
	portrait.show_species(def, looks, PackedStringArray(["x"]))
	return portrait


func test_the_giant_fits_in_a_wide_photo() -> void:
	var def: SpeciesDef = load(GIANT) as SpeciesDef
	var adult: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
	var portrait: AsciiPortrait = _portrait(DexLayout.wanted_portrait_width(adult.width), 9)
	assert_eq(portrait.shown_width(), adult.width)


func test_the_giant_with_images_keeps_its_adult_sprite_in_a_small_photo() -> void:
	var def: SpeciesDef = load(GIANT) as SpeciesDef
	assert_true(ImageFishView.has_masks(def.id), "el gigante se dibuja con imágenes")
	var adult: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
	var portrait: AsciiPortrait = _portrait(10, 9)
	assert_eq(portrait.shown_width(), adult.width)


func test_an_ascii_giant_falls_back_to_a_smaller_sprite_in_a_small_photo() -> void:
	var def: SpeciesDef = load(ASCII_GIANT) as SpeciesDef
	assert_false(ImageFishView.has_masks(def.id), "este gigante se dibuja con caracteres")
	var adult: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
	var portrait: AsciiPortrait = _portrait_of(def, 12, 12)
	assert_gt(portrait.shown_width(), 0)
	assert_lt(portrait.shown_width(), adult.width)


func test_the_widest_sprite_is_found() -> void:
	var def: SpeciesDef = load(GIANT) as SpeciesDef
	var defs: Array[SpeciesDef] = [def]
	assert_gte(AsciiPortrait.widest_sprite(defs), 11)
