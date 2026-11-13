extends GutTest
## Contenido de equipos, bonificaciones acumuladas y efectos en la simulación.

var _content: ContentDB = null
var _rng: RandomNumberGenerator = null
var _state: GameState = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()
	_content.load_equipment_dir()


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 5
	_state = GameState.new()


func _tank() -> Tank:
	return _state.tanks[0]


func _fill(count: int) -> void:
	for _index: int in range(count):
		_tank().add_fish(Fish.new("pond_guppy"))


func _run(seconds: float) -> void:
	for _step: int in range(roundi(seconds / 0.1)):
		Simulation.step(_state, 0.1, _content, _rng)


func test_the_seven_equipment_definitions_load_without_errors() -> void:
	assert_eq(_content.errors, PackedStringArray())
	assert_eq(_content.equipment_ids().size(), 7)
	for effect: int in EquipmentDef.Effect.values():
		var found: bool = false
		for equipment_id: String in _content.equipment_ids():
			if _content.get_equipment(equipment_id).effect == effect:
				found = true
		assert_true(found, "falta un equipo con el efecto %d" % effect)


func test_validation_rejects_a_broken_definition() -> void:
	var def: EquipmentDef = EquipmentDef.new()
	def.id = "Bad Id"
	def.max_level = 0
	def.base_cost = -1.0
	assert_gt(ContentDB.validate_equipment(def).size(), 3)


func test_no_equipment_means_neutral_bonuses() -> void:
	var bonuses: TankBonuses = TankBonuses.compute({}, _content)
	assert_eq(bonuses.dirt_factor, 1.0)
	assert_eq(bonuses.capacity_bonus, 0)
	assert_eq(bonuses.growth_speed, 1.0)
	assert_eq(bonuses.feed_interval, 0.0)
	assert_eq(bonuses.magnet_delay, 0.0)


func test_each_level_of_an_effect_is_stronger() -> void:
	for equipment_id: String in _content.equipment_ids():
		var def: EquipmentDef = _content.get_equipment(equipment_id)
		var low: Dictionary[String, int] = {equipment_id: 1}
		var high: Dictionary[String, int] = {equipment_id: def.max_level}
		var weak: TankBonuses = TankBonuses.compute(low, _content)
		var strong: TankBonuses = TankBonuses.compute(high, _content)
		var changed: bool = (
			strong.dirt_factor < weak.dirt_factor
			or strong.feed_interval < weak.feed_interval
			or strong.comfort > weak.comfort
			or strong.growth_speed > weak.growth_speed
			or strong.capacity_bonus > weak.capacity_bonus
			or strong.hatch_speed > weak.hatch_speed
			or strong.magnet_delay < weak.magnet_delay
		)
		assert_true(changed, "%s no mejora con el nivel" % equipment_id)


func test_bonuses_of_different_equipment_accumulate() -> void:
	var levels: Dictionary[String, int] = {"filter": 2, "aerator": 3, "lamp": 4, "incubator": 2}
	var bonuses: TankBonuses = TankBonuses.compute(levels, _content)
	assert_almost_eq(bonuses.dirt_factor, 0.6, 0.0001)
	assert_eq(bonuses.capacity_bonus, 12)
	assert_almost_eq(bonuses.growth_speed, 2.0, 0.0001)
	assert_almost_eq(bonuses.hatch_speed, 1.6, 0.0001)
	assert_almost_eq(bonuses.rare_multiplier, 1.8, 0.0001)


func test_levels_above_the_maximum_are_clamped() -> void:
	var levels: Dictionary[String, int] = {"aerator": 99}
	var bonuses: TankBonuses = TankBonuses.compute(levels, _content)
	assert_eq(bonuses.capacity_bonus, 20)


func test_the_filter_never_removes_all_dirt() -> void:
	var levels: Dictionary[String, int] = {"filter": 5}
	assert_almost_eq(TankBonuses.compute(levels, _content).dirt_factor, 0.2, 0.0001)


func test_equipment_survives_a_save_and_unknown_ids_are_dropped() -> void:
	_tank().set_level("filter", 3, _content)
	_tank().set_level("aerator", 2, _content)
	var data: Dictionary = _tank().to_dict()
	var equipment: Dictionary = data["equipment"]
	equipment["ghost"] = 4
	equipment["lamp"] = 99
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: Tank = Tank.from_dict(data, _content, warnings)
	assert_eq(loaded.level_of("filter"), 3)
	assert_eq(loaded.level_of("aerator"), 2)
	assert_eq(loaded.level_of("lamp"), 5)
	assert_false(loaded.equipment.has("ghost"))
	assert_eq(loaded.total_capacity(), Tank.DEFAULT_CAPACITY + 8)


func test_migration_adds_empty_equipment() -> void:
	var data: Dictionary = {"tanks": [{"fish": []}]}
	var migrated: Dictionary = SaveMigrations.migrate_3_to_4(data)
	var tanks: Array = migrated["tanks"]
	var tank: Dictionary = tanks[0]
	assert_true(tank.has("equipment"))


func test_equipment_cost_grows_by_level() -> void:
	var def: EquipmentDef = _content.get_equipment("filter")
	assert_eq(Economy.equipment_cost(def.base_cost, 0), def.base_cost)
	assert_gt(Economy.equipment_cost(def.base_cost, 1), def.base_cost)
