class_name DexText
extends RefCounted
## Textos de las variantes de una especie en la Enciclopedia: la fila de marcas, la
## lista de la página derecha y los nombres que acompañan a cada aspecto de la foto.


## Una línea con cada variante: marcada si ya se ha tenido.
static func variant_line(def: SpeciesDef) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for variant_id: String in Game.content.variant_ids():
		var variant: VariantDef = Game.content.get_variant(variant_id)
		var mark: String = "x" if Game.state.is_discovered(def.id, variant_id) else " "
		parts.append("[%s]%s" % [mark, TranslationServer.translate(variant.name_key)])
	return " ".join(parts)


## Nombre de cada variante, en el orden del contenido.
static func variant_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for variant_id: String in Game.content.variant_ids():
		names.append(TranslationServer.translate(Game.content.get_variant(variant_id).name_key))
	return names


## Si cada variante ya se ha tenido de [param def], en el mismo orden.
static func found_flags(def: SpeciesDef) -> Array[bool]:
	var flags: Array[bool] = []
	for variant_id: String in Game.content.variant_ids():
		flags.append(Game.state.is_discovered(def.id, variant_id))
	return flags


## Los aspectos de las variantes que se han tenido de [param def].
static func discovered_looks(def: SpeciesDef) -> Array[VariantDef.Look]:
	var looks: Array[VariantDef.Look] = []
	for variant_id: String in Game.content.variant_ids():
		if Game.state.is_discovered(def.id, variant_id):
			looks.append(Game.content.get_variant(variant_id).look)
	return looks


## Los nombres de las variantes que se han tenido de [param def].
static func discovered_names(def: SpeciesDef) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for variant_id: String in Game.content.variant_ids():
		if Game.state.is_discovered(def.id, variant_id):
			names.append(TranslationServer.translate(Game.content.get_variant(variant_id).name_key))
	return names
