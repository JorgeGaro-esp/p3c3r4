class_name VariantRoll
extends RefCounted
## Sorteo de la variante de color de un huevo (GDD §6, D27). Función pura: recibe
## el generador aleatorio, así que con la misma semilla sale siempre lo mismo.


## Elige una variante según los pesos de [param content]. [param rare_multiplier]
## multiplica el peso de todas las variantes menos la normal (equipos y decoración
## lo usarán para subir la probabilidad de variantes raras).
static func pick(
	content: ContentDB, rng: RandomNumberGenerator, rare_multiplier: float = 1.0
) -> String:
	var ids: PackedStringArray = content.variant_ids()
	if ids.is_empty():
		return VariantDef.NORMAL_ID
	var weights: PackedFloat64Array = weights_for(content, rare_multiplier)
	var total: float = 0.0
	for weight: float in weights:
		total += weight
	if total <= 0.0:
		return VariantDef.NORMAL_ID
	var roll: float = rng.randf() * total
	var running: float = 0.0
	for index: int in range(ids.size()):
		running += weights[index]
		if roll < running:
			return ids[index]
	return ids[ids.size() - 1]


## Peso efectivo de cada variante, en el orden de [method ContentDB.variant_ids].
static func weights_for(content: ContentDB, rare_multiplier: float = 1.0) -> PackedFloat64Array:
	var weights: PackedFloat64Array = PackedFloat64Array()
	for id: String in content.variant_ids():
		var def: VariantDef = content.get_variant(id)
		var factor: float = 1.0 if id == VariantDef.NORMAL_ID else maxf(rare_multiplier, 0.0)
		weights.append(def.weight * factor)
	return weights
