extends GutTest
## El ciclo del día: franjas y oscuridad suave.


func test_the_hours_fall_into_four_phases() -> void:
	assert_eq(DayCycle.phase_at(3.0), DayCycle.Phase.NIGHT)
	assert_eq(DayCycle.phase_at(7.0), DayCycle.Phase.DAWN)
	assert_eq(DayCycle.phase_at(12.0), DayCycle.Phase.DAY)
	assert_eq(DayCycle.phase_at(19.0), DayCycle.Phase.DUSK)
	assert_eq(DayCycle.phase_at(23.0), DayCycle.Phase.NIGHT)


func test_phase_boundaries() -> void:
	assert_eq(DayCycle.phase_at(6.0), DayCycle.Phase.DAWN)
	assert_eq(DayCycle.phase_at(8.0), DayCycle.Phase.DAY)
	assert_eq(DayCycle.phase_at(18.0), DayCycle.Phase.DUSK)
	assert_eq(DayCycle.phase_at(21.0), DayCycle.Phase.NIGHT)


func test_hours_outside_the_range_wrap_around() -> void:
	assert_eq(DayCycle.normalize(25.5), 1.5)
	assert_eq(DayCycle.normalize(-1.0), 23.0)
	assert_eq(DayCycle.phase_at(36.0), DayCycle.Phase.DAY)


func test_darkness_is_full_at_night_and_zero_at_noon() -> void:
	assert_eq(DayCycle.darkness(0.0), 1.0)
	assert_eq(DayCycle.darkness(5.9), 1.0)
	assert_eq(DayCycle.darkness(12.0), 0.0)
	assert_eq(DayCycle.darkness(21.0), 1.0)


func test_darkness_changes_smoothly_through_dusk_and_dawn() -> void:
	assert_almost_eq(DayCycle.darkness(19.5), 0.5, 0.001)
	assert_almost_eq(DayCycle.darkness(7.0), 0.5, 0.001)
	var previous: float = DayCycle.darkness(18.0)
	for step: int in range(1, 31):
		var value: float = DayCycle.darkness(18.0 + float(step) * 0.1)
		assert_true(value >= previous, "el atardecer solo oscurece")
		assert_lt(value - previous, 0.1, "sin saltos bruscos")
		previous = value


func test_darkness_has_no_jump_at_the_phase_edges() -> void:
	assert_almost_eq(DayCycle.darkness(5.999), DayCycle.darkness(6.0), 0.01)
	assert_almost_eq(DayCycle.darkness(7.999), DayCycle.darkness(8.0), 0.01)
	assert_almost_eq(DayCycle.darkness(17.999), DayCycle.darkness(18.0), 0.01)
	assert_almost_eq(DayCycle.darkness(20.999), DayCycle.darkness(21.0), 0.01)
