extends GutTest
## Pruebas de la geometría de la franja con distintas escalas y monitores.

## Altura de celda aproximada para la fuente base a 100 %, 125 % y 150 %.
const CELL_HEIGHTS: Array[float] = [19.82, 24.44, 30.3]
const SCALES: Array[int] = [96, 120, 144]
## Área útil de un monitor 1920×1080 con la barra de tareas (40 px) abajo.
const USABLE: Rect2i = Rect2i(0, 0, 1920, 1040)


func test_scale_from_dpi_matches_windows_percentages() -> void:
	assert_eq(StripLayout.scale_from_dpi(96), 1.0)
	assert_eq(StripLayout.scale_from_dpi(120), 1.25)
	assert_eq(StripLayout.scale_from_dpi(144), 1.5)
	assert_eq(StripLayout.scale_from_dpi(192), 2.0)


func test_scale_from_dpi_rejects_impossible_values() -> void:
	assert_eq(StripLayout.scale_from_dpi(0), 1.0)
	assert_eq(StripLayout.scale_from_dpi(-5), 1.0)
	assert_eq(StripLayout.scale_from_dpi(48), 1.0)
	assert_eq(StripLayout.scale_from_dpi(100000), StripLayout.MAX_SCALE)


func test_scaled_font_grows_with_scale() -> void:
	assert_eq(StripLayout.scaled_font_px(17, 1.0), 17)
	assert_eq(StripLayout.scaled_font_px(17, 1.25), 21)
	assert_eq(StripLayout.scaled_font_px(17, 1.5), 26)


func test_window_sits_on_the_bottom_edge_without_covering_the_taskbar() -> void:
	for cell: float in CELL_HEIGHTS:
		var rect: Rect2i = StripLayout.window_rect(USABLE, 12, cell)
		assert_eq(rect.end.y, USABLE.end.y, "el borde inferior coincide con el área útil")
		assert_eq(rect.size.x, USABLE.size.x, "ocupa todo el ancho")
		assert_eq(rect.position.x, USABLE.position.x)
		assert_lte(rect.end.y, 1040, "no entra en la barra de tareas")


func test_height_gives_exactly_the_requested_rows() -> void:
	for cell: float in CELL_HEIGHTS:
		for rows: int in range(SettingsData.MIN_STRIP_ROWS, SettingsData.MAX_STRIP_ROWS + 1):
			var height: int = StripLayout.height_for_rows(rows, cell)
			assert_eq(int(float(height) / cell), rows, "celda %s, filas %d" % [cell, rows])


func test_strip_is_proportional_at_each_windows_scale() -> void:
	var heights: Array[int] = []
	for index: int in range(SCALES.size()):
		var scale: float = StripLayout.scale_from_dpi(SCALES[index])
		var rect: Rect2i = StripLayout.window_rect(USABLE, 12, CELL_HEIGHTS[index])
		heights.append(rect.size.y)
		assert_almost_eq(float(rect.size.y) / scale, 240.0, 14.0, "escala %s" % scale)
	assert_lt(heights[0], heights[1])
	assert_lt(heights[1], heights[2])


func test_window_is_clamped_to_a_small_screen() -> void:
	var small: Rect2i = Rect2i(0, 0, 1280, 300)
	var rect: Rect2i = StripLayout.window_rect(small, 24, 19.82)
	assert_lte(rect.size.y, 300)
	assert_eq(rect.end.y, 300)


func test_window_follows_a_monitor_with_negative_coordinates() -> void:
	var second: Rect2i = Rect2i(-1920, -120, 1920, 1080)
	var rect: Rect2i = StripLayout.window_rect(second, 12, 19.82)
	assert_eq(rect.position.x, -1920)
	assert_eq(rect.end.y, -120 + 1080)


func test_taskbar_on_top_or_side_is_respected() -> void:
	var usable_top: Rect2i = Rect2i(0, 40, 1920, 1040)
	assert_eq(StripLayout.window_rect(usable_top, 12, 19.82).end.y, 1080)
	var usable_left: Rect2i = Rect2i(64, 0, 1856, 1080)
	var rect: Rect2i = StripLayout.window_rect(usable_left, 12, 19.82)
	assert_eq(rect.position.x, 64)
	assert_eq(rect.size.x, 1856)


func test_resolve_screen_uses_primary_by_default() -> void:
	assert_eq(StripLayout.resolve_screen(SettingsData.PRIMARY_SCREEN, 2, 1), 1)


func test_resolve_screen_keeps_a_valid_choice() -> void:
	assert_eq(StripLayout.resolve_screen(0, 2, 1), 0)


func test_resolve_screen_falls_back_when_the_monitor_disappears() -> void:
	assert_eq(StripLayout.resolve_screen(3, 2, 0), 0)


func test_fit_rows_handles_degenerate_cells() -> void:
	assert_eq(StripLayout.fit_rows(12, 1000, 0.0), 12)
	assert_eq(StripLayout.fit_rows(12, 5, 20.0), 1)


func test_cycle_screen_walks_primary_then_each_monitor_and_wraps() -> void:
	var primary: int = SettingsData.PRIMARY_SCREEN
	assert_eq(StripLayout.cycle_screen(primary, 1, 2), 0)
	assert_eq(StripLayout.cycle_screen(0, 1, 2), 1)
	assert_eq(StripLayout.cycle_screen(1, 1, 2), primary)
	assert_eq(StripLayout.cycle_screen(primary, -1, 2), 1)
	assert_eq(StripLayout.cycle_screen(0, -1, 2), primary)


func test_cycle_screen_with_one_monitor_and_stale_choice() -> void:
	var primary: int = SettingsData.PRIMARY_SCREEN
	assert_eq(StripLayout.cycle_screen(primary, 1, 1), 0)
	assert_eq(StripLayout.cycle_screen(0, 1, 1), primary)
	assert_eq(
		StripLayout.cycle_screen(5, 1, 1), 0, "un monitor que ya no existe cuenta como el principal"
	)
	assert_eq(StripLayout.cycle_screen(primary, 1, 0), primary)
