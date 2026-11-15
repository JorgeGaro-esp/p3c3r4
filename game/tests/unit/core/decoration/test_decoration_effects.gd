extends GutTest
## Bonificaciones de la decoración, desbloqueos y guardado.

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


func test_comfort_bonuses_add_up_with_a_cap() -> void:
	_place("ruins_arch", 0)
	_place("big_rock", 500)
	_tank().refresh_bonuses(_content)
	assert_almost_eq(_tank().bonuses.comfort, 0.10, 0.0001)
	var levels: Dictionary[String, int] = {"heater": 5}
	var combined: TankBonuses = TankBonuses.compute(levels, _content, _tank().decorations)
	assert_almost_eq(combined.comfort, 0.70, 0.0001)


func test_production_bonus_raises_the_rate_and_is_capped() -> void:
	_tank().add_fish(Fish.new("pond_guppy"))
	var base: float = Simulation.total_production(_state, _content)
	_place("statue", 0)
	_tank().refresh_bonuses(_content)
	assert_almost_eq(Simulation.total_production(_state, _content), base * 1.03, 0.0001)
	var many: Array[PlacedDecoration] = []
	for _index: int in range(20):
		many.append(PlacedDecoration.new(_def("statue"), 0, 0))
	var capped: TankBonuses = TankBonuses.compute({}, _content, many)
	assert_almost_eq(capped.production_multiplier, 1.0 + TankBonuses.MAX_PRODUCTION_BONUS, 0.0001)


func test_rare_variant_decoration_raises_the_multiplier() -> void:
	_place("crystal", 0)
	_tank().refresh_bonuses(_content)
	assert_almost_eq(_tank().bonuses.rare_multiplier, 1.15, 0.0001)


func test_loach_needs_a_cave() -> void:
	var loach: SpeciesDef = _content.get_species("pond_catfish")
	assert_false(Unlocks.is_met(loach, _state))
	_place("cave", 100)
	assert_true(Unlocks.is_met(loach, _state))


func test_decorations_survive_a_save_and_bad_entries_are_dropped() -> void:
	_place("cave", 250)
	_place("water_lily", 600, 7)
	_state.decoration_stock["chest"] = 2
	var data: Dictionary = _state.to_dict()
	var tanks: Array = data["tanks"]
	var tank_data: Dictionary = tanks[0]
	var list: Array = tank_data["decorations"]
	list.append({"def_id": "ghost", "x": 1, "y": 0})
	list.append("basura")
	var stock: Dictionary = data["decoration_stock"]
	stock["ghost"] = 3
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(data, _content, warnings)
	var tank: Tank = loaded.tanks[0]
	assert_eq(tank.decorations.size(), 2)
	assert_eq(tank.decorations[0].def.id, "cave")
	assert_eq(tank.decorations[0].x_permille, 250)
	assert_eq(tank.decorations[1].lift, 7)
	var chests: int = loaded.decoration_stock.get("chest", 0)
	assert_eq(chests, 2)
	assert_false(loaded.decoration_stock.has("ghost"))


func test_excess_decorations_are_dropped_on_load() -> void:
	var list: Array = []
	for index: int in range(Tank.MAX_DECORATIONS + 5):
		list.append({"def_id": "pebbles", "x": index, "y": 0})
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: Tank = Tank.from_dict({"decorations": list}, _content, warnings)
	assert_eq(loaded.decorations.size(), Tank.MAX_DECORATIONS)


func test_migration_adds_empty_decoration_data() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_4_to_5({"tanks": [{"fish": []}]})
	assert_true(migrated.has("decoration_stock"))
	var tanks: Array = migrated["tanks"]
	var tank: Dictionary = tanks[0]
	assert_true(tank.has("decorations"))
