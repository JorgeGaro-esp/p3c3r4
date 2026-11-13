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
## Hay algo que contar sobre la decoración (para un aviso en la barra lateral).
signal decor_message(text: String)

const SEED: int = 20261112
const SURFACE_ROWS: int = 1
const SAND_ROWS: int = 2
const BUBBLE_GAP_MIN: float = 0.4
const BUBBLE_GAP_MAX: float = 1.6
const LAYER_BACK: int = 0
const LAYER_FISH: int = 10
const LAYER_FRONT: int = 20
## A qué distancia, en celdas, un pez hambriento ve la comida.
const SEEK_RADIUS: float = 30.0
## A qué distancia de la boca se come un copo.
const EAT_DISTANCE: float = 1.8
## Sprites de alevín y juvenil de las especies que no traen los suyos.
const GENERIC_FRY: String = "res://content/sprites/stage_fry.txt"
const AERATOR_BUBBLE_SECONDS: float = 0.7
const GENERIC_JUVENILE: String = "res://content/sprites/stage_juvenile.txt"


## Lo necesario para dibujar una especie: se prepara una vez y se reutiliza.
class Look:
	extends RefCounted
	var def: SpeciesDef
	var sprite: AsciiSprite
	var fry_sprite: AsciiSprite
	var juvenile_sprite: AsciiSprite
	var palette: AsciiPalette

	func _init(
		new_def: SpeciesDef,
		new_sprite: AsciiSprite,
		new_fry: AsciiSprite,
		new_juvenile: AsciiSprite
	) -> void:
		def = new_def
		sprite = new_sprite
		fry_sprite = new_fry
		juvenile_sprite = new_juvenile
		palette = new_def.build_palette()

	## Sprite de la etapa [param stage].
	func sprite_for(stage: LifeStage.Stage) -> AsciiSprite:
		match stage:
			LifeStage.Stage.FRY:
				return fry_sprite
			LifeStage.Stage.JUVENILE:
				return juvenile_sprite
			_:
				return sprite


@export var canvas_path: NodePath

var canvas: AsciiCanvas

var _area: Rect2i = Rect2i()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _looks: Dictionary[String, Look] = {}
var _views: Dictionary[Fish, FishView] = {}
var _owners: Dictionary[FishView, Fish] = {}
var _fish: Array[FishView] = []
var _backdrop: BackdropView = BackdropView.new()
var _particles: ParticleField = ParticleField.new()
var _surface: SurfaceView = SurfaceView.new()
var _sand: SandView = SandView.new()
var _weeds: SeaweedView = SeaweedView.new()
var _bubbles: BubbleField = BubbleField.new()
var _food: FoodField = FoodField.new()
var _spots: GlassSpots = GlassSpots.new()
var _pearls: PearlField = PearlField.new()
var _eggs: EggField = EggField.new()
var _equipment: EquipmentField = EquipmentField.new()
var _decor_back: DecorationField = DecorationField.new(false)
var _decor_front: DecorationField = DecorationField.new(true)
var _decorating: bool = false
var _held_id: String = ""
var _biome: BiomeDef = null
var _aerator_clock: float = 0.0
var _next_bubble_in: float = 1.0


