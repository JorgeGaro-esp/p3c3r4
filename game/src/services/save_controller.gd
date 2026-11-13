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

## Si es falso no se lee ni se escribe nada.
var enabled: bool = false
## Verdadero si el archivo es de una versión más nueva: no se carga ni se pisa.
var blocked: bool = false
var store: SaveStore = SaveStore.new()

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


## Pide un guardado: inmediato si hace tiempo que no se guarda; si no, en cuanto toque.
func request_save() -> void:
	if not enabled or blocked:
		return
	if _since_save >= MIN_INTERVAL_SECONDS:
		save_now()
	else:
		_pending = true


func _on_minimized_changed(is_minimized: bool) -> void:
	if is_minimized:
		save_now()


func _quarantine_all(names: PackedStringArray) -> void:
	for file_name: String in names:
		store.quarantine(file_name, _now())


func _now() -> int:
	return int(Time.get_unix_time_from_system())
