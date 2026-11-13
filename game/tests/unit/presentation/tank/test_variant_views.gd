extends GutTest
## Aspecto de las variantes en `FishView` y huevos en `EggField`.

var _sprite: AsciiSprite = null
var _palette: AsciiPalette = null


func before_each() -> void:
	_sprite = SpriteLoader.load_file("res://content/sprites/pond_guppy.txt")
	_palette = AsciiPalette.from_arrays(
		PackedStringArray(["b", "t", "e"]),
		PackedColorArray([Color(0.9, 0.4, 0.2), Color(0.8, 0.3, 0.1), Color(1.0, 1.0, 1.0)])
	)


func _view(look: VariantDef.Look) -> FishView:
	var motion: SwimMotion = SwimMotion.new(
		RandomNumberGenerator.new(), SwimMotion.Style.GLIDE, 4.0, 0.1, 1.0
	)
	return FishView.new(_sprite, _palette, motion, 0.4, look)


func _first_color(view: FishView) -> Color:
	return view._cells[0].colors[0]


func test_a_golden_fish_has_other_colours_than_a_normal_one() -> void:
	assert_ne(
		_first_color(_view(VariantDef.Look.GOLDEN)), _first_color(_view(VariantDef.Look.NONE))
	)


func test_a_prismatic_fish_keeps_changing_colour_while_it_swims() -> void:
	var view: FishView = _view(VariantDef.Look.PRISMATIC)
	var before: Color = _first_color(view)
	view.update(1.0, null)
	assert_ne(_first_color(view), before)


func test_a_normal_fish_never_changes_colour() -> void:
	var view: FishView = _view(VariantDef.Look.NONE)
	var before: Color = _first_color(view)
	view.update(2.0, null)
	assert_eq(_first_color(view), before)


func test_the_mood_still_desaturates_a_variant() -> void:
	var view: FishView = _view(VariantDef.Look.PRISMATIC)
	view.set_mood(0.0)
	view.update(1.0, null)
	assert_gt(view.desaturation(), 0.5)
	var color: Color = _first_color(view)
	var gray: float = color.get_luminance()
	assert_lt(absf(color.r - gray), 0.5)


func test_the_egg_field_counts_the_eggs_it_is_given() -> void:
	var field: EggField = EggField.new()
	var eggs: Array[Egg] = [
		Egg.new("pond_guppy", "normal", 10.0), Egg.new("pond_koi", "golden", 3.0)
	]
	field.set_eggs(eggs, 80)
	assert_eq(field.count(), 2)
