class_name EventLayer
extends RefCounted
## Lo visible de la hora y los eventos dentro de la pecera: el tinte del día, el
## pez dorado, la botella y el visitante raro. Lo posee [TankView], que le pasa la
## zona y los clics. El estado manda: cada fotograma se compara con
## `Game.state.events` y se crea o quita lo que haga falta.

## Cuántos copos cae en una lluvia de comida.
const RAIN_FLAKES: int = 10
const LAYER_FIELD: int = 15
const LAYER_TINT: int = 22

var daylight: DaylightView = DaylightView.new()
var field: EventField = EventField.new()

var _tank: TankView = null
var _make_visitor: Callable = Callable()
var _bounds_for: Callable = Callable()
var _canvas: AsciiCanvas = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _visitor: FishView = null
var _water: Rect2 = Rect2()


func _init(tank: TankView, make_visitor: Callable, bounds_for: Callable) -> void:
	_tank = tank
	_make_visitor = make_visitor
	_bounds_for = bounds_for
	_rng.seed = TankView.SEED + 31
	daylight.layer = LAYER_TINT
	field.layer = LAYER_FIELD


## Añade lo que dibuja al lienzo.
func attach(canvas: AsciiCanvas) -> void:
	_canvas = canvas
	canvas.add_drawable(daylight)
	canvas.add_drawable(field)


## Fija la zona de la pecera ([param area], en celdas) y el agua por la que se mueven
## los clicables ([param water], donde puede estar la esquina de un dibujo).
func configure(area: Rect2i, water: Rect2) -> void:
	daylight.area = area
	field.bounds = water
	_water = water
	if _visitor != null:
		var bounds: Rect2 = _bounds_for.call(_visitor)
		_visitor.motion.set_bounds(bounds)


## Sincroniza lo que se ve con el estado. Se llama cada fotograma.
func update() -> void:
	var state: GameState = Game.state
	var tank: Tank = state.active()
	daylight.set_conditions(
		state.darkness, tank.bonuses.night_shield, state.events.warm_seconds > 0.0
	)
	var def: EventDef = state.events.pickup
	var shown: bool = def != null and state.events.pickup_tank == state.active_tank
	if not shown:
		clear()
		return
	if def.kind == EventDef.Kind.VISITOR:
		_sync_visitor(state.events.pickup_species_id)
	elif not field.is_active():
		field.spawn(def.kind, _rng)
	if _visitor != null:
		field.set_marker(_visitor.motion.position + Vector2(float(_visitor.width) * 0.5, -1.0))


## Si hay un clicable en [param cell], lo cobra y devuelve verdadero.
func click(cell: Vector2i) -> bool:
	var hit: bool = field.hit(cell)
	if not hit and _visitor != null:
		hit = _visitor_area().has_point(Vector2(cell) + Vector2(0.5, 0.5))
	if not hit:
		return false
	return Game.events.claim()


## Quita todo lo que haya de eventos (al cambiar de pecera o terminar el evento).
func clear() -> void:
	field.clear()
	field.set_marker(Vector2(-1.0, -1.0))
	if _visitor != null:
		_canvas.remove_drawable(_visitor)
		_visitor = null


## Celda donde está el marcador del visitante ((-1, -1) si no hay).
func field_marker_cell() -> Vector2:
	return field.marker_cell()


## Hay algún clicable de evento a la vista.
func has_pickup() -> bool:
	return field.is_active() or _visitor != null


## Un evento empezó: la lluvia de comida deja caer copos desde arriba.
func on_event_started(event_id: String) -> void:
	var def: EventDef = Game.content.events.get_event(event_id)
	if def == null or def.kind != EventDef.Kind.FOOD_RAIN:
		return
	for _index: int in range(RAIN_FLAKES):
		var column: float = _rng.randf_range(_water.position.x, maxf(_water.end.x, 1.0))
		_tank.drop_food(Vector2i(int(column), int(_water.position.y)))


func _sync_visitor(species_id: String) -> void:
	if _visitor != null:
		return
	var made: FishView = _make_visitor.call(species_id)
	if made == null:
		return
	_visitor = made
	var bounds: Rect2 = _bounds_for.call(_visitor)
	_visitor.motion.set_bounds(bounds)
	_visitor.motion.scatter()
	_canvas.add_drawable(_visitor)


func _visitor_area() -> Rect2:
	var origin: Vector2 = _visitor.motion.position
	return Rect2(origin - Vector2(0.5, 0.5), Vector2(_visitor.width + 1, _visitor.height + 1))
