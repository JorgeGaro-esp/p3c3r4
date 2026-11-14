class_name FishCard
extends UiPanel
## Ficha de un pez: nombre, rareza, etapa y variante, producción, felicidad y venta.
## Se dibuja encima de la pecera, en una esquina, sin cambiar el tamaño de la ventana.
##
## Vender pide confirmación: el primer clic cambia el botón a «¿Seguro?» y el
## segundo vende. Cambiar de pez o cerrar la ficha cancela la venta pendiente.

signal close_requested

enum Pending { NONE, ONE, SURPLUS }

const WIDTH: int = 34
const HEIGHT: int = 9
const MARGIN: int = 1
const SELL_BUTTON_WIDTH: int = 14

var _fish: Fish = null
var _pending: Pending = Pending.NONE
var _frame: AsciiFrame = AsciiFrame.new()
var _name: AsciiLabel = null
var _rarity: AsciiLabel = null
var _variant: AsciiLabel = null
var _production: AsciiLabel = null
var _happiness: AsciiLabel = null
var _satiety: AsciiLabel = null
var _bar: AsciiProgress = AsciiProgress.new()
var _close: AsciiButton = null
var _sell: AsciiButton = null
var _sell_surplus: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	_add(_frame, UiRoot.LAYER_PANEL)
	_name = _make_label("", AsciiColors.AMBER)
	_rarity = _make_label("")
	_variant = _make_label("")
	_production = _make_label("")
	_happiness = _make_label("")
	_satiety = _make_label("")
	_add(_bar)
	_close = _make_button("")
	_close.activated.connect(func() -> void: close_requested.emit())
	_sell = _make_button("")
	_sell_surplus = _make_button("")
	_sell.activated.connect(_on_sell_pressed)
	_sell_surplus.activated.connect(_on_sell_surplus_pressed)
	EventBus.shells_changed.connect(func(_shells: float) -> void: _update_texts())
	EventBus.fish_removed.connect(_on_fish_removed)
	refresh()


## El pez que muestra la ficha, o null.
func fish() -> Fish:
	return _fish


## Cambia el pez mostrado. Con null la ficha queda vacía.
func show_fish(new_fish: Fish) -> void:
	if new_fish != _fish:
		_pending = Pending.NONE
	_fish = new_fish
	_update_texts()


## Dónde cabe la ficha dentro de [param tank_area], o un rectángulo vacío si no cabe.
static func fit_in(tank_area: Rect2i) -> Rect2i:
	if tank_area.size.x < WIDTH + 2 * MARGIN or tank_area.size.y < HEIGHT + MARGIN:
		return Rect2i()
	return Rect2i(tank_area.position + Vector2i(MARGIN, MARGIN), Vector2i(WIDTH, HEIGHT))


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 2
	var top: int = area.position.y
	var inner: int = area.size.x - 4
	_name.rect = Rect2i(left, top + 1, inner, 1)
	_rarity.rect = Rect2i(left, top + 2, inner, 1)
	_variant.rect = Rect2i(left, top + 3, inner, 1)
	_production.rect = Rect2i(left, top + 4, inner, 1)
	_happiness.rect = Rect2i(left, top + 5, inner, 1)
	_satiety.rect = Rect2i(left, top + 6, inner, 1)
	_bar.rect = Rect2i(left, top + 7, mini(inner, 20), 1)
	_close.rect = Rect2i(left + 21, top + 7, maxi(inner - 21, 1), 1)
	_sell.rect = Rect2i(left, top + 8, SELL_BUTTON_WIDTH, 1)
	_sell_surplus.rect = Rect2i(
		left + SELL_BUTTON_WIDTH + 1, top + 8, maxi(inner - SELL_BUTTON_WIDTH - 1, 1), 1
	)


func refresh() -> void:
	_frame.title = _text("FISH_CARD_TITLE")
	_close.label = "[Esc]"
	_update_texts()


