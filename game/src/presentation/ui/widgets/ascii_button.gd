class_name AsciiButton
extends AsciiWidget
## Botón de una fila. Se activa con clic, Intro o Espacio (con el foco) o con su
## tecla rápida. Con el foco se ve en vídeo inverso ámbar; con el ratón encima,
## en ámbar.

var label: String = ""


func _init() -> void:
	is_focusable = true


func draw(canvas: AsciiCanvas) -> void:
	if rect.size.x <= 0:
		return
	var color: Color = AsciiColors.TEXT
	if not is_enabled:
		color = AsciiColors.TEXT_DIM
	elif is_focused:
		canvas.fill_rect_cells(rect, AsciiColors.AMBER)
		color = Color.BLACK
	elif is_hovered:
		color = AsciiColors.AMBER
	canvas.put_string(UiText.center(label, rect.size.x), Vector2(rect.position), color)


func handle_key(event: InputEventKey) -> bool:
	if not is_enabled or not is_confirm_key(event):
		return false
	activated.emit()
	return true


func handle_click(_cell: Vector2i, _is_double: bool) -> bool:
	if is_enabled:
		activated.emit()
	return true


func activate() -> bool:
	if not is_interactive():
		return false
	activated.emit()
	return true
