extends GutTest
## La fuente debe tener todos los caracteres permitidos y el contenido debe ser válido.

const SPRITES_DIR: String = "res://content/sprites"
const SPECIES_DIR: String = "res://content/species"


func test_font_has_every_allowed_character() -> void:
	var font: Font = load(AsciiCanvas.DEFAULT_FONT_PATH) as Font
	assert_not_null(font)
	for character: String in AsciiCharset.all_characters():
		assert_true(font.has_char(character.unicode_at(0)), "missing glyph: %s" % character)


func test_all_content_sprites_are_valid() -> void:
	var names: PackedStringArray = DirAccess.get_files_at(SPRITES_DIR)
	assert_gt(names.size(), 0)
	for file_name: String in names:
		if not file_name.ends_with(".txt"):
			continue
		var sprite: AsciiSprite = SpriteLoader.load_file(SPRITES_DIR.path_join(file_name))
		assert_true(sprite.is_valid(), "%s: %s" % [file_name, sprite.errors])


func test_species_reference_existing_sprites_and_cover_colors() -> void:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(SPECIES_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var def: SwimmerDef = load(SPECIES_DIR.path_join(file_name)) as SwimmerDef
		assert_not_null(def, file_name)
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		assert_true(sprite.is_valid(), file_name)
		var palette: AsciiPalette = def.build_palette()
		for rows: PackedStringArray in sprite.colors:
			for row: String in rows:
				for letter: String in row:
					if letter != " ":
						assert_true(
							palette.has_role(letter), "%s lacks role %s" % [file_name, letter]
						)
		count += 1
	assert_gte(count, 3)
