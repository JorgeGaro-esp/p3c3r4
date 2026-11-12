extends GutTest
## Pruebas del espejado automático de sprites.

const ANGEL: String = (
	"[frame]\n  /\\\n><  °>\n  \\/\n" + "[colors]\n  ff\ntt  eb\n  ff\n[anchor]\neye=4,1\n"
)


func test_mirrors_text_and_swaps_pairs() -> void:
	var mirrored: AsciiSprite = SpriteLoader.parse(ANGEL).mirrored()
	assert_eq(mirrored.frames[0], PackedStringArray(["  /\\  ", "<°  ><", "  \\/  "]))


func test_mirrors_colors_and_anchor() -> void:
	var mirrored: AsciiSprite = SpriteLoader.parse(ANGEL).mirrored()
	assert_eq(mirrored.colors[0][1], "be  tt")
	assert_eq(mirrored.anchors["eye"], Vector2i(1, 1))


func test_mirror_twice_is_identity() -> void:
	var original: AsciiSprite = SpriteLoader.parse(ANGEL)
	var twice: AsciiSprite = original.mirrored().mirrored()
	assert_eq(twice.frames[0], original.frames[0])
	assert_eq(twice.colors[0], original.colors[0])


func test_mirror_table_is_involution() -> void:
	assert_eq(AsciiSprite.MIRROR_FROM.length(), AsciiSprite.MIRROR_TO.length())
	for character: String in AsciiSprite.MIRROR_FROM:
		assert_eq(AsciiSprite.mirror_char(AsciiSprite.mirror_char(character)), character)


func test_unpaired_characters_stay() -> void:
	assert_eq(AsciiSprite.mirror_char("o"), "o")
	assert_eq(AsciiSprite.mirror_char("°"), "°")
