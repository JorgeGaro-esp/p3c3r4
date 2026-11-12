extends GutTest
## Pruebas del lector de sprites.

const ANGEL: String = (
	"# angel · adulto\n[frame]\n  /\\\n><  °>\n  \\/\n"
	+ "[colors]\n  ff\ntt  eb\n  ff\n[anchor]\neye=4,1\n"
)


func test_reads_size_and_id() -> void:
	var sprite: AsciiSprite = SpriteLoader.parse(ANGEL)
	assert_true(sprite.is_valid(), str(sprite.errors))
	assert_eq(sprite.id, "angel")
	assert_eq(sprite.width, 6)
	assert_eq(sprite.height, 3)
	assert_eq(sprite.frame_count(), 1)


func test_pads_lines_to_uniform_width() -> void:
	var sprite: AsciiSprite = SpriteLoader.parse(ANGEL)
	for line: String in sprite.frames[0]:
		assert_eq(line.length(), 6)


func test_reads_colors_and_anchor() -> void:
	var sprite: AsciiSprite = SpriteLoader.parse(ANGEL)
	assert_eq(sprite.colors[0][1], "tt  eb")
	assert_eq(sprite.anchors["eye"], Vector2i(4, 1))


func test_multiple_frames_inherit_colors() -> void:
	var text: String = "[frame]\nab\n[colors]\ntb\n[frame]\ncd\n"
	var sprite: AsciiSprite = SpriteLoader.parse(text, "x")
	assert_true(sprite.is_valid(), str(sprite.errors))
	assert_eq(sprite.frame_count(), 2)
	assert_eq(sprite.colors[1][0], "tb")


func test_missing_frame_is_error() -> void:
	assert_false(SpriteLoader.parse("# a · b\n").is_valid())


func test_disallowed_character_is_error() -> void:
	assert_false(SpriteLoader.parse("[frame]\nab猫\n").is_valid())


func test_anchor_outside_is_error() -> void:
	assert_false(SpriteLoader.parse("[frame]\nab\n[anchor]\neye=9,0\n").is_valid())


func test_color_rows_mismatch_is_error() -> void:
	assert_false(SpriteLoader.parse("[frame]\nab\ncd\n[colors]\ntb\n").is_valid())


func test_text_before_section_is_error() -> void:
	assert_false(SpriteLoader.parse("hola\n[frame]\nab\n").is_valid())


func test_default_id_without_header() -> void:
	assert_eq(SpriteLoader.parse("[frame]\nab\n", "fallback").id, "fallback")


func test_load_file_missing_reports_error() -> void:
	var sprite: AsciiSprite = SpriteLoader.load_file("res://content/sprites/nope.txt")
	assert_false(sprite.is_valid())
