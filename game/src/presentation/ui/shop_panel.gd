class_name ShopPanel
extends UiPanel
## Tienda de peces: lista las especies del estanque con su precio, rareza y
## condición de desbloqueo, y compra con [method GameService.buy_fish].
##
## Solo muestra y pide: las reglas (coste, capacidad, desbloqueo) viven en `Game`.
## Se refresca sola cuando cambian las conchas, los peces o los desbloqueos.

signal close_requested
signal message(text: String)
## El jugador quiere colocar decoración (pasa al modo decorar).
signal decorate_requested

const MIN_LIST_WIDTH: int = 24
const MAX_LIST_WIDTH: int = 44
const DETAIL_GAP: int = 2
const CLOSE_BUTTON_WIDTH: int = 16
const BUY_BUTTON_WIDTH: int = 12
const DECORATE_BUTTON_WIDTH: int = 14

var _ids: PackedStringArray = PackedStringArray()
var _equipment_ids: PackedStringArray = PackedStringArray()
var _decor_ids: PackedStringArray = PackedStringArray()
var _biome_ids: PackedStringArray = PackedStringArray()
var _tab: int = 0
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
var _decorate: AsciiButton = null


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
	_decorate = _make_button("", "D")
	_list.selection_changed.connect(_show_detail)
	_list.chosen.connect(func(_index: int) -> void: _buy_selected())
	_buy.activated.connect(_buy_selected)
	_close.activated.connect(func() -> void: close_requested.emit())
	_decorate.activated.connect(func() -> void: decorate_requested.emit())
	EventBus.decoration_changed.connect(_on_decoration_changed)
	EventBus.shells_changed.connect(_on_state_changed)
	EventBus.fish_added.connect(_on_fish_changed)
	EventBus.fish_removed.connect(_on_fish_changed)
	EventBus.species_unlocked.connect(_on_state_changed)
	EventBus.active_tank_changed.connect(_on_state_changed)
	EventBus.tank_unlocked.connect(_on_state_changed)
	EventBus.equipment_changed.connect(_on_equipment_changed)
	_tabs.tab_changed.connect(_on_tab_changed)
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
	var decorate_x: int = detail_x + BUY_BUTTON_WIDTH + CLOSE_BUTTON_WIDTH + 2
	_decorate.rect = Rect2i(decorate_x, top + height - 2, DECORATE_BUTTON_WIDTH, 1)
	_show_detail(_list.selected_index())


## Vuelve a escribir todos los textos (cambio de idioma) y la lista.
func refresh() -> void:
	_frame.title = _text("SHOP_TITLE")
	_tabs.set_titles(
		PackedStringArray(
			[
				_text("SHOP_TAB_FISH"),
				_text("SHOP_TAB_EQUIPMENT"),
				_text("SHOP_TAB_DECOR"),
				_text("SHOP_TAB_BIOMES")
			]
		)
	)
	_tabs.selected = _tab
	_buy.label = "[ %s ]" % _text("UI_BUY")
	_close.label = _text("UI_CLOSE_PANEL")
	_decorate.label = _text("UI_DECORATE")
	_fill_list()


## Ids de las especies a la venta, de la más barata a la más cara.
func species_ids() -> PackedStringArray:
	return _ids


## Muestra el botón de decorar solo en la pestaña de decoración.
func set_active(value: bool) -> void:
	super(value)
	_decorate.is_shown = value and _tab == 2


## Ids de la decoración a la venta, en el orden de la lista.
func decoration_ids() -> PackedStringArray:
	return _decor_ids


