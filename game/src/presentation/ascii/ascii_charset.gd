class_name AsciiCharset
extends RefCounted
## Juego de caracteres permitido en el arte y la interfaz.
##
## Es la tabla de `docs/05-GUIA-ARTE-ASCII.md` §3. Si se añade un carácter,
## se añade primero allí y aquí, y se comprueba que la fuente lo tiene.

const LATIN: String = "áéíóúüñÁÉÍÓÚÜÑ¿¡"
const SYMBOLS: String = "°º·•¢¥§¤«»×÷±"
const BOX: String = "─│┌┐└┘├┤┬┴┼═║╔╗╚╝"
const BLOCKS: String = "░▒▓█▀▄▌▐"
const SHAPES: String = "◎○●◦◆◇▲▼◄►≡≈∞"

const _FIRST_PRINTABLE: int = 32
const _LAST_PRINTABLE: int = 126


## Devuelve todos los caracteres permitidos, sin repetir.
static func all_characters() -> String:
	var result: String = ""
	for code: int in range(_FIRST_PRINTABLE, _LAST_PRINTABLE + 1):
		result += String.chr(code)
	return result + LATIN + SYMBOLS + BOX + BLOCKS + SHAPES


## Indica si [param character] (una sola letra) está en el juego permitido.
static func is_allowed(character: String) -> bool:
	if character.length() != 1:
		return false
	var code: int = character.unicode_at(0)
	if code >= _FIRST_PRINTABLE and code <= _LAST_PRINTABLE:
		return true
	return (LATIN + SYMBOLS + BOX + BLOCKS + SHAPES).contains(character)


## Devuelve el primer carácter no permitido de [param text], o "" si todos lo son.
static func first_disallowed(text: String) -> String:
	for index: int in range(text.length()):
		var character: String = text[index]
		if not is_allowed(character):
			return character
	return ""
