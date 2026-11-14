extends GutTest
## El efecto CRT en la escena principal: sigue el ajuste y no estorba al ratón.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"

var _main: Node = null
var _overlay: CrtOverlay = null
var _previous_level: int = 0


func before_each() -> void:
	_previous_level = Settings.data.crt_level
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	(_main.get_node("StripController") as StripController).uses_saves = false
	add_child(_main)
	_overlay = _main.get_node("CrtOverlay") as CrtOverlay
	await wait_frames(2)


func after_each() -> void:
	Settings.set_crt_level(_previous_level)
	_main.queue_free()
	await wait_frames(2)


func test_the_overlay_follows_the_setting() -> void:
	Settings.set_crt_level(0)
	assert_false(_overlay.is_active())
	Settings.set_crt_level(1)
	assert_true(_overlay.is_active())
	Settings.set_crt_level(2)
	assert_true(_overlay.is_active())


func test_the_full_level_adds_vignette_and_flicker() -> void:
	Settings.set_crt_level(1)
	var soft: ShaderMaterial = _overlay.shader_material()
	var soft_vignette: float = soft.get_shader_parameter("vignette")
	assert_eq(soft_vignette, 0.0)
	Settings.set_crt_level(2)
	var vignette: float = soft.get_shader_parameter("vignette")
	var flicker: float = soft.get_shader_parameter("flicker")
	assert_gt(vignette, 0.0)
	assert_gt(flicker, 0.0)


func test_the_overlay_does_not_catch_mouse_clicks() -> void:
	var rect: ColorRect = _overlay.screen_rect()
	assert_eq(rect.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_shader_compiles_with_its_parameters() -> void:
	var shader: Shader = load(CrtOverlay.SHADER_PATH) as Shader
	assert_not_null(shader)
	var names: PackedStringArray = PackedStringArray()
	for uniform: Dictionary in shader.get_shader_uniform_list():
		names.append(str(uniform["name"]))
	for key: String in CrtOverlay.LEVELS[2]:
		assert_true(names.has(key), "falta el parámetro %s" % key)