func _ready() -> void:
	canvas = get_node(canvas_path) as AsciiCanvas
	assert(canvas != null, "TankView needs an AsciiCanvas")
	_rng.seed = SEED
	_backdrop.layer = LAYER_BACK - 1
	_particles.layer = LAYER_FISH - 1
	_surface.layer = LAYER_FRONT
	_sand.layer = LAYER_BACK
	_weeds.layer = LAYER_BACK + 1
	_bubbles.layer = LAYER_FISH + 1
	_food.layer = LAYER_FISH + 2
	_pearls.layer = LAYER_FISH + 3
	_spots.layer = LAYER_FRONT + 1
	_eggs.layer = LAYER_BACK + 2
	_equipment.layer = LAYER_BACK + 3
	_decor_back.layer = LAYER_BACK + 4
	_decor_front.layer = LAYER_FISH + 4
	for drawable: AsciiDrawable in [
		_backdrop,
		_particles,
		_sand,
		_weeds,
		_eggs,
		_equipment,
		_decor_back,
		_decor_front,
		_bubbles,
		_surface,
		_food,
		_pearls,
		_spots
	]:
		canvas.add_drawable(drawable)
	_load_looks()
	_biome = Game.content.biomes.get_biome(Game.state.active().biome_id)
	canvas.grid_changed.connect(_on_grid_changed)
	_on_grid_changed()
	EventBus.fish_added.connect(_on_fish_added)
	EventBus.fish_removed.connect(_on_fish_removed)
	EventBus.pearl_spawned.connect(_on_pearl_spawned)
	EventBus.active_tank_changed.connect(_on_active_tank_changed)
	for fish: Fish in Game.state.active().fish:
		_add_view(fish)


func _process(delta: float) -> void:
	_update_care()
	_update_equipment(delta)
	_update_decoration()
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
	if _decorating and _handle_decor_input(event):
		get_viewport().set_input_as_handled()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			if click_cell(canvas.cell_at(button.position)):
				get_viewport().set_input_as_handled()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if clean_at(canvas.cell_at(motion.position)):
			get_viewport().set_input_as_handled()


## Clic del jugador sobre la celda [param cell]. Por orden: limpiar una mancha,
## recoger una perla, abrir la ficha de un pez o echar comida al agua. Devuelve
## verdadero si hizo algo.
func click_cell(cell: Vector2i) -> bool:
	if not _in_water(cell):
		return false
	if clean_at(cell) or _collect_pearl_at(cell):
		return true
	var hit: Fish = fish_at(cell)
	if hit != null:
		fish_clicked.emit(hit)
	else:
		drop_food(cell)
	return true


## Limpia la mancha de alga que haya en [param cell]. Devuelve verdadero si limpió.
func clean_at(cell: Vector2i) -> bool:
	var index: int = _spots.spot_at(cell)
	if index < 0:
		return false
	_spots.mark_for_removal(index)
	if not Game.clean_spot():
		return false
	_spots.set_count(Care.spots_for(Game.state.active().cleanliness))
	return true


## Echa comida desde la celda [param cell] (lo mismo que hace un clic en el agua).
func drop_food(cell: Vector2i) -> void:
	_food.drop(Vector2(cell) + Vector2(0.5, 0.0), _rng)


func food_count() -> int:
	return _food.count()


func spot_count() -> int:
	return _spots.count()


## Verdadero si hay una mancha visible en [param cell].
func spot_cell_hit(cell: Vector2i) -> bool:
	return _spots.spot_at(cell) >= 0


func pearl_count() -> int:
	return _pearls.count()


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


## Número de huevos que se dibujan.
func egg_count() -> int:
	return _eggs.count()


## Número de burbujas vivas.
func bubble_count() -> int:
	return _bubbles.count()


## Prepara el sprite y la paleta de cada especie del contenido.
func _load_looks() -> void:
	for species_id: String in Game.content.species_ids():
		var def: SpeciesDef = Game.content.get_species(species_id)
		var sprite: AsciiSprite = _load_sprite(def.sprite_path)
		var fry: AsciiSprite = _load_sprite(_path_or(def.fry_sprite_path, GENERIC_FRY))
		var juvenile: AsciiSprite = _load_sprite(
			_path_or(def.juvenile_sprite_path, GENERIC_JUVENILE)
		)
		if sprite == null or fry == null or juvenile == null:
			continue
		_looks[species_id] = Look.new(def, sprite, fry, juvenile)


func _path_or(path: String, fallback: String) -> String:
	return fallback if path.is_empty() else path


