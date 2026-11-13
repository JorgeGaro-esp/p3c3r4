class_name SaveMigrations
extends RefCounted
## Migraciones del formato de guardado (06-SEGURIDAD §5).
##
## Cada salto es una función pura `diccionario -> diccionario` de una versión a la
## siguiente. Al cargar se encadenan hasta [constant CURRENT_FORMAT]. Una versión
## superior a la conocida no se migra: la rechaza [SaveCodec].

## Versión actual del formato. Sube en cada cambio incompatible.
const CURRENT_FORMAT: int = 2

## Especies de prueba de las fases 3 y 4 y la especie definitiva que las sustituye.
const RENAMED_SPECIES: Dictionary[String, String] = {
	"test_guppy": "pond_guppy",
	"test_minnow": "pond_minnow",
	"test_angelfish": "pond_angelfish",
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
