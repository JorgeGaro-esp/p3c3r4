extends GutTest
## Pruebas del servicio de ajustes con un archivo temporal propio (nunca toca el
## `settings.json` de verdad).

const TEST_PATH: String = "user://test_settings.json"

var _previous_fps: int = 0


func before_each() -> void:
	_previous_fps = Engine.max_fps
	_remove_files()


func after_each() -> void:
	Engine.max_fps = _previous_fps
	_remove_files()


func _remove_files() -> void:
	for path: String in [TEST_PATH, TEST_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _make_service() -> SettingsService:
	var service: SettingsService = SettingsService.new()
	service.storage_path = TEST_PATH
	add_child_autofree(service)
	return service


func test_missing_file_gives_the_decided_defaults() -> void:
	var service: SettingsService = _make_service()
	assert_eq(service.data.strip_rows, 12)
	assert_false(service.data.launch_with_windows)
	assert_eq(service.data.screen_index, SettingsData.PRIMARY_SCREEN)


func test_changes_are_saved_and_loaded_back() -> void:
	var service: SettingsService = _make_service()
	service.set_strip_rows(15)
	service.set_screen_index(1)
	service.set_always_on_top(false)
	service.set_fps_limit(60)
	service.set_panel_mode(SettingsData.PanelMode.GROW_UP)
	assert_true(service.save_now())
	var other: SettingsService = _make_service()
	assert_eq(other.data.to_dict(), service.data.to_dict())
	assert_eq(other.data.strip_rows, 15)


func test_setters_clamp_and_ignore_invalid_values() -> void:
	var service: SettingsService = _make_service()
	service.set_strip_rows(500)
	assert_eq(service.data.strip_rows, SettingsData.MAX_STRIP_ROWS)
	service.set_strip_rows(-5)
	assert_eq(service.data.strip_rows, SettingsData.MIN_STRIP_ROWS)
	service.set_fps_limit(24)
	assert_eq(service.data.fps_limit, SettingsData.DEFAULT_FPS)


func test_changed_is_emitted_only_when_something_changes() -> void:
	var service: SettingsService = _make_service()
	watch_signals(service)
	service.set_strip_rows(service.data.strip_rows)
	assert_signal_not_emitted(service, "changed")
	service.set_strip_rows(service.data.strip_rows + 1)
	assert_signal_emit_count(service, "changed", 1)


func test_fps_limit_is_applied_to_the_engine() -> void:
	var service: SettingsService = _make_service()
	service.set_fps_limit(15)
	assert_eq(Engine.max_fps, 15)


func test_corrupt_file_falls_back_to_defaults_without_errors() -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string('{"strip_rows": "mucho", "launch_with_windows": tru')
	file.close()
	var service: SettingsService = _make_service()
	assert_eq(service.data.to_dict(), SettingsData.new().to_dict())


func test_autostart_is_refused_outside_an_exported_windows_build() -> void:
	var service: SettingsService = _make_service()
	assert_false(service.set_launch_with_windows(true))
	assert_false(service.data.launch_with_windows, "si el sistema no puede, el ajuste no cambia")
	assert_true(
		service.set_launch_with_windows(false), "ya estaba desactivado: no hay nada que hacer"
	)


func test_crt_level_is_clamped_and_announced() -> void:
	var service: SettingsService = _make_service()
	var counter: Array[int] = [0]
	service.changed.connect(func() -> void: counter[0] += 1)
	service.set_crt_level(0)
	assert_eq(service.data.crt_level, 0)
	service.set_crt_level(77)
	assert_eq(service.data.crt_level, SettingsData.CRT_LEVELS - 1)
	service.set_crt_level(SettingsData.CRT_LEVELS - 1)
	assert_eq(counter[0], 2, "solo avisa cuando cambia")
