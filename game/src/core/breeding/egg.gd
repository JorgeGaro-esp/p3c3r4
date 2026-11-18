class_name Egg
extends RefCounted
## Un huevo puesto en la pecera. La variante de color se sortea al ponerlo y se
## desvela al eclosionar. Ocupa un hueco de la capacidad desde que se pone.

const MAX_SECONDS: float = 86400.0

var species_id: String = ""
var variant_id: String = VariantDef.NORMAL_ID
## Pelaje de color del pez que saldrá (solo estético, como en [Fish]).
var coat: int = 0
## Segundos que faltan para que eclosione.
var remaining: float = 0.0
## Dónde está en el fondo, de 0 (izquierda) a 1 (derecha). Es solo estético.
var position_x: float = 0.5


func _init(
	new_species_id: String = "",
	new_variant_id: String = VariantDef.NORMAL_ID,
	new_remaining: float = 0.0,
	new_position_x: float = 0.5
) -> void:
	species_id = new_species_id
	variant_id = new_variant_id
	remaining = new_remaining
	position_x = new_position_x


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"species_id": species_id,
		"variant_id": variant_id,
		"remaining": remaining,
		"position_x": position_x,
	}
	if coat != 0:
		data["coat"] = coat
	return data


## Lee un huevo de [param source]; null (con aviso) si no es válido.
static func from_dict(source: Variant, content: ContentDB, warnings: PackedStringArray) -> Egg:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("huevo: no es un objeto")
		return null
	var data: Dictionary = source
	var id: String = SaveFields.read_string(data, "species_id", "", warnings)
	if not content.has_species(id):
		warnings.append("huevo descartado: especie desconocida '%s'" % id)
		return null
	var egg: Egg = Egg.new(id)
	egg.variant_id = Fish.read_variant(data, content, warnings)
	egg.coat = SaveFields.read_int(
		data, "coat", 0, 0, maxi(content.get_species(id).coat_count() - 1, 0), warnings
	)
	egg.remaining = SaveFields.read_float(data, "remaining", 0.0, 0.0, MAX_SECONDS, warnings)
	egg.position_x = SaveFields.read_float(data, "position_x", 0.5, 0.0, 1.0, warnings)
	return egg
