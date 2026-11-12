class_name AsciiPalette
extends RefCounted
## Colores de una especie por rol (b cuerpo, t cola, e ojo, f aleta, d detalle).
##
## Los sprites solo guardan la letra del rol; el color real sale de aquí. Así una
## variante de color sustituye la paleta sin tocar la forma.

## Color de los roles que la paleta no define.
const FALLBACK: Color = Color(1.0, 1.0, 1.0)

var _colors: Dictionary[String, Color] = {}


## Crea una paleta a partir de dos listas paralelas de roles y colores.
static func from_arrays(roles: PackedStringArray, values: PackedColorArray) -> AsciiPalette:
	var palette: AsciiPalette = AsciiPalette.new()
	var count: int = mini(roles.size(), values.size())
	for index: int in range(count):
		palette._colors[roles[index]] = values[index]
	return palette


## Indica si la paleta define el rol [param role].
func has_role(role: String) -> bool:
	return _colors.has(role)


## Devuelve el color del rol, o blanco si no está definido.
func color_for(role: String) -> Color:
	if _colors.has(role):
		return _colors[role]
	return FALLBACK
