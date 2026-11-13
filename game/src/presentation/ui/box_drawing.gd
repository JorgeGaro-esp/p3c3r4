class_name BoxDrawing
extends RefCounted
## Marcos hechos con los caracteres de caja de la guía de arte (§3).

const SINGLE: String = "┌┐└┘─│"
const DOUBLE: String = "╔╗╚╝═║"
## Caracteres que ocupa la decoración de la esquina antes del título: `┌─ `.
const TITLE_LEAD: int = 3
## Caracteres que hay que dejar tras el título: ` ─` y la esquina.
const TITLE_TAIL: int = 3


## Línea superior de un marco de [param width] caracteres, con [param title]
## incrustado (`┌─ Título ───┐`). Si el título no cabe se recorta.
static func top_line(width: int, title: String, is_double: bool) -> String:
	var chars: String = DOUBLE if is_double else SINGLE
	if width < 2:
		return ""
	var line: String = chars[4].repeat(width - 2)
	var room: int = width - TITLE_LEAD - TITLE_TAIL
	if not title.is_empty() and room >= 1:
		var label: String = " " + UiText.fit(title, room) + " "
		line = chars[4] + label + chars[4].repeat(maxi(width - 3 - label.length(), 0))
	return chars[0] + line.substr(0, width - 2) + chars[1]


## Línea inferior de un marco.
static func bottom_line(width: int, is_double: bool) -> String:
	var chars: String = DOUBLE if is_double else SINGLE
	if width < 2:
		return ""
	return chars[2] + chars[4].repeat(width - 2) + chars[3]


## Carácter de los lados verticales.
static func side(is_double: bool) -> String:
	return (DOUBLE if is_double else SINGLE)[5]


## Todas las líneas de un marco vacío de [param width] × [param height].
## Devuelve una lista vacía si el marco no cabe (menos de 2 × 2).
static func frame_lines(
	width: int, height: int, title: String = "", is_double: bool = false
) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if width < 2 or height < 2:
		return lines
	lines.append(top_line(width, title, is_double))
	var middle: String = side(is_double) + "".lpad(width - 2) + side(is_double)
	for _row: int in range(height - 2):
		lines.append(middle)
	lines.append(bottom_line(width, is_double))
	return lines
