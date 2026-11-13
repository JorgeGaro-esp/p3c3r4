class_name UiText
extends RefCounted
## Utilidades puras para colocar texto en celdas de ancho fijo.
##
## Todo se mide en caracteres, porque la interfaz es una rejilla de celdas.

## Marca que sustituye al final de un texto recortado. Está en la tabla de
## caracteres permitidos (la elipsis `…` no).
const TRUNCATION_MARK: String = "·"
const FULL_BLOCK: String = "█"
const LIGHT_SHADE: String = "░"


## Recorta [param text] a [param width] caracteres, con una marca al final si
## hubo que cortar.
static func fit(text: String, width: int) -> String:
	if width <= 0:
		return ""
	if text.length() <= width:
		return text
	return text.substr(0, width - 1) + TRUNCATION_MARK


## Recorta y rellena con espacios a la derecha hasta [param width].
static func pad_right(text: String, width: int) -> String:
	return fit(text, width).rpad(maxi(width, 0))


## Recorta y rellena con espacios a la izquierda hasta [param width].
static func pad_left(text: String, width: int) -> String:
	return fit(text, width).lpad(maxi(width, 0))


## Centra el texto en [param width] caracteres.
static func center(text: String, width: int) -> String:
	var fitted: String = fit(text, width)
	var total: int = maxi(width, 0) - fitted.length()
	var left: int = total / 2
	return "".lpad(left) + fitted + "".lpad(total - left)


## Une [param left] y [param right] en una línea de [param width] caracteres, con
## el segundo pegado al borde derecho. Si no caben, se recorta el primero.
static func join_ends(left: String, right: String, width: int) -> String:
	if width <= 0:
		return ""
	var right_part: String = fit(right, width)
	var room: int = width - right_part.length() - 1
	if room <= 0:
		return right_part.lpad(width)
	return pad_right(left, room) + " " + right_part


## Reparte [param text] en líneas de como máximo [param width] caracteres,
## partiendo por espacios. Una palabra más larga que la línea se parte.
static func wrap(text: String, width: int) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if width <= 0:
		return lines
	var current: String = ""
	for word: String in text.split(" ", false):
		var remaining: String = word
		while remaining.length() > width:
			if not current.is_empty():
				lines.append(current)
				current = ""
			lines.append(remaining.substr(0, width))
			remaining = remaining.substr(width)
		if current.is_empty():
			current = remaining
		elif current.length() + 1 + remaining.length() <= width:
			current += " " + remaining
		else:
			lines.append(current)
			current = remaining
	if not current.is_empty():
		lines.append(current)
	return lines


## Barra de progreso de [param width] caracteres para [param fraction] (0 a 1).
static func bar(fraction: float, width: int) -> String:
	if width <= 0:
		return ""
	var filled: int = clampi(roundi(clampf(fraction, 0.0, 1.0) * float(width)), 0, width)
	return FULL_BLOCK.repeat(filled) + LIGHT_SHADE.repeat(width - filled)
