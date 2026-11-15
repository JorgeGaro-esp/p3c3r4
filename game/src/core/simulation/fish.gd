class_name Fish
extends RefCounted
## Un pez del modelo. Solo datos de juego: el dibujo vive en `FishView`.
##
## Madurez de 0 (recién nacido) a 1 (adulto): de ella sale la etapa de vida. Un pez
## comprado, o de una partida anterior a la cría, es adulto.

var species_id: String = ""
## Variante de color (identificador de [VariantDef]).
var variant_id: String = VariantDef.NORMAL_ID
## Avanza con el tiempo hasta [constant LifeStage.ADULT_FROM].
var maturity: float = LifeStage.ADULT_FROM
## 0 (muy triste) a 100 (radiante). Los cuidados la modificarán en la Fase 6.
var happiness: float = 100.0
## Saciedad de 0 (hambriento) a 100 (lleno). Baja con el tiempo.
var hunger: float = Care.MAX_HUNGER
## Apodo elegido por el jugador (vacío si no tiene).
var nickname: String = ""
## Un favorito no se vende por error ni entra en la venta de sobrantes.
var favorite: bool = false


func _init(new_species_id: String = "") -> void:
	species_id = new_species_id


func stage() -> LifeStage.Stage:
	return LifeStage.from_maturity(maturity)


## Solo los adultos producen conchas y crían.
func is_adult() -> bool:
	return maturity >= LifeStage.ADULT_FROM


## Da de comer: sube la saciedad [param amount] puntos sin pasar del máximo.
func feed(amount: float) -> void:
	hunger = clampf(hunger + amount, 0.0, Care.MAX_HUNGER)


func to_dict() -> Dictionary:
	return {
		"species_id": species_id,
		"variant_id": variant_id,
		"maturity": maturity,
		"happiness": happiness,
		"hunger": hunger,
		"nickname": nickname,
		"favorite": favorite,
	}


## Lee la variante de [param data]; si no existe en [param content], la normal.
static func read_variant(
	data: Dictionary, content: ContentDB, warnings: PackedStringArray
) -> String:
	var id: String = SaveFields.read_string(data, "variant_id", VariantDef.NORMAL_ID, warnings)
	if id != VariantDef.NORMAL_ID and not content.has_variant(id):
		warnings.append("variante desconocida '%s': se usa la normal" % id)
		return VariantDef.NORMAL_ID
	return id


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
	fish.variant_id = read_variant(data, content, warnings)
	fish.maturity = SaveFields.read_float(
		data, "maturity", LifeStage.ADULT_FROM, 0.0, LifeStage.ADULT_FROM, warnings
	)
	fish.happiness = SaveFields.read_float(data, "happiness", 100.0, 0.0, 100.0, warnings)
	fish.hunger = SaveFields.read_float(
		data, "hunger", Care.MAX_HUNGER, 0.0, Care.MAX_HUNGER, warnings
	)
	fish.nickname = SaveFields.read_string(data, "nickname", "", warnings)
	if data.get("favorite", false) is bool:
		fish.favorite = data.get("favorite", false)
	return fish
