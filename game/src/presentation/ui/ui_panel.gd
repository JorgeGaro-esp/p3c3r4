class_name UiPanel
extends RefCounted
## Grupo de componentes que se muestran y se ocultan juntos (la barra lateral,
## la tienda, los ajustes…). Cada panel crea sus componentes, los coloca en
## [method layout] y los enciende o apaga con [method set_active].

var is_active: bool = false
## Grupo de foco de los componentes de este panel (ver [member AsciiWidget.focus_group]).
var focus_group: int = 0

var _root: UiRoot = null
var _widgets: Array[AsciiWidget] = []


func _init(root: UiRoot) -> void:
	_root = root


## Muestra u oculta todos los componentes del panel.
func set_active(value: bool) -> void:
	is_active = value
	for widget: AsciiWidget in _widgets:
		widget.is_shown = value


## Coloca los componentes dentro de [param _area] (en celdas). Cada panel lo define.
func layout(_area: Rect2i) -> void:
	pass


## Vuelve a escribir los textos que dependen de los ajustes o del idioma.
func refresh() -> void:
	pass


func _add(widget: AsciiWidget, layer: int = UiRoot.LAYER_WIDGET) -> void:
	widget.focus_group = focus_group
	_widgets.append(widget)
	_root.add_widget(widget, layer)
	widget.is_shown = is_active


## Crea un botón con el texto y la tecla rápida dados.
func _make_button(text: String, key_text: String = "") -> AsciiButton:
	var button: AsciiButton = AsciiButton.new()
	button.label = text
	if not key_text.is_empty():
		button.hotkey = OS.find_keycode_from_string(key_text)
	_add(button)
	return button


func _make_label(text: String, color: Color = AsciiColors.TEXT) -> AsciiLabel:
	var label: AsciiLabel = AsciiLabel.new()
	label.text = text
	label.color = color
	_add(label)
	return label


## Traduce [param key] con el servidor de traducciones.
func _text(key: String) -> String:
	return TranslationServer.translate(key)
