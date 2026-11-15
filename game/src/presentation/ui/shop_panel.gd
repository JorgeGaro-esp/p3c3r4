# gdlint: disable=max-public-methods
# (fachada de la tienda: un método de consulta o de prueba por pestaña)
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
## El jugador quiere volver a ver la secuencia final.
signal final_requested

## Grupos de pestañas: cada acceso de la barra lateral abre solo el suyo.
enum Group { SHOP, DEX, ACHIEVEMENTS, STATS }

const MIN_LIST_WIDTH: int = 24
const MAX_LIST_WIDTH: int = 44
const DETAIL_GAP: int = 2
const CLOSE_BUTTON_WIDTH: int = 16
const BUY_BUTTON_WIDTH: int = 12
const DECORATE_BUTTON_WIDTH: int = 14
## Posición de la pestaña de la Enciclopedia.
const DEX_TAB: int = 4
## Posición de las pestañas de Logros y de Estadísticas.
const ACHIEVEMENTS_TAB: int = 5
const STATS_TAB: int = 6
## Posición de la pestaña de la Gran marea (prestigio).
const PRESTIGE_TAB: int = 7
## Filas especiales de la pestaña de la Gran marea (el resto son mejoras).
const RESET_ENTRY: String = "@reset"
const FINAL_ENTRY: String = "@final"
## Pestañas de la tienda (peces, equipo, decoración, biomas y la Gran marea).
const SHOP_TABS: PackedInt32Array = [0, 1, 2, 3, 7]

var _ids: PackedStringArray = PackedStringArray()
var _equipment_ids: PackedStringArray = PackedStringArray()
var _decor_ids: PackedStringArray = PackedStringArray()
var _biome_ids: PackedStringArray = PackedStringArray()
var _dex_ids: PackedStringArray = PackedStringArray()
var _achievement_ids: PackedStringArray = PackedStringArray()
var _prestige_ids: PackedStringArray = PackedStringArray()
## Verdadero tras el primer pulsado de «Reiniciar»: el segundo lo confirma.
var _reset_armed: bool = false
var _stat_rows: Array[PackedStringArray] = []
var _tab: int = 0
var _group: Group = Group.SHOP
## Pestaña cuya lista se pintó por última vez (para conservar el desplazamiento).
var _filled_tab: int = -1
var _frame: AsciiFrame = AsciiFrame.new()
var _tabs: AsciiTabs = AsciiTabs.new()
## Pestañas de bioma de la Enciclopedia (comparten la fila de las pestañas del grupo).
var _dex_tabs: AsciiTabs = AsciiTabs.new()
var _dex_biomes: PackedStringArray = PackedStringArray()
var _list: AsciiList = AsciiList.new()
var _name: AsciiLabel = null
var _price: AsciiLabel = null
var _rarity: AsciiLabel = null
var _description: AsciiLabel = null
var _owned: AsciiLabel = null
var _progress: AsciiProgress = AsciiProgress.new()
var _portrait: AsciiPortrait = AsciiPortrait.new()
var _book: DexBook = DexBook.new()
var _area: Rect2i = Rect2i()
var _buy: AsciiButton = null
var _close: AsciiButton = null
var _decorate: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_add(_tabs)
	_add(_dex_tabs)
	_add(_list)
	_name = _make_label("", AsciiColors.AMBER)
	_price = _make_label("")
	_rarity = _make_label("")
	_description = _make_label("", AsciiColors.TEXT_DIM)
	_description.wraps = true
	_owned = _make_label("")
	_add(_progress)
	_add(_portrait)
	_add(_book, UiRoot.LAYER_WIDGET + 5)
	_buy = _make_button("")
	_close = _make_button("")
	_decorate = _make_button("", "D")
	_list.selection_changed.connect(_on_selection_changed)
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
	EventBus.achievement_unlocked.connect(_on_state_changed)
	_tabs.tab_changed.connect(_on_tab_changed)
	_dex_tabs.tab_changed.connect(_on_dex_biome_changed)
	_tabs.set_visible_tabs(SHOP_TABS)
	refresh()


