class_name SaveCodec
extends RefCounted
## Convierte la partida en texto JSON y viceversa, con comprobación de integridad.
##
## Formato (06-SEGURIDAD §2): `format_version`, `game_version`, `saved_at_unix`,
## `checksum` (SHA-256 del campo `data` serializado de forma canónica) y `data`.
## Solo JSON: nunca se cargan recursos ni scripts desde el archivo.

## Tamaño máximo de un archivo de guardado.
const MAX_BYTES: int = 5 * 1024 * 1024


## Serializa [param state]. Devuelve el texto del archivo.
static func encode(state: GameState, game_version: String, saved_at_unix: int) -> String:
	var data: Dictionary = _canonical(state.to_dict())
	var envelope: Dictionary = {
		"format_version": SaveMigrations.CURRENT_FORMAT,
		"game_version": game_version,
		"saved_at_unix": saved_at_unix,
		"checksum": checksum_of(data),
		"data": data,
	}
	return JSON.stringify(envelope, "\t", true)


## Lee [param text]. Nunca lanza: el resultado dice qué ocurrió.
static func decode(text: String, content: ContentDB) -> DecodeResult:
	if text.length() > MAX_BYTES:
		return DecodeResult.failure(DecodeResult.Status.MALFORMED, "archivo demasiado grande")
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		return DecodeResult.failure(DecodeResult.Status.MALFORMED, "JSON inválido")
	if typeof(parser.data) != TYPE_DICTIONARY:
		return DecodeResult.failure(DecodeResult.Status.MALFORMED, "la raíz no es un objeto")
	var envelope: Dictionary = parser.data
	var warnings: PackedStringArray = PackedStringArray()
	var version: int = SaveFields.read_int(envelope, "format_version", -1, -1, 1000000, warnings)
	if version < 0:
		return DecodeResult.failure(DecodeResult.Status.MALFORMED, "falta format_version")
	if version > SaveMigrations.CURRENT_FORMAT:
		return DecodeResult.failure(
			DecodeResult.Status.TOO_NEW, "formato %d más nuevo que el conocido" % version
		)
	var raw_data: Variant = envelope.get("data")
	if typeof(raw_data) != TYPE_DICTIONARY:
		return DecodeResult.failure(DecodeResult.Status.MALFORMED, "falta data")
	var data: Dictionary = raw_data
	var expected: String = SaveFields.read_string(envelope, "checksum", "", warnings)
	if expected.is_empty() or expected != checksum_of(data):
		return DecodeResult.failure(
			DecodeResult.Status.CHECKSUM, "la suma de comprobación no coincide"
		)
	var migrated: Dictionary = SaveMigrations.migrate(data, version)
	var state: GameState = GameState.from_dict(migrated, content, warnings)
	if state == null:
		return DecodeResult.failure(DecodeResult.Status.INVALID, "datos inválidos: %s" % warnings)
	var result: DecodeResult = DecodeResult.new()
	result.status = DecodeResult.Status.OK
	result.state = state
	result.warnings = warnings
	return result


## SHA-256 (en hexadecimal) de [param data] serializado de forma canónica.
static func checksum_of(data: Dictionary) -> String:
	return _canonical_text(data).sha256_text()


## Pasa [param data] por JSON para que enteros y decimales tengan la misma forma
## al escribir y al leer (el JSON no distingue 1 de 1.0).
static func _canonical(data: Dictionary) -> Dictionary:
	var parser: JSON = JSON.new()
	parser.parse(JSON.stringify(data, "", true))
	var result: Dictionary = {}
	if typeof(parser.data) == TYPE_DICTIONARY:
		result = parser.data
	return result


static func _canonical_text(data: Dictionary) -> String:
	return JSON.stringify(data, "", true)
