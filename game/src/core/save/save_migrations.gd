class_name SaveMigrations
extends RefCounted
## Migraciones del formato de guardado (06-SEGURIDAD §5).
##
## Cada salto es una función pura `diccionario -> diccionario` de una versión a la
## siguiente. Al cargar se encadenan hasta [constant CURRENT_FORMAT]. Una versión
## superior a la conocida no se migra: la rechaza [SaveCodec].

## Versión actual del formato. Sube en cada cambio incompatible.
const CURRENT_FORMAT: int = 13

## Especies de prueba de las fases 3 y 4 y la especie definitiva que las sustituye.
const RENAMED_SPECIES: Dictionary[String, String] = {
	"test_guppy": "pond_guppy",
	"test_minnow": "pond_carp",
	"test_angelfish": "pond_salmon",
}

## Enciclopedia 2 (Estanque): las especies que salen pasan a la que ocupa su hueco.
const POND_REPLACEMENTS: Dictionary[String, String] = {
	"pond_minnow": "pond_carp",
	"pond_tetra": "pond_goldfish",
	"pond_loach": "pond_catfish",
	"pond_snail": "pond_trout",
	"pond_angelfish": "pond_salmon",
}

## Enciclopedia 2 (Arrecife). Un solo paso, sin encadenar: la raya y el pez payaso
## conservan su identificador pero cambian de hueco, así que la antigua raya pasa a
## tiburón y el pez globo a raya a la vez.
const REEF_REPLACEMENTS: Dictionary[String, String] = {
	"reef_damsel": "reef_anchovy",
	"reef_butterfly": "reef_clownfish",
	"reef_starfish": "reef_eel",
	"reef_tang": "reef_tuna",
	"reef_seahorse": "reef_squid",
	"reef_puffer": "reef_ray",
	"reef_ray": "reef_shark",
}

## Enciclopedia 2 (Manglar): cada especie pasa a la que ocupa su hueco, también en un
## solo paso (varias conservan su identificador pero cambian de hueco).
const MANGROVE_REPLACEMENTS: Dictionary[String, String] = {
	"mangrove_archer": "mangrove_tadpole",
	"mangrove_crab": "mangrove_frog",
	"mangrove_shrimp": "mangrove_crab",
	"mangrove_catfish": "mangrove_mudskipper",
	"mangrove_snapper": "mangrove_archer",
	"mangrove_mudskipper": "mangrove_barracuda",
	"mangrove_barracuda": "mangrove_arawana",
	"mangrove_sawfish": "mangrove_crocodile",
}

## Enciclopedia 2 (Abismo): un solo paso por hueco. La linterna y la medusa se
## mantienen; el pez remo pasa a ser el calamar gigante y este, al cachalote.
const ABYSS_REPLACEMENTS: Dictionary[String, String] = {
	"abyss_hatchet": "abyss_viperfish",
	"abyss_squid": "abyss_blobfish",
	"abyss_viperfish": "abyss_anglerfish",
	"abyss_anglerfish": "abyss_pelican",
	"abyss_oarfish": "abyss_giant_squid",
	"abyss_giant_squid": "abyss_sperm_whale",
}


## Lleva [param data] de [param from_version] a [constant CURRENT_FORMAT].
static func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var version: int = from_version
	while version < CURRENT_FORMAT:
		match version:
			0:
				result = migrate_0_to_1(result)
			1:
				result = migrate_1_to_2(result)
			2:
				result = migrate_2_to_3(result)
			3:
				result = migrate_3_to_4(result)
			4:
				result = migrate_4_to_5(result)
			5:
				result = migrate_5_to_6(result)
			6:
				result = migrate_6_to_7(result)
			7:
				result = migrate_7_to_8(result)
			8:
				result = migrate_8_to_9(result)
			9:
				result = migrate_9_to_10(result)
			10:
				result = migrate_10_to_11(result)
			11:
				result = migrate_11_to_12(result)
			12:
				result = migrate_12_to_13(result)
			_:
				push_error("SaveMigrations: no hay migración desde la versión %d" % version)
				return result
		version += 1
	return result


