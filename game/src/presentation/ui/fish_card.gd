class_name FishCard
extends UiPanel
## Ficha de un pez: nombre, rareza, etapa y variante, producción, felicidad y venta.
## Se dibuja encima de la pecera, en una esquina, sin cambiar el tamaño de la ventana.
##
## Vender pide confirmación: el primer clic cambia el botón a «¿Seguro?» y el
## segundo vende. Cambiar de pez o cerrar la ficha cancela la venta pendiente.

signal close_requested
## El ancho que pide el contenido cambió (otro texto, otra cifra): hay que recolocar la ficha.
signal size_changed

enum Pending { NONE, ONE, SURPLUS }

## Ancho mínimo; la ficha crece si el contenido no cabe.
const WIDTH: int = 34
const MAX_WIDTH: int = 60
const BAR_WIDTH: int = 20
const HEIGHT: int = 12
const MARGIN: int = 1
const SELL_BUTTON_WIDTH: int = 12
const NAME_BUTTON_WIDTH: int = 12
const BUTTON_PADDING: int = 2

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
var _rename: AsciiButton = null
var _favorite: AsciiButton = null
var _write: AsciiButton = null
var _input: AsciiTextInput = AsciiTextInput.new()
var _name_rect: Rect2i = Rect2i()
var _sell_text: String = ""
var _surplus_text: String = ""
var _last_width: int = WIDTH


func _init(root: UiRoot) -> void:
	super(root)
	_add(_frame, UiRoot.LAYER_PANEL + 5)
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
	_rename = _make_button("")
	_favorite = _make_button("")
	_write = _make_button("")
	_add(_input)
	_input.submitted.connect(_on_name_submitted)
	_input.cancelled.connect(_stop_editing)
	_write.activated.connect(_on_write_pressed)
	_rename.activated.connect(_on_rename_pressed)
	_favorite.activated.connect(_on_favorite_pressed)
	_sell.activated.connect(_on_sell_pressed)
	_sell_surplus.activated.connect(_on_sell_surplus_pressed)
	EventBus.shells_changed.connect(func(_shells: float) -> void: _update_texts())
	EventBus.fish_removed.connect(_on_fish_removed)
	refresh()


## El pez que muestra la ficha, o null.
func fish() -> Fish:
	return _fish


## Al cerrar la ficha se cancela el apodo que se estuviera escribiendo.
func set_active(value: bool) -> void:
	super(value)
	if not value:
		_stop_editing()


## Si se está escribiendo un apodo.
func is_editing_name() -> bool:
	return _input.is_editing


## Cambia el pez mostrado. Con null la ficha queda vacía.
func show_fish(new_fish: Fish) -> void:
	if new_fish != _fish:
		_pending = Pending.NONE
		_stop_editing()
	_fish = new_fish
	_update_texts()


## Ancho que necesita la ficha para mostrar todo su texto sin recortar.
func desired_width() -> int:
	var inner: int = 0
	for label: AsciiLabel in [_name, _rarity, _variant, _production, _happiness, _satiety]:
		inner = maxi(inner, label.text.length())
	inner = maxi(inner, BAR_WIDTH + 1 + _close.label.length())
	inner = maxi(inner, _sell_width() + 1 + _wide(_surplus_text))
	inner = maxi(inner, _rename_width() + 1 + _wide(_favorite.label))
	inner = maxi(inner, _wide(_write.label))
	return clampi(inner + 4, WIDTH, MAX_WIDTH)


## Dónde cabe la ficha dentro de [param tank_area], o un rectángulo vacío si no cabe.
func fit_in(tank_area: Rect2i) -> Rect2i:
	var width: int = mini(desired_width(), tank_area.size.x - 2 * MARGIN)
	if width < WIDTH or tank_area.size.y < HEIGHT + MARGIN:
		return Rect2i()
	return Rect2i(tank_area.position + Vector2i(MARGIN, MARGIN), Vector2i(width, HEIGHT))


static func _wide(text: String) -> int:
	return text.length() + BUTTON_PADDING


func _sell_width() -> int:
	return maxi(SELL_BUTTON_WIDTH, _wide(_sell_text))


