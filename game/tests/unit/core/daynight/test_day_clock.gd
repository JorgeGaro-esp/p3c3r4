extends GutTest
## Los relojes: el del sistema y el fijo de los tests.


func test_the_fixed_clock_returns_its_hour() -> void:
	var clock: FixedDayClock = FixedDayClock.new(21.5)
	assert_eq(clock.hour(), 21.5)


func test_the_fixed_clock_can_be_moved() -> void:
	var clock: FixedDayClock = FixedDayClock.new(10.0)
	clock.value = 23.0
	assert_eq(clock.hour(), 23.0)


func test_the_offset_wraps_past_midnight() -> void:
	var clock: FixedDayClock = FixedDayClock.new(22.0)
	clock.offset_hours = 5.0
	assert_eq(clock.hour(), 3.0)


func test_the_system_clock_stays_inside_a_day() -> void:
	var clock: DayClock = DayClock.new()
	var hour: float = clock.hour()
	assert_between(hour, 0.0, 24.0)
	assert_ne(hour, 24.0)
