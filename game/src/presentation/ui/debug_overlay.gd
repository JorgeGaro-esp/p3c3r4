class_name DebugOverlay
extends CanvasLayer
## Indicador de depuración. F3 lo muestra u oculta; F4 añade 5 peces y
## Mayús+F4 quita 5, para probar el rendimiento con la pecera llena.
##
## Es una herramienta de desarrollo: sus textos no se traducen.

const REFRESH_SECONDS: float = 0.25
const MEGABYTE: float = 1048576.0
const TEXT_COLOR: Color = Color(1.0, 0.7843, 0.3412)
const FONT_SIZE: int = 13
const FISH_STEP: int = 5

@export var canvas_path: NodePath
@export var tank_path: NodePath

var canvas: AsciiCanvas
var tank: TankView

var _label: Label
var _elapsed: float = 0.0


func _ready() -> void:
	canvas = get_node(canvas_path) as AsciiCanvas
	tank = get_node(tank_path) as TankView
	layer = 100
	_label = Label.new()
	_label.position = Vector2(8.0, 8.0)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(_label)
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return
	_elapsed = 0.0
	_label.text = _build_text()


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_F3:
		visible = not visible
	elif key_event.keycode == KEY_F4:
		if key_event.shift_pressed:
			tank.remove_fish(FISH_STEP)
		else:
			tank.add_fish(FISH_STEP)


func _build_text() -> String:
	var memory_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / MEGABYTE
	return (
		"FPS %d\nupdate %.2f ms\ndraw %.2f ms\nglyphs %d\nfish %d  bubbles %d\nmem %.1f MB\n%s"
		% [
			Engine.get_frames_per_second(),
			float(canvas.last_update_usec) / 1000.0,
			float(canvas.last_draw_usec) / 1000.0,
			canvas.glyph_count,
			tank.fish_count(),
			tank.bubble_count(),
			memory_mb,
			"F3 hide | F4 +5 fish | Shift+F4 -5",
		]
	)
