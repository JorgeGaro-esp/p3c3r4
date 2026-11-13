class_name ShopPanel
extends UiPanel
## Tienda de peces: lista las especies del estanque con su precio, rareza y
## condición de desbloqueo, y compra con [method GameService.buy_fish].
##
## Solo muestra y pide: las reglas (coste, capacidad, desbloqueo) viven en `Game`.
## Se refresca sola cuando cambian las conchas, los peces o los desbloqueos.

signal close_requested
signal message(text: String)

const BIOME_ID: String = "pond"
const MIN_LIST_WIDTH: int = 24
const MAX_LIST_WIDTH: int = 44
const DETAIL_GAP: int = 2
const CLOSE_BUTTON_WIDTH: int = 16
const BUY_BUTTON_WIDTH: int = 12

var _ids: PackedStringArray = PackedStringArray()
var _frame: AsciiFrame = AsciiFrame.new()
var _tabs: AsciiTabs = AsciiTabs.new()
var _list: AsciiList = AsciiList.new()
var _name: AsciiLabel = null
var _price: AsciiLabel = null
var _rarity: AsciiLabel = null
var _description: AsciiLabel = null
var _owned: AsciiLabel = null
var _progress: AsciiProgress = AsciiProgress.new()
var _buy: AsciiButton = null
var _close: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_add(_tabs)
	_add(_list)
	_name = _make_label("", AsciiColors.AMBER)
	_price = _make_label("")
	_rarity = _make_label("")
	_description = _make_label("", AsciiColors.TEXT_DIM)
	_description.wraps = true
	_owned = _make_label("")
	_add(_progress)
	_buy = _make_button("")
	_close = _make_button("")
	_list.selection_changed.connect(_show_detail)
	_list.chosen.connect(func(_index: int) -> void: _buy_selected())
	_buy.activated.connect(_buy_selected)
	_close.activated.connect(func() -> void: close_requested.emit())
	EventBus.shells_changed.connect(_on_state_changed)
	EventBus.fish_added.connect(_on_fish_changed)
	EventBus.fish_removed.connect(_on_fish_changed)
	EventBus.species_unlocked.connect(_on_state_changed)
	refresh()


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 1
	var top: int = area.position.y
	var inner: int = area.size.x - 2
	var height: int = area.size.y
	var list_width: int = clampi(floori(float(inner) * 0.4), MIN_LIST_WIDTH, MAX_LIST_WIDTH)
	_tabs.rect = Rect2i(left, top + 1, inner, 1)
	_list.set_rect(Rect2i(left, top + 2, list_width, maxi(height - 4, 1)))
	var detail_x: int = left + list_width + DETAIL_GAP
	var detail_width: int = maxi(inner - list_width - DETAIL_GAP, 1)
	var owned_row: int = top + height - 4
	_name.rect = Rect2i(detail_x, top + 2, detail_width, 1)
	_price.rect = Rect2i(detail_x, top + 3, detail_width, 1)
	_rarity.rect = Rect2i(detail_x, top + 4, detail_width, 1)
	_description.rect = Rect2i(detail_x, top + 5, detail_width, maxi(owned_row - top - 5, 0))
	_owned.rect = Rect2i(detail_x, owned_row, detail_width, 1)
	_progress.rect = Rect2i(detail_x, owned_row + 1, mini(detail_width, 24), 1)
	_buy.rect = Rect2i(detail_x, top + height - 2, BUY_BUTTON_WIDTH, 1)
	_close.rect = Rect2i(detail_x + BUY_BUTTON_WIDTH + 1, top + height - 2, CLOSE_BUTTON_WIDTH, 1)
	_show_detail(_list.selected_index())


## Vuelve a escribir todos los textos (cambio de idioma) y la lista.
func refresh() -> void:
	_frame.title = _text("SHOP_TITLE")
	_tabs.set_titles(PackedStringArray([_text("SHOP_TAB_FISH")]))
	_buy.label = "[ %s ]" % _text("UI_BUY")
	_close.label = _text("UI_CLOSE_PANEL")
	_fill_list()


## Ids de las especies a la venta, de la más barata a la más cara.
func species_ids() -> PackedStringArray:
	return _ids


## Pulsa «Comprar» sobre la especie seleccionada.
func buy_selected() -> void:
	_buy_selected()


