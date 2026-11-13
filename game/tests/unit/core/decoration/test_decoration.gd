extends GutTest
## Contenido de decoración, colocación, solapes, límites, bonificaciones y guardado.

const WIDTH: int = 80
const WATER: int = 12

var _content: ContentDB = null
var _state: GameState = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()
	_content.load_equipment_dir()
	_content.load_decorations_dir()


func before_each() -> void:
	_state = GameState.new()


func _tank() -> Tank:
	return _state.tanks[0]


func _def(decoration_id: String) -> DecorationDef:
	return _content.get_decoration(decoration_id)


func _place(decoration_id: String, x: int, lift: int = 0) -> void:
	_tank().decorations.append(PlacedDecoration.new(_def(decoration_id), x, lift))


func test_the_decoration_catalogue_loads_with_about_twenty_objects() -> void:
	assert_eq(_content.errors, PackedStringArray())
	assert_gte(_content.decoration_ids().size(), 20)


func test_declared_sizes_match_the_sprites() -> void:
	for decoration_id: String in _content.decoration_ids():
		var def: DecorationDef = _def(decoration_id)
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		assert_eq(sprite.width, def.cells_wide, "%s ancho" % decoration_id)
		assert_eq(sprite.height, def.cells_high, "%s alto" % decoration_id)


func test_validation_rejects_a_broken_definition() -> void:
	var def: DecorationDef = DecorationDef.new()
	def.id = "Bad Id"
	def.cells_wide = 0
	def.base_cost = 0.0
	assert_gt(ContentDB.validate_decoration(def).size(), 3)


func test_floor_objects_only_sit_on_the_floor() -> void:
	var rock: DecorationDef = _def("small_rock")
	var ok: DecorationLayout.Result = DecorationLayout.check(_tank(), rock, 500, 0, WIDTH, WATER)
	assert_eq(ok, DecorationLayout.Result.OK)
	var floating: DecorationLayout.Result = DecorationLayout.check(
		_tank(), rock, 500, 3, WIDTH, WATER
	)
	assert_eq(floating, DecorationLayout.Result.OUT_OF_BOUNDS)


func test_water_objects_can_float_but_not_leave_the_water() -> void:
	var lily: DecorationDef = _def("water_lily")
	assert_eq(
		DecorationLayout.check(_tank(), lily, 500, 8, WIDTH, WATER), DecorationLayout.Result.OK
	)
	assert_eq(
		DecorationLayout.check(_tank(), lily, 500, WATER, WIDTH, WATER),
		DecorationLayout.Result.OUT_OF_BOUNDS
	)


func test_objects_taller_than_the_water_do_not_fit() -> void:
	var bamboo: DecorationDef = _def("bamboo")
	var verdict: DecorationLayout.Result = DecorationLayout.check(_tank(), bamboo, 0, 0, WIDTH, 3)
	assert_eq(verdict, DecorationLayout.Result.OUT_OF_BOUNDS)


func test_objects_in_the_same_layer_cannot_overlap() -> void:
	_place("big_rock", 500)
	var verdict: DecorationLayout.Result = DecorationLayout.check(
		_tank(), _def("big_rock"), 505, 0, WIDTH, WATER
	)
	assert_eq(verdict, DecorationLayout.Result.OVERLAP)
	var far: DecorationLayout.Result = DecorationLayout.check(
		_tank(), _def("big_rock"), 900, 0, WIDTH, WATER
	)
	assert_eq(far, DecorationLayout.Result.OK)


func test_objects_in_different_layers_can_share_cells() -> void:
	_place("big_rock", 500)
	var front: DecorationLayout.Result = DecorationLayout.check(
		_tank(), _def("pebbles"), 500, 0, WIDTH, WATER
	)
	assert_eq(front, DecorationLayout.Result.OK)


func test_moving_an_object_ignores_itself() -> void:
	_place("big_rock", 500)
	var self_check: DecorationLayout.Result = DecorationLayout.check(
		_tank(), _def("big_rock"), 505, 0, WIDTH, WATER, _tank().decorations[0]
	)
	assert_eq(self_check, DecorationLayout.Result.OK)


func test_the_tank_has_an_object_limit() -> void:
	for index: int in range(Tank.MAX_DECORATIONS):
		_place("pebbles", index * 80)
	var verdict: DecorationLayout.Result = DecorationLayout.check(
		_tank(), _def("small_rock"), 990, 0, WIDTH, WATER
	)
	assert_eq(verdict, DecorationLayout.Result.TOO_MANY)


func test_position_is_independent_of_the_window_width() -> void:
	var placed: PlacedDecoration = PlacedDecoration.new(_def("big_rock"), 1000, 0)
	assert_eq(placed.rect(80).end.x, 80)
	assert_eq(placed.rect(200).end.x, 200)
	var left: PlacedDecoration = PlacedDecoration.new(_def("big_rock"), 0, 0)
	assert_eq(left.rect(80).position.x, 0)


func test_column_to_permille_round_trips_and_clamps() -> void:
	var rock: DecorationDef = _def("big_rock")
	assert_eq(DecorationLayout.permille_for_column(-5, rock, WIDTH), 0)
	assert_eq(DecorationLayout.permille_for_column(500, rock, WIDTH), 1000)
	var permille: int = DecorationLayout.permille_for_column(36, rock, WIDTH)
	assert_eq(PlacedDecoration.new(rock, permille, 0).rect(WIDTH).position.x, 36)