## Carga un sprite; devuelve null (y avisa) si no es válido.
func _load_sprite(path: String) -> AsciiSprite:
	var sprite: AsciiSprite = SpriteLoader.load_file(path)
	if not sprite.is_valid():
		push_error("TankView: invalid sprite %s: %s" % [path, sprite.errors])
		return null
	return sprite


func _add_view(fish: Fish) -> void:
	if not _looks.has(fish.species_id):
		return
	var view: FishView = _make_view(fish)
	view.motion.scatter()
	_register_view(fish, view)


## Crea la vista de [param fish] con el sprite de su etapa y los colores de su variante.
func _make_view(fish: Fish) -> FishView:
	var look: Look = _looks[fish.species_id]
	var def: SpeciesDef = look.def
	var motion: SwimMotion = SwimMotion.new(
		_rng, def.style as SwimMotion.Style, def.speed, def.amplitude, def.frequency
	)
	var variant_look: VariantDef.Look = VariantDef.Look.NONE
	var variant: VariantDef = Game.content.get_variant(fish.variant_id)
	if variant != null:
		variant_look = variant.look
	var view: FishView = FishView.new(
		look.sprite_for(fish.stage()), look.palette, motion, def.frame_duration, variant_look
	)
	view.layer = LAYER_FISH
	view.stage = fish.stage()
	view.variant_id = fish.variant_id
	motion.set_bounds(_bounds_for(view))
	view.set_mood(fish.happiness)
	return view


func _register_view(fish: Fish, view: FishView) -> void:
	_views[fish] = view
	_owners[view] = fish
	_fish.append(view)
	canvas.add_drawable(view)


## Cambia la vista de [param fish] por una nueva con el sprite de su etapa actual,
## en el mismo sitio y con el mismo rumbo.
func _restage(old_view: FishView, fish: Fish) -> void:
	var view: FishView = _make_view(fish)
	var old: SwimMotion = old_view.motion
	view.motion.position = old.position
	view.motion.velocity = old.velocity
	view.motion.facing = old.facing
	view.motion.phase = old.phase
	view.motion.set_bounds(_bounds_for(view))
	_views.erase(fish)
	_owners.erase(old_view)
	_fish.erase(old_view)
	canvas.remove_drawable(old_view)
	_register_view(fish, view)


## Estado de ánimo, manchas y búsqueda de comida de cada pez.
func _update_care() -> void:
	_spots.set_count(Care.spots_for(Game.state.active().cleanliness))
	_eggs.set_eggs(Game.state.active().eggs, _current_area().size.x)
	for view: FishView in _fish.duplicate():
		var fish: Fish = _owners[view]
		if view.stage != fish.stage():
			_restage(view, fish)
			continue
		view.set_mood(fish.happiness)
		if _food.count() > 0 and fish.hunger < Care.HUNGRY_BELOW:
			_hunt(view, fish)


## Equipo dibujado, burbujas del aireador y perlas que recoge el imán.
func _update_equipment(delta: float) -> void:
	var tank: Tank = Game.state.active()
	_equipment.set_equipment(tank.equipment, Game.content)
	if tank.bonuses.magnet_delay > 0.0:
		for value: float in _pearls.take_ripe(tank.bonuses.magnet_delay):
			Game.collect_pearl(value)
	if tank.level_of("aerator") > 0 and _equipment.count() > 0:
		_aerator_clock += delta
		if _aerator_clock >= AERATOR_BUBBLE_SECONDS:
			_aerator_clock = 0.0
			var origin: Vector2 = _equipment.position_of("aerator")
			_bubbles.spawn(origin + Vector2(0.0, -1.0), _rng)


## Número de equipos que se dibujan.
func equipment_count() -> int:
	return _equipment.count()


