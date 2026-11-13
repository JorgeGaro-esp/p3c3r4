extends GutTest
## Pruebas de SaveController con un almacén temporal (no usa `user://saves`).

const TEST_DIR: String = "user://test_saves_controller"

var _controller: SaveController = null


func before_each() -> void:
	_clean()
	Game.start_new_game(42)
	_controller = SaveController.new()
	_controller.store = SaveStore.new(TEST_DIR)
	_controller.enabled = true
	add_child_autofree(_controller)


func after_all() -> void:
	_clean()
	Game.start_new_game(Game.DEFAULT_SEED)


func _clean() -> void:
	if DirAccess.dir_exists_absolute(TEST_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_DIR):
			DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
		DirAccess.remove_absolute(TEST_DIR)


func test_save_and_load_restore_the_game() -> void:
	Game.state.wallet.add(500.0)
	assert_true(_controller.save_now())
	Game.start_new_game(1)
	assert_eq(_controller.load_game(), "")
	assert_almost_eq(Game.state.wallet.shells, 520.0, 0.001)


func test_nothing_to_load_gives_no_notice() -> void:
	assert_eq(_controller.load_game(), "")


func test_corrupt_main_recovers_from_backup() -> void:
	Game.state.wallet.add(100.0)
	_controller.save_now()
	_controller.save_now()
	var file: FileAccess = FileAccess.open(
		TEST_DIR.path_join(SaveStore.MAIN_FILE), FileAccess.WRITE
	)
	file.store_string("{ roto")
	file.close()
	Game.start_new_game(1)
	assert_eq(_controller.load_game(), "TOAST_SAVE_RECOVERED")
	assert_almost_eq(Game.state.wallet.shells, 120.0, 0.001)
	assert_eq(_controller.store.quarantined().size(), 1)


func test_all_corrupt_starts_fresh_with_notice() -> void:
	var file: FileAccess = FileAccess.open(
		TEST_DIR.path_join(SaveStore.MAIN_FILE), FileAccess.WRITE
	)
	if file == null:
		DirAccess.make_dir_recursive_absolute(TEST_DIR)
		file = FileAccess.open(TEST_DIR.path_join(SaveStore.MAIN_FILE), FileAccess.WRITE)
	file.store_string("basura")
	file.close()
	assert_eq(_controller.load_game(), "TOAST_SAVE_CORRUPT")
	assert_false(_controller.store.exists(SaveStore.MAIN_FILE))


func test_newer_save_blocks_saving() -> void:
	_controller.save_now()
	var text: String = _controller.store.read(SaveStore.MAIN_FILE)
	var parser: JSON = JSON.new()
	parser.parse(text)
	var envelope: Dictionary = parser.data
	envelope["format_version"] = SaveMigrations.CURRENT_FORMAT + 1
	var file: FileAccess = FileAccess.open(
		TEST_DIR.path_join(SaveStore.MAIN_FILE), FileAccess.WRITE
	)
	file.store_string(JSON.stringify(envelope))
	file.close()
	assert_eq(_controller.load_game(), "TOAST_SAVE_NEWER")
	assert_true(_controller.blocked)
	assert_false(_controller.save_now())


func test_disabled_controller_never_writes() -> void:
	_controller.enabled = false
	assert_false(_controller.save_now())
	assert_true(_controller.store.candidates().is_empty())


func test_purchase_requests_a_save_and_respects_the_minimum_interval() -> void:
	_controller.save_now()
	Game.state.wallet.add(100.0)
	_controller.request_save()
	assert_true(_controller._pending)
	_controller._process(SaveController.MIN_INTERVAL_SECONDS + 0.1)
	assert_false(_controller._pending)