## Selecciona la decoración [param decoration_id] (para los tests).
func select_decoration(decoration_id: String) -> void:
	select_tab(2)
	var index: int = _decor_ids.find(decoration_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


## Ids de los biomas de la lista, en orden de pestaña.
func biome_ids() -> PackedStringArray:
	return _biome_ids


## Selecciona el bioma [param biome_id] (para los tests).
func select_biome(biome_id: String) -> void:
	select_tab(3)
	var index: int = _biome_ids.find(biome_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


## Ids de los equipos a la venta, en el orden de la lista.
func equipment_ids() -> PackedStringArray:
	return _equipment_ids


## Cambia a la pestaña [param index] (0 peces, 1 equipo, 2 decoración, 3 biomas).
func select_tab(index: int) -> void:
	_tabs.select(index)


## Selecciona el equipo [param equipment_id] (para los tests).
func select_equipment(equipment_id: String) -> void:
	select_tab(1)
	var index: int = _equipment_ids.find(equipment_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


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


func _on_equipment_changed(_tank_index: int, _equipment_id: String, _level: int) -> void:
	if is_active:
		_fill_list()


func _on_decoration_changed(_tank_index: int) -> void:
	if is_active:
		_fill_list()


func _on_tab_changed(index: int) -> void:
	_tab = index
	_decorate.is_shown = is_active and _tab == 2
	_fill_list()


func _on_fish_changed(_tank_index: int, _fish: Fish) -> void:
	if is_active:
		_fill_list()


func _collect_ids() -> PackedStringArray:
	var entries: Array[SpeciesDef] = []
	for species_id: String in Game.content.species_ids():
		var def: SpeciesDef = Game.content.get_species(species_id)
		if def.biome_id == Game.state.active().biome_id:
			entries.append(def)
	entries.sort_custom(
		func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost
	)
	var result: PackedStringArray = PackedStringArray()
	for def: SpeciesDef in entries:
		result.append(def.id)
	return result


func _fill_list() -> void:
	if _tab == 3:
		_fill_biome_list()
		return
	if _tab == 1:
		_fill_equipment_list()
		return
	if _tab == 2:
		_fill_decoration_list()
		return
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


func _fill_equipment_list() -> void:
	_equipment_ids = Game.content.equipment_ids()
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	var tank: Tank = Game.state.active()
	var locale: String = TranslationServer.get_locale()
	for equipment_id: String in _equipment_ids:
		var def: EquipmentDef = Game.content.get_equipment(equipment_id)
		names.append("%s %d/%d" % [_text(def.name_key), tank.level_of(def.id), def.max_level])
		var cost: float = Game.equipment_cost(def.id)
		extras.append(
			"%s ¢" % NumberFormat.compact(cost, locale) if cost < INF else _text("SHOP_EQ_MAXED")
		)
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _fill_decoration_list() -> void:
	_decor_ids = _decoration_for_active_biome()
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var prices: PackedStringArray = PackedStringArray()
	var locale: String = TranslationServer.get_locale()
	for decoration_id: String in _decor_ids:
		var def: DecorationDef = Game.content.get_decoration(decoration_id)
		var stock: int = Game.state.decoration_stock.get(decoration_id, 0)
		var suffix: String = " ×%d" % stock if stock > 0 else ""
		names.append("%s%s" % [_text(def.name_key), suffix])
		prices.append("%s ¢" % NumberFormat.compact(Game.decoration_cost(def.id), locale))
	_list.set_items(names, prices)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


## Decoración que se vende en la pecera activa: la de todos los biomas y la del suyo.
func _decoration_for_active_biome() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	var biome_id: String = Game.state.active().biome_id
	for decoration_id: String in Game.content.decoration_ids():
		var def: DecorationDef = Game.content.get_decoration(decoration_id)
		if def.biome_id.is_empty() or def.biome_id == biome_id:
			ids.append(decoration_id)
	return ids


func _fill_biome_list() -> void:
	_biome_ids = Game.content.biomes.ids()
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	var locale: String = TranslationServer.get_locale()
	for biome_id: String in _biome_ids:
		var biome: BiomeDef = Game.content.biomes.get_biome(biome_id)
		names.append(_text(biome.name_key))
		if Game.state.tank_index_of(biome_id) >= 0:
			extras.append(_text("SHOP_BIOME_OPEN"))
		else:
			extras.append("%s ¢" % NumberFormat.compact(biome.unlock_cost, locale))
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_biome_detail(index: int) -> void:
	if index < 0 or index >= _biome_ids.size():
		_clear_detail()
		return
	var biome: BiomeDef = Game.content.biomes.get_biome(_biome_ids[index])
	var locale: String = TranslationServer.get_locale()
	var tank_index: int = Game.state.tank_index_of(biome.id)
	var missing: bool = (
		not biome.requires_biome_id.is_empty()
		and Game.state.tank_index_of(biome.requires_biome_id) < 0
	)
	_name.text = _text(biome.name_key)
	_description.text = _text(biome.description_key)
	_rarity.text = ""
	_owned.text = ""
	_progress.value = 0.0
	if tank_index >= 0:
		_price.text = _text("SHOP_BIOME_OPEN")
		_buy.is_enabled = false
	elif missing:
		var needed: BiomeDef = Game.content.biomes.get_biome(biome.requires_biome_id)
		_price.text = _text("SHOP_BIOME_REQUIRES") % _text(needed.name_key)
		_buy.is_enabled = false
	else:
		_price.text = _text("SHOP_PRICE") % NumberFormat.compact(biome.unlock_cost, locale)
		_progress.value = clampf(Game.state.wallet.shells / maxf(biome.unlock_cost, 1.0), 0.0, 1.0)
		_buy.is_enabled = true


func _buy_biome() -> void:
	var index: int = _list.selected_index()
	if index < 0 or index >= _biome_ids.size():
		return
	var biome: BiomeDef = Game.content.biomes.get_biome(_biome_ids[index])
	match Game.biomes.unlock(biome.id):
		BiomeDirector.Result.NOT_ENOUGH_SHELLS:
			message.emit(_text("TOAST_NOT_ENOUGH"))
		_:
			pass
	_fill_list()


func _show_decoration_detail(index: int) -> void:
	if index < 0 or index >= _decor_ids.size():
		_clear_detail()
		return
	var def: DecorationDef = Game.content.get_decoration(_decor_ids[index])
	var tank: Tank = Game.state.active()
	var locale: String = TranslationServer.get_locale()
	var stock: int = Game.state.decoration_stock.get(def.id, 0)
	var placed: int = Game.state.decoration_owned(def.id) - stock
	_name.text = _text(def.name_key)
	_price.text = _text("SHOP_PRICE") % NumberFormat.compact(Game.decoration_cost(def.id), locale)
	_rarity.text = DecorationText.bonus(def)
	_rarity.color = AsciiColors.SEAWEED_LIGHT
	_description.text = _text(def.description_key)
	_owned.text = _text("SHOP_DECOR_STOCK") % [stock, placed]
	_progress.value = float(tank.decorations.size()) / float(Tank.MAX_DECORATIONS)
	_buy.is_enabled = true


func _buy_decoration() -> void:
	var index: int = _list.selected_index()
	if index < 0 or index >= _decor_ids.size():
		return
	var def: DecorationDef = Game.content.get_decoration(_decor_ids[index])
	match Game.buy_decoration(def.id):
		GameService.DecorResult.OK:
			message.emit(_text("TOAST_DECOR_BOUGHT") % _text(def.name_key))
		GameService.DecorResult.NOT_ENOUGH_SHELLS:
			message.emit(_text("TOAST_NOT_ENOUGH"))
		_:
			pass
	_fill_list()


func _show_equipment_detail(index: int) -> void:
	if index < 0 or index >= _equipment_ids.size():
		_clear_detail()
		return
	var def: EquipmentDef = Game.content.get_equipment(_equipment_ids[index])
	var tank: Tank = Game.state.active()
	var level: int = tank.level_of(def.id)
	var cost: float = Game.equipment_cost(def.id)
	var locale: String = TranslationServer.get_locale()
	_name.text = _text(def.name_key)
	_rarity.text = _text("SHOP_EQ_LEVEL") % [level, def.max_level]
	_rarity.color = AsciiColors.TEXT
	_description.text = _text(def.description_key)
	_owned.text = EquipmentText.effect(def, level, Game.content)
	_progress.value = float(level) / float(def.max_level)
	if cost < INF:
		_price.text = _text("SHOP_EQ_NEXT") % NumberFormat.compact(cost, locale)
	else:
		_price.text = _text("SHOP_EQ_MAXED")
	_buy.is_enabled = cost < INF


func _buy_equipment() -> void:
	var index: int = _list.selected_index()
	if index < 0 or index >= _equipment_ids.size():
		return
	var def: EquipmentDef = Game.content.get_equipment(_equipment_ids[index])
	match Game.buy_equipment(def.id):
		GameService.EquipResult.OK:
			var level: int = Game.state.active().level_of(def.id)
			message.emit(_text("TOAST_EQ_BOUGHT") % [_text(def.name_key), level])
		GameService.EquipResult.NOT_ENOUGH_SHELLS:
			message.emit(_text("TOAST_NOT_ENOUGH"))
		GameService.EquipResult.MAXED:
			message.emit(_text("TOAST_EQ_MAXED"))
		_:
			pass
	_fill_list()


func _show_detail(index: int) -> void:
	if _tab == 3:
		_show_biome_detail(index)
		return
	if _tab == 2:
		_show_decoration_detail(index)
		return
	if _tab == 1:
		_show_equipment_detail(index)
		return
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
		var tank: Tank = Game.state.active()
		_name.text = _text(def.name_key)
		_price.text = _text("SHOP_PRICE") % NumberFormat.compact(Game.fish_cost(def.id), locale)
		_description.text = _text(def.description_key)
		_owned.text = (
			_text("SHOP_OWNED") % [tank.count_of(def.id), tank.fish.size(), tank.total_capacity()]
		)
		_progress.value = float(tank.fish.size()) / float(maxi(tank.total_capacity(), 1))
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
		SpeciesDef.UnlockKind.DECORATION_TAG:
			var tag_name: String = _text("TAG_%s" % def.unlock_tag.to_upper())
			return _text("UNLOCK_DECORATION_TAG") % tag_name
		SpeciesDef.UnlockKind.SPECIES_COUNT:
			var needed: SpeciesDef = Game.content.get_species(def.unlock_species_id)
			var needed_name: String = def.unlock_species_id
			if needed != null:
				needed_name = _text(needed.name_key)
			return _text("UNLOCK_SPECIES_COUNT") % [roundi(def.unlock_amount), needed_name]
		_:
			return ""


func _buy_selected() -> void:
	if _tab == 3:
		_buy_biome()
		return
	if _tab == 2:
		_buy_decoration()
		return
	if _tab == 1:
		_buy_equipment()
		return
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
		GameService.BuyResult.WRONG_BIOME:
			message.emit(_text("TOAST_WRONG_BIOME"))
		_:
			pass
	_fill_list()
