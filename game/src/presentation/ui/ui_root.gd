class_name UiRoot
extends Node
## Raíz de la interfaz ASCII: guarda los componentes y reparte entre ellos el
## ratón y el teclado.
##
## Ratón: pasar por encima los resalta; un clic llega al componente de más arriba
## bajo el cursor. Teclado: Tab y Mayús+Tab mueven el foco; las flechas y Intro
## las atiende el componente con foco; cada componente puede tener una tecla
## rápida; Esc avisa con [signal escape_pressed].

## El jugador pulsó Escape.
signal escape_pressed
## Se pulsó un botón del ratón (la primera vez activa el teclado, ver `Platform`).
signal pointer_pressed

## Capa de dibujo de los componentes de interfaz: por encima de la pecera.
const LAYER_PANEL: int = 50
const LAYER_WIDGET: int = 60

@export var canvas_path: NodePath

var canvas: AsciiCanvas

var _widgets: Array[AsciiWidget] = []
var _focused: AsciiWidget = null
var _hovered: AsciiWidget = null
var _ring: FocusRing = FocusRing.new()


func _ready() -> void:
	canvas = get_node(canvas_path) as AsciiCanvas
	assert(canvas != null, "UiRoot needs an AsciiCanvas")


func _process(_delta: float) -> void:
	if _focused != null and not _focused.can_focus():
		_set_focus(null)


## Registra un componente y lo añade al lienzo en la capa [param layer].
func add_widget(widget: AsciiWidget, layer: int = LAYER_WIDGET) -> void:
	widget.layer = layer
	_widgets.append(widget)
	canvas.add_drawable(widget)


## Da el foco del teclado a [param widget] (si puede tenerlo).
func focus_widget(widget: AsciiWidget) -> void:
	if widget != null and widget.can_focus():
		_set_focus(widget)


## Copia de la lista de componentes registrados, en orden de registro.
func all_widgets() -> Array[AsciiWidget]:
	return _widgets.duplicate()


## Componente que tiene el foco ahora, o null.
func focused_widget() -> AsciiWidget:
	return _focused


func _input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_update_hover(canvas.cell_at(motion.position))
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		_on_mouse_button(button)
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed:
		_on_key(key)


func _on_mouse_button(button: InputEventMouseButton) -> void:
	if not button.pressed:
		return
	pointer_pressed.emit()
	var cell: Vector2i = canvas.cell_at(button.position)
	if (
		button.button_index == MOUSE_BUTTON_WHEEL_UP
		or button.button_index == MOUSE_BUTTON_WHEEL_DOWN
	):
		var direction: int = -1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		if dispatch_wheel(cell, direction):
			get_viewport().set_input_as_handled()
		return
	var target: AsciiWidget = _widget_at(cell)
	if target == null:
		return
	var handled: bool = false
	if button.button_index == MOUSE_BUTTON_LEFT and target.is_interactive():
		if target.focus_on_click:
			_set_focus(target)
		handled = target.handle_click(cell, button.double_click)
		if handled:
			EventBus.ui_clicked.emit()
	if handled:
		get_viewport().set_input_as_handled()


## Reparte la rueda: primero los componentes bajo el cursor, de arriba abajo; si
## ninguno la atiende, las listas visibles (el cursor puede estar sobre su detalle).
func dispatch_wheel(cell: Vector2i, direction: int) -> bool:
	var under: Array[AsciiWidget] = []
	for widget: AsciiWidget in _widgets:
		if widget.contains_cell(cell):
			under.append(widget)
	under.sort_custom(
		func(first: AsciiWidget, second: AsciiWidget) -> bool:
			if first.layer != second.layer:
				return first.layer > second.layer
			return _widgets.find(first) > _widgets.find(second)
	)
	for widget: AsciiWidget in under:
		if widget.handle_wheel(cell, direction):
			return true
	for widget: AsciiWidget in _widgets:
		if (
			widget.wheel_fallback
			and widget.is_interactive()
			and widget.handle_wheel(cell, direction)
		):
			return true
	return false


func _on_key(key: InputEventKey) -> void:
	if key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
		return
	if key.keycode == KEY_ESCAPE and not key.echo:
		escape_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_TAB:
		_move_focus(-1 if key.shift_pressed else 1)
		get_viewport().set_input_as_handled()
		return
	if not key.echo and _press_hotkey(key.keycode):
		get_viewport().set_input_as_handled()
		return
	if _focused != null and _focused.handle_key(key):
		get_viewport().set_input_as_handled()
		return
	var step: int = _arrow_step(key.keycode)
	if step != 0:
		_move_focus(step)
		get_viewport().set_input_as_handled()


func _press_hotkey(keycode: Key) -> bool:
	for widget: AsciiWidget in _widgets:
		if widget.hotkey == keycode and widget.is_interactive():
			return widget.activate()
	return false


func _arrow_step(keycode: Key) -> int:
	if keycode == KEY_DOWN or keycode == KEY_RIGHT:
		return 1
	if keycode == KEY_UP or keycode == KEY_LEFT:
		return -1
	return 0


func _move_focus(step: int) -> void:
	var ordered: Array[AsciiWidget] = _focus_order()
	var flags: Array[bool] = []
	for widget: AsciiWidget in ordered:
		flags.append(widget.can_focus())
	_ring.rebuild(flags)
	_ring.set_current(ordered.find(_focused))
	var index: int = _ring.move(step)
	_set_focus(ordered[index] if index >= 0 else null)


## Componentes en orden de foco: por grupo y, dentro del grupo, por registro.
func _focus_order() -> Array[AsciiWidget]:
	var ordered: Array[AsciiWidget] = _widgets.duplicate()
	ordered.sort_custom(
		func(first: AsciiWidget, second: AsciiWidget) -> bool:
			if first.focus_group != second.focus_group:
				return first.focus_group < second.focus_group
			return _widgets.find(first) < _widgets.find(second)
	)
	return ordered


func _set_focus(widget: AsciiWidget) -> void:
	if _focused != null:
		_focused.is_focused = false
	_focused = widget
	if _focused != null:
		_focused.is_focused = true


func _update_hover(cell: Vector2i) -> void:
	var target: AsciiWidget = _widget_at(cell)
	if target != null and not target.is_interactive():
		target = null
	if target == _hovered:
		return
	if _hovered != null:
		_hovered.is_hovered = false
	_hovered = target
	if _hovered != null:
		_hovered.is_hovered = true


## Componente más alto (por capa y, a igual capa, por orden de registro) bajo [param cell].
func _widget_at(cell: Vector2i) -> AsciiWidget:
	var best: AsciiWidget = null
	for widget: AsciiWidget in _widgets:
		if not widget.contains_cell(cell):
			continue
		if best == null or widget.layer >= best.layer:
			best = widget
	return best
