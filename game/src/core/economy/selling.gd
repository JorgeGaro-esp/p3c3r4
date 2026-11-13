class_name Selling
extends RefCounted
## Reglas de venta (GDD §3.2): cuánto vale un pez y qué peces son «sobrantes».

## Cuántos peces de cada especie y variante se conservan en una venta de sobrantes
## (una pareja para seguir criando).
const KEEP_BREEDERS: int = 2


## Conchas que da vender [param fish] ahora mismo.
static func value_of(fish: Fish, content: ContentDB) -> float:
	var species: SpeciesDef = content.get_species(fish.species_id)
	if species == null:
		return 0.0
	var multiplier: float = 1.0
	var variant: VariantDef = content.get_variant(fish.variant_id)
	if variant != null:
		multiplier = variant.sale_multiplier
	return Economy.sale_value(species.base_cost, multiplier, LifeStage.sale_factor(fish.stage()))


## Peces de [param species_id] y [param variant_id] que se pueden vender sin perder
## la pareja de cría: se conservan los [constant KEEP_BREEDERS] más maduros.
static func surplus(tank: Tank, species_id: String, variant_id: String) -> Array[Fish]:
	var same: Array[Fish] = []
	for fish: Fish in tank.fish:
		if fish.species_id == species_id and fish.variant_id == variant_id:
			same.append(fish)
	same.sort_custom(func(a: Fish, b: Fish) -> bool: return a.maturity > b.maturity)
	var extra: Array[Fish] = []
	for index: int in range(KEEP_BREEDERS, same.size()):
		extra.append(same[index])
	return extra


## Suma de [method value_of] de [param fish_list].
static func total_value(fish_list: Array[Fish], content: ContentDB) -> float:
	var total: float = 0.0
	for fish: Fish in fish_list:
		total += value_of(fish, content)
	return total
