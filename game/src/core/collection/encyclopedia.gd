class_name Encyclopedia
extends RefCounted
## Consultas sobre la colección del jugador (Enciclopedia, GDD §8).
##
## Una combinación de especie y variante se descubre al tener ese pez por primera
## vez (`GameState.discovered`). Aquí solo se lee: no se modifica nada.

## Progreso: [code]x[/code] cosas vistas de [code]y[/code] posibles.
const NONE_FOUND: Vector2i = Vector2i.ZERO


## Especies del bioma [param biome_id] (todas si está vacío), de la más barata a la
## más cara.
static func species_of(content: ContentDB, biome_id: String = "") -> PackedStringArray:
	var entries: Array[SpeciesDef] = []
	for species_id: String in content.species_ids():
		var def: SpeciesDef = content.get_species(species_id)
		if biome_id.is_empty() or def.biome_id == biome_id:
			entries.append(def)
	entries.sort_custom(
		func(a: SpeciesDef, b: SpeciesDef) -> bool: return a.base_cost < b.base_cost
	)
	var result: PackedStringArray = PackedStringArray()
	for def: SpeciesDef in entries:
		result.append(def.id)
	return result


## Cuántas variantes de [param species_id] se han tenido.
static func variants_found(state: GameState, content: ContentDB, species_id: String) -> int:
	var found: int = 0
	for variant_id: String in content.variant_ids():
		if state.is_discovered(species_id, variant_id):
			found += 1
	return found


## Si se ha tenido alguna vez algún pez de [param species_id].
static func is_species_found(state: GameState, content: ContentDB, species_id: String) -> bool:
	return variants_found(state, content, species_id) > 0


## Especies descubiertas y totales del bioma (todas si [param biome_id] está vacío).
static func species_progress(
	state: GameState, content: ContentDB, biome_id: String = ""
) -> Vector2i:
	var ids: PackedStringArray = species_of(content, biome_id)
	var found: int = 0
	for species_id: String in ids:
		if is_species_found(state, content, species_id):
			found += 1
	return Vector2i(found, ids.size())


## Combinaciones de especie y variante descubiertas y totales del bioma.
static func variant_progress(
	state: GameState, content: ContentDB, biome_id: String = ""
) -> Vector2i:
	var ids: PackedStringArray = species_of(content, biome_id)
	var found: int = 0
	for species_id: String in ids:
		found += variants_found(state, content, species_id)
	return Vector2i(found, ids.size() * content.variant_ids().size())


## Variantes que no son la normal descubiertas, del bioma (todos si está vacío).
static func rare_variants_found(state: GameState, content: ContentDB, biome_id: String = "") -> int:
	var found: int = 0
	for species_id: String in species_of(content, biome_id):
		for variant_id: String in content.variant_ids():
			if variant_id != VariantDef.NORMAL_ID and state.is_discovered(species_id, variant_id):
				found += 1
	return found


## Cuántas especies legendarias se han tenido alguna vez.
static func legendary_found(state: GameState, content: ContentDB) -> int:
	var found: int = 0
	for species_id: String in species_of(content):
		var def: SpeciesDef = content.get_species(species_id)
		if (
			def.rarity == SpeciesDef.Rarity.LEGENDARY
			and is_species_found(state, content, species_id)
		):
			found += 1
	return found


## La Enciclopedia está completa cuando se tiene cada variante de cada especie.
static func is_complete(state: GameState, content: ContentDB) -> bool:
	var progress: Vector2i = variant_progress(state, content)
	return progress.y > 0 and progress.x >= progress.y
