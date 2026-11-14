class_name EventCatalog
extends RefCounted
## Los eventos aleatorios del contenido: carga, valida e indexa los [EventDef]. Lo
## cuelga [ContentDB] en `content.events`.

const EVENTS_DIR: String = "res://content/events"
const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
## Tope de la recompensa en segundos de producción (que no rompa la economía).
const MAX_REWARD_SECONDS: float = 600.0

var errors: PackedStringArray = PackedStringArray()

var _events: Dictionary[String, EventDef] = {}
var _order: PackedStringArray = PackedStringArray()


## Lista los problemas de un evento (vacía si es válido).
static func validate_event(def: EventDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(def.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % def.id)
	if def.name_key.is_empty():
		problems.append("falta name_key")
	if def.message_key.is_empty():
		problems.append("falta message_key")
	if is_nan(def.weight) or def.weight <= 0.0:
		problems.append("weight debe ser mayor que 0")
	if def.min_fish < 0:
		problems.append("min_fish no puede ser negativo")
	var needs_time: bool = def.is_pickup() or def.kind == EventDef.Kind.WARM_CURRENT
	if needs_time and (is_nan(def.duration) or def.duration <= 0.0):
		problems.append("duration debe ser mayor que 0")
	if is_nan(def.reward_seconds) or def.reward_seconds < 0.0:
		problems.append("reward_seconds no puede ser negativo")
	if def.reward_seconds > MAX_REWARD_SECONDS:
		problems.append("reward_seconds no puede pasar de %s" % MAX_REWARD_SECONDS)
	if is_nan(def.reward_min) or def.reward_min < 0.0:
		problems.append("reward_min no puede ser negativo")
	return problems


## Carga los eventos de [param directory]. Devuelve verdadero si todo es válido.
func load_dir(directory: String = EVENTS_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var def: EventDef = load(path) as EventDef
		if def == null:
			errors.append("%s: no es una EventDef" % path)
			continue
		add(def, path)
	if _events.is_empty():
		errors.append("no hay eventos en %s" % directory)
	return errors.is_empty()


## Valida y registra [param def]. Devuelve falso si es inválido o repetido.
func add(def: EventDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_event(def)
	if _events.has(def.id):
		problems.append("id repetido: %s" % def.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else def.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_events[def.id] = def
	_order.append(def.id)
	return true


func get_event(event_id: String) -> EventDef:
	if not _events.has(event_id):
		return null
	return _events[event_id]


func has(event_id: String) -> bool:
	return _events.has(event_id)


## Ids de los eventos en orden de carga (alfabético por archivo).
func ids() -> PackedStringArray:
	return _order


## El primer evento del tipo [param kind], o null.
func first_of_kind(kind: EventDef.Kind) -> EventDef:
	for event_id: String in _order:
		if _events[event_id].kind == kind:
			return _events[event_id]
	return null
