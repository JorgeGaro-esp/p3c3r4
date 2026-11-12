class_name AsciiSprite
extends RefCounted
## Sprite ASCII cargado desde un archivo de `content/sprites/`.
##
## Todas las líneas de todos los fotogramas miden lo mismo (se rellenan con
## espacios). Un sprite se dibuja mirando a la derecha; [method mirrored]
## genera la versión que mira a la izquierda.

## Carácter que se dibuja como un hueco opaco: tapa lo que hay detrás.
const OPAQUE_MARKER: String = "¤"
## Rol de color de las celdas que no tienen letra de color.
const DEFAULT_COLOR_ROLE: String = "b"
## Pares de espejado: cada carácter de MIRROR_FROM se convierte en el que ocupa
## la misma posición en MIRROR_TO. El resto de caracteres no cambia.
const MIRROR_FROM: String = "()<>/\\[]{}┌┐└┘├┤◄►«»"
const MIRROR_TO: String = ")(><\\/][}{┐┌┘└┤├►◄»«"

var id: String = ""
var width: int = 0
var height: int = 0
## Un elemento por fotograma; cada uno es la lista de sus líneas.
var frames: Array[PackedStringArray] = []
## Un elemento por fotograma, con la misma forma que [member frames].
var colors: Array[PackedStringArray] = []
## Puntos con nombre (por ejemplo `eye`), en celdas del sprite.
var anchors: Dictionary[String, Vector2i] = {}
## Problemas encontrados al cargar. Vacío si el sprite es válido.
var errors: PackedStringArray = PackedStringArray()


## Devuelve el carácter que queda al espejar [param character].
static func mirror_char(character: String) -> String:
	if character.length() != 1:
		return character
	var index: int = MIRROR_FROM.find(character)
	if index < 0:
		return character
	return MIRROR_TO[index]


## Indica si el sprite se cargó sin errores y tiene al menos un fotograma.
func is_valid() -> bool:
	return errors.is_empty() and not frames.is_empty()


## Número de fotogramas.
func frame_count() -> int:
	return frames.size()


## Devuelve la versión que mira a la izquierda: líneas invertidas, caracteres
## espejados, colores invertidos y puntos de anclaje reflejados.
func mirrored() -> AsciiSprite:
	var result: AsciiSprite = AsciiSprite.new()
	result.id = id
	result.width = width
	result.height = height
	for frame: PackedStringArray in frames:
		var flipped: PackedStringArray = PackedStringArray()
		for line: String in frame:
			flipped.append(_mirror_line(line))
		result.frames.append(flipped)
	for color_lines: PackedStringArray in colors:
		var reversed_lines: PackedStringArray = PackedStringArray()
		for line: String in color_lines:
			reversed_lines.append(_reverse_line(line))
		result.colors.append(reversed_lines)
	for key: String in anchors:
		var point: Vector2i = anchors[key]
		result.anchors[key] = Vector2i(width - 1 - point.x, point.y)
	return result


func _mirror_line(line: String) -> String:
	var result: String = ""
	for index: int in range(line.length() - 1, -1, -1):
		result += mirror_char(line[index])
	return result


func _reverse_line(line: String) -> String:
	var result: String = ""
	for index: int in range(line.length() - 1, -1, -1):
		result += line[index]
	return result
