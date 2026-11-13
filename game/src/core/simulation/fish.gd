class_name Fish
extends RefCounted
## Un pez del modelo. Solo datos de juego: el dibujo vive en `FishView`.
##
## Las etapas de vida y la variante de color llegan en la Fase 7; por ahora todos
## los peces son adultos.

var species_id: String = ""
## 0 (muy triste) a 100 (radiante). Los cuidados la modificarán en la Fase 6.
var happiness: float = 100.0


func _init(new_species_id: String = "") -> void:
	species_id = new_species_id


func to_dict() -> Dictionary:
	return {"species_id": species_id, "happiness": happiness}


## Lee un pez de [param source]. Devuelve null (y avisa) si no es válido o si su
## especie no existe en [param content].
static func from_dict(source: Variant, content: ContentDB, warnings: PackedStringArray) -> Fish:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("pez: no es un objeto")
		return null
	var data: Dictionary = source
	var id: String = SaveFields.read_string(data, "species_id", "", warnings)
	if not content.has_species(id):
		warnings.append("pez descartado: especie desconocida '%s'" % id)
		return null
	var fish: Fish = Fish.new(id)
	fish.happiness = SaveFields.read_float(data, "happiness", 100.0, 0.0, 100.0, warnings)
	return fish
