class_name ContentDB
extends RefCounted
## Carga, indexa y valida el contenido del juego (especies, por ahora).
##
## Los errores no se lanzan: se acumulan en [member errors] para que el arranque
## y los tests puedan mostrarlos todos a la vez.

const SPECIES_DIR: String = "res://content/species"
const VARIANTS_DIR: String = "res://content/variants"
const EQUIPMENT_DIR: String = "res://content/equipment"
const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"

var errors: PackedStringArray = PackedStringArray()

var _species: Dictionary[String, SpeciesDef] = {}
var _order: PackedStringArray = PackedStringArray()
var _variants: Dictionary[String, VariantDef] = {}
var _variant_order: PackedStringArray = PackedStringArray()
var _equipment: Dictionary[String, EquipmentDef] = {}
var _equipment_order: PackedStringArray = PackedStringArray()


## Carga todas las especies de [param directory]. Devuelve verdadero si todo es válido.
func load_species_dir(directory: String = SPECIES_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		# En una exportación, Godot añade `.remap` al nombre de los recursos.
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var species: SpeciesDef = load(path) as SpeciesDef
		if species == null:
			errors.append("%s: no es una SpeciesDef" % path)
			continue
		add_species(species, path)
	if _species.is_empty():
		errors.append("no hay especies en %s" % directory)
	return errors.is_empty()


## Carga las variantes de color de [param directory]. Devuelve verdadero si todo es
## válido (incluida la existencia de la variante normal).
func load_variants_dir(directory: String = VARIANTS_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var variant: VariantDef = load(path) as VariantDef
		if variant == null:
			errors.append("%s: no es una VariantDef" % path)
			continue
		add_variant(variant, path)
	if not _variants.has(VariantDef.NORMAL_ID):
		errors.append("falta la variante '%s' en %s" % [VariantDef.NORMAL_ID, directory])
	return errors.is_empty()


## Valida y registra [param variant]. Devuelve falso si es inválida o repetida.
func add_variant(variant: VariantDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_variant(variant)
	if _variants.has(variant.id):
		problems.append("id repetido: %s" % variant.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else variant.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_variants[variant.id] = variant
	_variant_order.append(variant.id)
	return true


## Lista los problemas de una variante (vacía si es válida).
static func validate_variant(variant: VariantDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(variant.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % variant.id)
	if variant.name_key.is_empty():
		problems.append("falta name_key")
	if variant.weight <= 0.0 or is_nan(variant.weight) or is_inf(variant.weight):
		problems.append("weight debe ser mayor que 0")
	if variant.sale_multiplier < 1.0 or is_nan(variant.sale_multiplier):
		problems.append("sale_multiplier no puede ser menor que 1")
	if is_inf(variant.sale_multiplier):
		problems.append("sale_multiplier no es finito")
	return problems


## Devuelve la variante con ese id, o null si no existe.
func get_variant(variant_id: String) -> VariantDef:
	if not _variants.has(variant_id):
		return null
	return _variants[variant_id]


func has_variant(variant_id: String) -> bool:
	return _variants.has(variant_id)


## Ids de variantes en orden de carga (alfabético por archivo).
func variant_ids() -> PackedStringArray:
	return _variant_order


## Valida y registra [param species]. Devuelve falso si es inválida o repetida.
func add_species(species: SpeciesDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_species(species)
	if _species.has(species.id):
		problems.append("id repetido: %s" % species.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else species.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_species[species.id] = species
	_order.append(species.id)
	return true


## Lista los problemas de una definición (vacía si es válida).
static func validate_species(species: SpeciesDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(species.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % species.id)
	if species.name_key.is_empty():
		problems.append("falta name_key")
	if species.base_cost <= 0.0 or is_nan(species.base_cost) or is_inf(species.base_cost):
		problems.append("base_cost debe ser mayor que 0")
	if species.base_production < 0.0 or is_nan(species.base_production):
		problems.append("base_production no puede ser negativa")
	if is_inf(species.base_production):
		problems.append("base_production no es finita")
	if species.sprite_path.is_empty() or not FileAccess.file_exists(species.sprite_path):
		problems.append("el sprite no existe: %s" % species.sprite_path)
	if species.palette_roles.size() != species.palette_colors.size():
		problems.append("palette_roles y palette_colors tienen distinto tamaño")
	if species.growth_seconds <= 0.0 or is_nan(species.growth_seconds):
		problems.append("growth_seconds debe ser mayor que 0")
	if species.breed_seconds <= 0.0 or is_nan(species.breed_seconds):
		problems.append("breed_seconds debe ser mayor que 0")
	if species.hatch_seconds <= 0.0 or is_nan(species.hatch_seconds):
		problems.append("hatch_seconds debe ser mayor que 0")
	for extra_path: String in [species.fry_sprite_path, species.juvenile_sprite_path]:
		if not extra_path.is_empty() and not FileAccess.file_exists(extra_path):
			problems.append("el sprite no existe: %s" % extra_path)
	if species.speed <= 0.0:
		problems.append("speed debe ser mayor que 0")
	if species.frame_duration <= 0.0:
		problems.append("frame_duration debe ser mayor que 0")
	return problems


## Devuelve la especie con ese id, o null si no existe.
func get_species(species_id: String) -> SpeciesDef:
	if not _species.has(species_id):
		return null
	return _species[species_id]


func has_species(species_id: String) -> bool:
	return _species.has(species_id)


## Ids en orden de carga (alfabético por archivo).
func species_ids() -> PackedStringArray:
	return _order


## Carga los equipos de [param directory]. Devuelve verdadero si todo es válido.
func load_equipment_dir(directory: String = EQUIPMENT_DIR) -> bool:
	var names: PackedStringArray = DirAccess.get_files_at(directory)
	names.sort()
	for file_name: String in names:
		var clean_name: String = file_name.trim_suffix(".remap")
		if not clean_name.ends_with(".tres"):
			continue
		var path: String = directory.path_join(clean_name)
		var equipment: EquipmentDef = load(path) as EquipmentDef
		if equipment == null:
			errors.append("%s: no es una EquipmentDef" % path)
			continue
		add_equipment(equipment, path)
	return errors.is_empty()


## Valida y registra [param equipment]. Devuelve falso si es inválido o repetido.
func add_equipment(equipment: EquipmentDef, source: String = "") -> bool:
	var problems: PackedStringArray = validate_equipment(equipment)
	if _equipment.has(equipment.id):
		problems.append("id repetido: %s" % equipment.id)
	if not problems.is_empty():
		var label: String = source if not source.is_empty() else equipment.id
		for problem: String in problems:
			errors.append("%s: %s" % [label, problem])
		return false
	_equipment[equipment.id] = equipment
	_equipment_order.append(equipment.id)
	return true


## Lista los problemas de un equipo (vacía si es válido).
static func validate_equipment(equipment: EquipmentDef) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var pattern: RegEx = RegEx.create_from_string(ID_PATTERN)
	if pattern.search(equipment.id) == null:
		problems.append("id inválido '%s' (minúsculas, cifras y _)" % equipment.id)
	if equipment.name_key.is_empty() or equipment.description_key.is_empty():
		problems.append("faltan name_key o description_key")
	if equipment.max_level < 1 or equipment.max_level > 20:
		problems.append("max_level debe estar entre 1 y 20")
	if equipment.base_cost <= 0.0 or is_nan(equipment.base_cost) or is_inf(equipment.base_cost):
		problems.append("base_cost debe ser mayor que 0")
	if equipment.per_level <= 0.0 or is_nan(equipment.per_level) or is_inf(equipment.per_level):
		problems.append("per_level debe ser mayor que 0")
	if equipment.sprite_path.is_empty() or not FileAccess.file_exists(equipment.sprite_path):
		problems.append("el sprite no existe: %s" % equipment.sprite_path)
	if equipment.palette_roles.size() != equipment.palette_colors.size():
		problems.append("palette_roles y palette_colors tienen distinto tamaño")
	if equipment.frame_duration <= 0.0:
		problems.append("frame_duration debe ser mayor que 0")
	if equipment.place_x < 0.0 or equipment.place_x > 1.0:
		problems.append("place_x debe estar entre 0 y 1")
	return problems


func get_equipment(equipment_id: String) -> EquipmentDef:
	if not _equipment.has(equipment_id):
		return null
	return _equipment[equipment_id]


func has_equipment(equipment_id: String) -> bool:
	return _equipment.has(equipment_id)


## Ids de equipos en orden de carga (alfabético por archivo).
func equipment_ids() -> PackedStringArray:
	return _equipment_order
