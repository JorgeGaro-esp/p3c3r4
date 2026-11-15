extends GutTest
## Todos los colores de las especies tienen que verse sobre el fondo negro; los
## ojos, que son un solo carácter, necesitan aún más contraste.

const DIR: String = "res://content/species"
const MIN_CONTRAST: float = 4.5
const MIN_EYE_CONTRAST: float = 10.0


func test_every_species_colour_is_readable_on_black() -> void:
	var checked: int = 0
	for file: String in DirAccess.get_files_at(DIR):
		if not file.ends_with(".tres"):
			continue
		var def: SpeciesDef = load("%s/%s" % [DIR, file]) as SpeciesDef
		for index: int in range(def.palette_roles.size()):
			var role: String = def.palette_roles[index]
			var needed: float = MIN_EYE_CONTRAST if role == "e" else MIN_CONTRAST
			var ratio: float = _contrast(def.palette_colors[index])
			assert_gte(ratio, needed - 0.05, "%s rol %s" % [def.id, role])
			checked += 1
	assert_gt(checked, 0)


func _contrast(color: Color) -> float:
	return (_linear_luminance(color) + 0.05) / 0.05


func _linear_luminance(color: Color) -> float:
	var lin: Color = color.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b
