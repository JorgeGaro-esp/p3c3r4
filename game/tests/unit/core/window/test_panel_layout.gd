extends GutTest
## Pruebas del reparto de la ventana entre pecera, barra lateral y panel.

const REPLACE: SettingsData.PanelMode = SettingsData.PanelMode.REPLACE
const GROW_UP: SettingsData.PanelMode = SettingsData.PanelMode.GROW_UP


func test_closed_panel_leaves_tank_and_sidebar_side_by_side() -> void:
	for mode: SettingsData.PanelMode in [REPLACE, GROW_UP]:
		var layout: PanelLayout = PanelLayout.compute(120, 12, 12, mode, false)
		assert_false(layout.panel_rect.has_area())
		assert_eq(layout.sidebar_rect.size.x, PanelLayout.SIDEBAR_WIDTH)
		assert_eq(layout.tank_rect.size.x + layout.sidebar_rect.size.x, 120)
		assert_eq(layout.tank_rect.size.y, 12)


func test_replace_panel_covers_the_tank() -> void:
	var layout: PanelLayout = PanelLayout.compute(120, 12, 12, REPLACE, true)
	assert_eq(layout.panel_rect, layout.tank_rect)
	assert_eq(layout.sidebar_rect.position.x, 100)


func test_grow_up_panel_goes_above_the_tank() -> void:
	var layout: PanelLayout = PanelLayout.compute(120, 26, 12, GROW_UP, true)
	assert_eq(layout.panel_rect, Rect2i(0, 0, 120, 14))
	assert_eq(layout.tank_rect, Rect2i(0, 14, 100, 12), "la pecera conserva su altura")
	assert_eq(layout.sidebar_rect, Rect2i(100, 14, 20, 12))
	assert_false(layout.panel_rect.intersects(layout.tank_rect))
	assert_false(layout.panel_rect.intersects(layout.sidebar_rect))


func test_grow_up_without_room_waits_for_the_window_to_grow() -> void:
	var layout: PanelLayout = PanelLayout.compute(120, 12, 12, GROW_UP, true)
	assert_false(layout.panel_rect.has_area(), "aún no hay filas nuevas: no se dibuja el panel")
	assert_eq(layout.tank_rect.size.y, 12)


func test_total_rows_only_grows_in_grow_up_mode_with_an_open_panel() -> void:
	assert_eq(PanelLayout.total_rows(12, REPLACE, true, 60), 12)
	assert_eq(PanelLayout.total_rows(12, GROW_UP, false, 60), 12)
	assert_eq(PanelLayout.total_rows(12, GROW_UP, true, 60), 12 + PanelLayout.GROW_ROWS)


func test_total_rows_is_limited_by_the_screen() -> void:
	assert_eq(PanelLayout.total_rows(12, GROW_UP, true, 22), 22)
	assert_eq(PanelLayout.total_rows(12, GROW_UP, true, 16), 12, "no cabe: se queda como REPLACE")
	assert_eq(PanelLayout.total_rows(24, GROW_UP, true, 20), 24)


func test_tiny_window_never_makes_negative_rectangles() -> void:
	var layout: PanelLayout = PanelLayout.compute(10, 12, 12, REPLACE, true)
	assert_gte(layout.tank_rect.size.x, 0)
	assert_eq(layout.sidebar_rect.size.x, 10)


func test_effective_mode_falls_back_to_replace_when_the_window_cannot_grow() -> void:
	assert_eq(PanelLayout.effective_mode(GROW_UP, 12, 12, true), REPLACE)
	assert_eq(PanelLayout.effective_mode(GROW_UP, 12, 26, true), GROW_UP)
	assert_eq(PanelLayout.effective_mode(GROW_UP, 12, 12, false), GROW_UP)
	assert_eq(PanelLayout.effective_mode(REPLACE, 12, 12, true), REPLACE)
