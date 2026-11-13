extends GutTest
## Cría, crecimiento y venta sobre la escena principal completa.

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


func _visible_label_texts() -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for widget: AsciiWidget in _ui.all_widgets():
		var label: AsciiLabel = widget as AsciiLabel
		if label != null and label.is_shown:
			texts.append(label.text)
	return texts


func _view_of(fish: Fish) -> FishView:
	return _tank._views[fish]


func _hatch(species_id: String, variant_id: String) -> Fish:
	var baby: Fish = Fish.new(species_id)
	baby.maturity = 0.0
	baby.variant_id = variant_id
	Game.state.tanks[0].fish.append(baby)
	Game.state.pending_hatched.append(HatchEvent.new(0, baby))
	await wait_frames(3)
	return baby


func test_a_hatchling_appears_as_a_fry_and_changes_sprite_when_it_grows() -> void:
	var baby: Fish = await _hatch("pond_koi", "normal")
	var view: FishView = _view_of(baby)
	assert_eq(view.stage, LifeStage.Stage.FRY)
	var fry_width: int = view.width
	baby.maturity = 0.5
	await wait_frames(2)
	assert_eq(_view_of(baby).stage, LifeStage.Stage.JUVENILE)
	baby.maturity = 1.0
	await wait_frames(2)
	var adult: FishView = _view_of(baby)
	assert_eq(adult.stage, LifeStage.Stage.ADULT)
	assert_gt(adult.width, fry_width)
	assert_eq(_tank.fish_count(), Game.state.fish_total(), "no se duplican vistas")


func test_a_growing_fish_keeps_its_place_in_the_water() -> void:
	var baby: Fish = await _hatch("pond_goldfish", "normal")
	var before: Vector2 = _tank.fish_position(baby)
	baby.maturity = 0.5
	await wait_frames(1)
	assert_lt(before.distance_to(_tank.fish_position(baby)), 3.0)


func test_eggs_in_the_model_are_drawn_on_the_bottom() -> void:
	assert_eq(_tank.egg_count(), 0)
	Game.state.tanks[0].eggs.append(Egg.new("pond_guppy", "normal", 20.0, 0.3))
	await wait_frames(2)
	assert_eq(_tank.egg_count(), 1)


func test_a_rare_hatchling_shows_a_notice_in_the_sidebar() -> void:
	await _hatch("pond_tetra", "golden")
	var found: bool = false
	for text: String in _visible_label_texts():
		if text.contains("Dorada"):
			found = true
	assert_true(found, "aviso de variante nueva en la barra lateral")


func test_the_fish_card_shows_stage_and_variant() -> void:
	var baby: Fish = await _hatch("pond_tetra", "albino")
	_controller.show_card(baby)
	await wait_frames(2)
	var found: bool = false
	for text: String in _visible_label_texts():
		if text.contains("Alevín") and text.contains("Albina") and text.contains("×3"):
			found = true
	assert_true(found, str(_visible_label_texts()))


func test_selling_from_the_card_needs_a_second_press_to_confirm() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	var count: int = Game.state.fish_total()
	var before: float = Game.state.wallet.shells
	_controller.show_card(fish)
	await wait_frames(2)
	var button: AsciiButton = _controller._card._sell
	assert_true(button.activate())
	assert_eq(Game.state.fish_total(), count, "la primera pulsación solo pide confirmar")
	assert_string_contains(button.label, "Seguro")
	assert_true(button.activate())
	await wait_frames(2)
	assert_eq(Game.state.fish_total(), count - 1)
	assert_gt(Game.state.wallet.shells, before)
	assert_null(_controller.card_fish(), "la ficha se cierra al vender")


func test_changing_fish_cancels_a_pending_sale() -> void:
	var first: Fish = Game.state.tanks[0].fish[0]
	var second: Fish = Game.state.tanks[0].fish[1]
	_controller.show_card(first)
	await wait_frames(2)
	_controller._card._sell.activate()
	_controller.show_card(second)
	await wait_frames(2)
	assert_string_contains(_controller._card._sell.label, "Vender")


func test_surplus_button_is_only_enabled_with_extra_normal_fish() -> void:
	var fish: Fish = Game.state.tanks[0].fish[0]
	_controller.show_card(fish)
	await wait_frames(2)
	assert_false(_controller._card._sell_surplus.is_enabled, "solo hay una pareja")
	for _index: int in range(3):
		Game.state.tanks[0].add_fish(Fish.new(fish.species_id))
	_controller.show_card(null)
	_controller.show_card(fish)
	await wait_frames(2)
	assert_true(_controller._card._sell_surplus.is_enabled)
	var count: int = Game.state.tanks[0].count_of(fish.species_id)
	_controller._card._sell_surplus.activate()
	_controller._card._sell_surplus.activate()
	await wait_frames(2)
	assert_eq(Game.state.tanks[0].count_of(fish.species_id), Selling.KEEP_BREEDERS)


func test_rare_variants_are_not_offered_in_bulk() -> void:
	var rare: Fish = await _hatch("pond_koi", "prismatic")
	_controller.show_card(rare)
	await wait_frames(2)
	assert_false(_controller._card._sell_surplus.is_enabled)


func test_sell_all_from_the_settings_needs_three_presses() -> void:
	_controller.open_panel(StripController.Kind.SETTINGS)
	await wait_frames(3)
	var button: AsciiButton = _controller._settings_panel._sell_all
	var count: int = Game.state.fish_total()
	assert_gt(count, 0)
	assert_true(button.activate())
	assert_string_contains(button.label, "¿Vender")
	assert_eq(Game.state.fish_total(), count)
	assert_true(button.activate())
	assert_string_contains(button.label, "Seguro")
	assert_eq(Game.state.fish_total(), count)
	assert_true(button.activate())
	await wait_frames(2)
	assert_eq(Game.state.fish_total(), 0)
	assert_false(button.is_enabled, "sin peces el botón se desactiva")


func test_closing_the_settings_cancels_a_pending_sale() -> void:
	_controller.open_panel(StripController.Kind.SETTINGS)
	await wait_frames(3)
	var button: AsciiButton = _controller._settings_panel._sell_all
	button.activate()
	_controller.close_panel()
	_controller.open_panel(StripController.Kind.SETTINGS)
	await wait_frames(3)
	assert_string_contains(button.label, "Vender todos")
