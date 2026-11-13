class_name SaveFields
extends RefCounted
## Lectura segura de campos de un diccionario cargado de un archivo.
##
## Nada de lo que viene de un archivo se da por bueno: cada campo se comprueba de
## tipo y de rango, y lo inválido se sustituye por el valor por defecto y se anota
## en [param warnings] (06-SEGURIDAD §3). Nunca se usa una cadena del archivo como
## ruta, clase o expresión.

const MAX_ID_LENGTH: int = 64


## Número finito dentro de [param low, high]. Fuera de rango se recorta.
static func read_float(
	source: Dictionary,
	key: String,
	fallback: float,
	low: float,
	high: float,
	warnings: PackedStringArray
) -> float:
	if not source.has(key):
		return fallback
	var raw: Variant = source[key]
	if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
		warnings.append("%s: no es un número" % key)
		return fallback
	var value: float = 0.0
	if typeof(raw) == TYPE_INT:
		var whole: int = raw
		value = whole
	else:
		var decimal: float = raw
		value = decimal
	if is_nan(value) or is_inf(value):
		warnings.append("%s: número no finito" % key)
		return fallback
	if value < low or value > high:
		warnings.append("%s: fuera de rango, recortado" % key)
	return clampf(value, low, high)


## Entero (también acepta 3.0) dentro de [param low, high].
static func read_int(
	source: Dictionary, key: String, fallback: int, low: int, high: int, warnings: PackedStringArray
) -> int:
	var as_float: float = read_float(
		source, key, float(fallback), float(low), float(high), warnings
	)
	return clampi(roundi(as_float), low, high)


## Cadena de hasta [constant MAX_ID_LENGTH] caracteres.
static func read_string(
	source: Dictionary, key: String, fallback: String, warnings: PackedStringArray
) -> String:
	if not source.has(key):
		return fallback
	var raw: Variant = source[key]
	if typeof(raw) != TYPE_STRING:
		warnings.append("%s: no es texto" % key)
		return fallback
	var text: String = raw
	if text.length() > MAX_ID_LENGTH:
		warnings.append("%s: demasiado largo" % key)
		return fallback
	return text


## Entero de 64 bits guardado como texto (el JSON pierde precisión por encima de 2^53).
static func read_big_int(
	source: Dictionary, key: String, fallback: int, warnings: PackedStringArray
) -> int:
	var text: String = read_string(source, key, "", warnings)
	if text.is_empty():
		return fallback
	if not text.is_valid_int():
		warnings.append("%s: entero inválido" % key)
		return fallback
	return text.to_int()


## Lista o null si falta o no es una lista.
static func read_array(source: Dictionary, key: String, warnings: PackedStringArray) -> Variant:
	if not source.has(key) or typeof(source[key]) != TYPE_ARRAY:
		warnings.append("%s: falta o no es una lista" % key)
		return null
	return source[key]


## Diccionario o null si falta o no es un diccionario.
static func read_dict(source: Dictionary, key: String, warnings: PackedStringArray) -> Variant:
	if not source.has(key) or typeof(source[key]) != TYPE_DICTIONARY:
		warnings.append("%s: falta o no es un objeto" % key)
		return null
	return source[key]
