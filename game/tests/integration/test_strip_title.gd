extends GutTest
## Pantalla de título: se enseña al arrancar sin ranura abierta, bloquea la
## pecera y deja elegir ranura. Todo con carpetas y ajustes temporales.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)
const TEST_DIR: String = "user://test_title_slots"
const TEST_SETTINGS: String = "user://test_title_settings.json"

var _main: Node = null
var _canvas: AsciiCanvas = null
var _ui: UiRoot = null
var _controller: StripController = null
var _tank: TankView = null
var _previous_size: Vector2i = Vector2i.ZERO
var _previous_dir: String = ""
var _previous_path: String = ""
var _previous_data: SettingsData = null
var _previous_locale: String = ""
var _previous_fps: int = 0


func before_each() -> void:
	_clean()
	_previous_locale = TranslationServer.get_locale()
	_previous_fps = Engine.max_fps
	TranslationServer.set_locale("es")
	_previous_dir = SaveService.slots_directory
	_previous_path = Settings.storage_path
	_previous_data = Settings.data
	SaveService.slots_directory = TEST_DIR
	Settings.storage_path = TEST_SETTINGS
	Settings.data = SettingsData.new()
	Settings.data.language = SettingsData.Language.SPANISH
	Settings.active_slot = 0
	SaveService.active_slot = 0
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_frames(1)


func after_each() -> void:
	if _main != null:
		_main.queue_free()
		await wait_process_frames(2)
		_main = null
	SaveService.slots_directory = _previous_dir
	SaveService.active_slot = 0
	SaveService.enabled = false
	Settings.storage_path = _previous_path
	Settings.data = _previous_data
	Settings.active_slot = 0
	get_tree().root.size = _previous_size
	Engine.max_fps = _previous_fps
	TranslationServer.set_locale(_previous_locale)
	Game.set_paused(false)
	Game.start_new_game(Game.DEFAULT_SEED)
	_clean()


func _clean() -> void:
	_remove_tree(TEST_DIR)
	for path: String in [TEST_SETTINGS, TEST_SETTINGS + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub: String in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(sub))
	for file_name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)


func _start_scene() -> void:
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	add_child(_main)
	_canvas = _main.get_node("AsciiCanvas") as AsciiCanvas
	_ui = _main.get_node("UiRoot") as UiRoot
	_controller = _main.get_node("StripController") as StripController
	_tank = _main.get_node("TankView") as TankView
	await wait_frames(3)


func _button(label_text: String) -> AsciiButton:
	for widget: AsciiWidget in _ui.all_widgets():
		var button: AsciiButton = widget as AsciiButton
		if button != null and button.is_shown and button.label.begins_with(label_text):
			return button
	return null


func test_the_title_shows_when_no_slot_is_open() -> void:
	await _start_scene()
	assert_true(_controller._title_active)
	assert_true(_controller._title.is_active)
	assert_false(_controller._sidebar.is_active)
	assert_false(_tank.input_enabled)
	assert_eq(Game.state.fish_total(), 2 + Game.TITLE_FISH.size())
	assert_not_null(_button("CONTINUAR"))
	assert_not_null(_button("CARGAR"))
	assert_not_null(_button("NUEVA"))
	assert_not_null(_button("SALIR"))


func test_continue_and_load_are_off_without_saved_games() -> void:
	await _start_scene()
	assert_false(_button("CONTINUAR").is_enabled)
	assert_false(_button("CARGAR").is_enabled)
	assert_true(_button("NUEVA").is_enabled)


func test_the_title_draws_without_errors() -> void:
	await _start_scene()
	_canvas.queue_redraw()
	await wait_frames(2)
	assert_true(_controller._title.is_active)


func test_new_on_an_empty_slot_starts_at_once() -> void:
	await _start_scene()
	var title: TitlePanel = _controller._title
	watch_signals(title)
	_button("NUEVA").activated.emit()
	assert_eq(title.current_view(), TitlePanel.View.NEW)
	_button("Ranura 2").activated.emit()
	assert_signal_emitted_with_parameters(title, "slot_chosen", [2, true])


func test_new_on_a_used_slot_asks_before_overwriting() -> void:
	SaveService.open_slot(1, true)
	SaveService.enabled = false
	SaveService.active_slot = 0
	await _start_scene()
	var title: TitlePanel = _controller._title
	watch_signals(title)
	_button("NUEVA").activated.emit()
	_button("Ranura 1").activated.emit()
	assert_signal_not_emitted(title, "slot_chosen")
	assert_not_null(_button("¿Borrar la ranura 1"))
	_button("¿Borrar la ranura 1").activated.emit()
	assert_signal_emitted_with_parameters(title, "slot_chosen", [1, true])


func test_load_lists_the_slots_and_picks_a_used_one() -> void:
	SaveService.open_slot(3, true)
	SaveService.enabled = false
	SaveService.active_slot = 0
	await _start_scene()
	var title: TitlePanel = _controller._title
	watch_signals(title)
	assert_true(_button("CARGAR").is_enabled)
	_button("CARGAR").activated.emit()
	assert_eq(title.current_view(), TitlePanel.View.LOAD)
	assert_false(_button("Ranura 1").is_enabled)
	_button("Ranura 3").activated.emit()
	assert_signal_emitted_with_parameters(title, "slot_chosen", [3, false])


func test_continue_resumes_the_last_slot() -> void:
	SaveService.open_slot(2, true)
	SaveService.enabled = false
	SaveService.active_slot = 0
	await _start_scene()
	var title: TitlePanel = _controller._title
	watch_signals(title)
	assert_true(_button("CONTINUAR").is_enabled)
	_button("CONTINUAR").activated.emit()
	assert_signal_emitted_with_parameters(title, "slot_chosen", [2, false])


func test_escape_goes_back_from_the_slot_list() -> void:
	await _start_scene()
	var title: TitlePanel = _controller._title
	_button("NUEVA").activated.emit()
	assert_true(title.escape())
	assert_eq(title.current_view(), TitlePanel.View.MAIN)
	assert_false(title.escape())


func test_the_banner_builds_the_logo_in_five_rows() -> void:
	var rows: PackedStringArray = AsciiBanner.build("P3C3R4")
	assert_eq(rows.size(), AsciiBanner.GLYPH_HEIGHT)
	for row: String in rows:
		assert_eq(row.length(), 6 * 5 + 5)


func test_slot_line_formats_the_summary() -> void:
	var info: Dictionary = {
		"exists": true, "damaged": false, "shells": 1500.0, "fish": 7, "time": 4500.0
	}
	var line: String = TitleText.slot_line(1, info, "es")
	assert_true(line.begins_with("Ranura 1 · "))
	assert_true(line.contains("7 peces"))
	assert_true(line.contains("1 h 15 min"))
	assert_eq(TitleText.slot_line(2, {"exists": false}, "es"), "Ranura 2 · vacía")
