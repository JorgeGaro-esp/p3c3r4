extends GutTest
## El ciclo del día: franjas, oscuridad suave y efecto sobre la producción.


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


func test_nocturnal_species_gain_at_night_and_lose_by_day() -> void:
	var night: float = DayCycle.activity_factor(SpeciesDef.Activity.NOCTURNAL, 1.0, 0.0)
	var day: float = DayCycle.activity_factor(SpeciesDef.Activity.NOCTURNAL, 0.0, 0.0)
	assert_almost_eq(night, 1.0 + DayCycle.NIGHT_EFFECT, 0.0001)
	assert_almost_eq(day, 1.0 - DayCycle.NIGHT_EFFECT, 0.0001)


func test_diurnal_species_are_the_mirror_image() -> void:
	var night: float = DayCycle.activity_factor(SpeciesDef.Activity.DIURNAL, 1.0, 0.0)
	var day: float = DayCycle.activity_factor(SpeciesDef.Activity.DIURNAL, 0.0, 0.0)
	assert_almost_eq(night, 1.0 - DayCycle.NIGHT_EFFECT, 0.0001)
	assert_almost_eq(day, 1.0 + DayCycle.NIGHT_EFFECT, 0.0001)


func test_neutral_species_ignore_the_time() -> void:
	for dark: float in [0.0, 0.3, 0.7, 1.0]:
		assert_eq(DayCycle.activity_factor(SpeciesDef.Activity.NEUTRAL, dark, 0.0), 1.0)


func test_twilight_is_halfway() -> void:
	assert_almost_eq(DayCycle.activity_factor(SpeciesDef.Activity.NOCTURNAL, 0.5, 0.0), 1.0, 0.0001)


func test_the_lamp_only_removes_the_penalty() -> void:
	var diurnal_night: float = DayCycle.activity_factor(SpeciesDef.Activity.DIURNAL, 1.0, 1.0)
	var nocturnal_day: float = DayCycle.activity_factor(SpeciesDef.Activity.NOCTURNAL, 0.0, 1.0)
	var nocturnal_night: float = DayCycle.activity_factor(SpeciesDef.Activity.NOCTURNAL, 1.0, 1.0)
	assert_eq(diurnal_night, 1.0)
	assert_eq(nocturnal_day, 1.0)
	assert_almost_eq(nocturnal_night, 1.0 + DayCycle.NIGHT_EFFECT, 0.0001)


func test_a_half_lamp_halves_the_penalty() -> void:
	var factor: float = DayCycle.activity_factor(SpeciesDef.Activity.DIURNAL, 1.0, 0.5)
	assert_almost_eq(factor, 1.0 - DayCycle.NIGHT_EFFECT * 0.5, 0.0001)


func test_the_effect_never_goes_beyond_its_limit() -> void:
	for activity: SpeciesDef.Activity in [
		SpeciesDef.Activity.NEUTRAL, SpeciesDef.Activity.DIURNAL, SpeciesDef.Activity.NOCTURNAL
	]:
		for hour: int in range(0, 24):
			var factor: float = DayCycle.activity_factor(
				activity, DayCycle.darkness(float(hour)), 0.0
			)
			assert_between(factor, 1.0 - DayCycle.NIGHT_EFFECT, 1.0 + DayCycle.NIGHT_EFFECT)
