class_name DecorationShelf
extends RefCounted
## Qué decoración se puede comprar o encontrar: todas menos los premios
## ([member DecorationDef.is_reward]).


## Ids de las decoraciones que no son premios, en el orden del contenido.
static func sellable_ids(content: ContentDB) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for decoration_id: String in content.decoration_ids():
		if not content.get_decoration(decoration_id).is_reward:
			ids.append(decoration_id)
	return ids


## Ids de las decoraciones a la venta en el bioma [param biome_id]: las suyas y las
## que sirven en cualquiera.
static func sellable_in(content: ContentDB, biome_id: String) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for decoration_id: String in sellable_ids(content):
		var def: DecorationDef = content.get_decoration(decoration_id)
		if def.biome_id.is_empty() or def.biome_id == biome_id:
			ids.append(decoration_id)
	return ids
