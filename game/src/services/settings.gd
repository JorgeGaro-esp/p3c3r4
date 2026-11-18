# gdlint: disable=max-public-methods
# (fachada de setters: un método por ajuste, por eso pasa de 20)
class_name SettingsService
extends Node
## Servicio de ajustes del usuario (autoload `Settings`).
##
## Guarda y carga `user://settings.json` con la validación de [SettingsData] y
## avisa con [signal changed] cada vez que algo cambia. Los cambios se escriben
## en disco tras una pequeña espera para no guardar a cada clic.

## Se emite cuando cambia cualquier ajuste (o se recargan desde disco).
signal changed

const DEFAULT_PATH: String = "user://settings.json"
const SAVE_DELAY_SECONDS: float = 0.5

## Ajustes actuales. Se modifican con los métodos `set_*` de este servicio.
var data: SettingsData = SettingsData.new()
## Archivo de ajustes. Solo lo cambian las pruebas.
var storage_path: String = DEFAULT_PATH
## Ranura de guardado abierta (1 a 3; 0 = ninguna: se está en el título).
var active_slot: int = 0

var _save_timer: Timer = Timer.new()
var _system_language: String = "en"


func _ready() -> void:
	_system_language = TranslationServer.get_locale().substr(0, 2)
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY_SECONDS
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	load_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _save_timer.is_stopped():
		save_now()


## Lee los ajustes del disco. Un archivo ausente, roto o manipulado da los
## valores por defecto sin afectar a nada más.
func load_settings() -> void:
	data = _read_file(storage_path)
	_apply_engine_settings()
	changed.emit()


## Escribe los ajustes ya mismo, de forma atómica (archivo temporal y renombrado).
## Devuelve si se pudo.
func save_now() -> bool:
	_save_timer.stop()
	var temp_path: String = storage_path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Settings: cannot write the settings file")
		return false
	file.store_string(data.to_json())
	file.close()
	if DirAccess.rename_absolute(temp_path, storage_path) != OK:
		push_warning("Settings: cannot replace the settings file")
		return false
	return true


## Altura de la franja en filas, recortada a los límites permitidos.
func set_strip_rows(rows: int) -> void:
	var value: int = clampi(rows, SettingsData.MIN_STRIP_ROWS, SettingsData.MAX_STRIP_ROWS)
	if value != data.strip_rows:
		data.strip_rows = value
		_commit()


## Monitor elegido ([constant SettingsData.PRIMARY_SCREEN] = el principal).
func set_screen_index(index: int) -> void:
	var value: int = clampi(index, SettingsData.PRIMARY_SCREEN, SettingsData.MAX_SCREEN_INDEX)
	if value != data.screen_index:
		data.screen_index = value
		_commit()


func set_always_on_top(enabled: bool) -> void:
	if enabled != data.always_on_top:
		data.always_on_top = enabled
		_commit()


func set_transparent_background(enabled: bool) -> void:
	if enabled != data.transparent_background:
		data.transparent_background = enabled
		_commit()


## Límite de fotogramas; si no es una de las opciones, se ignora.
func set_fps_limit(fps: int) -> void:
	if SettingsData.FPS_CHOICES.has(fps) and fps != data.fps_limit:
		data.fps_limit = fps
		_commit()


## Activa o desactiva el arranque con Windows (P09). Solo cambia el ajuste si el
## sistema lo ha podido hacer; devuelve si ha ido bien.
func set_launch_with_windows(enabled: bool) -> bool:
	if enabled == data.launch_with_windows:
		return true
	if not Platform.set_launch_with_windows(enabled):
		return false
	data.launch_with_windows = enabled
	_commit()
	return true


func set_panel_mode(mode: SettingsData.PanelMode) -> void:
	if mode != data.panel_mode:
		data.panel_mode = mode
		_commit()


## Nivel del efecto CRT (0 apagado, 1 suave, 2 completo); se limita al rango.
func set_crt_level(level: int) -> void:
	var value: int = clampi(level, 0, SettingsData.CRT_LEVELS - 1)
	if value != data.crt_level:
		data.crt_level = value
		_commit()


