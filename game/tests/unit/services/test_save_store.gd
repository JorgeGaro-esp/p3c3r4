extends GutTest
## Pruebas de SaveStore en un directorio temporal (nunca toca la partida real).

const TEST_DIR: String = "user://test_saves"

var _store: SaveStore = null


func before_each() -> void:
	_clean()
	_store = SaveStore.new(TEST_DIR)


func after_all() -> void:
	_clean()


func _clean() -> void:
	if DirAccess.dir_exists_absolute(TEST_DIR):
		for file_name: String in DirAccess.get_files_at(TEST_DIR):
			DirAccess.remove_absolute(TEST_DIR.path_join(file_name))
		DirAccess.remove_absolute(TEST_DIR)


func test_write_then_read() -> void:
	assert_true(_store.write('{"a": 1}'))
	assert_eq(_store.read(SaveStore.MAIN_FILE), '{"a": 1}')


func test_non_json_is_refused_and_nothing_is_written() -> void:
	assert_false(_store.write("esto no es json"))
	assert_true(_store.candidates().is_empty())


func test_writes_rotate_backups() -> void:
	for number: int in range(1, 6):
		_store.write('{"n": %d}' % number)
	assert_eq(_store.read(SaveStore.MAIN_FILE), '{"n": 5}')
	assert_eq(_store.read(SaveStore.backup_name(1)), '{"n": 4}')
	assert_eq(_store.read(SaveStore.backup_name(3)), '{"n": 2}')
	assert_false(_store.exists(SaveStore.TEMP_FILE))


func test_candidates_are_ordered_best_first() -> void:
	_store.write('{"n": 1}')
	_store.write('{"n": 2}')
	var found: PackedStringArray = _store.candidates()
	assert_eq(found[0], SaveStore.MAIN_FILE)
	assert_eq(found[1], SaveStore.backup_name(1))


func test_leftover_temp_does_not_hide_the_main_save() -> void:
	_store.write('{"n": 1}')
	var file: FileAccess = FileAccess.open(
		TEST_DIR.path_join(SaveStore.TEMP_FILE), FileAccess.WRITE
	)
	file.store_string('{"n": ')
	file.close()
	assert_eq(_store.read(SaveStore.MAIN_FILE), '{"n": 1}')
	assert_eq(_store.candidates()[0], SaveStore.MAIN_FILE)


func test_quarantine_moves_the_file_aside() -> void:
	_store.write('{"n": 1}')
	assert_true(_store.quarantine(SaveStore.MAIN_FILE, 99))
	assert_false(_store.exists(SaveStore.MAIN_FILE))
	assert_eq(_store.quarantined().size(), 1)


func test_quarantine_keeps_only_the_latest() -> void:
	for number: int in range(1, SaveStore.MAX_QUARANTINED + 4):
		_store.write('{"n": %d}' % number)
		_store.quarantine(SaveStore.MAIN_FILE, number)
	assert_eq(_store.quarantined().size(), SaveStore.MAX_QUARANTINED)


func test_read_of_missing_file_is_empty() -> void:
	assert_eq(_store.read("nada.json"), "")
