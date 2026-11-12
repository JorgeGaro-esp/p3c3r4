class_name TankView
extends Node
## Vista de la pecera: monta el entorno (superficie, arena, algas, burbujas) y los
## peces de prueba sobre un [AsciiCanvas].
##
## Los peces salen de los recursos [SwimmerDef] de `content/species/`: añadir uno
## nuevo no requiere tocar este código. En la Fase 3 los peces pasarán a salir del
## modelo de juego.

const SEED: int = 20261112
const SURFACE_ROWS: int = 1
const SAND_ROWS: int = 2
const START_FISH: int = 9
const MAX_FISH: int = 40
const BUBBLE_GAP_MIN: float = 0.4
const BUBBLE_GAP_MAX: float = 1.6
const LAYER_BACK: int = 0
const LAYER_FISH: int = 10
const LAYER_FRONT: int = 20

@export var canvas_path: NodePath
@export_dir var species_dir: String = "res://content/species"

var canvas: AsciiCanvas

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _sprites: Array[AsciiSprite] = []
var _palettes: Array[AsciiPalette] = []
var _defs: Array[SwimmerDef] = []
var _fish: Array[FishView] = []
var _spawned: int = 0
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
	_load_species()
	canvas.grid_changed.connect(_on_grid_changed)
	_on_grid_changed()
	add_fish(START_FISH)


func _process(delta: float) -> void:
	_next_bubble_in -= delta
	if _next_bubble_in > 0.0 or _fish.is_empty():
		return
	var emitter: FishView = _fish[_rng.randi_range(0, _fish.size() - 1)]
	var mouth: Vector2 = emitter.anchor_cell("eye") + Vector2(float(emitter.motion.facing), 0.0)
	_bubbles.spawn(mouth, _rng)
	_next_bubble_in = _rng.randf_range(BUBBLE_GAP_MIN, BUBBLE_GAP_MAX)


## Añade hasta [param count] peces de prueba, sin pasar de [constant MAX_FISH].
func add_fish(count: int) -> void:
	if _defs.is_empty():
		return
	for _index: int in range(count):
		if _fish.size() >= MAX_FISH:
			return
		_add_one_fish()


## Quita hasta [param count] peces, empezando por los últimos añadidos.
func remove_fish(count: int) -> void:
	for _index: int in range(count):
		if _fish.is_empty():
			return
		var last: FishView = _fish.pop_back()
		canvas.remove_drawable(last)


## Número de peces que hay ahora mismo.
func fish_count() -> int:
	return _fish.size()


## Número de burbujas vivas.
func bubble_count() -> int:
	return _bubbles.count()


func _load_species() -> void:
	var directory: DirAccess = DirAccess.open(species_dir)
	if directory == null:
		push_error("TankView: cannot open %s" % species_dir)
		return
	var names: PackedStringArray = directory.get_files()
	names.sort()
	for file_name: String in names:
		# En una exportación, Godot añade `.remap` al nombre de los recursos.
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var def: SwimmerDef = load(species_dir.path_join(clean_name)) as SwimmerDef
		if def == null:
			continue
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		if not sprite.is_valid():
			push_error("TankView: invalid sprite %s: %s" % [def.sprite_path, sprite.errors])
			continue
		_defs.append(def)
		_sprites.append(sprite)
		_palettes.append(def.build_palette())
	if _defs.is_empty():
		push_error("TankView: no species found in %s" % species_dir)


func _add_one_fish() -> void:
	var index: int = _spawned % _defs.size()
	_spawned += 1
	var def: SwimmerDef = _defs[index]
	var motion: SwimMotion = SwimMotion.new(
		_rng, def.style, def.speed, def.amplitude, def.frequency
	)
	var fish: FishView = FishView.new(_sprites[index], _palettes[index], motion, def.frame_duration)
	fish.layer = LAYER_FISH
	motion.set_bounds(_bounds_for(fish))
	motion.scatter()
	_fish.append(fish)
	canvas.add_drawable(fish)


func _on_grid_changed() -> void:
	var sand_top: int = canvas.row_count - SAND_ROWS
	_surface.configure(canvas.columns)
	_sand.configure(canvas.columns, sand_top, SAND_ROWS)
	_weeds.configure(canvas.columns, sand_top, sand_top - SURFACE_ROWS - 2)
	_bubbles.surface_row = float(SURFACE_ROWS)
	for fish: FishView in _fish:
		fish.motion.set_bounds(_bounds_for(fish))


## Zona donde puede estar la esquina superior izquierda de un pez: bajo la
## superficie, sobre la arena y sin salirse por los lados.
func _bounds_for(fish: FishView) -> Rect2:
	var top: float = float(SURFACE_ROWS + 1)
	var bottom: float = float(canvas.row_count - SAND_ROWS - fish.height)
	var right: float = float(canvas.columns - fish.width)
	return Rect2(0.0, top, maxf(right, 0.0), maxf(bottom - top, 0.0))
