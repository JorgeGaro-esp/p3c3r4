extends GutTest
## Pruebas de la selección y el desplazamiento de listas.


func _model(count: int, rows: int) -> ListModel:
	var model: ListModel = ListModel.new()
	model.configure(count, rows)
	return model


func test_starts_with_the_first_item_selected() -> void:
	assert_eq(_model(5, 3).selected, 0)
	assert_eq(_model(0, 3).selected, -1)


func test_move_scrolls_to_keep_the_selection_visible() -> void:
	var model: ListModel = _model(10, 3)
	model.move(3)
	assert_eq(model.selected, 3)
	assert_eq(model.scroll, 1)
	model.move(-3)
	assert_eq(model.selected, 0)
	assert_eq(model.scroll, 0)


func test_move_does_not_wrap_or_leave_the_list() -> void:
	var model: ListModel = _model(4, 3)
	model.move(-5)
	assert_eq(model.selected, 0)
	model.move(99)
	assert_eq(model.selected, 3)
	assert_eq(model.scroll, 1)


func test_page_moves_almost_a_screen() -> void:
	var model: ListModel = _model(30, 8)
	model.page(1)
	assert_eq(model.selected, 7)
	model.page(1)
	assert_eq(model.selected, 14)
	model.page(-1)
	assert_eq(model.selected, 7)


func test_scroll_by_is_clamped_and_keeps_selection() -> void:
	var model: ListModel = _model(10, 4)
	model.scroll_by(99)
	assert_eq(model.scroll, 6)
	assert_eq(model.selected, 0)
	model.scroll_by(-99)
	assert_eq(model.scroll, 0)


func test_index_at_row_maps_visible_rows() -> void:
	var model: ListModel = _model(10, 4)
	model.scroll_by(3)
	assert_eq(model.index_at_row(0), 3)
	assert_eq(model.index_at_row(3), 6)
	assert_eq(model.index_at_row(4), -1)
	assert_eq(model.index_at_row(-1), -1)
	var short: ListModel = _model(2, 5)
	assert_eq(short.index_at_row(1), 1)
	assert_eq(short.index_at_row(2), -1)


func test_configure_corrects_selection_and_scroll_when_the_list_shrinks() -> void:
	var model: ListModel = _model(20, 5)
	model.select(18)
	model.configure(6, 5)
	assert_eq(model.selected, 5)
	assert_lte(model.scroll, model.max_scroll())
	model.configure(0, 5)
	assert_eq(model.selected, -1)
	assert_eq(model.scroll, 0)


func test_select_on_an_empty_list_does_nothing() -> void:
	var model: ListModel = _model(0, 3)
	model.select(2)
	model.move(1)
	assert_eq(model.selected, -1)
