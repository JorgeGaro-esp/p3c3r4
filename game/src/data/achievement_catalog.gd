class_name AchievementCatalog
extends RefCounted
## Los logros del contenido: carga, valida e indexa los [AchievementDef]. Lo cuelga
## [ContentDB] en `content.achievements`.

const ACHIEVEMENTS_DIR: String = "res://content/achievements"
const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
const MAX_REWARD_PERCENT: float = 5.0

var errors: PackedStringArray = PackedStringArray()

var _achievements: Dictionary[String, AchievementDef] = {}
var _order: PackedStringArray = PackedStringArray()


## Comprueba que los biomas que nombran los logros existen. Se llama tras cargar
## todo; los problemas se suman a [member errors].
static func check_references(content: ContentDB) -> bool:
	var catalog: AchievementCatalog = content.achievements
	for achievement_id: String in catalog.ids():
		var biome_id: String = catalog.get_achievement(achievement_id).biome_id
		if not biome_id.is_empty() and not content.biomes.has(biome_id):
			catalog.errors.append("%s: el bioma '%s' no existe" % [achievement_id, biome_id])
	return catalog.errors.is_empty()


## Lista los problemas de un logro (vacía si es válido).
static func validate_achievement(def: AchievementDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(def.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % def.id)
	if def.name_key.is_empty():
		problems.append("falta name_key")
	if is_nan(def.target) or is_inf(def.target) or def.target <= 0.0:
		problems.append("target debe ser mayor que 0")
	if is_nan(def.reward_percent) or def.reward_percent < 0.0:
		problems.append("reward_percent no puede ser negativo")
	if def.reward_percent > MAX_REWARD_PERCENT:
		problems.append("reward_percent no puede pasar de %s" % MAX_REWARD_PERCENT)
	if def.metric == AchievementDef.Metric.STAT:
		if not GameStats.IDS.has(def.stat_id):
			problems.append("stat_id desconocido '%s'" % def.stat_id)
	elif not def.stat_id.is_empty():
		problems.append("stat_id solo vale con la métrica STAT")
	var by_biome: bool = (
		def.metric == AchievementDef.Metric.SPECIES_FOUND
		or def.metric == AchievementDef.Metric.VARIANTS_FOUND
	)
	if not def.biome_id.is_empty() and not by_biome:
		problems.append("biome_id solo vale con SPECIES_FOUND o VARIANTS_FOUND")
	if def.metric == AchievementDef.Metric.COLLECTION_PERCENT and def.target > 100.0:
		problems.append("COLLECTION_PERCENT no puede pasar de 100")
	return problems


## Carga los logros de [param directory]. Devuelve verdadero si todo es válido.
func load_dir(directory: String = ACHIEVEMENTS_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var def: AchievementDef = load(path) as AchievementDef
		if def == null:
			errors.append("%s: no es una AchievementDef" % path)
			continue
		add(def, path)
	if _achievements.is_empty():
		errors.append("no hay logros en %s" % directory)
	return errors.is_empty()


## Valida y registra [param def]. Devuelve falso si es inválido o repetido.
func add(def: AchievementDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_achievement(def)
	if _achievements.has(def.id):
		problems.append("id repetido: %s" % def.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else def.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_achievements[def.id] = def
	_order.append(def.id)
	_order = _sorted()
	return true


func get_achievement(achievement_id: String) -> AchievementDef:
	if not _achievements.has(achievement_id):
		return null
	return _achievements[achievement_id]


func has(achievement_id: String) -> bool:
	return _achievements.has(achievement_id)


## Ids de los logros en el orden de la lista.
func ids() -> PackedStringArray:
	return _order


func _sorted() -> PackedStringArray:
	var list: Array[String] = []
	for achievement_id: String in _order:
		list.append(achievement_id)
	list.sort_custom(
		func(a: String, b: String) -> bool:
			if _achievements[a].order != _achievements[b].order:
				return _achievements[a].order < _achievements[b].order
			return a < b
	)
	return PackedStringArray(list)
