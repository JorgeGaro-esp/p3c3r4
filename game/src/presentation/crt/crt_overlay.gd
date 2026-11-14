class_name CrtOverlay
extends CanvasLayer
## Capa que aplica el efecto CRT (`crt.gdshader`) a toda la ventana. Sigue el
## ajuste `crt_level` de [SettingsService]: 0 la apaga, 1 es suave (brillo y
## líneas) y 2 es completa (además viñeta, desajuste de color y parpadeo).

const SHADER_PATH: String = "res://src/presentation/crt/crt.gdshader"
## Parámetros del sombreador por nivel: brillo, líneas, viñeta, desajuste, parpadeo.
const LEVELS: Array[Dictionary] = [
	{},
	{"glow": 0.45, "scanlines": 0.18, "vignette": 0.0, "fringe": 0.0, "flicker": 0.0},
	{"glow": 0.6, "scanlines": 0.26, "vignette": 0.35, "fringe": 0.0007, "flicker": 0.015},
]

var _rect: ColorRect = ColorRect.new()
var _material: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	# Por encima de la pecera y de la interfaz, por debajo de la depuración.
	layer = 10
	_material.shader = load(SHADER_PATH) as Shader
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	Settings.changed.connect(apply_level)
	apply_level()


## Ajusta el efecto al nivel de los ajustes.
func apply_level() -> void:
	var level: int = clampi(Settings.data.crt_level, 0, LEVELS.size() - 1)
	_rect.visible = level > 0
	var params: Dictionary = LEVELS[level]
	for key: String in params:
		_material.set_shader_parameter(key, params[key])
	if Settings.data.reduce_motion:
		_material.set_shader_parameter("flicker", 0.0)


## El material con los parámetros del sombreador.
func shader_material() -> ShaderMaterial:
	return _material


## El rectángulo que cubre la ventana.
func screen_rect() -> ColorRect:
	return _rect


## Si el efecto se está dibujando.
func is_active() -> bool:
	return _rect.visible
