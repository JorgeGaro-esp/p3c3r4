extends GutTest
## Logros en el guardado: ida y vuelta, ids desconocidos y migración 7 → 8.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.biomes.load_dir())
	assert_true(_content.achievements.load_dir())


func test_achievements_survive_a_save_and_load() -> void:
	var state: GameState = GameState.new()
	state.achievements["first_fish"] = true
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(state.to_dict(), _content, warnings)
	assert_not_null(loaded)
	assert_true(loaded.achievements.has("first_fish"))


func test_unknown_and_false_entries_are_dropped() -> void:
	var data: Dictionary = GameState.new().to_dict()
	data["achievements"] = {"first_fish": true, "ghost": true, "first_sale": false, "x": 3}
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(data, _content, warnings)
	assert_not_null(loaded)
	assert_eq(loaded.achievements.size(), 1)
	assert_true(loaded.achievements.has("first_fish"))


func test_a_broken_achievements_field_warns_and_loads_empty() -> void:
	var data: Dictionary = GameState.new().to_dict()
	data["achievements"] = [1, 2]
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(data, _content, warnings)
	assert_not_null(loaded)
	assert_true(loaded.achievements.is_empty())
	assert_false(warnings.is_empty())


func test_migration_7_to_8_adds_an_empty_list() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_7_to_8({"stats": {}})
	assert_true(migrated.has("achievements"))
	var entries: Dictionary = migrated["achievements"]
	assert_true(entries.is_empty())
