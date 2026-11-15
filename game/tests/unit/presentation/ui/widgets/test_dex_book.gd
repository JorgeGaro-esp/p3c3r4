extends GutTest
## Los adornos de libro de la Enciclopedia.


func _book() -> DexBook:
	var book: DexBook = DexBook.new()
	book.page = Rect2i(10, 2, 40, 6)
	return book


func test_flipping_a_page_takes_a_moment_and_ends() -> void:
	var book: DexBook = _book()
	assert_false(book.is_flipping())
	book.flip()
	assert_true(book.is_flipping())
	book.update(DexBook.FLIP_SECONDS * 0.5, null)
	assert_true(book.is_flipping())
	book.update(DexBook.FLIP_SECONDS, null)
	assert_false(book.is_flipping())


func test_no_page_to_flip_means_no_animation() -> void:
	var book: DexBook = DexBook.new()
	book.flip()
	assert_false(book.is_flipping())


func test_reduced_motion_skips_the_flip() -> void:
	var previous: bool = Settings.data.reduce_motion
	Settings.data.reduce_motion = true
	var book: DexBook = _book()
	book.flip()
	assert_false(book.is_flipping())
	Settings.data.reduce_motion = previous


func test_the_book_never_takes_clicks() -> void:
	var book: DexBook = _book()
	book.is_shown = true
	assert_false(book.contains_cell(Vector2i(12, 3)))
	assert_false(book.handle_click(Vector2i(12, 3), false))