func layout(area: Rect2i) -> void:
	_area = area
	_frame.rect = area
	var left: int = area.position.x + 1
	var top: int = area.position.y
	var inner: int = area.size.x - 2
	var height: int = area.size.y
	var list_width: int = clampi(floori(float(inner) * 0.4), MIN_LIST_WIDTH, MAX_LIST_WIDTH)
	_tabs.rect = Rect2i(left, top + 1, inner, 1)
	_dex_tabs.rect = _tabs.rect
	_list.set_rect(Rect2i(left, top + 2, list_width, maxi(height - 4, 1)))
	var detail_x: int = left + list_width + DETAIL_GAP
	var full_width: int = maxi(inner - list_width - DETAIL_GAP, 1)
	var owned_row: int = top + height - 4
	var detail_width: int = full_width
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
	_book.spine = Rect2i()
	_book.page = Rect2i()
	_book.checklist = Rect2i()
	if _tab >= DEX_TAB and _tab != PRESTIGE_TAB:
		_layout_dex(detail_x, top, owned_row, full_width)
	else:
		_portrait.is_shown = false
	if _tab == DEX_TAB:
		_book.spine = Rect2i(left + list_width, area.position.y, DETAIL_GAP, height)
		_book.page = Rect2i(detail_x, top + 2, full_width, maxi(owned_row - top, 1))
	_book.is_shown = is_active and _tab == DEX_TAB
	_show_detail(_list.selected_index())


## Coloca el detalle de la Enciclopedia, Logros o Estadísticas (ver [DexLayout]).
func _layout_dex(detail_x: int, top: int, owned_row: int, full_width: int) -> void:
	var plan: DexLayout = DexLayout.compute(
		_tab == DEX_TAB,
		detail_x,
		top,
		owned_row,
		full_width,
		DexLayout.wanted_portrait_width(AsciiPortrait.widest_fish(Game.content))
	)
	_portrait.rect = plan.portrait
	_portrait.is_shown = is_active and plan.has_portrait
	_name.rect = plan.name_rect
	_rarity.rect = plan.rarity
	_description.rect = plan.description
	_owned.rect = plan.owned
	_price.rect = plan.price
	_progress.rect = plan.progress
	_book.checklist = plan.checklist


## Vuelve a escribir todos los textos (cambio de idioma) y la lista.
func refresh() -> void:
	_tabs.set_titles(
		PackedStringArray(
			[
				_text("SHOP_TAB_FISH"),
				_text("SHOP_TAB_EQUIPMENT"),
				_text("SHOP_TAB_DECOR"),
				_text("SHOP_TAB_BIOMES"),
				_text("SHOP_TAB_DEX"),
				_text("SHOP_TAB_ACHIEVEMENTS"),
				_text("SHOP_TAB_STATS"),
				_text("SHOP_TAB_PRESTIGE")
			]
		)
	)
	_tabs.selected = _tab
	_refresh_dex_tabs()
	_book.heading = _text("DEX_VARIANTS")
	_update_group_header()
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
	_portrait.is_shown = value and _tab == DEX_TAB
	_book.is_shown = value and _tab == DEX_TAB
	_tabs.is_shown = value and _tabs.shown_tabs().size() > 1
	_dex_tabs.is_shown = value and _tab == DEX_TAB


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


## Ids de los logros de la lista, en orden.
func achievement_ids() -> PackedStringArray:
	return _achievement_ids


