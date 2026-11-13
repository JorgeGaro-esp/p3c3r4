class_name TankView
extends Node
## Vista de la pecera: monta el entorno (superficie, arena, algas, burbujas) y un
## [FishView] por cada pez del modelo, sobre un [AsciiCanvas].
##
## No decide qué peces hay: lee el modelo de `Game` y escucha `EventBus`
## (`fish_added`, `fish_removed`). El aspecto sale de las [SpeciesDef] del
## contenido, así que añadir una especie no requiere tocar este código.

## El jugador hizo clic sobre un pez.
signal fish_clicked(fish: Fish)

const SEED: int = 20261112
const SURFACE_ROWS: int = 1
const SAND_ROWS: int = 2
const BUBBLE_GAP_MIN: float = 0.4
const BUBBLE_GAP_MAX: float = 1.6
const LAYER_BACK: int = 0
const LAYER_FISH: int = 10
const LAYER_FRONT: int = 20


## Lo necesario para dibujar una especie: se prepara una vez y se reutiliza.
class Look:
	extends RefCounted
	var def: SpeciesDef
	var sprite: AsciiSprite
	var palette: AsciiPalette

	func _init(new_def: SpeciesDef, new_sprite: AsciiSprite) -> void:
		def = new_def
		sprite = new_sprite
		palette = new_def.build_palette()


@export var canvas_path: NodePath

var canvas: AsciiCanvas

var _area: Rect2i = Rect2i()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _looks: Dictionary[String, Look] = {}
var _views: Dictionary[Fish, FishView] = {}
var _fish: Array[FishView] = []
var _surface: SurfaceView = SurfaceView.new()
var _sand: SandView = SandView.new()
var _weeds: SeaweedView = SeaweedView.new()
var _bubbles: BubbleField = BubbleField.new()
var _next_bubble_in: float = 1.0


func _ready() -> void:
	canvas = get_node(canvas_path) as AsciiCanvas
	assert(canvas != null, "TankView needs an AsciiCanvas")
	_rng.seed = SEED
	_surface.layer = LAYER_FRONT
	_sand.layer = LAYER_BACK
	_weeds.layer = LAYER_BACK + 1
	_bubbles.layer = LAYER_FISH + 1
	for drawable: AsciiDrawable in [_sand, _weeds, _bubbles, _surface]:
		canvas.add_drawable(drawable)
	_load_looks()
	canvas.grid_changed.connect(_on_grid_changed)
	_on_grid_changed()
	EventBus.fish_added.connect(_on_fish_added)
	EventBus.fish_removed.connect(_on_fish_removed)
	for fish: Fish in Game.state.tanks[0].fish:
		_add_view(fish)


func _process(delta: float) -> void:
	_next_bubble_in -= delta
	if _next_bubble_in > 0.0 or _fish.is_empty():
		return
	var emitter: FishView = _fish[_rng.randi_range(0, _fish.size() - 1)]
	var mouth: Vector2 = emitter.anchor_cell("eye") + Vector2(float(emitter.motion.facing), 0.0)
	_bubbles.spawn(mouth, _rng)
	_next_bubble_in = _rng.randf_range(BUBBLE_GAP_MIN, BUBBLE_GAP_MAX)


## Se usa `_input` y no `_unhandled_input`: el clic llega después de `UiRoot` (que va
## más abajo en el árbol y por tanto recibe antes) y solo si éste no lo consumió.
func _input(event: InputEvent) -> void:
	if get_viewport().is_input_handled():
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	var hit: Fish = fish_at(canvas.cell_at(button.position))
	if hit != null:
		fish_clicked.emit(hit)
		get_viewport().set_input_as_handled()


## Esquina superior izquierda, en celdas, del pez [param fish]; (-1, -1) si no se dibuja.
func fish_position(fish: Fish) -> Vector2:
	if not _views.has(fish):
		return Vector2(-1.0, -1.0)
	return _views[fish].motion.position


## El pez que ocupa la celda [param cell] (el último dibujado si se solapan), o null.
func fish_at(cell: Vector2i) -> Fish:
	var found: Fish = null
	for fish: Fish in _views:
		var view: FishView = _views[fish]
		var origin: Vector2 = view.motion.position
		var area: Rect2 = Rect2(
			origin - Vector2(0.5, 0.5), Vector2(view.width + 1, view.height + 1)
		)
		if area.has_point(Vector2(cell) + Vector2(0.5, 0.5)):
			found = fish
	return found


## Fija la zona de la rejilla donde vive la pecera (en celdas). Sin zona, ocupa
## toda la ventana. La zona cambia cuando aparece la barra lateral o crece la
## ventana hacia arriba.
func set_area(area: Rect2i) -> void:
	_area = area
	if canvas != null:
		_on_grid_changed()


## Número de peces que hay ahora mismo.
func fish_count() -> int:
	return _fish.size()


## Número de burbujas vivas.
func bubble_count() -> int:
	return _bubbles.count()


## Prepara el sprite y la paleta de cada especie del contenido.
func _load_looks() -> void:
	for species_id: String in Game.content.species_ids():
		var def: SpeciesDef = Game.content.get_species(species_id)
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		if not sprite.is_valid():
			push_error("TankView: invalid sprite %s: %s" % [def.sprite_path, sprite.errors])
			continue
		_looks[species_id] = Look.new(def, sprite)


func _add_view(fish: Fish) -> void:
	if not _looks.has(fish.species_id):
		return
	var look: Look = _looks[fish.species_id]
	var def: SpeciesDef = look.def
	var motion: SwimMotion = SwimMotion.new(
		_rng, def.style as SwimMotion.Style, def.speed, def.amplitude, def.frequency
	)
	var view: FishView = FishView.new(look.sprite, look.palette, motion, def.frame_duration)
	view.layer = LAYER_FISH
	motion.set_bounds(_bounds_for(view))
	motion.scatter()
	_views[fish] = view
	_fish.append(view)
	canvas.add_drawable(view)


func _on_fish_added(tank_index: int, fish: Fish) -> void:
	if tank_index == 0:
		_add_view(fish)


func _on_fish_removed(tank_index: int, fish: Fish) -> void:
	if tank_index != 0 or not _views.has(fish):
		return
	var view: FishView = _views[fish]
	_views.erase(fish)
	_fish.erase(view)
	canvas.remove_drawable(view)


func _on_grid_changed() -> void:
	var area: Rect2i = _current_area()
	var sand_top: int = area.end.y - SAND_ROWS
	_surface.configure(area.size.x, area.position.y)
	_sand.configure(area.size.x, sand_top, SAND_ROWS)
	_weeds.configure(area.size.x, sand_top, sand_top - area.position.y - SURFACE_ROWS - 2)
	_bubbles.surface_row = float(area.position.y + SURFACE_ROWS)
	for fish: FishView in _fish:
		fish.motion.set_bounds(_bounds_for(fish))


## Zona de la pecera: la que se fijó o, si no hay, toda la ventana.
func _current_area() -> Rect2i:
	if _area.has_area():
		return _area
	return Rect2i(0, 0, canvas.columns, canvas.row_count)


## Zona donde puede estar la esquina superior izquierda de un pez: bajo la
## superficie, sobre la arena y sin salirse por los lados.
func _bounds_for(fish: FishView) -> Rect2:
	var area: Rect2i = _current_area()
	var top: float = float(area.position.y + SURFACE_ROWS + 1)
	var bottom: float = float(area.end.y - SAND_ROWS - fish.height)
	var right: float = float(area.size.x - fish.width)
	return Rect2(0.0, top, maxf(right, 0.0), maxf(bottom - top, 0.0))
