extends GutTest
## Pruebas de los unos y ceros flotantes.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 11


func _drift() -> BinaryDrift:
	var drift: BinaryDrift = BinaryDrift.new()
	drift.configure(Rect2(0.0, 2.0, 100.0, 10.0), 0.04, _rng)
	return drift


func test_configure_fills_the_area_by_density() -> void:
	var drift: BinaryDrift = _drift()
	assert_eq(drift.count(), 40)
	for glyph: BinaryDrift.Glyph in drift.glyphs():
		assert_true(Rect2(0.0, 2.0, 100.0, 10.0).grow(0.5).has_point(Vector2(glyph.x, glyph.y)))


func test_empty_area_has_no_glyphs() -> void:
	var drift: BinaryDrift = BinaryDrift.new()
	drift.configure(Rect2(), 0.5, _rng)
	assert_eq(drift.count(), 0)
	drift.update(1.0, _rng)
	assert_eq(drift.count(), 0)


func test_glyphs_rise_and_are_replaced_so_the_count_holds() -> void:
	var drift: BinaryDrift = _drift()
	for _step: int in range(600):
		drift.update(0.1, _rng)
	assert_eq(drift.count(), drift.target_count())
	for glyph: BinaryDrift.Glyph in drift.glyphs():
		assert_true(glyph.character in ["0", "1", BinaryDrift.DOT])
		assert_gte(glyph.y, 2.0)


func test_speed_scale_slows_the_rise() -> void:
	var fast: BinaryDrift = _drift()
	var slow: BinaryDrift = _drift()
	slow.speed_scale = 0.0
	var start: float = slow.glyphs()[0].y
	slow.update(1.0, _rng)
	assert_almost_eq(slow.glyphs()[0].y, start, 0.0001)
	var before: float = fast.glyphs()[0].y
	fast.update(1.0, _rng)
	assert_lt(fast.glyphs()[0].y, before)


func test_fade_is_zero_at_the_ends_and_peaks_in_the_middle() -> void:
	var glyph: BinaryDrift.Glyph = BinaryDrift.Glyph.new()
	glyph.life = 10.0
	glyph.age = 0.0
	assert_almost_eq(BinaryDrift.fade(glyph), 0.0, 0.001)
	glyph.age = 5.0
	assert_almost_eq(BinaryDrift.fade(glyph), 1.0, 0.001)
	glyph.age = 10.0
	assert_almost_eq(BinaryDrift.fade(glyph), 0.0, 0.001)


func test_trail_only_appears_when_the_cursor_moves() -> void:
	var drift: BinaryDrift = _drift()
	drift.move_cursor(Vector2(10.0, 5.0), _rng)
	assert_eq(drift.trail_count(), 0)
	drift.move_cursor(Vector2(10.0, 5.0), _rng)
	assert_eq(drift.trail_count(), 0)
	drift.move_cursor(Vector2(20.0, 5.0), _rng)
	assert_gt(drift.trail_count(), 0)


func test_trail_fades_away_and_is_capped() -> void:
	var drift: BinaryDrift = _drift()
	drift.move_cursor(Vector2(0.0, 5.0), _rng)
	drift.move_cursor(Vector2(90.0, 5.0), _rng)
	assert_lte(drift.trail_count(), BinaryDrift.MAX_TRAIL)
	for _step: int in range(30):
		drift.update(0.1, _rng)
	assert_eq(drift.trail_count(), 0)


func test_losing_the_cursor_does_not_draw_a_line_from_the_old_spot() -> void:
	var drift: BinaryDrift = _drift()
	drift.move_cursor(Vector2(0.0, 5.0), _rng)
	drift.lose_cursor()
	drift.move_cursor(Vector2(80.0, 5.0), _rng)
	assert_eq(drift.trail_count(), 0)


func test_clear_trail_empties_it() -> void:
	var drift: BinaryDrift = _drift()
	drift.move_cursor(Vector2(0.0, 5.0), _rng)
	drift.move_cursor(Vector2(30.0, 5.0), _rng)
	assert_gt(drift.trail_count(), 0)
	drift.clear_trail()
	assert_eq(drift.trail_count(), 0)


func test_background_mixes_sizes_brightness_and_dots() -> void:
	var drift: BinaryDrift = BinaryDrift.new()
	drift.configure(Rect2(0.0, 0.0, 200.0, 20.0), 0.07, _rng)
	var dots: int = 0
	var small: int = 0
	var big: int = 0
	for glyph: BinaryDrift.Glyph in drift.glyphs():
		assert_between(glyph.bright, 0.35, 1.0)
		if glyph.is_dot:
			dots += 1
		elif glyph.scale < 0.9:
			small += 1
		elif glyph.scale > 1.1:
			big += 1
	assert_gt(dots, 0)
	assert_gt(small, big)
	assert_gt(big, 0)
