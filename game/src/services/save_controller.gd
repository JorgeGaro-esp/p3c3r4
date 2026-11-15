class_name SaveController
extends Node
## Autoload `SaveService`: carga la partida al arrancar y la guarda cada 60
## segundos, al cerrar, al minimizar y tras compras (06-SEGURIDAD §3 y §4).
##
## No arranca solo: la escena principal llama a [method start]. Así los tests, que
## no la llaman, nunca leen ni pisan la partida real del jugador.

signal saved

const AUTOSAVE_SECONDS: float = 60.0
## Mínimo entre dos guardados (los guardados por compra esperan si es antes).
const MIN_INTERVAL_SECONDS: float = 5.0
const SETTING_VERSION: String = "application/config/version"
const SLOTS_DIRECTORY: String = "user://saves"

## Ranura abierta (1 a 3; 0 = ninguna, se está en el título).
var active_slot: int = 0
## Si es falso no se lee ni se escribe nada.
var enabled: bool = false
## Verdadero si el archivo es de una versión más nueva: no se carga ni se pisa.
var blocked: bool = false
var store: SaveStore = SaveStore.new()
## Carpeta que contiene las ranuras. Solo la cambian las pruebas.
var slots_directory: String = SLOTS_DIRECTORY

var _since_save: float = 0.0
var _pending: bool = false


func _process(delta: float) -> void:
	if not enabled:
		return
	_since_save += delta
	if _pending and _since_save >= MIN_INTERVAL_SECONDS:
		save_now()
	elif _since_save >= AUTOSAVE_SECONDS:
		save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()


## Carga la partida (si hay) y activa el guardado. Devuelve la clave del aviso que
## hay que enseñar al jugador, o "" si no hay nada que contar.
func start() -> String:
	if enabled:
		return ""
	enabled = true
	if not Platform.closing.is_connected(save_now):
		Platform.closing.connect(save_now)
		Platform.minimized_changed.connect(_on_minimized_changed)
		EventBus.purchase_made.connect(request_save)
	return load_game()


## Carpeta de la ranura [param slot] (1 a 3).
func slot_directory(slot: int) -> String:
	return "%s/slot_%d" % [slots_directory, slot]


## Prepara las ranuras: la partida de antes de que existieran pasa a la ranura 1.
func prepare_slots() -> void:
	var legacy: SaveStore = SaveStore.new(slots_directory)
	if legacy.candidates().is_empty():
		return
	if not SaveStore.new(slot_directory(1)).candidates().is_empty():
		return
	legacy.move_to(slot_directory(1))


## Resumen de la ranura [param slot] para el título: `exists`, `damaged`, `shells`,
## `fish`, `time` (segundos de juego) y `prestige`.
func slot_info(slot: int) -> Dictionary:
	var slot_store: SaveStore = SaveStore.new(slot_directory(slot))
	var names: PackedStringArray = slot_store.candidates()
	if names.is_empty():
		return {"exists": false}
	for file_name: String in names:
		var result: DecodeResult = SaveCodec.decode(slot_store.read(file_name), Game.content)
		if result.is_ok():
			return {
				"exists": true,
				"damaged": false,
				"shells": result.state.wallet.shells,
				"fish": result.state.fish_total(),
				"time": result.state.sim_time,
				"prestige": result.state.prestige.count,
			}
	return {"exists": true, "damaged": true}


## Abre la ranura [param slot]. Con [param fresh] empieza una partida nueva en ella
## (se borra lo que hubiera). Después hay que recargar la escena, que llama a
## [method start].
func open_slot(slot: int, fresh: bool) -> void:
	if enabled:
		save_now()
	enabled = false
	blocked = false
	_pending = false
	active_slot = clampi(slot, 1, SettingsData.SLOT_COUNT)
	store = SaveStore.new(slot_directory(active_slot))
	Game.set_paused(false)
	Game.start_new_game()
	if fresh:
		store.clear()
		_write_state()
	Settings.use_slot(active_slot, fresh)


## Guarda la partida y sale al título (ninguna ranura abierta).
func close_slot() -> void:
	save_now()
	enabled = false
	blocked = false
	active_slot = 0
	Settings.use_slot(0)


## Borra la partida de la ranura [param slot]. Si era la abierta, se sale al título.
func delete_slot(slot: int) -> void:
	SaveStore.new(slot_directory(slot)).clear()
	if slot == active_slot:
		enabled = false
		blocked = false
		active_slot = 0
	Settings.forget_slot(slot)


## Lee la mejor partida disponible y la pone en [Game]. Devuelve la clave del aviso.
func load_game() -> String:
	var names: PackedStringArray = store.candidates()
	if names.is_empty():
		return ""
	var failed: PackedStringArray = PackedStringArray()
	for file_name: String in names:
		var result: DecodeResult = SaveCodec.decode(store.read(file_name), Game.content)
		if result.is_ok():
			Game.adopt_state(result.state)
			_quarantine_all(failed)
			if not result.warnings.is_empty():
				push_warning("Partida cargada con avisos: %s" % result.warnings)
			return "" if file_name == SaveStore.MAIN_FILE else "TOAST_SAVE_RECOVERED"
		if result.status == DecodeResult.Status.TOO_NEW:
			blocked = true
			enabled = false
			return "TOAST_SAVE_NEWER"
		push_warning("Partida ilegible (%s): %s" % [file_name, result.reason])
		failed.append(file_name)
	_quarantine_all(failed)
	return "TOAST_SAVE_CORRUPT"


## Guarda ahora. Devuelve si se pudo; si no, avisa al jugador.
func save_now() -> bool:
	if not enabled or blocked:
		return false
	return _write_state()


## Pide un guardado: inmediato si hace tiempo que no se guarda; si no, en cuanto toque.
func request_save() -> void:
	if not enabled or blocked:
		return
	if _since_save >= MIN_INTERVAL_SECONDS:
		save_now()
	else:
		_pending = true


func _write_state() -> bool:
	Game.state.rng_state = Game.rng.state
	var version: String = str(ProjectSettings.get_setting(SETTING_VERSION, "0.0.0"))
	var text: String = SaveCodec.encode(Game.state, version, _now())
	_since_save = 0.0
	_pending = false
	if not store.write(text):
		EventBus.notice_requested.emit("TOAST_SAVE_FAILED")
		return false
	saved.emit()
	return true


func _on_minimized_changed(is_minimized: bool) -> void:
	if is_minimized:
		save_now()


func _quarantine_all(names: PackedStringArray) -> void:
	for file_name: String in names:
		store.quarantine(file_name, _now())


func _now() -> int:
	return int(Time.get_unix_time_from_system())