## Migración de ejemplo: el formato 0 llamaba `coins` a las conchas del monedero.
static func migrate_0_to_1(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if typeof(result.get("wallet")) == TYPE_DICTIONARY:
		var wallet: Dictionary = result["wallet"]
		if wallet.has("coins") and not wallet.has("shells"):
			wallet["shells"] = wallet["coins"]
		wallet.erase("coins")
		if wallet.has("lifetime_coins") and not wallet.has("total_earned"):
			wallet["total_earned"] = wallet["lifetime_coins"]
		wallet.erase("lifetime_coins")
	return result


## Las especies de prueba pasan a ser las del estanque definitivo.
static func migrate_1_to_2(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var tanks: Variant = result.get("tanks")
	if typeof(tanks) != TYPE_ARRAY:
		return result
	var tank_list: Array = tanks
	for tank: Variant in tank_list:
		if typeof(tank) != TYPE_DICTIONARY:
			continue
		var tank_data: Dictionary = tank
		var fish_list: Variant = tank_data.get("fish")
		if typeof(fish_list) != TYPE_ARRAY:
			continue
		var entries: Array = fish_list
		for entry: Variant in entries:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var fish_data: Dictionary = entry
			var old_id: Variant = fish_data.get("species_id")
			if typeof(old_id) == TYPE_STRING and RENAMED_SPECIES.has(old_id):
				fish_data["species_id"] = RENAMED_SPECIES[old_id]
	return result


## Fase 7: cada pez pasa a tener madurez y variante. Los peces antiguos son adultos
## de variante normal y las peceras antiguas no tienen huevos.
static func migrate_2_to_3(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var tanks: Variant = result.get("tanks")
	if typeof(tanks) != TYPE_ARRAY:
		return result
	var tank_list: Array = tanks
	for tank: Variant in tank_list:
		if typeof(tank) != TYPE_DICTIONARY:
			continue
		var tank_data: Dictionary = tank
		if not tank_data.has("eggs"):
			tank_data["eggs"] = []
		var fish_list: Variant = tank_data.get("fish")
		if typeof(fish_list) != TYPE_ARRAY:
			continue
		var entries: Array = fish_list
		for entry: Variant in entries:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var fish_data: Dictionary = entry
			if not fish_data.has("maturity"):
				fish_data["maturity"] = LifeStage.ADULT_FROM
			if not fish_data.has("variant_id"):
				fish_data["variant_id"] = VariantDef.NORMAL_ID
	return result


## Fase 8: las peceras antiguas no tienen equipo.
static func migrate_3_to_4(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var tanks: Variant = result.get("tanks")
	if typeof(tanks) != TYPE_ARRAY:
		return result
	var tank_list: Array = tanks
	for tank: Variant in tank_list:
		if typeof(tank) != TYPE_DICTIONARY:
			continue
		var tank_data: Dictionary = tank
		if not tank_data.has("equipment"):
			tank_data["equipment"] = {}
	return result


## Fase 9: las peceras antiguas no tienen decoración y el inventario empieza vacío.
static func migrate_4_to_5(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("decoration_stock"):
		result["decoration_stock"] = {}
	var tanks: Variant = result.get("tanks")
	if typeof(tanks) != TYPE_ARRAY:
		return result
	var tank_list: Array = tanks
	for tank: Variant in tank_list:
		if typeof(tank) != TYPE_DICTIONARY:
			continue
		var tank_data: Dictionary = tank
		if not tank_data.has("decorations"):
			tank_data["decorations"] = []
	return result


## Varias peceras: se guarda cuál es la activa. Las partidas antiguas tienen una sola.
static func migrate_5_to_6(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("active_tank"):
		result["active_tank"] = 0
	return result


## Fase 11: aparecen las estadísticas. Las partidas antiguas empiezan con todo a cero.
static func migrate_6_to_7(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("stats"):
		result["stats"] = {}
	return result


## Fase 11B: aparecen los logros. Las partidas antiguas empiezan sin ninguno y los
## desbloquean al cargar si ya cumplen la condición.
static func migrate_7_to_8(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("achievements"):
		result["achievements"] = {}
	return result


## Fase 13: aparece el prestigio. Las partidas antiguas empiezan sin perlas negras y
## su ciclo actual cuenta desde el principio.
static func migrate_8_to_9(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if not result.has("prestige"):
		result["prestige"] = {}
	return result


## Enciclopedia 2: las especies del Estanque cambian. Los peces, los huevos, las
## especies desbloqueadas y lo descubierto en la Enciclopedia pasan a la especie
## nueva que ocupa el hueco de la antigua ([constant POND_REPLACEMENTS]).
static func migrate_9_to_10(data: Dictionary) -> Dictionary:
	return _replace_species(data, POND_REPLACEMENTS)


## Enciclopedia 2: lo mismo para el Arrecife ([constant REEF_REPLACEMENTS]).
static func migrate_10_to_11(data: Dictionary) -> Dictionary:
	return _replace_species(data, REEF_REPLACEMENTS)


## Enciclopedia 2: lo mismo para el Manglar ([constant MANGROVE_REPLACEMENTS]).
static func migrate_11_to_12(data: Dictionary) -> Dictionary:
	return _replace_species(data, MANGROVE_REPLACEMENTS)


## Enciclopedia 2: lo mismo para el Abismo ([constant ABYSS_REPLACEMENTS]).
static func migrate_12_to_13(data: Dictionary) -> Dictionary:
	return _replace_species(data, ABYSS_REPLACEMENTS)


static func _replace_species(
	data: Dictionary, replacements: Dictionary[String, String]
) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var tanks: Variant = result.get("tanks")
	if typeof(tanks) == TYPE_ARRAY:
		var tank_list: Array = tanks
		for tank: Variant in tank_list:
			if typeof(tank) != TYPE_DICTIONARY:
				continue
			var tank_data: Dictionary = tank
			for key: String in ["fish", "eggs"]:
				_replace_species_in(tank_data.get(key), replacements)
	if result.has("unlocked"):
		result["unlocked"] = _replace_ids(result["unlocked"], false, replacements)
	if result.has("discovered"):
		result["discovered"] = _replace_ids(result["discovered"], true, replacements)
	return result


static func _replace_species_in(entries: Variant, replacements: Dictionary[String, String]) -> void:
	if typeof(entries) != TYPE_ARRAY:
		return
	var list: Array = entries
	for entry: Variant in list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_data: Dictionary = entry
		var old_id: Variant = entry_data.get("species_id")
		if typeof(old_id) == TYPE_STRING and replacements.has(old_id):
			entry_data["species_id"] = replacements[old_id]


## Cambia los identificadores de una lista (`unlocked`) o de claves `especie|variante`
## (`discovered`), sin repetir ninguno. Si no hay lista, la deja como estaba.
static func _replace_ids(
	raw: Variant, has_variant: bool, replacements: Dictionary[String, String]
) -> Variant:
	if typeof(raw) != TYPE_ARRAY:
		return raw
	var source: Array = raw
	var result: Array = []
	for item: Variant in source:
		var value: Variant = item
		if typeof(item) == TYPE_STRING:
			var text: String = item
			var parts: PackedStringArray = text.split("|") if has_variant else [text]
			if replacements.has(parts[0]):
				parts[0] = replacements[parts[0]]
			value = "|".join(parts)
		if not result.has(value):
			result.append(value)
	return result
