extends Node
## Servicio de plataforma (autoload `Platform`): todo lo que depende del
## escritorio, aislado en un solo sitio (02-ARQUITECTURA §1.6).
##
## Coloca la ventana en franja, detecta cambios de monitor, resolución o escala,
## y ofrece minimizar, cerrar y arrancar con Windows. Los cálculos de geometría
## viven en [StripLayout] y se prueban aparte; aquí solo se aplican.

## Cambió el monitor, la resolución, la escala o la ventana se movió sola.
signal display_changed
signal minimized_changed(is_minimized: bool)
## La ventana va a cerrarse: quien tenga algo que guardar debe hacerlo ya.
signal closing

const POLL_SECONDS: float = 1.0
## Intentos seguidos de recolocar la ventana si el sistema no la deja donde se pide.
const MAX_REPLACE_STREAK: int = 3
const _REG_RELATIVE_PATH: String = "\\System32\\reg.exe"

var _preferred_screen: int = SettingsData.PRIMARY_SCREEN
var _expected_rect: Rect2i = Rect2i()
var _snapshot: String = ""
var _is_minimized: bool = false
var _keyboard_ready: bool = false
var _replace_streak: int = 0
var _poll_timer: Timer = Timer.new()


func _ready() -> void:
	if not is_desktop():
		return
	_poll_timer.wait_time = POLL_SECONDS
	_poll_timer.timeout.connect(_poll)
	add_child(_poll_timer)
	_poll_timer.start()


## Indica si hay una ventana de escritorio de verdad (falso en las pruebas sin pantalla).
func is_desktop() -> bool:
	return DisplayServer.get_name() != "headless"


func screen_count() -> int:
	return maxi(DisplayServer.get_screen_count(), 1)


func primary_screen() -> int:
	return DisplayServer.get_primary_screen()


## Pantalla que se usa de verdad para la preferencia [param preferred].
func target_screen(preferred: int) -> int:
	return StripLayout.resolve_screen(preferred, screen_count(), primary_screen())


## Zona de la pantalla sin la barra de tareas, en píxeles del escritorio.
func usable_rect(screen: int) -> Rect2i:
	return DisplayServer.screen_get_usable_rect(screen)


func screen_size(screen: int) -> Vector2i:
	return DisplayServer.screen_get_size(screen)


## Puntos por pulgada de la pantalla (96 = 100 %). Windows no da la escala directa.
func screen_dpi(screen: int) -> int:
	return DisplayServer.screen_get_dpi(screen)


## Coloca la ventana pegada al borde inferior del área útil de la pantalla
## elegida, con [param rows] filas de [param cell_height] píxeles. Devuelve el
## rectángulo calculado.
func place_strip(preferred_screen: int, rows: int, cell_height: float) -> Rect2i:
	_preferred_screen = preferred_screen
	var screen: int = target_screen(preferred_screen)
	var rect: Rect2i = StripLayout.window_rect(usable_rect(screen), rows, cell_height)
	if not is_desktop() or not rect.has_area():
		return rect
	DisplayServer.window_set_size(rect.size)
	DisplayServer.window_set_position(rect.position)
	_expected_rect = rect
	_snapshot = _take_snapshot()
	return rect


func set_always_on_top(enabled: bool) -> void:
	if is_desktop():
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, enabled)


## La ventana arranca sin foco para no quitárselo a la aplicación en la que se
## trabaja. Al primer clic se activa de verdad, para que funcione el teclado.
func enable_keyboard_focus() -> void:
	if _keyboard_ready or not is_desktop():
		return
	_keyboard_ready = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)
	DisplayServer.window_move_to_foreground()


func minimize() -> void:
	if is_desktop():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


## Cierra el juego de forma limpia: avisa a quien tenga algo que guardar y sale.
func request_quit() -> void:
	closing.emit()
	get_tree().quit()


## Registra o quita el juego en el arranque de Windows (P09). Solo funciona en
## Windows y en el juego exportado: desde el editor el ejecutable sería Godot.
## Devuelve si se pudo.
##
## Es el único `OS.execute` del proyecto (excepción T26): argumentos fijos de
## `reg.exe` más la ruta del propio ejecutable, validada por [AutostartCommand].
func set_launch_with_windows(enabled: bool) -> bool:
	if OS.get_name() != "Windows" or OS.has_feature("editor"):
		return false
	var arguments: PackedStringArray = AutostartCommand.delete_arguments()
	if enabled:
		arguments = AutostartCommand.add_arguments(OS.get_executable_path())
	if arguments.is_empty():
		return false
	var output: Array = []
	var code: int = OS.execute(_reg_path(), arguments, output, true)
	# `reg delete` devuelve 1 si el valor no existía: para quitarlo es lo mismo.
	return code == 0 or (not enabled and code == 1)


func _reg_path() -> String:
	var root: String = OS.get_environment("SystemRoot")
	if root.is_empty():
		return "reg"
	return root + _REG_RELATIVE_PATH


func _take_snapshot() -> String:
	var screen: int = target_screen(_preferred_screen)
	return "%d|%s|%d" % [screen_count(), usable_rect(screen), screen_dpi(screen)]


func _poll() -> void:
	var minimized: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED
	if minimized != _is_minimized:
		_is_minimized = minimized
		minimized_changed.emit(minimized)
	if minimized or not _expected_rect.has_area():
		return
	var has_changed: bool = _take_snapshot() != _snapshot
	if has_changed:
		_replace_streak = 0
	else:
		var actual: Rect2i = Rect2i(
			DisplayServer.window_get_position(), DisplayServer.window_get_size()
		)
		if actual == _expected_rect:
			_replace_streak = 0
		elif _replace_streak < MAX_REPLACE_STREAK:
			_replace_streak += 1
			has_changed = true
	if has_changed:
		display_changed.emit()
