extends GutTest
## Equipo: pestaña de la tienda, compra y dibujo en la pecera.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _canvas: AsciiCanvas = null
var _ui: UiRoot = null
var _controller: StripController = null
var _tank: TankView = null
var _previous_locale: String = ""
var _previous_size: Vector2i = Vector2i.ZERO


func before_each() -> void:
	_previous_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_previous_size = get_tree().root.size
	get_tree().root.size = WINDOW_SIZE
	await wait_frames(1)
	var scene: PackedScene = load(MAIN_SCENE)
	_main = scene.instantiate()
	(_main.get_node("StripController") as StripController).uses_saves = false
	add_child(_main)
	_canvas = _main.get_node("AsciiCanvas") as AsciiCanvas
	_ui = _main.get_node("UiRoot") as UiRoot
	_controller = _main.get_node("StripController") as StripController
	_tank = _main.get_node("TankView") as TankView
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	Game.start_new_game(Game.DEFAULT_SEED)


func _shop() -> ShopPanel:
	return _controller._shop


func _open_equipment_tab() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	_shop().select_tab(1)
	await wait_frames(2)


func test_shop_has_an_equipment_tab_with_the_seven_items() -> void:
	await _open_equipment_tab()
	assert_eq(_shop().equipment_ids().size(), 7)
	var found: bool = false
	for widget: AsciiWidget in _ui.all_widgets():
		var list: AsciiList = widget as AsciiList
		if list != null and list.is_shown:
			found = true
			assert_eq(list.names.size(), 7)
			assert_true(list.names[0].contains("0/5"), list.names[0])
	assert_true(found)


func test_buying_equipment_from_the_shop_shows_it_in_the_tank() -> void:
	Game.state.wallet.add(10000.0)
	await _open_equipment_tab()
	_shop().select_equipment("filter")
	_shop().buy_selected()
	await wait_frames(3)
	assert_eq(Game.state.tanks[0].level_of("filter"), 1)
	assert_eq(_tank.equipment_count(), 1)


func test_buying_too_expensive_equipment_does_nothing() -> void:
	await _open_equipment_tab()
	_shop().select_equipment("incubator")
	_shop().buy_selected()
	await wait_frames(2)
	assert_eq(Game.state.tanks[0].level_of("incubator"), 0)
	assert_eq(_tank.equipment_count(), 0)


func test_magnet_collects_pearls_that_rest_on_the_floor() -> void:
	Game.state.tanks[0].set_level("pearl_magnet", 5, Game.content)
	var before: float = Game.state.wallet.shells
	var fish: Fish = Game.state.tanks[0].fish[0]
	Game.state.pending_pearls.append(PearlSpawn.new(0, fish, 50.0))
	await wait_frames(3)
	assert_eq(_tank.pearl_count(), 1)
	_tank._pearls.floor_row = 0.0
	await wait_seconds(6.0)
	assert_eq(_tank.pearl_count(), 0)
	assert_gt(Game.state.wallet.shells, before + 40.0)
