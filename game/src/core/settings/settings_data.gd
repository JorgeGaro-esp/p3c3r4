class_name SettingsData
extends RefCounted
## Ajustes del usuario: datos puros, con validación estricta al leerlos.
##
## Se guardan en `user://settings.json` (06-SEGURIDAD §6). Un archivo inválido
## o manipulado nunca rompe el juego: cada campo erróneo vuelve a su valor por
## defecto. Ninguna cadena del archivo se usa como ruta ni como nombre de método.

## Qué hace un panel (tienda, ajustes…) con la franja. Es la decisión P02: de
## momento conviven las dos formas para que Jorge elija con el prototipo.
enum PanelMode { REPLACE, GROW_UP }

const FORMAT_VERSION: int = 1
## Altura de la franja en filas de texto (P01: ajustable, 12 por defecto).
const DEFAULT_STRIP_ROWS: int = 12
const MIN_STRIP_ROWS: int = 10
const MAX_STRIP_ROWS: int = 24
## Monitor que se usa por defecto: el principal (P10).
const PRIMARY_SCREEN: int = -1
const MAX_SCREEN_INDEX: int = 15
const FPS_CHOICES: Array[int] = [15, 30, 60]
const DEFAULT_FPS: int = 30
## Efecto CRT: 0 apagado, 1 suave, 2 completo.
const CRT_LEVELS: int = 3
const DEFAULT_CRT_LEVEL: int = 2
## Límite de tamaño del archivo de ajustes antes de leerlo, en bytes.
const MAX_FILE_BYTES: int = 65536

var strip_rows: int = DEFAULT_STRIP_ROWS
var screen_index: int = PRIMARY_SCREEN
var always_on_top: bool = true
var fps_limit: int = DEFAULT_FPS
## Arrancar con Windows (P09): desactivado por defecto.
var launch_with_windows: bool = false
var panel_mode: PanelMode = PanelMode.REPLACE
var crt_level: int = DEFAULT_CRT_LEVEL


## Convierte el texto de un archivo en ajustes. Nunca falla: ante un texto
## vacío, roto o que no sea un objeto JSON, devuelve los valores por defecto.
static func from_json(text: String) -> SettingsData:
	if text.is_empty() or text.length() > MAX_FILE_BYTES:
		return SettingsData.new()
	# Se usa una instancia de JSON porque, a diferencia de JSON.parse_string, no
	# escribe un error en la consola cuando el texto está roto.
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK:
		return SettingsData.new()
	return from_dict(parser.data)


## Construye ajustes desde un diccionario ya leído. Ignora los campos
## desconocidos y sustituye por el valor por defecto los que tengan un tipo o un
## rango imposible.
static func from_dict(raw: Variant) -> SettingsData:
	var result: SettingsData = SettingsData.new()
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	var source: Dictionary = raw
	result.strip_rows = _read_int(
		source, "strip_rows", DEFAULT_STRIP_ROWS, MIN_STRIP_ROWS, MAX_STRIP_ROWS
	)
	result.screen_index = _read_int(
		source, "screen_index", PRIMARY_SCREEN, PRIMARY_SCREEN, MAX_SCREEN_INDEX
	)
	result.always_on_top = _read_bool(source, "always_on_top", true)
	result.fps_limit = _read_choice(source, "fps_limit", DEFAULT_FPS, FPS_CHOICES)
	result.launch_with_windows = _read_bool(source, "launch_with_windows", false)
	var mode: int = _read_int(source, "panel_mode", PanelMode.REPLACE, 0, PanelMode.size() - 1)
	result.panel_mode = mode as PanelMode
	result.crt_level = _read_int(source, "crt_level", DEFAULT_CRT_LEVEL, 0, CRT_LEVELS - 1)
	return result


## Siguiente valor permitido de [constant FPS_CHOICES] a partir de [param current]
## ([param step] = 1 sube, -1 baja). No pasa de los extremos.
static func next_fps(current: int, step: int) -> int:
	var index: int = FPS_CHOICES.find(current)
	if index < 0:
		return DEFAULT_FPS
	return FPS_CHOICES[clampi(index + step, 0, FPS_CHOICES.size() - 1)]


## Serializa a un diccionario listo para JSON.
func to_dict() -> Dictionary:
	return {
		"format_version": FORMAT_VERSION,
		"strip_rows": strip_rows,
		"screen_index": screen_index,
		"always_on_top": always_on_top,
		"fps_limit": fps_limit,
		"launch_with_windows": launch_with_windows,
		"panel_mode": int(panel_mode),
		"crt_level": crt_level,
	}


## Serializa a texto JSON.
func to_json() -> String:
	return JSON.stringify(to_dict(), "\t")


static func _read_int(source: Dictionary, key: String, fallback: int, low: int, high: int) -> int:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return fallback
	var number: float = value
	if not is_finite(number):
		return fallback
	return clampi(roundi(number), low, high)


static func _read_bool(source: Dictionary, key: String, fallback: bool) -> bool:
	if source.has(key) and typeof(source[key]) == TYPE_BOOL:
		var value: bool = source[key]
		return value
	return fallback


static func _read_choice(
	source: Dictionary, key: String, fallback: int, choices: Array[int]
) -> int:
	var value: int = _read_int(source, key, fallback, 0, 1000)
	return value if choices.has(value) else fallback
