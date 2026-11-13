extends GutTest
## Pruebas de las utilidades de texto en celdas.


func test_fit_keeps_short_text_and_marks_cut_text() -> void:
	assert_eq(UiText.fit("Guppy", 10), "Guppy")
	assert_eq(UiText.fit("Guppy", 5), "Guppy")
	assert_eq(UiText.fit("Pez ángel", 6), "Pez á" + UiText.TRUNCATION_MARK)
	assert_eq(UiText.fit("abc", 1), UiText.TRUNCATION_MARK)
	assert_eq(UiText.fit("abc", 0), "")
	assert_eq(UiText.fit("abc", -3), "")


func test_truncation_mark_is_an_allowed_character() -> void:
	assert_true(AsciiCharset.is_allowed(UiText.TRUNCATION_MARK))
	assert_true(AsciiCharset.is_allowed(UiText.FULL_BLOCK))
	assert_true(AsciiCharset.is_allowed(UiText.LIGHT_SHADE))


func test_padding_always_gives_the_exact_width() -> void:
	for width: int in range(0, 12):
		assert_eq(UiText.pad_right("Tienda", width).length(), width)
		assert_eq(UiText.pad_left("Tienda", width).length(), width)
		assert_eq(UiText.center("Tienda", width).length(), width)


func test_center_puts_extra_space_on_the_right() -> void:
	assert_eq(UiText.center("ab", 5), " ab  ")
	assert_eq(UiText.center("ab", 4), " ab ")


func test_join_ends_aligns_the_right_text() -> void:
	assert_eq(UiText.join_ends("Guppy", "12 ¢", 14), "Guppy     12 ¢")
	assert_eq(UiText.join_ends("Guppy", "12 ¢", 14).length(), 14)


func test_join_ends_cuts_the_left_text_when_it_does_not_fit() -> void:
	var line: String = UiText.join_ends("Pez ángel dorado", "120 ¢", 12)
	assert_eq(line.length(), 12)
	assert_true(line.ends_with("120 ¢"))
	assert_eq(UiText.join_ends("x", "muy largo para la línea", 6).length(), 6)
	assert_eq(UiText.join_ends("x", "y", 0), "")


func test_wrap_breaks_on_spaces_without_exceeding_the_width() -> void:
	var lines: PackedStringArray = UiText.wrap("Nueva variante descubierta en la pecera", 14)
	assert_eq(lines, PackedStringArray(["Nueva variante", "descubierta en", "la pecera"]))
	for line: String in lines:
		assert_lte(line.length(), 14)


func test_wrap_splits_words_longer_than_the_line() -> void:
	var lines: PackedStringArray = UiText.wrap("supercalifragilistico ok", 8)
	assert_eq(lines, PackedStringArray(["supercal", "ifragili", "stico ok"]))


func test_wrap_handles_empty_text_and_bad_widths() -> void:
	assert_eq(UiText.wrap("", 10).size(), 0)
	assert_eq(UiText.wrap("hola", 0).size(), 0)
	assert_eq(UiText.wrap("   ", 5).size(), 0)


func test_bar_fills_proportionally_and_clamps() -> void:
	assert_eq(UiText.bar(0.5, 10), "█████░░░░░")
	assert_eq(UiText.bar(0.0, 4), "░░░░")
	assert_eq(UiText.bar(1.0, 4), "████")
	assert_eq(UiText.bar(-3.0, 4), "░░░░")
	assert_eq(UiText.bar(9.0, 4), "████")
	assert_eq(UiText.bar(0.5, 0), "")
