extends GutTest
## Pruebas de la visita de un pájaro a la superficie.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 5


func _visit(first_wait: float = 10.0) -> BirdVisit:
	var visit: BirdVisit = BirdVisit.new()
	visit.configure(0.0, 240.0, _rng, first_wait)
	return visit


func test_starts_waiting_with_nothing_visible() -> void:
	var visit: BirdVisit = _visit()
	assert_eq(visit.phase, BirdVisit.Phase.WAITING)
	assert_false(visit.is_visible())
	assert_almost_eq(visit.seconds_until_visit(), 10.0, 0.001)


func test_after_the_wait_the_bird_arrives_flying() -> void:
	var visit: BirdVisit = _visit()
	visit.step(10.5, _rng)
	assert_eq(visit.phase, BirdVisit.Phase.ARRIVING)
	assert_true(visit.is_visible())
	assert_true(visit.is_flying())


func test_full_visit_goes_through_every_phase_and_returns_to_waiting() -> void:
	var visit: BirdVisit = _visit(1.0)
	var seen: Dictionary = {}
	for _step: int in range(4000):
		visit.step(0.1, _rng)
		seen[visit.phase] = true
		if seen.size() == 4 and visit.phase == BirdVisit.Phase.WAITING:
			break
	assert_eq(seen.size(), 4)
	assert_eq(visit.phase, BirdVisit.Phase.WAITING)
	assert_gte(visit.seconds_until_visit(), BirdVisit.MIN_WAIT)
	assert_lte(visit.seconds_until_visit(), BirdVisit.MAX_WAIT)


func test_perches_inside_the_world_and_stays_a_while() -> void:
	var visit: BirdVisit = _visit()
	visit.call_bird(_rng)
	while visit.phase == BirdVisit.Phase.ARRIVING:
		visit.step(0.1, _rng)
	assert_eq(visit.phase, BirdVisit.Phase.PERCHED)
	assert_gte(visit.x, BirdVisit.EDGE_MARGIN - 0.01)
	assert_lte(visit.x, 240.0 - BirdVisit.EDGE_MARGIN + 0.01)
	assert_false(visit.is_flying())
	var perched_for: float = 0.0
	while visit.phase == BirdVisit.Phase.PERCHED:
		visit.step(0.1, _rng)
		perched_for += 0.1
	assert_gte(perched_for, BirdVisit.MIN_PERCH - 0.2)
	assert_lte(perched_for, BirdVisit.MAX_PERCH + 0.2)


func test_flies_in_the_direction_it_faces() -> void:
	var visit: BirdVisit = _visit()
	visit.call_bird(_rng)
	var before: float = visit.x
	visit.step(0.5, _rng)
	assert_eq(signf(visit.x - before), float(visit.direction))
