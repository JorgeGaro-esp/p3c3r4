extends GutTest
## Pruebas de los argumentos de `reg.exe` para arrancar con Windows (P09).

const EXE: String = "C:/Users/Jorge/Games/P3C3R4/P3C3R4.exe"


func test_add_arguments_register_the_exe_in_the_user_run_key() -> void:
	var arguments: PackedStringArray = AutostartCommand.add_arguments(EXE)
	assert_eq(
		arguments,
		PackedStringArray(
			[
				"add",
				"HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
				"/v",
				"P3C3R4",
				"/t",
				"REG_SZ",
				"/d",
				'"C:\\Users\\Jorge\\Games\\P3C3R4\\P3C3R4.exe"',
				"/f",
			]
		)
	)


func test_delete_arguments_only_touch_our_value() -> void:
	var arguments: PackedStringArray = AutostartCommand.delete_arguments()
	assert_eq(arguments.size(), 5)
	assert_eq(arguments[0], "delete")
	assert_eq(arguments[3], "P3C3R4")


func test_paths_with_spaces_are_accepted_and_quoted() -> void:
	var arguments: PackedStringArray = AutostartCommand.add_arguments("C:/Mis Juegos/p3c3r4.exe")
	assert_eq(arguments[7], '"C:\\Mis Juegos\\p3c3r4.exe"')


func test_unsafe_paths_produce_no_command() -> void:
	var bad_paths: Array[String] = [
		"",
		"P3C3R4.exe",
		"/usr/bin/godot",
		"C:/juego/p3c3r4.bat",
		'C:/juego/p3c3r4.exe" /f & calc.exe & "',
		"C:/juego/p3c3r4.exe\nnotepad",
		"\\\\server\\share\\game.exe",
		"C:/a.exe\u0000",
	]
	for path: String in bad_paths:
		assert_true(AutostartCommand.add_arguments(path).is_empty(), "debería rechazar: %s" % path)
		assert_false(AutostartCommand.is_safe_path(path))


func test_extension_check_ignores_case() -> void:
	assert_true(AutostartCommand.is_safe_path("D:/Juegos/P3C3R4.EXE"))