func _rename_width() -> int:
	return maxi(NAME_BUTTON_WIDTH, _wide(_rename.label))


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 2
	var top: int = area.position.y
	var inner: int = area.size.x - 4
	_name_rect = Rect2i(left, top + 1, inner, 1)
	_name.rect = _name_rect
	_input.rect = Rect2i()
	_rarity.rect = Rect2i(left, top + 2, inner, 1)
	_variant.rect = Rect2i(left, top + 3, inner, 1)
	_production.rect = Rect2i(left, top + 4, inner, 1)
	_happiness.rect = Rect2i(left, top + 5, inner, 1)
	_satiety.rect = Rect2i(left, top + 6, inner, 1)
	_bar.rect = Rect2i(left, top + 7, mini(inner, BAR_WIDTH), 1)
	_close.rect = Rect2i(left + BAR_WIDTH + 1, top + 7, maxi(inner - BAR_WIDTH - 1, 1), 1)
	var sell_width: int = mini(_sell_width(), maxi(inner - 2, 1))
	_sell.rect = Rect2i(left, top + 8, sell_width, 1)
	_sell_surplus.rect = Rect2i(left + sell_width + 1, top + 8, maxi(inner - sell_width - 1, 1), 1)
	var rename_width: int = mini(_rename_width(), maxi(inner - 2, 1))
	_rename.rect = Rect2i(left, top + 9, rename_width, 1)
	_favorite.rect = Rect2i(left + rename_width + 1, top + 9, maxi(inner - rename_width - 1, 1), 1)
	_write.rect = Rect2i(left, top + 10, inner, 1)
	_set_editing_layout(_input.is_editing)


func refresh() -> void:
	_frame.title = _text("FISH_CARD_TITLE")
	_close.label = "[Esc]"
	_update_texts()


func _on_fish_removed(_tank_index: int, removed: Fish) -> void:
	if removed == _fish:
		_fish = null
		_pending = Pending.NONE
		_stop_editing()
		close_requested.emit()
	elif _pending == Pending.SURPLUS:
		_pending = Pending.NONE
		_update_texts()


func _on_rename_pressed() -> void:
	if _fish == null:
		return
	_fish.nickname = FishNames.next(_fish.nickname)
	_update_texts()


## Pulsar el botón de escribir empieza a escribir un apodo propio; si ya se estaba
## escribiendo, lo guarda.
func _on_write_pressed() -> void:
	if _fish == null:
		return
	if _input.is_editing:
		var typed: String = _input.text.strip_edges()
		_input.stop()
		_on_name_submitted(typed)
		return
	_input.prefix = _text("FISH_NAME_PROMPT") + " "
	_input.begin(_fish.nickname)
	_set_editing_layout(true)
	_update_texts()


func _on_name_submitted(value: String) -> void:
	if _fish != null:
		_fish.nickname = value
	_set_editing_layout(false)
	_update_texts()


func _stop_editing() -> void:
	_input.stop()
	_set_editing_layout(false)
	_update_texts()


## Con el campo de texto activo ocupa la fila del nombre (que se esconde).
func _set_editing_layout(editing: bool) -> void:
	_input.rect = _name_rect if editing else Rect2i()
	_name.rect = Rect2i() if editing else _name_rect


func _on_favorite_pressed() -> void:
	if _fish == null:
		return
	_fish.favorite = not _fish.favorite
	_pending = Pending.NONE
	_update_texts()


func _on_sell_pressed() -> void:
	if _fish == null or _fish.favorite:
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
	if not _fish.nickname.is_empty():
		_name.text = "%s (%s)" % [_fish.nickname, _text(def.name_key)]
	if _fish.favorite:
		_name.text = "◆ " + _name.text
	_rarity.text = "%s %s" % [def.rarity_symbol(), _text(RarityStyle.name_key(def.rarity))]
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
	_sell_text = _text("FISH_SELL") % NumberFormat.compact(value, locale)
	_sell.label = _sell_text
	if _pending == Pending.ONE:
		_sell.label = _text("FISH_SELL_CONFIRM")
	_sell.is_enabled = not _fish.favorite
	_rename.label = _text("FISH_RENAME")
	_write.label = _text("FISH_NAME_EDITING" if _input.is_editing else "FISH_WRITE")
	_favorite.label = _text("FISH_FAVORITE_ON") if _fish.favorite else _text("FISH_FAVORITE_OFF")
	var extra: Array[Fish] = _surplus()
	_sell_surplus.is_enabled = not extra.is_empty()
	_surplus_text = ""
	if not extra.is_empty():
		var total: String = NumberFormat.compact(Selling.total_value(extra, Game.content), locale)
		_surplus_text = _text("FISH_SELL_SURPLUS") % [extra.size(), total]
	_sell_surplus.label = _surplus_text
	if _pending == Pending.SURPLUS and not extra.is_empty():
		_sell_surplus.label = _text("FISH_SELL_CONFIRM")
	_notify_size()


## Avisa si el contenido pide otro ancho, para que se recoloque la ficha.
func _notify_size() -> void:
	var width: int = desired_width()
	if width == _last_width:
		return
	_last_width = width
	if is_active:
		size_changed.emit()