## Selecciona la especie [param species_id] (para los tests).
func select_species(species_id: String) -> void:
	var index: int = _ids.find(species_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


func _on_state_changed(_value: Variant = null) -> void:
	if is_active:
		_fill_list()


func _on_fish_changed(_tank_index: int, _fish: Fish) -> void:
	if is_active:
		_fill_list()


func _collect_ids() -> PackedStringArray:
	var entries: Array[SpeciesDef] = []
	for species_id: String in Game.content.species_ids():
		var def: SpeciesDef = Game.content.get_species(species_id)
		if def.biome_id == BIOME_ID:
			entries.append(def)
	entries.sort_custom(
		func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost
	)
	var result: PackedStringArray = PackedStringArray()
	for def: SpeciesDef in entries:
		result.append(def.id)
	return result


func _fill_list() -> void:
	_ids = _collect_ids()
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var prices: PackedStringArray = PackedStringArray()
	var locale: String = TranslationServer.get_locale()
	for species_id: String in _ids:
		var def: SpeciesDef = Game.content.get_species(species_id)
		var unlocked: bool = Game.state.is_unlocked(species_id)
		var shown_name: String = _text(def.name_key) if unlocked else _text("SHOP_LOCKED_NAME")
		names.append("%s %s" % [def.rarity_symbol(), shown_name])
		if unlocked:
			prices.append("%s ¢" % NumberFormat.compact(Game.fish_cost(species_id), locale))
		else:
			prices.append(_text("SHOP_LOCKED_PRICE"))
	_list.set_items(names, prices)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_detail(index: int) -> void:
	if index < 0 or index >= _ids.size():
		_clear_detail()
		return
	var def: SpeciesDef = Game.content.get_species(_ids[index])
	var unlocked: bool = Game.state.is_unlocked(def.id)
	var locale: String = TranslationServer.get_locale()
	_rarity.text = "%s %s" % [def.rarity_symbol(), _text(RarityStyle.name_key(def.rarity))]
	_rarity.color = RarityStyle.color(def.rarity)
	_buy.is_enabled = unlocked
	if unlocked:
		var tank: Tank = Game.state.tanks[0]
		_name.text = _text(def.name_key)
		_price.text = _text("SHOP_PRICE") % NumberFormat.compact(Game.fish_cost(def.id), locale)
		_description.text = _text(def.description_key)
		_owned.text = _text("SHOP_OWNED") % [tank.count_of(def.id), tank.fish.size(), tank.capacity]
		_progress.value = float(tank.fish.size()) / float(maxi(tank.capacity, 1))
	else:
		_name.text = _text("SHOP_LOCKED_NAME")
		_price.text = _text("SHOP_LOCKED_PRICE")
		_description.text = _text("SHOP_LOCKED_HINT") % _unlock_hint(def)
		_owned.text = ""
		_progress.value = Unlocks.progress_ratio(def, Game.state)


func _clear_detail() -> void:
	_name.text = ""
	_price.text = _text("SHOP_EMPTY")
	_rarity.text = ""
	_description.text = ""
	_owned.text = ""
	_progress.value = 0.0
	_buy.is_enabled = false


## Frase de lo que falta para desbloquear [param def] («ganes 100 ¢ en total»).
func _unlock_hint(def: SpeciesDef) -> String:
	var locale: String = TranslationServer.get_locale()
	match def.unlock_kind:
		SpeciesDef.UnlockKind.TOTAL_EARNED:
			return _text("UNLOCK_TOTAL_EARNED") % NumberFormat.compact(def.unlock_amount, locale)
		SpeciesDef.UnlockKind.FISH_COUNT:
			return _text("UNLOCK_FISH_COUNT") % roundi(def.unlock_amount)
		SpeciesDef.UnlockKind.SPECIES_COUNT:
			var needed: SpeciesDef = Game.content.get_species(def.unlock_species_id)
			var needed_name: String = def.unlock_species_id
			if needed != null:
				needed_name = _text(needed.name_key)
			return _text("UNLOCK_SPECIES_COUNT") % [roundi(def.unlock_amount), needed_name]
		_:
			return ""


func _buy_selected() -> void:
	var index: int = _list.selected_index()
	if index < 0 or index >= _ids.size():
		return
	var def: SpeciesDef = Game.content.get_species(_ids[index])
	match Game.buy_fish(def.id):
		GameService.BuyResult.OK:
			message.emit(_text("TOAST_BOUGHT") % _text(def.name_key))
		GameService.BuyResult.NOT_ENOUGH_SHELLS:
			message.emit(_text("TOAST_NOT_ENOUGH"))
		GameService.BuyResult.TANK_FULL:
			message.emit(_text("TOAST_TANK_FULL"))
		GameService.BuyResult.LOCKED:
			message.emit(_text("TOAST_LOCKED"))
		_:
			pass
	_fill_list()
