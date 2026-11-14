extends GutTest
## El tinte del día y los eventos dentro de la escena principal.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1280, 480)

var _main: Node = null
var _tank: TankView = null
var _strip: StripController = null
var _previous_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
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
	_tank = _main.get_node("TankView") as TankView
	await wait_process_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	get_tree().root.size = _previous_size
	Game.daylight.clock = DayClock.new()
	Game.start_new_game(Game.DEFAULT_SEED)


func _set_hour(hour: float) -> void:
	(Game.daylight.clock as FixedDayClock).value = hour
	await wait_process_frames(3)


func test_there_is_no_tint_at_noon() -> void:
	var layer: EventLayer = _tank._events
	assert_eq(layer.daylight.night_alpha(), 0.0)
	assert_eq(layer.daylight.twilight_alpha(), 0.0)


func test_the_night_tints_the_water() -> void:
	await _set_hour(23.0)
	var layer: EventLayer = _tank._events
	assert_almost_eq(layer.daylight.night_alpha(), DaylightView.NIGHT_ALPHA, 0.0001)


func test_the_lamp_makes_the_night_lighter() -> void:
	await _set_hour(23.0)
	var layer: EventLayer = _tank._events
	var dark: float = layer.daylight.night_alpha()
	Game.state.active().set_level("lamp", 5, Game.content)
	await wait_process_frames(3)
	assert_lt(layer.daylight.night_alpha(), dark)


func test_dusk_adds_a_warm_veil() -> void:
	await _set_hour(19.5)
	assert_gt(_tank._events.daylight.twilight_alpha(), 0.0)


func test_a_golden_fish_appears_and_clicking_it_pays() -> void:
	Game.events.start_by_id("golden_fish")
	await wait_process_frames(3)
	var layer: EventLayer = _tank._events
	assert_true(layer.field.is_active())
	var cell: Vector2 = layer.field.cell_position() + Vector2(1.0, 0.0)
	var before: float = Game.state.wallet.shells
	assert_true(_tank.click_cell(Vector2i(int(cell.x), int(cell.y))))
	assert_gt(Game.state.wallet.shells, before)
	await wait_process_frames(2)
	assert_false(layer.field.is_active())


func test_a_missed_click_leaves_the_golden_fish() -> void:
	Game.events.start_by_id("golden_fish")
	await wait_process_frames(3)
	var layer: EventLayer = _tank._events
	assert_false(layer.field.hit(Vector2i(0, 0)))
	assert_true(Game.state.events.has_pickup())


func test_a_rare_visitor_swims_in_and_can_be_clicked() -> void:
	Game.events.start_by_id("rare_visitor")
	await wait_process_frames(3)
	var layer: EventLayer = _tank._events
	assert_true(layer.has_pickup())
	assert_eq(_tank.fish_count(), 2, "el visitante no cuenta como pez de la pecera")
	var visitor_cell: Vector2 = layer.field_marker_cell()
	var before: float = Game.state.wallet.shells
	assert_true(layer.click(Vector2i(int(visitor_cell.x), int(visitor_cell.y) + 1)))
	assert_gt(Game.state.wallet.shells, before)
	await wait_process_frames(2)
	assert_false(layer.has_pickup())


func test_the_bottle_floats_in_and_disappears_when_it_expires() -> void:
	Game.events.start_by_id("drifting_bottle")
	await wait_process_frames(3)
	assert_true(_tank._events.field.is_active())
	Game.events.advance(60.0)
	await wait_process_frames(2)
	assert_false(_tank._events.has_pickup())


func test_switching_tank_hides_the_event_and_coming_back_restores_it() -> void:
	Game.events.start_by_id("golden_fish")
	await wait_process_frames(3)
	Game.state.tanks.append(Tank.new())
	Game.state.tanks[1].biome_id = "reef"
	Game.biomes.set_active(1)
	await wait_process_frames(3)
	assert_false(_tank._events.field.is_active())
	Game.biomes.set_active(0)
	await wait_process_frames(3)
	assert_true(_tank._events.field.is_active())


func test_the_food_rain_drops_flakes() -> void:
	for fish: Fish in Game.state.active().fish:
		fish.hunger = 20.0
	Game.events.start_by_id("food_rain")
	await wait_process_frames(2)
	assert_gt(_tank.food_count(), 0)


func test_an_event_shows_a_notice() -> void:
	Game.events.start_by_id("warm_current")
	await wait_process_frames(2)
	var sidebar: SidebarPanel = _strip._sidebar
	assert_false(sidebar.toast_text().is_empty())


func test_the_phase_change_shows_a_notice() -> void:
	await _set_hour(23.0)
	var sidebar: SidebarPanel = _strip._sidebar
	assert_false(sidebar.toast_text().is_empty())


func test_the_sidebar_shows_the_game_hour() -> void:
	await _set_hour(23.25)
	var sidebar: SidebarPanel = _strip._sidebar
	assert_eq(sidebar._clock.text, "● 23:15")
	await _set_hour(12.0)
	assert_eq(sidebar._clock.text, "○ 12:00")
	assert_eq(sidebar._clock.color, ClockPalette.color_at(12.0))


func test_the_rate_sits_next_to_the_shells() -> void:
	await wait_process_frames(2)
	var sidebar: SidebarPanel = _strip._sidebar
	assert_eq(sidebar._rate.rect.position.y, sidebar._shells.rect.position.y)
	assert_gt(sidebar._rate.rect.position.x, sidebar._shells.rect.position.x)
	assert_gt(sidebar._clock.rect.position.y, sidebar._shells.rect.position.y)


func test_the_achievements_button_opens_the_shop() -> void:
	_strip._sidebar.achievements_pressed.emit()
	await wait_process_frames(2)
	assert_eq(_strip._open, StripController.Kind.SHOP)
