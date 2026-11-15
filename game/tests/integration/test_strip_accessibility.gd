extends GutTest
## Fase 15: tutorial por avisos, tamaño del texto, reducir movimiento y borrar partida.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1280, 480)

var _main: Node = null
var _strip: StripController = null
var _previous_size: Vector2i = Vector2i.ZERO
var _saved: SettingsData = null


func before_each() -> void:
	_saved = Settings.data
	Settings.data = SettingsData.new()
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_process_frames(1)
	Game.daylight.clock = FixedDayClock.new(12.0)
	Game.start_new_game(Game.DEFAULT_SEED)
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	_strip = _main.get_node("StripController") as StripController
	_strip.uses_saves = false
	add_child(_main)
	await wait_process_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	get_tree().root.size = _previous_size
	Settings.data = _saved
	Settings.changed.emit()
	Game.daylight.clock = DayClock.new()
	Game.start_new_game(Game.DEFAULT_SEED)


func test_the_tutorial_starts_at_the_first_step() -> void:
	assert_eq(_strip._hint.step(), 0)
	assert_eq(_strip._hint.body_text(), tr("TUTORIAL_0"))


func test_dropping_food_advances_the_tutorial() -> void:
	EventBus.food_dropped.emit()
	await wait_process_frames(2)
	assert_eq(Settings.data.tutorial_step, 1)
	assert_eq(_strip._hint.step(), 1)


func test_a_wrong_action_does_not_advance() -> void:
	EventBus.pearl_collected.emit(5.0)
	await wait_process_frames(2)
	assert_eq(Settings.data.tutorial_step, 0)


func test_escape_skips_the_tutorial() -> void:
	_strip._on_escape()
	await wait_process_frames(2)
	assert_eq(Settings.data.tutorial_step, Tutorial.DONE)
	assert_eq(_strip._hint.step(), -1)


func test_turning_the_tutorial_off_hides_the_hint() -> void:
	Settings.set_tutorial_enabled(false)
	await wait_process_frames(2)
	assert_eq(_strip._hint.step(), -1)
	Settings.set_tutorial_enabled(true)
	await wait_process_frames(2)
	assert_eq(_strip._hint.step(), 0)


func test_text_size_changes_the_cell_size() -> void:
	var normal: float = _strip._canvas.cell_size.y
	Settings.set_text_size(2)
	await wait_process_frames(2)
	assert_gt(_strip._canvas.cell_size.y, normal)
	Settings.set_text_size(0)
	await wait_process_frames(2)
	assert_lt(_strip._canvas.cell_size.y, normal)


func test_reduce_motion_scales_the_ripple() -> void:
	assert_eq(MotionScale.factor(), 1.0)
	Settings.set_reduce_motion(true)
	assert_eq(MotionScale.factor(), MotionScale.REDUCED)
	assert_true(MotionScale.is_reduced())


func test_reduce_motion_turns_off_the_crt_flicker() -> void:
	Settings.set_crt_level(2)
	Settings.set_reduce_motion(true)
	await wait_process_frames(2)
	var overlay: CrtOverlay = _main.get_node("CrtOverlay") as CrtOverlay
	var flicker: float = overlay.shader_material().get_shader_parameter("flicker")
	assert_eq(flicker, 0.0)


func test_deleting_the_slot_asks_the_title_only_after_three_presses() -> void:
	var settings: SettingsPanel = _strip._settings_panel
	watch_signals(settings)
	settings._on_delete_pressed()
	settings._on_delete_pressed()
	assert_signal_not_emitted(settings, "title_requested")
	settings._on_delete_pressed()
	assert_signal_emit_count(settings, "title_requested", 1)
	assert_signal_emitted_with_parameters(settings, "title_requested", [true])
