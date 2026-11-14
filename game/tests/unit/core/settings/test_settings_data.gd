extends GutTest
## Pruebas de los ajustes: valores por defecto de las decisiones y validación.


func test_defaults_follow_decisions() -> void:
	var settings: SettingsData = SettingsData.new()
	assert_eq(settings.strip_rows, 12, "P01: 12 filas por defecto")
	assert_eq(settings.screen_index, SettingsData.PRIMARY_SCREEN, "P10: monitor principal")
	assert_false(settings.launch_with_windows, "P09: arranque con Windows desactivado")
	assert_true(settings.always_on_top)
	assert_eq(settings.fps_limit, 30)


func test_round_trip_keeps_every_field() -> void:
	var original: SettingsData = SettingsData.new()
	original.strip_rows = 16
	original.screen_index = 2
	original.always_on_top = false
	original.fps_limit = 60
	original.launch_with_windows = true
	original.panel_mode = SettingsData.PanelMode.GROW_UP
	var restored: SettingsData = SettingsData.from_json(original.to_json())
	assert_eq(restored.to_dict(), original.to_dict())


func test_garbage_text_gives_defaults() -> void:
	for text: String in ["", "no es json", "[1, 2]", "42", "null", '{"strip_rows": ']:
		assert_eq(
			SettingsData.from_json(text).to_dict(), SettingsData.new().to_dict(), "texto: %s" % text
		)


func test_oversized_text_gives_defaults() -> void:
	var text: String = '{"strip_rows": 20}'.rpad(SettingsData.MAX_FILE_BYTES + 1, " ")
	assert_eq(SettingsData.from_json(text).strip_rows, SettingsData.DEFAULT_STRIP_ROWS)


func test_out_of_range_values_are_clamped() -> void:
	var low: SettingsData = SettingsData.from_dict({"strip_rows": 1, "screen_index": -50})
	assert_eq(low.strip_rows, SettingsData.MIN_STRIP_ROWS)
	assert_eq(low.screen_index, SettingsData.PRIMARY_SCREEN)
	var high: SettingsData = SettingsData.from_dict({"strip_rows": 9999, "screen_index": 9999})
	assert_eq(high.strip_rows, SettingsData.MAX_STRIP_ROWS)
	assert_eq(high.screen_index, SettingsData.MAX_SCREEN_INDEX)


func test_wrong_types_fall_back_to_defaults() -> void:
	var settings: SettingsData = (
		SettingsData
		. from_dict(
			{
				"strip_rows": "veinte",
				"screen_index": [1],
				"always_on_top": 1,
				"fps_limit": null,
				"launch_with_windows": "true",
				"panel_mode": {},
			}
		)
	)
	assert_eq(settings.to_dict(), SettingsData.new().to_dict())


func test_non_finite_numbers_fall_back() -> void:
	var settings: SettingsData = SettingsData.from_dict({"strip_rows": NAN, "screen_index": INF})
	assert_eq(settings.strip_rows, SettingsData.DEFAULT_STRIP_ROWS)
	assert_eq(settings.screen_index, SettingsData.PRIMARY_SCREEN)


func test_json_floats_are_accepted_as_integers() -> void:
	var settings: SettingsData = SettingsData.from_json('{"strip_rows": 14.0, "fps_limit": 60.0}')
	assert_eq(settings.strip_rows, 14)
	assert_eq(settings.fps_limit, 60)


func test_fps_must_be_one_of_the_choices() -> void:
	assert_eq(SettingsData.from_dict({"fps_limit": 24}).fps_limit, SettingsData.DEFAULT_FPS)
	assert_eq(SettingsData.from_dict({"fps_limit": 15}).fps_limit, 15)


func test_invalid_panel_mode_falls_back_to_replace() -> void:
	var settings: SettingsData = SettingsData.from_dict({"panel_mode": 7})
	assert_eq(settings.panel_mode, SettingsData.PanelMode.GROW_UP, "se recorta al máximo")
	assert_eq(
		SettingsData.from_dict({"panel_mode": "x"}).panel_mode, SettingsData.PanelMode.REPLACE
	)


func test_unknown_fields_are_ignored() -> void:
	var settings: SettingsData = SettingsData.from_dict(
		{"strip_rows": 18, "path": "C:/evil.exe", "launch": "rm -rf"}
	)
	assert_eq(settings.strip_rows, 18)
	assert_false(settings.to_dict().has("path"))


func test_next_fps_steps_and_stops_at_the_ends() -> void:
	assert_eq(SettingsData.next_fps(30, 1), 60)
	assert_eq(SettingsData.next_fps(60, 1), 60)
	assert_eq(SettingsData.next_fps(30, -1), 15)
	assert_eq(SettingsData.next_fps(15, -1), 15)
	assert_eq(SettingsData.next_fps(24, 1), SettingsData.DEFAULT_FPS)


func test_crt_level_defaults_to_full_and_is_validated() -> void:
	assert_eq(SettingsData.new().crt_level, 2)
	assert_eq(SettingsData.from_dict({"crt_level": 1}).crt_level, 1)
	assert_eq(SettingsData.from_dict({"crt_level": 99}).crt_level, 2)
	assert_eq(SettingsData.from_dict({"crt_level": "x"}).crt_level, 2)
	assert_eq(SettingsData.from_dict({"crt_level": -4}).crt_level, 0)
