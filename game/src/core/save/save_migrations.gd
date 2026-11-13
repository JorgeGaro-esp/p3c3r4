class_name SaveMigrations
extends RefCounted
## Migraciones del formato de guardado (06-SEGURIDAD §5).
##
## Cada salto es una función pura `diccionario -> diccionario` de una versión a la
## siguiente. Al cargar se encadenan hasta [constant CURRENT_FORMAT]. Una versión
## superior a la conocida no se migra: la rechaza [SaveCodec].

## Versión actual del formato. Sube en cada cambio incompatible.
const CURRENT_FORMAT: int = 1


## Lleva [param data] de [param from_version] a [constant CURRENT_FORMAT].
static func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	var version: int = from_version
	while version < CURRENT_FORMAT:
		match version:
			0:
				result = migrate_0_to_1(result)
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
