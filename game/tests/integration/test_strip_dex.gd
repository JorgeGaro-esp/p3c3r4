extends GutTest
## Enciclopedia en la franja: pestaña de la tienda, tecla E, retrato y progreso.

const MAIN_SCENE: String = "res://src/presentation/main.tscn"
const WINDOW_SIZE: Vector2i = Vector2i(1200, 240)

var _main: Node = null
var _controller: StripController = null
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
	Game.start_new_game(Game.DEFAULT_SEED)
	await wait_frames(3)


func after_each() -> void:
	_main.queue_free()
	await wait_frames(2)
	Game.start_new_game(Game.DEFAULT_SEED)
	TranslationServer.set_locale(_previous_locale)
	get_tree().root.size = _previous_size


func _press(keycode: Key) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	await wait_frames(3)


func test_the_e_key_opens_the_dex_tab_and_closes_it() -> void:
	await _press(KEY_E)
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.SHOP)
	assert_eq(_controller._shop.current_tab(), ShopPanel.DEX_TAB)
	await _press(KEY_E)
	await wait_frames(2)
	assert_eq(_controller.open_kind(), StripController.Kind.NONE)


func test_the_sidebar_button_opens_the_dex() -> void:
	_controller._sidebar.dex_pressed.emit()
	await wait_frames(2)
	assert_eq(_controller._shop.current_tab(), ShopPanel.DEX_TAB)


func test_the_dex_lists_the_species_of_one_biome_cheapest_first() -> void:
	await _press(KEY_E)
	await wait_frames(2)
	var ids: PackedStringArray = _controller._shop.dex_ids()
	assert_eq(ids, Encyclopedia.species_of(Game.content, "pond"))


func test_every_species_is_in_the_tab_of_its_biome() -> void:
	await _press(KEY_E)
	var total: int = 0
	for biome_id: String in Game.content.biomes.ids():
		_controller._shop.select_dex_species(Encyclopedia.species_of(Game.content, biome_id)[0])
		var ids: PackedStringArray = _controller._shop.dex_ids()
		assert_eq(ids, Encyclopedia.species_of(Game.content, biome_id), biome_id)
		total += ids.size()
	assert_eq(total, Game.content.species_ids().size())


func test_unknown_species_are_hidden_and_found_ones_are_shown() -> void:
	await _press(KEY_E)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_dex_species("abyss_giant_squid")
	assert_eq(shop._name.text, "???")
	shop.select_dex_species("pond_guppy")
	assert_eq(shop._name.text, tr("SPECIES_POND_GUPPY"))
	assert_true(shop._owned.text.contains("[x]Normal"))
	assert_true(shop._owned.text.contains("[ ]Albina"))
	assert_true(shop._rarity.text.contains("Estanque"))


func test_a_new_fish_fills_its_entry_at_once() -> void:
	Game.state.wallet.add(1.0e6)
	await _press(KEY_E)
	await wait_frames(2)
	var shop: ShopPanel = _controller._shop
	shop.select_dex_species("pond_carp")
	assert_eq(shop._name.text, "???")
	Game.state.unlocked["pond_carp"] = true
	Game.buy_fish("pond_carp")
	await wait_frames(2)
	shop.select_dex_species("pond_carp")
	assert_eq(shop._name.text, tr("SPECIES_POND_CARP"))


func test_the_dex_tab_cannot_buy_anything() -> void:
	await _press(KEY_E)
	await wait_frames(2)
	var before: float = Game.state.wallet.shells
	_controller._shop.buy_selected()
	assert_eq(Game.state.wallet.shells, before)
	assert_false(_controller._shop._buy.is_enabled)


func test_the_portrait_shows_a_silhouette_until_the_fish_is_found() -> void:
	await _press(KEY_E)
	var shop: ShopPanel = _controller._shop
	shop.select_dex_species("abyss_giant_squid")
	assert_true(shop.portrait().is_silhouette())
	shop.select_dex_species("pond_guppy")
	assert_false(shop.portrait().is_silhouette())
	assert_eq(shop.portrait().current_index(), 0)


func test_the_portrait_is_only_visible_in_the_encyclopedia_tab() -> void:
	await _press(KEY_E)
	var shop: ShopPanel = _controller._shop
	assert_true(shop.portrait().is_shown)
	shop.select_tab(0)
	assert_false(shop.portrait().is_shown)


func test_the_portrait_cycles_through_the_variants_that_were_found() -> void:
	Game.state.discover("pond_guppy", "golden")
	Game.state.discover("pond_guppy", "albino")
	await _press(KEY_E)
	var shop: ShopPanel = _controller._shop
	shop.select_dex_species("pond_guppy")
	assert_eq(shop.portrait().current_index(), 0)
	shop.portrait().update(AsciiPortrait.VARIANT_SECONDS + 0.1, null)
	assert_eq(shop.portrait().current_index(), 1)
	shop.portrait().update(AsciiPortrait.VARIANT_SECONDS, null)
	assert_eq(shop.portrait().current_index(), 2)
	shop.portrait().update(AsciiPortrait.VARIANT_SECONDS, null)
	assert_eq(shop.portrait().current_index(), 0)


func test_the_portrait_body_ripples_like_in_the_tank() -> void:
	await _press(KEY_E)
	var shop: ShopPanel = _controller._shop
	shop.select_dex_species("pond_guppy")
	var portrait: AsciiPortrait = shop.portrait()
	var offsets: Array[float] = []
	for _step: int in range(30):
		portrait.update(0.1, null)
		offsets.append(portrait.tail_offset())
	var lowest: float = offsets.min()
	var highest: float = offsets.max()
	assert_gt(highest - lowest, 0.05, "la cola sube y baja")
	assert_eq(portrait.head_offset(), 0.0, "la cabeza no se mueve")
