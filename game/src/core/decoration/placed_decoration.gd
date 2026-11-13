class_name PlacedDecoration
extends RefCounted
## Un objeto ya colocado en una pecera. La posición no depende del tamaño de la
## ventana: `x_permille` es la posición horizontal en milésimas del hueco libre
## (0 = pegado a la izquierda, 1000 = a la derecha) y `lift` las filas de agua
## entre el suelo y la base del objeto.

const MAX_PERMILLE: int = 1000
const MAX_LIFT: int = 60

var def: DecorationDef
var x_permille: int = 0
var lift: int = 0


func _init(new_def: DecorationDef, new_x: int = 0, new_lift: int = 0) -> void:
	def = new_def
	x_permille = clampi(new_x, 0, MAX_PERMILLE)
	lift = clampi(new_lift, 0, MAX_LIFT)


## Rectángulo que ocupa en una pecera de [param tank_width] celdas: la columna
## izquierda y las filas medidas hacia arriba desde el suelo.
func rect(tank_width: int) -> Rect2i:
	var span: int = maxi(tank_width - def.cells_wide, 0)
	var column: int = roundi(float(x_permille) / float(MAX_PERMILLE) * float(span))
	return Rect2i(column, lift, def.cells_wide, def.cells_high)


func to_dict() -> Dictionary:
	return {"def_id": def.id, "x": x_permille, "y": lift}


## Lee un objeto; null (con aviso) si no es válido o la decoración no existe.
static func from_dict(
	source: Variant, content: ContentDB, warnings: PackedStringArray
) -> PlacedDecoration:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("decoración: no es un objeto")
		return null
	var data: Dictionary = source
	var id: String = SaveFields.read_string(data, "def_id", "", warnings)
	var def: DecorationDef = content.get_decoration(id)
	if def == null:
		warnings.append("decoración desconocida descartada")
		return null
	var x: int = SaveFields.read_int(data, "x", 0, 0, MAX_PERMILLE, warnings)
	var y: int = SaveFields.read_int(data, "y", 0, 0, MAX_LIFT, warnings)
	return PlacedDecoration.new(def, x, y)