## Un pez hambriento nada hacia el copo más cercano y se lo come al llegar.
func _hunt(view: FishView, fish: Fish) -> void:
	var mouth: Vector2 = view.anchor_cell("eye")
	var index: int = _food.nearest_to(mouth, SEEK_RADIUS)
	if index < 0:
		return
	var flake: Vector2 = _food.position_of(index)
	if mouth.distance_to(flake) <= EAT_DISTANCE:
		if Game.feed_fish(fish):
			_food.remove_at(index)
		return
	view.motion.seek(flake - (mouth - view.motion.position))


func _in_water(cell: Vector2i) -> bool:
	var area: Rect2i = _current_area()
	var water: Rect2i = Rect2i(
		area.position.x,
		area.position.y + SURFACE_ROWS,
		area.size.x,
		area.size.y - SURFACE_ROWS - SAND_ROWS
	)
	return water.has_point(cell)


func _collect_pearl_at(cell: Vector2i) -> bool:
	var index: int = _pearls.pearl_at(cell)
	if index < 0:
		return false
	Game.collect_pearl(_pearls.take(index))
	return true


func _on_pearl_spawned(tank_index: int, fish: Fish, value: float) -> void:
	if tank_index != Game.state.active_tank or not _views.has(fish):
		return
	var view: FishView = _views[fish]
	var start: Vector2 = view.motion.position + Vector2(float(view.width) * 0.5, float(view.height))
	var evicted: float = _pearls.add(start, value)
	if evicted > 0.0:
		Game.collect_pearl(evicted)


func _on_fish_added(tank_index: int, fish: Fish) -> void:
	if tank_index == Game.state.active_tank and not _views.has(fish):
		_add_view(fish)


func _on_fish_removed(tank_index: int, fish: Fish) -> void:
	if tank_index != Game.state.active_tank or not _views.has(fish):
		return
	var view: FishView = _views[fish]
	_views.erase(fish)
	_owners.erase(view)
	_fish.erase(view)
	canvas.remove_drawable(view)


## Cambio de pecera: se vacía lo que se veía y se dibuja la pecera nueva.
func _on_active_tank_changed(_tank_index: int) -> void:
	for value: float in _pearls.take_all():
		Game.collect_pearl(value)
	_food.clear()
	_held_id = ""
	_decor_front.clear_ghost()
	for view: FishView in _fish.duplicate():
		canvas.remove_drawable(view)
	_views.clear()
	_owners.clear()
	_fish.clear()
	_biome = Game.content.biomes.get_biome(Game.state.active().biome_id)
	_on_grid_changed()
	for fish: Fish in Game.state.active().fish:
		_add_view(fish)


## Número de partículas flotantes y de caracteres de fondo del bioma actual.
func _ambience_count() -> int:
	return _particles.count() + _backdrop.count()


func _on_grid_changed() -> void:
	var area: Rect2i = _current_area()
	var sand_top: int = area.end.y - SAND_ROWS
	var offset: int = 0
	var water: Rect2i = Rect2i(
		area.position.x,
		area.position.y + SURFACE_ROWS,
		area.size.x,
		area.size.y - SURFACE_ROWS - SAND_ROWS
	)
	if _biome != null:
		offset = _biome.id.hash() & 0xFFFF
		_surface.configure(
			area.size.x, area.position.y, _biome.surface_pattern, _biome.surface_color
		)
		_sand.configure(
			area.size.x, sand_top, SAND_ROWS, _biome.sand_grains, _biome.sand_color, offset
		)
		_bubbles.color = _biome.bubble_color
	else:
		_surface.configure(area.size.x, area.position.y)
		_sand.configure(area.size.x, sand_top, SAND_ROWS)
		_bubbles.color = AsciiColors.BUBBLE
	_weeds.configure(
		area.size.x, sand_top, sand_top - area.position.y - SURFACE_ROWS - 2, _biome, offset
	)
	_backdrop.configure(water, _biome, offset)
	_particles.configure(water, _biome, offset)
	_bubbles.surface_row = float(area.position.y + SURFACE_ROWS)
	_food.floor_row = float(sand_top)
	_pearls.floor_row = float(sand_top - 1)
	_eggs.floor_row = float(sand_top)
	_equipment.configure(area.size.x, area.position.y + SURFACE_ROWS, sand_top)
	for field: DecorationField in [_decor_back, _decor_front]:
		field.configure(area.position.x, area.size.x, sand_top)
	_decor_front.hint_cell = Vector2(
		float(area.position.x + 1), float(area.position.y + SURFACE_ROWS)
	)
	_spots.configure(
		Rect2i(
			area.position.x,
			area.position.y + SURFACE_ROWS,
			area.size.x,
			area.size.y - SURFACE_ROWS - SAND_ROWS
		)
	)
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


