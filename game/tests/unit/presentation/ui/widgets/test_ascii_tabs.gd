extends GutTest
## Pestañas con solo algunas a la vista.


func _tabs() -> AsciiTabs:
	var tabs: AsciiTabs = AsciiTabs.new()
	tabs.set_titles(PackedStringArray(["A", "B", "C", "D"]))
	tabs.rect = Rect2i(0, 0, 40, 1)
	return tabs


func test_all_tabs_are_shown_by_default() -> void:
	assert_eq(_tabs().shown_tabs(), PackedInt32Array([0, 1, 2, 3]))


func test_arrows_stay_inside_the_visible_tabs() -> void:
	var tabs: AsciiTabs = _tabs()
	tabs.set_visible_tabs(PackedInt32Array([1, 3]))
	tabs.select(1)
	var right: InputEventKey = InputEventKey.new()
	right.keycode = KEY_RIGHT
	tabs.handle_key(right)
	assert_eq(tabs.selected, 3)
	tabs.handle_key(right)
	assert_eq(tabs.selected, 3, "no pasa de la última visible")
	var left: InputEventKey = InputEventKey.new()
	left.keycode = KEY_LEFT
	tabs.handle_key(left)
	assert_eq(tabs.selected, 1)
	tabs.handle_key(left)
	assert_eq(tabs.selected, 1)


func test_clicks_only_reach_the_visible_tabs() -> void:
	var tabs: AsciiTabs = _tabs()
	tabs.set_visible_tabs(PackedInt32Array([2]))
	tabs.select(2)
	tabs.handle_click(Vector2i(1, 0), false)
	assert_eq(tabs.selected, 2)
