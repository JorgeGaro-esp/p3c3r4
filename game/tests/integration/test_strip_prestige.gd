extends GutTest
## La pestaña de la Gran marea, la secuencia final y el reinicio con la interfaz viva.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1280, 480)

var _main: Node = null
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
	await wait_process_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_process_frames(2)
	get_tree().root.size = _previous_size
	Game.daylight.clock = DayClock.new()
	Game.start_new_game(Game.DEFAULT_SEED)


func _open_tab() -> ShopPanel:
	_strip.open_shop_tab(ShopPanel.PRESTIGE_TAB)
	await wait_process_frames(2)
	return _strip._shop


func test_the_prestige_tab_lists_the_reset_and_the_upgrades() -> void:
	var shop: ShopPanel = await _open_tab()
	assert_eq(shop.current_tab(), ShopPanel.PRESTIGE_TAB)
	assert_eq(shop._prestige_ids[0], ShopPanel.RESET_ENTRY)
	assert_eq(shop._prestige_ids.size(), 1 + Game.content.prestige.ids().size())


func test_the_reset_button_is_disabled_without_earnings() -> void:
	var shop: ShopPanel = await _open_tab()
	shop._list.model.select(0)
	shop._show_detail(0)
	assert_false(shop._buy.is_enabled)


func test_the_reset_needs_two_presses() -> void:
	Game.state.wallet.add(1.0e7)
	var shop: ShopPanel = await _open_tab()
	shop._list.model.select(0)
	shop._show_detail(0)
	assert_true(shop._buy.is_enabled)
	shop.buy_selected()
	assert_eq(Game.state.prestige.count, 0)
	assert_string_contains(shop._buy.label, tr("PRESTIGE_BUTTON_CONFIRM"))
	shop.buy_selected()
	assert_eq(Game.state.prestige.count, 1)
	assert_gt(Game.state.prestige.pearls, 0)
	assert_eq(Game.state.wallet.shells, Game.START_SHELLS)


func test_an_upgrade_is_bought_with_black_pearls() -> void:
	Game.state.prestige.add_pearls(50)
	var shop: ShopPanel = await _open_tab()
	shop._list.model.select(1)
	shop._show_detail(1)
	assert_true(shop._buy.is_enabled)
	shop.buy_selected()
	assert_eq(Game.state.prestige.level_of(Game.content.prestige.ids()[0]), 1)


func test_the_final_row_only_appears_after_the_ending() -> void:
	var shop: ShopPanel = await _open_tab()
	assert_false(shop._prestige_ids.has(ShopPanel.FINAL_ENTRY))
	Game.state.prestige.final_reached = true
	shop.select_tab(ShopPanel.STATS_TAB)
	shop.select_tab(ShopPanel.PRESTIGE_TAB)
	assert_true(shop._prestige_ids.has(ShopPanel.FINAL_ENTRY))


func test_completing_the_collection_opens_the_final_sequence() -> void:
	Game.prestige.debug_complete_collection()
	await wait_seconds(Game.ACHIEVEMENT_CHECK_SECONDS + 0.4)
	assert_eq(_strip.open_kind(), StripController.Kind.FINAL)
	assert_true(_strip._final.is_active)


func test_the_final_sequence_closes_with_a_click() -> void:
	Game.prestige.debug_complete_collection()
	await wait_seconds(Game.ACHIEVEMENT_CHECK_SECONDS + 0.4)
	_strip._final.close_requested.emit()
	await wait_process_frames(2)
	assert_eq(_strip.open_kind(), StripController.Kind.NONE)


func test_the_final_sequence_writes_every_line() -> void:
	var sequence: FinalSequence = _strip._final._sequence
	assert_eq(sequence.lines.size(), 5)
	assert_gt(sequence.total_seconds(), 5.0)


func test_the_reset_empties_the_tank_view() -> void:
	Game.state.wallet.add(1.0e7)
	var tank: TankView = _main.get_node("TankView") as TankView
	assert_gt(tank.fish_count(), 0)
	Game.prestige.reset()
	await wait_process_frames(2)
	assert_eq(tank.fish_count(), Game.START_FISH.size())
