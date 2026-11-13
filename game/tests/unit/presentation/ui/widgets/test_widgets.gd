extends GutTest
## Pruebas de la lógica de los componentes (la parte que no depende de dibujar).


func _key(code: Key, is_echo: bool = false) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = is_echo
	return event


func _list(count: int, rows: int) -> AsciiList:
	var list: AsciiList = AsciiList.new()
	var names: PackedStringArray = PackedStringArray()
	for index: int in range(count):
		names.append("item %d" % index)
	list.set_items(names, PackedStringArray())
	list.set_rect(Rect2i(0, 0, 20, rows))
	return list


func test_button_activates_with_click_enter_and_space() -> void:
	var button: AsciiButton = AsciiButton.new()
	watch_signals(button)
	button.handle_click(Vector2i.ZERO, false)
	assert_signal_emit_count(button, "activated", 1)
	assert_true(button.handle_key(_key(KEY_ENTER)))
	assert_true(button.handle_key(_key(KEY_SPACE)))
	assert_signal_emit_count(button, "activated", 3)


func test_button_ignores_key_repeat_and_other_keys() -> void:
	var button: AsciiButton = AsciiButton.new()
	watch_signals(button)
	assert_false(button.handle_key(_key(KEY_ENTER, true)))
	assert_false(button.handle_key(_key(KEY_A)))
	assert_signal_not_emitted(button, "activated")


func test_disabled_button_does_nothing_but_swallows_the_click() -> void:
	var button: AsciiButton = AsciiButton.new()
	button.is_enabled = false
	watch_signals(button)
	assert_true(button.handle_click(Vector2i.ZERO, false))
	assert_false(button.handle_key(_key(KEY_ENTER)))
	assert_false(button.activate())
	assert_signal_not_emitted(button, "activated")
	assert_false(button.can_focus())


func test_hidden_widget_is_not_interactive_nor_hit() -> void:
	var button: AsciiButton = AsciiButton.new()
	button.rect = Rect2i(2, 2, 4, 1)
	assert_true(button.contains_cell(Vector2i(3, 2)))
	button.is_shown = false
	assert_false(button.contains_cell(Vector2i(3, 2)))
	assert_false(button.is_interactive())


func test_list_keys_move_selection_and_report_it() -> void:
	var list: AsciiList = _list(10, 4)
	watch_signals(list)
	list.handle_key(_key(KEY_DOWN))
	list.handle_key(_key(KEY_DOWN))
	assert_eq(list.selected_index(), 2)
	list.handle_key(_key(KEY_END))
	assert_eq(list.selected_index(), 9)
	list.handle_key(_key(KEY_HOME))
	assert_eq(list.selected_index(), 0)
	assert_signal_emit_count(list, "selection_changed", 4)


func test_list_does_not_report_a_selection_that_did_not_change() -> void:
	var list: AsciiList = _list(3, 3)
	watch_signals(list)
	list.handle_key(_key(KEY_UP))
	assert_signal_not_emitted(list, "selection_changed")


func test_list_enter_chooses_and_unknown_keys_are_not_consumed() -> void:
	var list: AsciiList = _list(3, 3)
	watch_signals(list)
	assert_true(list.handle_key(_key(KEY_ENTER)))
	assert_signal_emitted_with_parameters(list, "chosen", [0])
	assert_false(list.handle_key(_key(KEY_A)))


func test_list_click_selects_the_row_and_double_click_chooses() -> void:
	var list: AsciiList = _list(10, 4)
	list.rect = Rect2i(5, 3, 20, 4)
	watch_signals(list)
	list.handle_click(Vector2i(8, 5), false)
	assert_eq(list.selected_index(), 2)
	assert_signal_not_emitted(list, "chosen")
	list.handle_click(Vector2i(8, 5), true)
	assert_signal_emitted_with_parameters(list, "chosen", [2])


func test_list_click_below_the_last_item_is_swallowed_without_changes() -> void:
	var list: AsciiList = _list(2, 5)
	assert_true(list.handle_click(Vector2i(1, 4), false))
	assert_eq(list.selected_index(), 0)


func test_list_wheel_scrolls_without_moving_selection() -> void:
	var list: AsciiList = _list(10, 4)
	list.handle_wheel(Vector2i.ZERO, 1)
	list.handle_wheel(Vector2i.ZERO, 1)
	assert_eq(list.model.scroll, 2)
	assert_eq(list.selected_index(), 0)
	list.handle_wheel(Vector2i.ZERO, -1)
	assert_eq(list.model.scroll, 1)


func test_list_set_items_resets_selection_and_scroll() -> void:
	var list: AsciiList = _list(10, 4)
	list.handle_key(_key(KEY_END))
	list.set_items(PackedStringArray(["a", "b"]), PackedStringArray())
	assert_eq(list.selected_index(), 0)
	assert_eq(list.model.scroll, 0)


func test_tabs_change_with_keys_and_clicks() -> void:
	var tabs: AsciiTabs = AsciiTabs.new()
	tabs.set_titles(PackedStringArray(["Peces", "Equipo", "Más"]))
	tabs.rect = Rect2i(10, 0, 40, 1)
	watch_signals(tabs)
	tabs.handle_key(_key(KEY_RIGHT))
	assert_eq(tabs.selected, 1)
	tabs.handle_key(_key(KEY_RIGHT))
	tabs.handle_key(_key(KEY_RIGHT))
	assert_eq(tabs.selected, 2, "no da la vuelta")
	tabs.handle_click(Vector2i(11, 0), false)
	assert_eq(tabs.selected, 0, "una pestaña activa es [Peces]: 7 caracteres desde la 10")
	assert_signal_emit_count(tabs, "tab_changed", 3)


func test_tabs_click_past_the_last_tab_changes_nothing() -> void:
	var tabs: AsciiTabs = AsciiTabs.new()
	tabs.set_titles(PackedStringArray(["A", "B"]))
	tabs.rect = Rect2i(0, 0, 30, 1)
	tabs.handle_click(Vector2i(25, 0), false)
	assert_eq(tabs.selected, 0)


func test_toast_shows_then_fades_out_by_itself() -> void:
	var toast: AsciiToast = AsciiToast.new()
	assert_false(toast.is_active())
	toast.show_message("¡Hola!", 1.0)
	assert_true(toast.is_active())
	toast.update(0.6, null)
	assert_true(toast.is_active())
	toast.update(0.6, null)
	assert_false(toast.is_active())


func test_frame_swallows_clicks_and_wheel() -> void:
	var frame: AsciiFrame = AsciiFrame.new()
	assert_true(frame.handle_click(Vector2i.ZERO, false))
	assert_true(frame.handle_wheel(Vector2i.ZERO, 1))
