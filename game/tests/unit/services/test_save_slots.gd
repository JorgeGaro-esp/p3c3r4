extends GutTest
## Ranuras de guardado: abrir, cerrar, borrar, resumen y migración de la partida
## de antes. Todo en carpetas temporales (nunca toca las ranuras de verdad).

const TEST_DIR: String = "user://test_slots"
const TEST_SETTINGS: String = "user://test_slots_settings.json"

var _controller: SaveController = null
var _previous_path: String = ""
var _previous_data: SettingsData = null
var _previous_fps: int = 0
var _previous_locale: String = ""


func before_each() -> void:
	_clean()
	_previous_fps = Engine.max_fps
	_previous_locale = TranslationServer.get_locale()
	_previous_path = Settings.storage_path
	_previous_data = Settings.data
	Settings.storage_path = TEST_SETTINGS
	Settings.data = SettingsData.new()
	Settings.active_slot = 0
	Game.start_new_game(42)
	_controller = SaveController.new()
	_controller.slots_directory = TEST_DIR
	add_child_autofree(_controller)


func after_each() -> void:
	Settings.data = _previous_data
	Settings.storage_path = _previous_path
	Settings.active_slot = 0
	Engine.max_fps = _previous_fps
	TranslationServer.set_locale(_previous_locale)
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


func _exists(slot: int) -> bool:
	var info: Dictionary = _controller.slot_info(slot)
	var exists: bool = info.get("exists", false)
	return exists


func _shells(slot: int) -> float:
	var info: Dictionary = _controller.slot_info(slot)
	var shells: float = info.get("shells", 0.0)
	return shells


func test_an_untouched_slot_is_empty() -> void:
	assert_false(_exists(1))


func test_a_new_game_writes_its_slot_at_once() -> void:
	_controller.open_slot(2, true)
	assert_true(_exists(2))
	assert_almost_eq(_shells(2), Game.START_SHELLS, 0.001)
	assert_eq(_controller.active_slot, 2)
	assert_eq(Settings.data.last_slot, 2)
	assert_false(_exists(1))


func test_start_loads_the_opened_slot() -> void:
	_controller.open_slot(1, true)
	Game.state.wallet.add(480.0)
	_controller.enabled = true
	_controller.save_now()
	_controller.open_slot(1, false)
	assert_almost_eq(Game.state.wallet.shells, Game.START_SHELLS, 0.001)
	_controller.start()
	assert_almost_eq(Game.state.wallet.shells, Game.START_SHELLS + 480.0, 0.001)


func test_slots_do_not_share_progress() -> void:
	_controller.open_slot(1, true)
	_controller.enabled = true
	Game.state.wallet.add(1000.0)
	_controller.open_slot(2, true)
	assert_almost_eq(_shells(1), 1020.0, 0.001)
	assert_almost_eq(_shells(2), 20.0, 0.001)


func test_close_slot_saves_and_returns_to_the_title() -> void:
	_controller.open_slot(3, true)
	_controller.enabled = true
	Game.state.wallet.add(55.0)
	_controller.close_slot()
	assert_eq(_controller.active_slot, 0)
	assert_false(_controller.enabled)
	assert_almost_eq(_shells(3), 75.0, 0.001)


func test_deleting_a_slot_empties_it_and_forgets_its_tutorial() -> void:
	_controller.open_slot(2, true)
	Settings.set_tutorial_step(3)
	_controller.delete_slot(2)
	assert_false(_exists(2))
	assert_eq(_controller.active_slot, 0)
	assert_eq(Settings.data.slot_steps[1], 0)
	assert_eq(Settings.data.last_slot, 0)


func test_the_game_from_before_slots_moves_to_slot_one() -> void:
	var legacy: SaveStore = SaveStore.new(TEST_DIR)
	Game.state.wallet.add(80.0)
	var text: String = SaveCodec.encode(Game.state, "0.19.0", 1)
	assert_true(legacy.write(text))
	_controller.prepare_slots()
	assert_false(legacy.exists(SaveStore.MAIN_FILE))
	assert_almost_eq(_shells(1), 100.0, 0.001)


func test_prepare_slots_never_overwrites_an_occupied_slot_one() -> void:
	_controller.open_slot(1, true)
	var legacy: SaveStore = SaveStore.new(TEST_DIR)
	assert_true(legacy.write(SaveCodec.encode(Game.state, "0.19.0", 1)))
	_controller.prepare_slots()
	assert_true(legacy.exists(SaveStore.MAIN_FILE))


func test_a_damaged_slot_is_reported() -> void:
	DirAccess.make_dir_recursive_absolute(_controller.slot_directory(1))
	var file: FileAccess = FileAccess.open(
		_controller.slot_directory(1).path_join(SaveStore.MAIN_FILE), FileAccess.WRITE
	)
	file.store_string("{ roto")
	file.close()
	var info: Dictionary = _controller.slot_info(1)
	var damaged: bool = info.get("damaged", false)
	assert_true(_exists(1))
	assert_true(damaged)


func test_the_tutorial_step_is_kept_per_slot() -> void:
	_controller.open_slot(1, true)
	Settings.set_tutorial_step(4)
	_controller.open_slot(2, true)
	assert_eq(Settings.data.tutorial_step, 0)
	Settings.set_tutorial_step(2)
	_controller.open_slot(1, false)
	assert_eq(Settings.data.tutorial_step, 4)
	_controller.open_slot(2, false)
	assert_eq(Settings.data.tutorial_step, 2)


func test_a_new_game_in_a_used_slot_restarts_its_tutorial() -> void:
	_controller.open_slot(1, true)
	Settings.set_tutorial_step(5)
	_controller.open_slot(1, true)
	assert_eq(Settings.data.tutorial_step, 0)
