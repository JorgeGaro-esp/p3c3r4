class_name FishCard
extends UiPanel
## Ficha de un pez: nombre, rareza, producción y felicidad. Se dibuja encima de la
## pecera, en una esquina, sin cambiar el tamaño de la ventana.

signal close_requested

const WIDTH: int = 34
const HEIGHT: int = 7
const MARGIN: int = 1

var _fish: Fish = null
var _frame: AsciiFrame = AsciiFrame.new()
var _name: AsciiLabel = null
var _rarity: AsciiLabel = null
var _production: AsciiLabel = null
var _happiness: AsciiLabel = null
var _bar: AsciiProgress = AsciiProgress.new()
var _close: AsciiButton = null


func _init(root: UiRoot) -> void:
	super(root)
	_add(_frame, UiRoot.LAYER_PANEL)
	_name = _make_label("", AsciiColors.AMBER)
	_rarity = _make_label("")
	_production = _make_label("")
	_happiness = _make_label("")
	_add(_bar)
	_close = _make_button("")
	_close.activated.connect(func() -> void: close_requested.emit())
	EventBus.shells_changed.connect(func(_shells: float) -> void: _update_texts())
	EventBus.fish_removed.connect(_on_fish_removed)
	refresh()


## El pez que muestra la ficha, o null.
func fish() -> Fish:
	return _fish


## Cambia el pez mostrado. Con null la ficha queda vacía.
func show_fish(new_fish: Fish) -> void:
	_fish = new_fish
	_update_texts()


## Dónde cabe la ficha dentro de [param tank_area], o un rectángulo vacío si no cabe.
static func fit_in(tank_area: Rect2i) -> Rect2i:
	if tank_area.size.x < WIDTH + 2 * MARGIN or tank_area.size.y < HEIGHT + 2 * MARGIN:
		return Rect2i()
	return Rect2i(tank_area.position + Vector2i(MARGIN, MARGIN), Vector2i(WIDTH, HEIGHT))


func layout(area: Rect2i) -> void:
	_frame.rect = area
	var left: int = area.position.x + 2
	var top: int = area.position.y
	var inner: int = area.size.x - 4
	_name.rect = Rect2i(left, top + 1, inner, 1)
	_rarity.rect = Rect2i(left, top + 2, inner, 1)
	_production.rect = Rect2i(left, top + 3, inner, 1)
	_happiness.rect = Rect2i(left, top + 4, inner, 1)
	_bar.rect = Rect2i(left, top + 5, mini(inner, 20), 1)
	_close.rect = Rect2i(left + 21, top + 5, maxi(inner - 21, 1), 1)


func refresh() -> void:
	_frame.title = _text("FISH_CARD_TITLE")
	_close.label = "[Esc]"
	_update_texts()


func _on_fish_removed(_tank_index: int, removed: Fish) -> void:
	if removed == _fish:
		_fish = null
		close_requested.emit()


func _update_texts() -> void:
	if _fish == null:
		return
	var def: SpeciesDef = Game.content.get_species(_fish.species_id)
	if def == null:
		return
	var rate: float = Economy.fish_rate(def.base_production, _fish.happiness)
	_name.text = _text(def.name_key)
	_rarity.text = "%s %s" % [def.rarity_symbol(), _text(RarityStyle.name_key(def.rarity))]
	_rarity.color = RarityStyle.color(def.rarity)
	_production.text = (
		_text("FISH_PRODUCTION") % NumberFormat.compact(rate, TranslationServer.get_locale())
	)
	_happiness.text = _text("FISH_HAPPINESS") % roundi(_fish.happiness)
	_bar.value = _fish.happiness / Economy.MAX_HAPPINESS
