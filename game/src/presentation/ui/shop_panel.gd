class_name ShopPanel
extends UiPanel
## PROTOTIPO de la tienda (Fase 2, decisión P02): datos de mentira para probar
## cómo caben pestañas, lista, ficha y botones en la franja. La tienda de verdad
## (Fase 5) la sustituirá y leerá el contenido de `content/`.

signal close_requested
signal message(text: String)

const FISH_KEYS: Array[String] = [
	"SHOP_ITEM_GUPPY",
	"SHOP_ITEM_MINNOW",
	"SHOP_ITEM_TETRA",
	"SHOP_ITEM_LOACH",
	"SHOP_ITEM_SNAIL",
	"SHOP_ITEM_GOLDFISH",
	"SHOP_ITEM_ANGEL",
	"SHOP_ITEM_KOI",
]
const FISH_PRICES: Array[int] = [10, 25, 60, 150, 400, 1200, 4000, 15000]
const FISH_RARITY: Array[int] = [0, 0, 1, 1, 2, 2, 3, 4]
const GEAR_KEYS: Array[String] = ["SHOP_ITEM_FILTER", "SHOP_ITEM_FEEDER", "SHOP_ITEM_LAMP"]
const GEAR_PRICES: Array[int] = [100, 500, 2500]
const GEAR_RARITY: Array[int] = [0, 1, 2]
const RARITY_KEYS: Array[String] = [
	"RARITY_COMMON",
	"RARITY_UNCOMMON",
	"RARITY_RARE",
	"RARITY_EPIC",
	"RARITY_LEGENDARY",
]
## Símbolo de rareza: el color nunca es la única señal (GDD §4.2).
const RARITY_SYMBOLS: Array[String] = ["·", "+", "*", "#", "@"]
const FAKE_CAPACITY: int = 8
const FAKE_OWNED_CYCLE: int = 5
const MIN_LIST_WIDTH: int = 24
const MAX_LIST_WIDTH: int = 44
const DETAIL_GAP: int = 2
const CLOSE_BUTTON_WIDTH: int = 16
const BUY_BUTTON_WIDTH: int = 12

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


func _init(root: UiRoot) -> void:
	super(root)
	_frame.title = _text("SHOP_TITLE")
	_frame.is_double = true
	_add(_frame, UiRoot.LAYER_PANEL)
	_tabs.set_titles(PackedStringArray([_text("SHOP_TAB_FISH"), _text("SHOP_TAB_GEAR")]))
	_add(_tabs)
	_add(_list)
	_name = _make_label("", AsciiColors.AMBER)
	_price = _make_label("")
	_rarity = _make_label("")
	_description = _make_label("", AsciiColors.TEXT_DIM)
	_description.wraps = true
	_owned = _make_label("")
	_add(_progress)
	_buy = _make_button("[ %s ]" % _text("UI_BUY"))
	_close = _make_button(_text("UI_CLOSE_PANEL"))
	_tabs.tab_changed.connect(_on_tab_changed)
	_list.selection_changed.connect(_show_detail)
	_list.chosen.connect(func(_index: int) -> void: _buy_selected())
	_buy.activated.connect(_buy_selected)
	_close.activated.connect(func() -> void: close_requested.emit())
	_fill_list()


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


func _keys() -> Array[String]:
	return FISH_KEYS if _tab == 0 else GEAR_KEYS


func _prices() -> Array[int]:
	return FISH_PRICES if _tab == 0 else GEAR_PRICES


func _rarities() -> Array[int]:
	return FISH_RARITY if _tab == 0 else GEAR_RARITY


func _on_tab_changed(index: int) -> void:
	_tab = index
	_fill_list()


func _fill_list() -> void:
	var names: PackedStringArray = PackedStringArray()
	var prices: PackedStringArray = PackedStringArray()
	for index: int in range(_keys().size()):
		names.append(_text(_keys()[index]))
		prices.append("%d ¢" % _prices()[index])
	_list.set_items(names, prices)
	_show_detail(_list.selected_index())


func _show_detail(index: int) -> void:
	if index < 0 or index >= _keys().size():
		return
	var rarity: int = _rarities()[index]
	var owned: int = index % FAKE_OWNED_CYCLE
	_name.text = _text(_keys()[index])
	_price.text = _text("SHOP_PRICE") % _prices()[index]
	_rarity.text = "%s %s" % [RARITY_SYMBOLS[rarity], _text(RARITY_KEYS[rarity])]
	_description.text = _text("SHOP_DESC")
	_owned.text = _text("SHOP_OWNED") % [owned, FAKE_CAPACITY]
	_progress.value = float(owned) / float(FAKE_CAPACITY)


func _buy_selected() -> void:
	var index: int = _list.selected_index()
	if index >= 0 and index < _keys().size():
		message.emit(_text("TOAST_BOUGHT") % _text(_keys()[index]))
