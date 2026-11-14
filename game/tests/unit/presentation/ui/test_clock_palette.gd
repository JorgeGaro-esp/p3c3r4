extends GutTest
## El color del reloj: cálido por la mañana, frío de noche, continuo.


func test_the_morning_is_warmer_than_the_night() -> void:
	var morning: Color = ClockPalette.color_at(7.0)
	var night: Color = ClockPalette.color_at(23.0)
	assert_gt(morning.r, morning.b)
	assert_gt(night.b, night.r)


func test_the_colors_wrap_around_midnight() -> void:
	assert_eq(ClockPalette.color_at(0.0), ClockPalette.color_at(24.0))
	assert_eq(ClockPalette.color_at(-1.0), ClockPalette.color_at(23.0))


func test_the_gradient_has_no_jumps() -> void:
	var previous: Color = ClockPalette.color_at(0.0)
	for step: int in range(1, 241):
		var current: Color = ClockPalette.color_at(float(step) * 0.1)
		assert_lt(absf(current.r - previous.r) + absf(current.g - previous.g), 0.2)
		previous = current
