extends GutTest
## Reparto del detalle de la Enciclopedia.


func test_wide_page_centers_the_photo_between_the_text_and_the_variants() -> void:
	var plan: DexLayout = DexLayout.compute(true, 40, 0, 6, 100)
	assert_true(plan.has_portrait)
	var photo_center: float = float(plan.portrait.position.x) + float(plan.portrait.size.x) / 2.0
	var page_center: float = 40.0 + 100.0 / 2.0
	assert_almost_eq(photo_center, page_center, 1.0)
	assert_lt(plan.name_rect.end.x, plan.portrait.position.x, "el texto queda a la izquierda")
	assert_gt(plan.checklist.position.x, plan.portrait.end.x, "las variantes, a la derecha")
	assert_lte(plan.checklist.end.x, 140)


func test_medium_page_puts_the_photo_on_the_right() -> void:
	var plan: DexLayout = DexLayout.compute(true, 40, 0, 6, 50)
	assert_true(plan.has_portrait)
	assert_gt(plan.portrait.position.x, plan.name_rect.position.x)
	assert_eq(plan.portrait.end.x, 40 + 50, "pegada al borde derecho")
	assert_eq(plan.checklist, Rect2i(), "sin lista aparte")
	assert_gt(plan.owned.size.x, 0, "las variantes van en una fila")


func test_narrow_page_has_no_photo() -> void:
	var plan: DexLayout = DexLayout.compute(true, 40, 0, 6, 30)
	assert_false(plan.has_portrait)


func test_other_tabs_never_have_a_photo() -> void:
	var plan: DexLayout = DexLayout.compute(false, 40, 0, 6, 120)
	assert_false(plan.has_portrait)
	assert_eq(plan.checklist, Rect2i())


func test_the_photo_is_tall_enough_for_a_three_row_fish_with_its_frame() -> void:
	var plan: DexLayout = DexLayout.compute(true, 40, 0, 6, 100)
	assert_gte(plan.portrait.size.y - 2, 3)


func test_a_wide_fish_widens_the_photo_but_the_text_keeps_its_column() -> void:
	var wanted: int = DexLayout.wanted_portrait_width(25)
	assert_gte(wanted, 29, "marco y margen de nado")
	var plan: DexLayout = DexLayout.compute(true, 40, 0, 6, 100, wanted)
	assert_eq(plan.portrait.size.x, wanted)
	assert_gte(plan.name_rect.size.x, DexLayout.MIN_TEXT_COLUMN)
	var narrow: DexLayout = DexLayout.compute(true, 40, 0, 6, 50, wanted)
	assert_gte(narrow.name_rect.size.x, DexLayout.MIN_TEXT_COLUMN)


func test_small_fish_keep_the_default_photo_width() -> void:
	assert_eq(DexLayout.wanted_portrait_width(10), DexLayout.PORTRAIT_WIDTH)
