class_name AsciiWidget
extends AsciiDrawable
## Base de los componentes de interfaz ASCII.
##
## Cada componente es un [AsciiDrawable] (no un nodo, T18) con un rectángulo en
## celdas. Su aspecto va en [method draw]; la respuesta al ratón y al teclado,
## en los métodos `handle_*`, que [UiRoot] llama.

## Se emite cuando el jugador activa el componente (clic, Intro o su tecla).
@warning_ignore("unused_signal")
signal activated

## Zona que ocupa, en celdas de la rejilla.
var rect: Rect2i = Rect2i()
## Un componente desactivado se ve atenuado y no responde.
var is_enabled: bool = true
## Si puede recibir el foco del teclado (Tab).
var is_focusable: bool = false
## Si un clic le da el foco (listas y pestañas sí; botones no).
var focus_on_click: bool = false
var is_focused: bool = false
var is_hovered: bool = false
## Orden de foco entre paneles: Tab recorre antes los grupos menores. Así un
## panel abierto se lleva el foco antes que la barra lateral.
var focus_group: int = 0
## Tecla que lo activa desde cualquier sitio (KEY_NONE = ninguna).
var hotkey: Key = KEY_NONE


## Indica si la celda [param cell] cae dentro del componente visible.
func contains_cell(cell: Vector2i) -> bool:
	return is_shown and rect.has_point(cell)


## Indica si responde al ratón y al teclado ahora mismo.
func is_interactive() -> bool:
	return is_shown and is_enabled


## Indica si puede recibir el foco del teclado ahora mismo.
func can_focus() -> bool:
	return is_interactive() and is_focusable


## Tecla pulsada con el foco puesto aquí. Devuelve si la ha consumido.
func handle_key(_event: InputEventKey) -> bool:
	return false


## Clic izquierdo en [param _cell]. Devuelve si lo ha consumido.
func handle_click(_cell: Vector2i, _is_double: bool) -> bool:
	return false


## Rueda del ratón: [param _direction] es -1 hacia arriba y 1 hacia abajo.
func handle_wheel(_cell: Vector2i, _direction: int) -> bool:
	return false


## Activación desde su tecla rápida. Devuelve si hizo algo.
func activate() -> bool:
	return false


## Indica si [param event] es Intro o Espacio recién pulsado (sin repetición).
static func is_confirm_key(event: InputEventKey) -> bool:
	if event.echo:
		return false
	return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
