class_name TankTabs
extends UiPanel
## Pestañas de las peceras abiertas, sobre la fila de la superficie del agua.
## Solo se muestran cuando hay más de una pecera.

var _tabs: AsciiTabs = AsciiTabs.new()
var _area: Rect2i = Rect2i()


func _init(root: UiRoot) -> void:
	super(root)
	# Por debajo de la ficha del pez, que se dibuja encima sin mezclarse.
	_add(_tabs, UiRoot.LAYER_PANEL)
	_tabs.tab_changed.connect(_on_tab_changed)
	EventBus.active_tank_changed.connect(_on_state_changed)
	EventBus.tank_unlocked.connect(_on_state_changed)
	refresh()


## Se coloca en la primera fila de [param area] (la zona de la pecera).
func layout(area: Rect2i) -> void:
	_area = area
	_tabs.rect = Rect2i(area.position.x + 1, area.position.y, maxi(area.size.x - 2, 0), 1)


## Muestra las pestañas si hay más de una pecera y [param room] lo permite.
func update_visibility(room: bool) -> void:
	set_active(room and Game.state.tanks.size() > 1 and _area.has_area())


## Vuelve a escribir los nombres (idioma) y marca la pecera activa.
func refresh() -> void:
	var titles: PackedStringArray = PackedStringArray()
	for tank: Tank in Game.state.tanks:
		var biome: BiomeDef = Game.content.biomes.get_biome(tank.biome_id)
		titles.append(_text(biome.name_key) if biome != null else tank.biome_id)
	_tabs.set_titles(titles)
	_tabs.selected = clampi(Game.state.active_tank, 0, maxi(titles.size() - 1, 0))


## Títulos de las pestañas, en orden (para los tests).
func titles() -> PackedStringArray:
	return _tabs.titles


## Pestaña marcada ahora.
func selected() -> int:
	return _tabs.selected


## Elige la pestaña [param index] como lo haría un clic.
func choose(index: int) -> void:
	_tabs.select(index)


func _on_tab_changed(index: int) -> void:
	Game.biomes.set_active(index)


func _on_state_changed(_value: int = 0) -> void:
	refresh()
