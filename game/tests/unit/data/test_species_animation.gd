extends GutTest
## Reglas de animación de los peces (Enciclopedia 2): el ojo no cambia nunca entre
## fotogramas y solo se mueven un poco la cola o las aletas. Cada bioma se añade a
## esta lista cuando se rediseña.

const MIGRATED_BIOMES: PackedStringArray = ["pond", "reef", "mangrove", "abyss"]
const EYE: String = "°"
const MAX_CHANGED_CELLS: int = 8


func test_the_eye_never_changes_and_only_the_tail_or_fins_move() -> void:
	var checked: int = 0
	for def: SpeciesDef in _species():
		for path: String in _paths(def):
			var sprite: AsciiSprite = SpriteLoader.load_file(path)
			assert_not_null(sprite, path)
			if sprite == null:
				continue
			assert_eq(sprite.errors, PackedStringArray(), path)
			assert_gte(sprite.frame_count(), 2, "%s: dos fotogramas" % path)
			_check_frames(sprite, path)
			checked += 1
	assert_gt(checked, 0)


func test_every_stage_has_its_own_sprite() -> void:
	for def: SpeciesDef in _species():
		assert_false(def.fry_sprite_path.is_empty(), "%s sin cría propia" % def.id)
		assert_false(def.juvenile_sprite_path.is_empty(), "%s sin juvenil propio" % def.id)


func _check_frames(sprite: AsciiSprite, path: String) -> void:
	var first: PackedStringArray = sprite.frames[0]
	var changed: int = 0
	for index: int in range(1, sprite.frame_count()):
		var other: PackedStringArray = sprite.frames[index]
		assert_eq(other.size(), first.size(), "%s: misma altura" % path)
		for row: int in range(first.size()):
			assert_eq(other[row].length(), first[row].length(), "%s: mismo ancho" % path)
			for column: int in range(first[row].length()):
				var a: String = first[row][column]
				var b: String = other[row][column]
				if a != b:
					changed += 1
					assert_ne(a, EYE, "%s: el ojo cambia" % path)
					assert_ne(b, EYE, "%s: el ojo aparece" % path)
	assert_lte(
		changed, MAX_CHANGED_CELLS * (sprite.frame_count() - 1), "%s: cambia demasiado" % path
	)


func _species() -> Array[SpeciesDef]:
	var result: Array[SpeciesDef] = []
	for file: String in DirAccess.get_files_at("res://content/species"):
		if not file.ends_with(".tres"):
			continue
		var def: SpeciesDef = load("res://content/species/%s" % file) as SpeciesDef
		if MIGRATED_BIOMES.has(def.biome_id):
			result.append(def)
	return result


func _paths(def: SpeciesDef) -> PackedStringArray:
	return PackedStringArray([def.sprite_path, def.fry_sprite_path, def.juvenile_sprite_path])