## Entra o sale del modo decorar.
func set_decorating(value: bool) -> void:
	_decorating = value
	_decor_front.clear_ghost()
	_decor_front.hint = tr("DECOR_HINT") if value else ""
	if value:
		_held_id = _first_stock_id()
		decor_message.emit(tr("TOAST_DECOR_MODE_ON"))
		if _held_id.is_empty():
			decor_message.emit(tr("TOAST_DECOR_EMPTY"))
		else:
			_announce_held()
	else:
		_held_id = ""


func is_decorating() -> bool:
	return _decorating


## Objeto del inventario que se está colocando ("" si ninguno).
func held_id() -> String:
	return _held_id


## Pasa al siguiente (o anterior) objeto del inventario.
func _cycle_held(step: int) -> void:
	var ids: PackedStringArray = _stock_ids()
	if ids.is_empty():
		_held_id = ""
		return
	var index: int = ids.find(_held_id)
	index = posmod(index + step, ids.size()) if index >= 0 else 0
	_held_id = ids[index]
	_announce_held()


## Clic en el modo decorar: coloca el objeto que se lleva o recoge el que hay en
## [param cell]. Devuelve verdadero si hizo algo.
func decor_click(cell: Vector2i) -> bool:
	if not _in_water(cell):
		return false
	if not _held_id.is_empty() and _try_place(cell):
		return true
	var hit: PlacedDecoration = decoration_at(cell)
	if hit != null:
		var id: String = hit.def.id
		if Game.remove_decoration(hit):
			_held_id = id
			decor_message.emit(tr("TOAST_DECOR_STORED") % tr(hit.def.name_key))
		return true
	if not _held_id.is_empty():
		decor_message.emit(tr("TOAST_DECOR_OVERLAP"))
	return true


## Guarda en el inventario el objeto que haya en [param cell]. Verdadero si había uno.
func _store_at(cell: Vector2i) -> bool:
	var hit: PlacedDecoration = decoration_at(cell)
	if hit == null:
		return false
	var name_key: String = hit.def.name_key
	if Game.remove_decoration(hit):
		decor_message.emit(tr("TOAST_DECOR_STORED") % tr(name_key))
	return true


## El objeto colocado que ocupa [param cell] (el de delante si se solapan), o null.
func decoration_at(cell: Vector2i) -> PlacedDecoration:
	var area: Rect2i = _current_area()
	var sand_top: int = area.end.y - SAND_ROWS
	var found: PlacedDecoration = null
	for placed: PlacedDecoration in Game.state.active().decorations:
		var rect: Rect2i = placed.rect(area.size.x)
		var top: int = sand_top - rect.position.y - rect.size.y
		var world: Rect2i = Rect2i(area.position.x + rect.position.x, top, rect.size.x, rect.size.y)
		if world.has_point(cell):
			if found == null or placed.def.layer >= found.def.layer:
				found = placed
	return found


## Número de objetos de decoración que se dibujan.
func decoration_count() -> int:
	return _decor_back.count() + _decor_front.count()