## Volumen general en porcentaje (0–100).
func set_master_volume(percent: int) -> void:
	var value: int = clampi(percent, 0, SettingsData.MAX_VOLUME)
	if value != data.master_volume:
		data.master_volume = value
		_commit()


## Volumen de la música en porcentaje (0–100).
func set_music_volume(percent: int) -> void:
	var value: int = clampi(percent, 0, SettingsData.MAX_VOLUME)
	if value != data.music_volume:
		data.music_volume = value
		_commit()


func set_muted(value: bool) -> void:
	if value != data.muted:
		data.muted = value
		_commit()


func set_reduce_motion(enabled: bool) -> void:
	if enabled != data.reduce_motion:
		data.reduce_motion = enabled
		_commit()


## Tamaño del texto (0 pequeño, 1 normal, 2 grande); se limita al rango.
func set_text_size(size: int) -> void:
	var value: int = clampi(size, 0, SettingsData.TEXT_SIZE_SCALES.size() - 1)
	if value != data.text_size:
		data.text_size = value
		_commit()


func set_language(language: SettingsData.Language) -> void:
	if language != data.language:
		data.language = language
		_commit()


## Enciende o apaga los unos y ceros del fondo y del puntero.
func set_binary_effect(enabled: bool) -> void:
	if enabled != data.binary_effect:
		data.binary_effect = enabled
		_commit()


## Símbolo de la moneda (posición en [constant Currency.SYMBOLS]); se limita al rango.
func set_currency(index: int) -> void:
	var value: int = clampi(index, 0, Currency.SYMBOLS.size() - 1)
	if value != data.currency:
		data.currency = value
		_commit()


## Activa o apaga el tutorial; al activarlo vuelve a empezar desde el primer paso.
func set_tutorial_enabled(enabled: bool) -> void:
	if enabled == data.tutorial_enabled:
		return
	data.tutorial_enabled = enabled
	if enabled:
		data.tutorial_step = 0
		_remember_step()
	_commit()


## Paso del tutorial (se limita a [0, Tutorial.DONE]).
func set_tutorial_step(step: int) -> void:
	var value: int = clampi(step, 0, Tutorial.DONE)
	if value != data.tutorial_step:
		data.tutorial_step = value
		_remember_step()
		_commit()


## Pasa a la ranura de guardado [param slot] (1 a 3; 0 = ninguna). Con
## [param fresh] su tutorial empieza de cero.
func use_slot(slot: int, fresh: bool = false) -> void:
	active_slot = clampi(slot, 0, SettingsData.SLOT_COUNT)
	if active_slot == 0:
		return
	if fresh:
		data.slot_steps[active_slot - 1] = 0
	data.tutorial_step = data.slot_steps[active_slot - 1]
	data.last_slot = active_slot
	_commit()


## Borra lo que se recuerda de la ranura [param slot] (su tutorial).
func forget_slot(slot: int) -> void:
	if slot < 1 or slot > SettingsData.SLOT_COUNT:
		return
	data.slot_steps[slot - 1] = 0
	if data.last_slot == slot:
		data.last_slot = 0
	if active_slot == slot:
		active_slot = 0
		data.tutorial_step = 0
	_commit()


func _remember_step() -> void:
	if active_slot > 0:
		data.slot_steps[active_slot - 1] = data.tutorial_step


## Código de idioma que se usa ahora (`es` o `en`).
func effective_language() -> String:
	match data.language:
		SettingsData.Language.SPANISH:
			return "es"
		SettingsData.Language.ENGLISH:
			return "en"
	return _system_language


func _commit() -> void:
	_apply_engine_settings()
	changed.emit()
	_save_timer.start()


func _apply_engine_settings() -> void:
	Engine.max_fps = data.fps_limit
	Currency.use_index(data.currency)
	var language: String = effective_language()
	if TranslationServer.get_locale().substr(0, 2) != language:
		TranslationServer.set_locale(language)


func _read_file(path: String) -> SettingsData:
	if not FileAccess.file_exists(path):
		return SettingsData.new()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > SettingsData.MAX_FILE_BYTES:
		return SettingsData.new()
	return SettingsData.from_json(file.get_as_text())
