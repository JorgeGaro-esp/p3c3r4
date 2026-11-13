extends GutTest
## Pruebas de los marcos de caja.


func test_frame_has_the_requested_size() -> void:
	var lines: PackedStringArray = BoxDrawing.frame_lines(20, 6, "Tienda")
	assert_eq(lines.size(), 6)
	for line: String in lines:
		assert_eq(line.length(), 20)


func test_frame_corners_and_sides() -> void:
	var lines: PackedStringArray = BoxDrawing.frame_lines(8, 4)
	assert_eq(lines[0], "┌──────┐")
	assert_eq(lines[1], "│      │")
	assert_eq(lines[3], "└──────┘")


func test_double_frame_uses_double_lines() -> void:
	var lines: PackedStringArray = BoxDrawing.frame_lines(6, 3, "", true)
	assert_eq(lines[0], "╔════╗")
	assert_eq(lines[2], "╚════╝")
	assert_eq(BoxDrawing.side(true), "║")


func test_title_is_embedded_in_the_top_line() -> void:
	assert_eq(BoxDrawing.top_line(16, "Tienda", false), "┌─ Tienda ─────┐")


func test_long_title_is_cut_to_fit() -> void:
	var line: String = BoxDrawing.top_line(12, "Un título larguísimo", false)
	assert_eq(line.length(), 12)
	assert_true(line.begins_with("┌─ "))
	assert_true(line.ends_with("─┐"))


func test_tiny_widths_fall_back_to_a_plain_line() -> void:
	assert_eq(BoxDrawing.top_line(5, "Tienda", false), "┌───┐")
	assert_eq(BoxDrawing.top_line(1, "x", false), "")
	assert_eq(BoxDrawing.frame_lines(1, 5).size(), 0)
	assert_eq(BoxDrawing.frame_lines(5, 1).size(), 0)


func test_every_frame_character_is_allowed_by_the_art_guide() -> void:
	for text: String in (
		BoxDrawing.frame_lines(10, 4, "Ajustes") + BoxDrawing.frame_lines(10, 4, "", true)
	):
		assert_eq(AsciiCharset.first_disallowed(text), "", text)
