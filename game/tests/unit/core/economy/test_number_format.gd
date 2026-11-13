extends GutTest


func test_small_numbers() -> void:
	assert_eq(NumberFormat.compact(0.0), "0")
	assert_eq(NumberFormat.compact(7.0), "7")
	assert_eq(NumberFormat.compact(12.4), "12,4")
	assert_eq(NumberFormat.compact(999.0), "999")
	assert_eq(NumberFormat.compact(0.5), "0,5")
	assert_eq(NumberFormat.compact(0.25), "0,25")


func test_thousands_and_millions_in_spanish() -> void:
	assert_eq(NumberFormat.compact(1000.0), "1K")
	assert_eq(NumberFormat.compact(12400.0), "12,4K")
	assert_eq(NumberFormat.compact(124000.0), "124K")
	assert_eq(NumberFormat.compact(3100000.0), "3,1M")
	assert_eq(NumberFormat.compact(1250000000.0), "1,25B")


func test_decimal_separator_follows_locale() -> void:
	assert_eq(NumberFormat.compact(12400.0, "en"), "12.4K")
	assert_eq(NumberFormat.compact(12400.0, "es_ES"), "12,4K")
	assert_eq(NumberFormat.compact(0.5, "en"), "0.5")


func test_rounding_rolls_over_to_the_next_suffix() -> void:
	assert_eq(NumberFormat.compact(999999.0), "1M")
	assert_eq(NumberFormat.compact(999950.0), "1M")
	assert_eq(NumberFormat.compact(999400.0), "999K")


func test_negative_numbers() -> void:
	assert_eq(NumberFormat.compact(-12400.0), "-12,4K")


func test_huge_numbers_use_scientific_notation() -> void:
	assert_eq(NumberFormat.compact(1.5e40), "1,5e40")
	assert_eq(NumberFormat.compact(1.0e300, "en"), "1e300")


func test_invalid_values_do_not_crash() -> void:
	assert_eq(NumberFormat.compact(INF), "inf")
	assert_eq(NumberFormat.compact(-INF), "-inf")
	assert_eq(NumberFormat.compact(NAN), "?")


func test_per_second_adds_suffix() -> void:
	assert_eq(NumberFormat.per_second(1.5), "1,5/s")
	assert_eq(NumberFormat.per_second(2500.0, "en"), "2.5K/s")


func test_output_only_uses_drawable_characters() -> void:
	for value: float in [0.0, 3.7, 12400.0, 3.1e6, 1.0e15, 1.0e50, -5.0]:
		var text: String = NumberFormat.per_second(value)
		assert_eq(AsciiCharset.first_disallowed(text), "", text)


func test_percent_has_sign_and_trims_zeroes() -> void:
	assert_eq(NumberFormat.percent(1.5), "+1,5 %")
	assert_eq(NumberFormat.percent(2.0), "+2 %")
	assert_eq(NumberFormat.percent(0.25, "en"), "+0.25 %")
	assert_eq(NumberFormat.percent(0.0), "+0 %")
	assert_eq(NumberFormat.percent(12.0), "+12 %")