func _handle_decor_input(event: InputEvent) -> bool:
	var button: InputEventMouseButton = event as InputEventMouseButton
	var handled: bool = false
	if button != null and button.pressed:
		var cell: Vector2i = canvas.cell_at(button.position)
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				handled = decor_click(cell)
			MOUSE_BUTTON_RIGHT:
				handled = _store_at(cell)
			MOUSE_BUTTON_WHEEL_UP:
				_cycle_held(-1)
				handled = true
			MOUSE_BUTTON_WHEEL_DOWN:
				_cycle_held(1)
				handled = true
			_:
				pass
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_C:
		_cycle_held(1)
		handled = true
	return handled


func _try_place(cell: Vector2i) -> bool:
	var def: DecorationDef = Game.content.get_decoration(_held_id)
	if def == null:
		return false
	var spot: Vector2i = _spot_for(def, cell)
	var area: Rect2i = _current_area()
	var result: GameService.DecorResult = Game.place_decoration(
		_held_id, spot.x, spot.y, area.size.x, _water_rows()
	)
	match result:
		GameService.DecorResult.OK:
			decor_message.emit(tr("TOAST_DECOR_PLACED") % tr(def.name_key))
			if not Game.state.decoration_stock.has(_held_id):
				_held_id = _first_stock_id()
			return true
		GameService.DecorResult.TOO_MANY:
			decor_message.emit(tr("TOAST_DECOR_TOO_MANY") % Tank.MAX_DECORATIONS)
		GameService.DecorResult.OVERLAP:
			return false
		_:
			decor_message.emit(tr("TOAST_DECOR_BOUNDS"))
	return false


## Permilésimas y filas de suelo que corresponden a apuntar con el ratón a [param cell]
## con [param def] (el objeto queda centrado en horizontal y con su base en la celda).
func _spot_for(def: DecorationDef, cell: Vector2i) -> Vector2i:
	var area: Rect2i = _current_area()
	var sand_top: int = area.end.y - SAND_ROWS
	var column: int = cell.x - area.position.x - def.cells_wide / 2
	var permille: int = DecorationLayout.permille_for_column(column, def, area.size.x)
	var lift: int = 0
	if def.anchor == DecorationDef.Anchor.WATER:
		lift = maxi(sand_top - 1 - cell.y, 0)
	return Vector2i(permille, lift)


func _water_rows() -> int:
	var area: Rect2i = _current_area()
	return area.size.y - SURFACE_ROWS - SAND_ROWS


func _stock_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for id: String in Game.content.decoration_ids():
		if Game.state.decoration_stock.get(id, 0) > 0:
			ids.append(id)
	return ids


func _first_stock_id() -> String:
	var ids: PackedStringArray = _stock_ids()
	return "" if ids.is_empty() else ids[0]


func _announce_held() -> void:
	var def: DecorationDef = Game.content.get_decoration(_held_id)
	if def != null:
		decor_message.emit(tr("TOAST_DECOR_HOLDING") % tr(def.name_key))


## Pasa la decoración al dibujo y, en el modo decorar, coloca la vista previa.
func _update_decoration() -> void:
	var items: Array[PlacedDecoration] = Game.state.active().decorations
	_decor_back.set_items(items)
	_decor_front.set_items(items)
	if not _decorating:
		return
	if _held_id.is_empty() or not Game.state.decoration_stock.has(_held_id):
		_held_id = _first_stock_id()
	var def: DecorationDef = Game.content.get_decoration(_held_id)
	if def == null:
		_decor_front.clear_ghost()
		return
	var cell: Vector2i = canvas.cell_at(get_viewport().get_mouse_position())
	if not _in_water(cell):
		_decor_front.clear_ghost()
		return
	var spot: Vector2i = _spot_for(def, cell)
	var area: Rect2i = _current_area()
	var verdict: DecorationLayout.Result = DecorationLayout.check(
		Game.state.active(), def, spot.x, spot.y, area.size.x, _water_rows()
	)
	var rect: Rect2i = PlacedDecoration.new(def, spot.x, spot.y).rect(area.size.x)
	_decor_front.set_ghost(
		def, rect.position.x, rect.position.y, verdict == DecorationLayout.Result.OK
	)
