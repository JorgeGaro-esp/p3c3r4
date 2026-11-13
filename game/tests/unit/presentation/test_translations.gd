extends GutTest
## Comprueba que las cadenas existen en es y en, y que se pueden dibujar en ASCII.

const CSV_PATH: String = "res://assets/i18n/strings.csv"
const UI_DIR: String = "res://src/presentation"


func _read_rows() -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "strings.csv se puede abrir")
	if file == null:
		return rows
	file.get_csv_line()
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() >= 3 and not line[0].is_empty():
			rows.append(line)
	return rows


func test_every_key_has_spanish_and_english_text() -> void:
	var rows: Array[PackedStringArray] = _read_rows()
	assert_gt(rows.size(), 10, "hay claves")
	for line: PackedStringArray in rows:
		assert_false(line[1].strip_edges().is_empty(), "%s tiene texto en es" % line[0])
		assert_false(line[2].strip_edges().is_empty(), "%s tiene texto en en" % line[0])


func test_keys_are_unique() -> void:
	var seen: Dictionary = {}
	for line: PackedStringArray in _read_rows():
		assert_false(seen.has(line[0]), "clave repetida: %s" % line[0])
		seen[line[0]] = true


func test_texts_only_use_drawable_characters() -> void:
	for line: PackedStringArray in _read_rows():
		for column: int in [1, 2]:
			for index: int in line[column].length():
				var char_text: String = line[column][index]
				if char_text == "\n" or char_text == "%":
					continue
				assert_true(
					AsciiCharset.is_allowed(char_text),
					"%s: carácter no permitido '%s'" % [line[0], char_text]
				)


func test_keys_used_in_code_exist() -> void:
	var known: Dictionary = {}
	for line: PackedStringArray in _read_rows():
		known[line[0]] = true
	var regex: RegEx = RegEx.new()
	regex.compile('"((?:UI|TOAST|SHOP|RARITY|SETTINGS)_[A-Z0-9_]+)"')
	for path: String in _gd_files(UI_DIR):
		var text: String = FileAccess.get_file_as_string(path)
		for found: RegExMatch in regex.search_all(text):
			assert_true(known.has(found.get_string(1)), "%s usa %s" % [path, found.get_string(1)])


func _gd_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			result.append(dir_path.path_join(file_name))
	for sub: String in DirAccess.get_directories_at(dir_path):
		result.append_array(_gd_files(dir_path.path_join(sub)))
	return result
