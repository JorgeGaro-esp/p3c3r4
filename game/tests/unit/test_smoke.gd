extends GutTest
## Test trivial de la Fase 0: comprueba que GUT funciona y que el proyecto está configurado.


func test_gut_runs() -> void:
	assert_eq(1 + 1, 2, "GUT ejecuta tests")


func test_project_has_name_and_version() -> void:
	var project_name: String = ProjectSettings.get_setting("application/config/name", "")
	var version: String = ProjectSettings.get_setting("application/config/version", "")
	assert_eq(project_name, "P3C3R4")
	assert_ne(version, "", "la versión está definida en project.godot")


func test_main_scene_loads() -> void:
	var scene: PackedScene = load("res://src/presentation/main.tscn")
	assert_not_null(scene)
	var main: Node = autofree(scene.instantiate())
	assert_not_null(main)
