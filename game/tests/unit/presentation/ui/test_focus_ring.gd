extends GutTest
## Pruebas del orden de foco del teclado.


func _ring(flags: Array[bool]) -> FocusRing:
	var ring: FocusRing = FocusRing.new()
	ring.rebuild(flags)
	return ring


func test_focus_first_skips_disabled_items() -> void:
	var ring: FocusRing = _ring([false, true, true])
	assert_eq(ring.focus_first(), 1)


func test_move_forward_wraps_around() -> void:
	var ring: FocusRing = _ring([true, true, true])
	ring.focus_first()
	assert_eq(ring.move(1), 1)
	assert_eq(ring.move(1), 2)
	assert_eq(ring.move(1), 0)


func test_move_backward_wraps_and_skips_disabled() -> void:
	var ring: FocusRing = _ring([true, false, true])
	ring.focus_first()
	assert_eq(ring.move(-1), 2)
	assert_eq(ring.move(-1), 0)


func test_backward_from_nothing_starts_at_the_last_item() -> void:
	var ring: FocusRing = _ring([true, true, false])
	assert_eq(ring.move(-1), 1)


func test_nothing_enabled_means_no_focus() -> void:
	var ring: FocusRing = _ring([false, false])
	assert_eq(ring.focus_first(), -1)
	assert_eq(ring.move(1), -1)
	assert_eq(_ring([]).move(1), -1)


func test_a_single_item_keeps_the_focus() -> void:
	var ring: FocusRing = _ring([false, true])
	ring.focus_first()
	assert_eq(ring.move(1), 1)
	assert_eq(ring.move(-1), 1)


func test_rebuild_drops_focus_when_the_item_is_disabled() -> void:
	var ring: FocusRing = _ring([true, true])
	ring.set_current(1)
	ring.rebuild([true, false])
	assert_eq(ring.current, -1)


func test_rebuild_keeps_focus_when_still_valid() -> void:
	var ring: FocusRing = _ring([true, true, true])
	ring.set_current(2)
	ring.rebuild([true, true, true])
	assert_eq(ring.current, 2)


func test_set_current_rejects_invalid_indexes() -> void:
	var ring: FocusRing = _ring([true, false])
	ring.set_current(1)
	assert_eq(ring.current, -1)
	ring.set_current(7)
	assert_eq(ring.current, -1)
	ring.set_current(0)
	assert_eq(ring.current, 0)
	assert_eq(ring.enabled_count(), 1)