## Selecciona el logro [param achievement_id] (para los tests).
func select_achievement(achievement_id: String) -> void:
	select_tab(ACHIEVEMENTS_TAB)
	var index: int = _achievement_ids.find(achievement_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


## Ids de las especies de la Enciclopedia, de la más barata a la más cara.
func dex_ids() -> PackedStringArray:
	return _dex_ids


## El retrato de la Enciclopedia (para los tests).
func portrait() -> AsciiPortrait:
	return _portrait


## Pestaña abierta ahora (0 peces ... 4 Enciclopedia).
func current_tab() -> int:
	return _tab


## Selecciona la especie [param species_id] en la Enciclopedia (para los tests).
func select_dex_species(species_id: String) -> void:
	select_tab(DEX_TAB)
	_dex_tabs.select(maxi(_dex_biomes.find(Game.content.get_species(species_id).biome_id), 0))
	var index: int = _dex_ids.find(species_id)
	if index >= 0:
		_list.model.select(index)
		_show_detail(index)


## Cambia a la pestaña [param index] (0 peces, 1 equipo, 2 decoración, 3 biomas,
## 4 Enciclopedia, 5 Logros, 6 Estadísticas, 7 Gran marea). Si pertenece a otro grupo
## de pestañas, pasa a ese grupo.
func select_tab(index: int) -> void:
	_set_group(group_of(index))
	_tabs.select(index)


## Grupo de pestañas que está a la vista.
func group() -> Group:
	return _group


## Grupo al que pertenece la pestaña [param tab].
static func group_of(tab: int) -> Group:
	match tab:
		DEX_TAB:
			return Group.DEX
		ACHIEVEMENTS_TAB:
			return Group.ACHIEVEMENTS
		STATS_TAB:
			return Group.STATS
	return Group.SHOP


## Enseña el grupo [param value] en su primera pestaña (o en la que ya estaba, si es
## de ese grupo).
func show_group(value: Group) -> void:
	if group_of(_tab) == value:
		_set_group(value)
		return
	match value:
		Group.DEX:
			select_tab(DEX_TAB)
		Group.ACHIEVEMENTS:
			select_tab(ACHIEVEMENTS_TAB)
		Group.STATS:
			select_tab(STATS_TAB)
		_:
			select_tab(0)


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


func _on_selection_changed(index: int) -> void:
	_reset_armed = false
	_show_detail(index)
	if _tab == DEX_TAB:
		_book.flip()


## Deja a la vista solo las pestañas del grupo [param value] y pone su título al marco.
func _set_group(value: Group) -> void:
	_group = value
	match value:
		Group.DEX:
			_tabs.set_visible_tabs(PackedInt32Array([DEX_TAB]))
		Group.ACHIEVEMENTS:
			_tabs.set_visible_tabs(PackedInt32Array([ACHIEVEMENTS_TAB]))
		Group.STATS:
			_tabs.set_visible_tabs(PackedInt32Array([STATS_TAB]))
		_:
			_tabs.set_visible_tabs(SHOP_TABS)
	_tabs.is_shown = is_active and _tabs.shown_tabs().size() > 1
	_update_group_header()


## El marco lleva «Tienda», o el nombre de la pestaña si el grupo es de una sola.
func _update_group_header() -> void:
	var shown: PackedInt32Array = _tabs.shown_tabs()
	if shown.size() == 1 and shown[0] < _tabs.titles.size():
		_frame.title = _tabs.titles[shown[0]]
	else:
		_frame.title = _text("SHOP_TITLE")


func _on_tab_changed(index: int) -> void:
	_tab = index
	_reset_armed = false
	_buy.label = "[ %s ]" % _text("UI_BUY")
	_decorate.is_shown = is_active and _tab == 2
	_dex_tabs.is_shown = is_active and _tab == DEX_TAB
	if _area.size != Vector2i.ZERO:
		layout(_area)
	_fill_list()


func _on_fish_changed(_tank_index: int, _fish: Fish) -> void:
	if is_active:
		_fill_list()


func _fill_list() -> void:
	var keep_scroll: int = _list.model.scroll if _filled_tab == _tab else 0
	_fill_tab_list()
	_filled_tab = _tab
	_list.model.scroll = clampi(keep_scroll, 0, _list.model.max_scroll())


func _fill_tab_list() -> void:
	match _tab:
		PRESTIGE_TAB:
			_fill_prestige_list()
		ACHIEVEMENTS_TAB:
			_fill_achievement_list()
		STATS_TAB:
			_fill_stats_list()
		DEX_TAB:
			_fill_dex_list()
		3:
			_fill_biome_list()
		1:
			_fill_equipment_list()
		2:
			_fill_decoration_list()
		_:
			_fill_fish_list()


func _fill_fish_list() -> void:
	_ids = Encyclopedia.species_of(Game.content, Game.state.active().biome_id)
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
	_decor_ids = DecorationShelf.sellable_in(Game.content, Game.state.active().biome_id)
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
## Pone los nombres de los biomas en sus pestañas (se conserva el bioma elegido).
func _refresh_dex_tabs() -> void:
	var keep: int = _dex_tabs.selected
	_dex_biomes = Game.content.biomes.ids()
	var titles: PackedStringArray = PackedStringArray()
	for biome_id: String in _dex_biomes:
		titles.append(_text(Game.content.biomes.get_biome(biome_id).name_key))
	_dex_tabs.set_titles(titles)
	_dex_tabs.selected = clampi(keep, 0, maxi(titles.size() - 1, 0))


func _on_dex_biome_changed(_index: int) -> void:
	_filled_tab = -1
	_list.model.select(0)
	_fill_list()


func _fill_dex_list() -> void:
	var biome_id: String = ""
	if _dex_tabs.selected < _dex_biomes.size():
		biome_id = _dex_biomes[_dex_tabs.selected]
	_dex_ids = Encyclopedia.species_of(Game.content, biome_id)
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	var total_variants: int = Game.content.variant_ids().size()
	for species_id: String in _dex_ids:
		var def: SpeciesDef = Game.content.get_species(species_id)
		var found: int = Encyclopedia.variants_found(Game.state, Game.content, species_id)
		var shown_name: String = _text(def.name_key) if found > 0 else _text("DEX_UNKNOWN")
		names.append("%s %s" % [def.rarity_symbol(), shown_name])
		extras.append("%d/%d" % [found, total_variants])
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_dex_detail(index: int) -> void:
	_buy.is_enabled = false
	var species_total: Vector2i = Encyclopedia.species_progress(Game.state, Game.content)
	_price.text = _text("DEX_TOTALS") % [species_total.x, species_total.y]
	if index < 0 or index >= _dex_ids.size():
		_clear_detail()
		_price.text = _text("DEX_TOTALS") % [species_total.x, species_total.y]
		_portrait.clear()
		_book.set_variants(PackedStringArray(), [])
		return
	var def: SpeciesDef = Game.content.get_species(_dex_ids[index])
	var found: int = Encyclopedia.variants_found(Game.state, Game.content, def.id)
	var biome: BiomeDef = Game.content.biomes.get_biome(def.biome_id)
	var rarity_name: String = _text(RarityStyle.name_key(def.rarity))
	_rarity.text = "%s %s · %s" % [def.rarity_symbol(), rarity_name, _text(biome.name_key)]
	_rarity.color = RarityStyle.color(def.rarity)
	if found > 0:
		_name.text = _text(def.name_key)
		_description.text = _text(def.description_key)
		_owned.text = DexText.variant_line(def)
	else:
		_name.text = _text("DEX_UNKNOWN")
		_description.text = _text("DEX_UNKNOWN_HINT")
		_owned.text = ""
	var total_variants: int = Game.content.variant_ids().size()
	_progress.value = float(found) / float(maxi(total_variants, 1))
	_show_portrait(def)
	_book.set_variants(DexText.variant_names(), DexText.found_flags(def))


## Pone la foto de [param def]: cada variante que se ha tenido o, si no hay ninguna,
## su silueta.
func _show_portrait(def: SpeciesDef) -> void:
	_portrait.show_species(def, DexText.discovered_looks(def), DexText.discovered_names(def))


func _fill_achievement_list() -> void:
	_achievement_ids = Game.content.achievements.ids()
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	var locale: String = TranslationServer.get_locale()
	for achievement_id: String in _achievement_ids:
		var def: AchievementDef = Game.content.achievements.get_achievement(achievement_id)
		var done: bool = Game.state.achievements.has(achievement_id)
		names.append("[%s] %s" % ["x" if done else " ", _text(def.name_key)])
		extras.append(NumberFormat.percent(def.reward_percent, locale))
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_achievement_detail(index: int) -> void:
	_buy.is_enabled = false
	var locale: String = TranslationServer.get_locale()
	_price.text = AchievementText.summary(Game.state, Game.content, locale)
	if index < 0 or index >= _achievement_ids.size():
		_name.text = ""
		_rarity.text = ""
		_description.text = ""
		_owned.text = ""
		_progress.value = 0.0
		return
	var def: AchievementDef = Game.content.achievements.get_achievement(_achievement_ids[index])
	var done: bool = Game.state.achievements.has(def.id)
	var state_key: String = "ACH_STATE_DONE" if done else "ACH_STATE_PENDING"
	_name.text = _text(def.name_key)
	_rarity.text = "%s · %s" % [_text(state_key), AchievementText.reward_text(def, locale)]
	_rarity.color = AsciiColors.SEAWEED_LIGHT if done else AsciiColors.TEXT
	_description.text = AchievementText.description(def, Game.content, locale)
	_owned.text = AchievementText.progress_text(def, Game.state, Game.content, locale)
	_progress.value = 1.0 if done else Achievements.progress_ratio(def, Game.state, Game.content)


func _fill_stats_list() -> void:
	_stat_rows = AchievementText.stat_rows(Game.state, Game.content, TranslationServer.get_locale())
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	for row: PackedStringArray in _stat_rows:
		names.append(row[0])
		extras.append(row[1])
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_stats_detail(index: int) -> void:
	_buy.is_enabled = false
	_rarity.text = ""
	_owned.text = ""
	_progress.value = 0.0
	_price.text = AchievementText.summary(Game.state, Game.content, TranslationServer.get_locale())
	if index < 0 or index >= _stat_rows.size():
		_name.text = ""
		_description.text = ""
		return
	_name.text = _stat_rows[index][0]
	_description.text = _stat_rows[index][1]


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
	match _tab:
		PRESTIGE_TAB:
			_show_prestige_detail(index)
		ACHIEVEMENTS_TAB:
			_show_achievement_detail(index)
		STATS_TAB:
			_show_stats_detail(index)
		DEX_TAB:
			_show_dex_detail(index)
		3:
			_show_biome_detail(index)
		2:
			_show_decoration_detail(index)
		1:
			_show_equipment_detail(index)
		_:
			_show_fish_detail(index)


func _show_fish_detail(index: int) -> void:
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
	if _tab == PRESTIGE_TAB:
		_buy_prestige()
		return
	if _tab >= DEX_TAB:
		return
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


func _fill_prestige_list() -> void:
	_prestige_ids = PackedStringArray([RESET_ENTRY])
	_prestige_ids.append_array(Game.content.prestige.ids())
	if Game.state.prestige.final_reached:
		_prestige_ids.append(FINAL_ENTRY)
	var previous: int = _list.selected_index()
	var names: PackedStringArray = PackedStringArray()
	var extras: PackedStringArray = PackedStringArray()
	for entry: String in _prestige_ids:
		if entry == RESET_ENTRY:
			names.append(_text("PRESTIGE_ROW_RESET"))
			extras.append("+%d %s" % [Game.prestige.pending_pearls(), PrestigeText.PEARL_SYMBOL])
		elif entry == FINAL_ENTRY:
			names.append(_text("PRESTIGE_ROW_FINAL"))
			extras.append("")
		else:
			var def: PrestigeUpgradeDef = Game.content.prestige.get_upgrade(entry)
			names.append(_text(def.name_key))
			var level: int = Game.state.prestige.level_of(entry)
			extras.append("%d/%d" % [level, def.max_level])
	_list.set_items(names, extras)
	if previous >= 0:
		_list.model.select(previous)
	_show_detail(_list.selected_index())


func _show_prestige_detail(index: int) -> void:
	_rarity.color = AsciiColors.TEXT
	_owned.text = ""
	_progress.value = 0.0
	_buy.is_enabled = false
	if index < 0 or index >= _prestige_ids.size():
		_name.text = ""
		_price.text = PrestigeText.held_line(Game.state)
		_rarity.text = ""
		_description.text = ""
		return
	var entry: String = _prestige_ids[index]
	var locale: String = TranslationServer.get_locale()
	if entry == RESET_ENTRY:
		_show_reset_detail(locale)
	elif entry == FINAL_ENTRY:
		_name.text = _text("PRESTIGE_ROW_FINAL")
		_price.text = PrestigeText.held_line(Game.state)
		_rarity.text = ""
		_description.text = _text("PRESTIGE_FINAL_DESC")
		_buy.label = "[ %s ]" % _text("PRESTIGE_BUTTON_FINAL")
		_buy.is_enabled = true
	else:
		var def: PrestigeUpgradeDef = Game.content.prestige.get_upgrade(entry)
		var level: int = Game.state.prestige.level_of(entry)
		_name.text = _text(def.name_key)
		_price.text = PrestigeText.cost_line(def, Game.state)
		_rarity.text = PrestigeText.level_line(def, level, locale)
		_description.text = _text(def.description_key)
		_progress.value = float(level) / float(def.max_level)
		_buy.label = "[ %s ]" % _text("UI_BUY")
		_buy.is_enabled = Prestige.can_buy(Game.state, def)


func _show_reset_detail(locale: String) -> void:
	var can_reset: bool = Game.prestige.can_reset()
	_name.text = _text("PRESTIGE_ROW_RESET")
	_price.text = PrestigeText.held_line(Game.state)
	_rarity.text = PrestigeText.gain_line(Game.state)
	_rarity.color = AsciiColors.AMBER if can_reset else AsciiColors.TEXT_DIM
	_description.text = _text("PRESTIGE_RESET_DESC")
	if Game.state.prestige.final_reached:
		_description.text += " " + _text("PRESTIGE_INFINITE")
	var run: float = Prestige.run_earned(Game.state)
	_owned.text = _text("PRESTIGE_RUN_EARNED") % NumberFormat.compact(run, locale)
	var root: float = sqrt(run / Prestige.SHELLS_PER_PEARL_SQUARED)
	_progress.value = root - floorf(root)
	var key: String = "PRESTIGE_BUTTON_CONFIRM" if _reset_armed else "PRESTIGE_BUTTON_RESET"
	_buy.label = "[ %s ]" % _text(key)
	_buy.is_enabled = can_reset


func _buy_prestige() -> void:
	var index: int = _list.selected_index()
	if index < 0 or index >= _prestige_ids.size():
		return
	var entry: String = _prestige_ids[index]
	if entry == RESET_ENTRY:
		_reset_prestige()
		return
	if entry == FINAL_ENTRY:
		final_requested.emit()
		return
	var def: PrestigeUpgradeDef = Game.content.prestige.get_upgrade(entry)
	if Game.prestige.buy_upgrade(entry):
		message.emit(_text("TOAST_PRESTIGE_UPGRADE") % _text(def.name_key))
	else:
		message.emit(_text("TOAST_PRESTIGE_NOT_ENOUGH"))
	_fill_list()


## Primer pulsado: pide confirmación. Segundo pulsado: hace la Gran marea.
func _reset_prestige() -> void:
	if not Game.prestige.can_reset():
		message.emit(_text("TOAST_PRESTIGE_NOT_YET"))
		return
	if not _reset_armed:
		_reset_armed = true
		_show_detail(_list.selected_index())
		return
	_reset_armed = false
	var gained: int = Game.prestige.reset()
	if gained >= 0:
		message.emit(_text("TOAST_PRESTIGE") % gained)
	_fill_list()
