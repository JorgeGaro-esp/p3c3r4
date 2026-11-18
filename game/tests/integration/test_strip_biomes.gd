extends GutTest
## Biomas en la franja: pestañas de pecera, cambio instantáneo, tienda de biomas.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
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
	_controller = _main.get_node("StripController") as StripController
	_tank = _main.get_node("TankView") as TankView
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)
	TranslationServer.set_locale(_previous_locale)
	get_tree().root.size = _previous_size


func _tabs() -> TankTabs:
	return _controller._tank_tabs


func _open_reef() -> void:
	Game.state.wallet.add(1.0e6)
	assert_eq(Game.biomes.unlock("reef"), BiomeDirector.Result.OK)


func test_tabs_are_hidden_until_a_second_tank_exists() -> void:
	assert_false(_tabs().is_active)
	_open_reef()
	await wait_frames(2)
	assert_true(_tabs().is_active)
	assert_eq(_tabs().titles().size(), 2)
	assert_eq(_tabs().titles()[0], "Estanque")
	assert_eq(_tabs().titles()[1], "Arrecife")
	assert_eq(_tabs().selected(), 1)


func test_switching_tanks_swaps_the_fish_and_the_look() -> void:
	_open_reef()
	Game.buy_fish("reef_krill")
	Game.buy_fish("reef_krill")
	await wait_frames(2)
	assert_eq(_tank.fish_count(), 2)
	assert_eq(_tank._biome.id, "reef")
	assert_gt(_tank._ambience_count(), 0)
	Game.biomes.set_active(0)
	await wait_frames(2)
	assert_eq(_tank._biome.id, "pond")
	assert_eq(_tank.fish_count(), 2, "dos guppies del estanque")
	assert_gt(_tank._ambience_count(), 0, "el estanque también tiene motas y fondo")


func test_clicking_a_tab_changes_the_active_tank() -> void:
	_open_reef()
	await wait_frames(2)
	_tabs().choose(0)
	await wait_frames(2)
	assert_eq(Game.state.active_tank, 0)
	assert_eq(_tank._biome.id, "pond")


func test_number_keys_switch_tanks() -> void:
	_open_reef()
	await wait_frames(2)
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_1
	key.pressed = true
	_controller._unhandled_key_input(key)
	assert_eq(Game.state.active_tank, 0)
	key.keycode = KEY_2
	_controller._unhandled_key_input(key)
	assert_eq(Game.state.active_tank, 1)
	key.keycode = KEY_6
	_controller._unhandled_key_input(key)
	assert_eq(Game.state.active_tank, 1, "una pecera que no existe se ignora")


func test_switching_is_instant_and_leaves_no_stray_views() -> void:
	_open_reef()
	for _index: int in range(10):
		Game.buy_fish("reef_krill")
	for _round: int in range(6):
		Game.biomes.set_active(0)
		Game.biomes.set_active(1)
	await wait_frames(2)
	assert_eq(_tank.fish_count(), Game.state.tanks[1].fish.size())


func test_unspent_pearls_are_paid_out_when_leaving_a_tank() -> void:
	_open_reef()
	Game.buy_fish("reef_krill")
	var fish: Fish = Game.state.tanks[1].fish[0]
	EventBus.pearl_spawned.emit(1, fish, 40.0)
	await wait_frames(2)
	assert_eq(_tank.pearl_count(), 1)
	var before: float = Game.state.wallet.shells
	Game.biomes.set_active(0)
	assert_eq(_tank.pearl_count(), 0)
	assert_gte(Game.state.wallet.shells, before + 40.0)


func test_the_shop_lists_only_the_species_of_the_active_biome() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	assert_true(shop.species_ids().has("pond_guppy"))
	assert_false(shop.species_ids().has("reef_krill"))
	_open_reef()
	await wait_frames(2)
	assert_true(shop.species_ids().has("reef_krill"))
	assert_false(shop.species_ids().has("pond_guppy"))
	assert_eq(shop.species_ids().size(), 10)


func test_the_shop_decor_tab_hides_other_biomes_objects() -> void:
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_tab(2)
	await wait_frames(2)
	assert_false(shop.decoration_ids().has("brain_coral"))
	assert_true(shop.decoration_ids().has("big_rock"))
	_open_reef()
	await wait_frames(2)
	assert_true(shop.decoration_ids().has("brain_coral"))
	assert_true(shop.decoration_ids().has("big_rock"))


func test_the_biome_tab_unlocks_the_reef_with_shells() -> void:
	Game.state.wallet.add(1.0e6)
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_biome("reef")
	await wait_frames(2)
	assert_eq(shop.biome_ids(), PackedStringArray(["pond", "reef", "mangrove", "abyss"]))
	shop.buy_selected()
	await wait_frames(2)
	assert_eq(Game.state.tanks.size(), 2)
	assert_eq(Game.state.active().biome_id, "reef")


func test_without_shells_the_biome_stays_closed() -> void:
	Game.state.wallet.spend(Game.state.wallet.shells)
	_controller.open_panel(StripController.Kind.SHOP)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_biome("reef")
	shop.buy_selected()
	await wait_frames(2)
	assert_eq(Game.state.tanks.size(), 1)