func _on_fish_removed(_tank_index: int, removed: Fish) -> void:
	if removed == _fish:
		_fish = null
		_pending = Pending.NONE
		close_requested.emit()
	elif _pending == Pending.SURPLUS:
		_pending = Pending.NONE
		_update_texts()


func _on_sell_pressed() -> void:
	if _fish == null:
		return
	if _pending != Pending.ONE:
		_pending = Pending.ONE
		_update_texts()
		return
	_pending = Pending.NONE
	Game.sell_fish(_fish)


func _on_sell_surplus_pressed() -> void:
	if _fish == null or _surplus().is_empty():
		return
	if _pending != Pending.SURPLUS:
		_pending = Pending.SURPLUS
		_update_texts()
		return
	_pending = Pending.NONE
	var species_id: String = _fish.species_id
	var variant_id: String = _fish.variant_id
	Game.sell_surplus(species_id, variant_id)
	_update_texts()


## Peces que vendería el botón de sobrantes: los de la misma especie y variante que
## el mostrado, salvo la pareja de cría. Solo con la variante normal: las raras no
## se venden en bloque.
func _surplus() -> Array[Fish]:
	if _fish == null or _fish.variant_id != VariantDef.NORMAL_ID:
		return []
	return Selling.surplus(Game.state.active(), _fish.species_id, _fish.variant_id)


func _update_texts() -> void:
	if _fish == null:
		return
	var def: SpeciesDef = Game.content.get_species(_fish.species_id)
	if def == null:
		return
	var rate: float = Economy.fish_rate(def.base_production, _fish.happiness)
	_name.text = _text(def.name_key)
	_rarity.text = "%s %s" % [def.rarity_symbol(), _text(RarityStyle.name_key(def.rarity))]
	if def.activity == SpeciesDef.Activity.DIURNAL:
		_rarity.text += " · " + _text("ACTIVITY_DIURNAL")
	elif def.activity == SpeciesDef.Activity.NOCTURNAL:
		_rarity.text += " · " + _text("ACTIVITY_NOCTURNAL")
	_rarity.color = RarityStyle.color(def.rarity)
	_production.text = (
		_text("FISH_PRODUCTION") % NumberFormat.compact(rate, TranslationServer.get_locale())
	)
	_happiness.text = _text("FISH_HAPPINESS") % roundi(_fish.happiness)
	_satiety.text = _text("FISH_SATIETY") % roundi(_fish.hunger)
	_bar.value = _fish.happiness / Economy.MAX_HAPPINESS
	_update_variant()
	_update_sell_buttons()


func _update_variant() -> void:
	var variant: VariantDef = Game.content.get_variant(_fish.variant_id)
	var name_key: String = "VARIANT_NORMAL"
	var multiplier: int = 1
	if variant != null:
		name_key = variant.name_key
		multiplier = roundi(variant.sale_multiplier)
	_variant.text = (
		_text("FISH_STAGE_VARIANT")
		% [_text(LifeStage.name_key(_fish.stage())), _text(name_key), multiplier]
	)
	_variant.color = (
		AsciiColors.AMBER if _fish.variant_id != VariantDef.NORMAL_ID else AsciiColors.TEXT
	)


func _update_sell_buttons() -> void:
	var locale: String = TranslationServer.get_locale()
	var value: float = Selling.value_of(_fish, Game.content)
	_sell.label = _text("FISH_SELL") % NumberFormat.compact(value, locale)
	if _pending == Pending.ONE:
		_sell.label = _text("FISH_SELL_CONFIRM")
	var extra: Array[Fish] = _surplus()
	_sell_surplus.is_enabled = not extra.is_empty()
	_sell_surplus.label = ""
	if not extra.is_empty():
		var total: String = NumberFormat.compact(Selling.total_value(extra, Game.content), locale)
		_sell_surplus.label = _text("FISH_SELL_SURPLUS") % [extra.size(), total]
		if _pending == Pending.SURPLUS:
			_sell_surplus.label = _text("FISH_SELL_CONFIRM")
