class_name PrestigeCatalog
extends RefCounted
## Las mejoras permanentes del contenido: carga, valida e indexa los
## [PrestigeUpgradeDef]. Lo cuelga [ContentDB] en `content.prestige`.

const PRESTIGE_DIR: String = "res://content/prestige"
const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
const MAX_LEVEL: int = 50

var errors: PackedStringArray = PackedStringArray()

var _upgrades: Dictionary[String, PrestigeUpgradeDef] = {}
var _order: PackedStringArray = PackedStringArray()


## Lista los problemas de una mejora (vacía si es válida).
static func validate_upgrade(def: PrestigeUpgradeDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(def.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % def.id)
	if def.name_key.is_empty() or def.description_key.is_empty():
		problems.append("faltan name_key o description_key")
	if def.max_level < 1 or def.max_level > MAX_LEVEL:
		problems.append("max_level debe estar entre 1 y %d" % MAX_LEVEL)
	if def.base_cost < 1:
		problems.append("base_cost debe ser al menos 1")
	if is_nan(def.cost_growth) or def.cost_growth < 1.0:
		problems.append("cost_growth debe ser 1 o mayor")
	if is_nan(def.per_level) or def.per_level <= 0.0:
		problems.append("per_level debe ser mayor que 0")
	return problems


## Carga las mejoras de [param directory]. Devuelve verdadero si todo es válido.
func load_dir(directory: String = PRESTIGE_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var def: PrestigeUpgradeDef = load(path) as PrestigeUpgradeDef
		if def == null:
			errors.append("%s: no es una PrestigeUpgradeDef" % path)
			continue
		add(def, path)
	if _upgrades.is_empty():
		errors.append("no hay mejoras en %s" % directory)
	return errors.is_empty()


## Valida y registra [param def]. Devuelve falso si es inválida o repetida.
func add(def: PrestigeUpgradeDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_upgrade(def)
	if _upgrades.has(def.id):
		problems.append("id repetido: %s" % def.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else def.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_upgrades[def.id] = def
	_order.append(def.id)
	return true


func get_upgrade(upgrade_id: String) -> PrestigeUpgradeDef:
	if not _upgrades.has(upgrade_id):
		return null
	return _upgrades[upgrade_id]


func has(upgrade_id: String) -> bool:
	return _upgrades.has(upgrade_id)


## Ids de las mejoras en orden de carga (alfabético por archivo).
func ids() -> PackedStringArray:
	return _order
