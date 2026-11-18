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

## Idioma: el del sistema, español o inglés.
enum Language { AUTO, SPANISH, ENGLISH }

const FORMAT_VERSION: int = 1
## Ranuras de guardado.
const SLOT_COUNT: int = 3
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
## Volumen en porcentaje (P06): general y música, de 10 en 10. Por defecto, bajo.
const DEFAULT_MASTER_VOLUME: int = 30
const DEFAULT_MUSIC_VOLUME: int = 100
const VOLUME_STEP: int = 10
const MAX_VOLUME: int = 100
## Tamaño del texto: pequeño, normal y grande (multiplican el tamaño de la fuente).
const TEXT_SIZE_SCALES: Array[float] = [0.85, 1.0, 1.25]
const DEFAULT_TEXT_SIZE: int = 1
## Límite de tamaño del archivo de ajustes antes de leerlo, en bytes.
const MAX_FILE_BYTES: int = 65536

var strip_rows: int = DEFAULT_STRIP_ROWS
var screen_index: int = PRIMARY_SCREEN
var always_on_top: bool = true
## Fondo negro transparente (el cielo sobre el agua siempre lo es).
var transparent_background: bool = false
var fps_limit: int = DEFAULT_FPS
## Arrancar con Windows (P09): desactivado por defecto.
var launch_with_windows: bool = false
var panel_mode: PanelMode = PanelMode.REPLACE
var crt_level: int = DEFAULT_CRT_LEVEL
var master_volume: int = DEFAULT_MASTER_VOLUME
var music_volume: int = DEFAULT_MUSIC_VOLUME
## Silencio total (tecla M); no cambia los volúmenes elegidos.
var muted: bool = false
## Menos ondulación y sin parpadeos (accesibilidad).
var reduce_motion: bool = false
var text_size: int = DEFAULT_TEXT_SIZE
var language: Language = Language.AUTO
## Tutorial: activado y paso por el que va ([constant Tutorial.DONE] = terminado).
var tutorial_enabled: bool = true
## Unos y ceros flotando en el fondo y en la estela del puntero.
var binary_effect: bool = true
## Símbolo de la moneda (posición en [constant Currency.SYMBOLS]; 0 = «¢»).
var currency: int = 0
## Paso del tutorial de la ranura abierta (es un reflejo de [member slot_steps]).
var tutorial_step: int = 0
## Paso del tutorial de cada ranura de guardado.
var slot_steps: PackedInt32Array = PackedInt32Array([0, 0, 0])
## Última ranura de guardado abierta (0 = ninguna todavía).
var last_slot: int = 0


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
	result.transparent_background = _read_bool(source, "transparent_background", false)
	result.fps_limit = _read_choice(source, "fps_limit", DEFAULT_FPS, FPS_CHOICES)
	result.launch_with_windows = _read_bool(source, "launch_with_windows", false)
	var mode: int = _read_int(source, "panel_mode", PanelMode.REPLACE, 0, PanelMode.size() - 1)
	result.panel_mode = mode as PanelMode
	result.crt_level = _read_int(source, "crt_level", DEFAULT_CRT_LEVEL, 0, CRT_LEVELS - 1)
	result.master_volume = _read_int(source, "master_volume", DEFAULT_MASTER_VOLUME, 0, MAX_VOLUME)
	result.music_volume = _read_int(source, "music_volume", DEFAULT_MUSIC_VOLUME, 0, MAX_VOLUME)
	result.muted = _read_bool(source, "muted", false)
	result.reduce_motion = _read_bool(source, "reduce_motion", false)
	result.text_size = _read_int(
		source, "text_size", DEFAULT_TEXT_SIZE, 0, TEXT_SIZE_SCALES.size() - 1
	)
	var lang: int = _read_int(source, "language", Language.AUTO, 0, Language.size() - 1)
	result.language = lang as Language
	result.tutorial_enabled = _read_bool(source, "tutorial_enabled", true)
	result.binary_effect = _read_bool(source, "binary_effect", true)
	result.currency = _read_int(source, "currency", 0, 0, Currency.SYMBOLS.size() - 1)
	result.tutorial_step = _read_int(source, "tutorial_step", 0, 0, Tutorial.DONE)
	result.slot_steps = _read_slot_steps(source, result.tutorial_step)
	result.last_slot = _read_int(source, "last_slot", 0, 0, SLOT_COUNT)
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
		"transparent_background": transparent_background,
		"fps_limit": fps_limit,
		"launch_with_windows": launch_with_windows,
		"panel_mode": int(panel_mode),
		"crt_level": crt_level,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"muted": muted,
		"reduce_motion": reduce_motion,
		"text_size": text_size,
		"language": int(language),
		"tutorial_enabled": tutorial_enabled,
		"binary_effect": binary_effect,
		"currency": currency,
		"tutorial_step": tutorial_step,
		"slot_steps": Array(slot_steps),
		"last_slot": last_slot,
	}


## Serializa a texto JSON.
func to_json() -> String:
	return JSON.stringify(to_dict(), "\t")


## Pasos del tutorial por ranura. Un archivo antiguo (sin la lista) cuenta su único
## paso como el de la ranura 1, donde se migra la partida de entonces.
static func _read_slot_steps(source: Dictionary, legacy_step: int) -> PackedInt32Array:
	var steps: PackedInt32Array = PackedInt32Array()
	steps.resize(SLOT_COUNT)
	var raw: Variant = source.get("slot_steps", null)
	if typeof(raw) != TYPE_ARRAY:
		steps[0] = legacy_step
		return steps
	var items: Array = raw
	for index: int in range(mini(items.size(), SLOT_COUNT)):
		var item: Variant = items[index]
		if typeof(item) == TYPE_INT:
			var whole: int = item
			steps[index] = clampi(whole, 0, Tutorial.DONE)
		elif typeof(item) == TYPE_FLOAT:
			var decimal: float = item
			steps[index] = clampi(roundi(decimal), 0, Tutorial.DONE)
	return steps


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
