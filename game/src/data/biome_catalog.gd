class_name BiomeCatalog
extends RefCounted
## Los biomas del contenido: carga, valida e indexa los [BiomeDef]. Lo cuelga
## [ContentDB] en `content.biomes`.

const BIOMES_DIR: String = "res://content/biomes"
const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"

var errors: PackedStringArray = PackedStringArray()

var _biomes: Dictionary[String, BiomeDef] = {}
var _order: PackedStringArray = PackedStringArray()


## Comprueba que las referencias entre contenidos existen (especies a biomas,
## requisitos de bioma, decoración de bioma). Se llama tras cargar todo; los
## problemas se suman a [member errors] de [param content].
static func check_references(content: ContentDB) -> bool:
	var catalog: BiomeCatalog = content.biomes
	for species_id: String in content.species_ids():
		var species: SpeciesDef = content.get_species(species_id)
		if not catalog.has(species.biome_id):
			catalog.errors.append("%s: el bioma '%s' no existe" % [species_id, species.biome_id])
	for biome_id: String in catalog.ids():
		var requires: String = catalog.get_biome(biome_id).requires_biome_id
		if not requires.is_empty() and (requires == biome_id or not catalog.has(requires)):
			catalog.errors.append("%s: requisito de bioma inválido '%s'" % [biome_id, requires])
	for decoration_id: String in content.decoration_ids():
		var decor_biome: String = content.get_decoration(decoration_id).biome_id
		if not decor_biome.is_empty() and not catalog.has(decor_biome):
			catalog.errors.append("%s: el bioma '%s' no existe" % [decoration_id, decor_biome])
	return catalog.errors.is_empty()


## Lista los problemas de un bioma (vacía si es válido).
static func validate_biome(biome: BiomeDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(biome.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % biome.id)
	if biome.name_key.is_empty() or biome.description_key.is_empty():
		problems.append("faltan name_key o description_key")
	if biome.unlock_cost < 0.0 or is_nan(biome.unlock_cost) or is_inf(biome.unlock_cost):
		problems.append("unlock_cost debe ser 0 o mayor")
	if biome.surface_pattern.is_empty():
		problems.append("surface_pattern no puede estar vacío")
	if biome.sand_grains.is_empty():
		problems.append("sand_grains no puede estar vacío")
	if biome.weed_chars.length() != 2:
		problems.append("weed_chars debe tener exactamente 2 caracteres")
	if biome.weed_gap_scale < 0.25 or biome.weed_gap_scale > 8.0:
		problems.append("weed_gap_scale debe estar entre 0,25 y 8")
	if biome.backdrop_density > 0.0 and biome.backdrop_char.length() != 1:
		problems.append("backdrop_char debe ser un carácter si hay densidad")
	if biome.particle_count > 0 and biome.particle_chars.is_empty():
		problems.append("particle_chars no puede estar vacío si hay partículas")
	if is_nan(biome.particle_fall) or absf(biome.particle_fall) > 10.0:
		problems.append("particle_fall debe estar entre -10 y 10")
	return problems


## Carga los biomas de [param directory]. Devuelve verdadero si todo es válido.
func load_dir(directory: String = BIOMES_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var biome: BiomeDef = load(path) as BiomeDef
		if biome == null:
			errors.append("%s: no es una BiomeDef" % path)
			continue
		add(biome, path)
	if _biomes.is_empty():
		errors.append("no hay biomas en %s" % directory)
	return errors.is_empty()


## Valida y registra [param biome]. Devuelve falso si es inválido o repetido.
func add(biome: BiomeDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_biome(biome)
	if _biomes.has(biome.id):
		problems.append("id repetido: %s" % biome.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else biome.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_biomes[biome.id] = biome
	_order.append(biome.id)
	_order = _sorted()
	return true


func get_biome(biome_id: String) -> BiomeDef:
	if not _biomes.has(biome_id):
		return null
	return _biomes[biome_id]


func has(biome_id: String) -> bool:
	return _biomes.has(biome_id)


## Ids de biomas por orden de pestaña.
func ids() -> PackedStringArray:
	return _order


func _sorted() -> PackedStringArray:
	var list: Array[String] = []
	for biome_id: String in _order:
		list.append(biome_id)
	list.sort_custom(
		func(a: String, b: String) -> bool:
			if _biomes[a].order != _biomes[b].order:
				return _biomes[a].order < _biomes[b].order
			return a < b
	)
	return PackedStringArray(list)
