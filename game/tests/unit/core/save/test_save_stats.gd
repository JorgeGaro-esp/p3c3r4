extends GutTest
## Estadísticas en el guardado: ida y vuelta y migración 6 → 7.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())


func test_stats_survive_a_save_and_load() -> void:
	var state: GameState = GameState.new()
	state.wallet.add(5.0)
	state.stats.add(GameStats.FISH_BOUGHT, 3.0)
	state.stats.add(GameStats.PEARLS_COLLECTED, 12.0)
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(state.to_dict(), _content, warnings)
	assert_not_null(loaded)
	assert_eq(loaded.stats.value(GameStats.FISH_BOUGHT), 3.0)
	assert_eq(loaded.stats.value(GameStats.PEARLS_COLLECTED), 12.0)


func test_an_old_save_without_stats_loads_with_zeroes() -> void:
	var state: GameState = GameState.new()
	var data: Dictionary = state.to_dict()
	data.erase("stats")
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameState = GameState.from_dict(data, _content, warnings)
	assert_not_null(loaded)
	assert_eq(loaded.stats.value(GameStats.FISH_SOLD), 0.0)


func test_migration_adds_empty_stats_and_keeps_existing_ones() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_6_to_7({"tanks": []})
	assert_true(migrated.has("stats"))
	var kept: Dictionary = SaveMigrations.migrate_6_to_7({"stats": {"fish_sold": 4.0}})
	var stats: Dictionary = kept["stats"]
	var sold: float = stats["fish_sold"]
	assert_eq(sold, 4.0)


func test_migrating_from_version_6_reaches_the_current_format() -> void:
	var migrated: Dictionary = SaveMigrations.migrate({"tanks": []}, 6)
	assert_true(migrated.has("stats"))
