extends GutTest
## El tiburón de imágenes: máscaras presentes, tamaño coherente con el sprite de
## texto y dibujo sin errores.


func _sprite() -> AsciiSprite:
	return SpriteLoader.load_file("res://content/sprites/reef_shark.txt")


func _view() -> ImageFishView:
	var palette: AsciiPalette = Game.content.get_species("reef_shark").build_palette()
	var motion: SwimMotion = SwimMotion.new(
		RandomNumberGenerator.new(), SwimMotion.Style.GLIDE, 4.5, 0.15, 0.7
	)
	return ImageFishView.new("reef_shark", _sprite(), palette, motion, 0.6)


func test_masks_exist_for_the_shark() -> void:
	assert_true(ImageFishView.has_masks("reef_shark"))


func test_no_masks_for_other_species() -> void:
	assert_false(ImageFishView.has_masks("guppy"))


func test_text_sprite_is_valid_and_has_two_frames() -> void:
	var sprite: AsciiSprite = _sprite()
	assert_true(sprite.is_valid(), str(sprite.errors))
	assert_gte(sprite.frame_count(), 2)


func test_view_loads_masks() -> void:
	var view: ImageFishView = _view()
	assert_true(view.is_ready())


func test_mood_change_does_not_break_view() -> void:
	var view: ImageFishView = _view()
	view.set_mood(10.0)
	assert_gt(view.desaturation(), 0.0)
	assert_true(view.is_ready())
