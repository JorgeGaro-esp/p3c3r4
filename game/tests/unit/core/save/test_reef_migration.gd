extends GutTest
## Migración 10 → 11: las especies del Arrecife cambian (Enciclopedia 2).


func _ids(migrated: Dictionary, key: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var tanks: Array = migrated["tanks"]
	var tank: Dictionary = tanks[0]
	var entries: Array = tank[key]
	for entry: Variant in entries:
		var data: Dictionary = entry
		result.append(str(data["species_id"]))
	return result


func test_old_species_become_the_ones_that_took_their_slot() -> void:
	var tank: Dictionary = {
		"fish":
		[
			{"species_id": "reef_damsel"},
			{"species_id": "reef_puffer"},
			{"species_id": "reef_ray"},
			{"species_id": "reef_clownfish"},
		],
		"eggs": [{"species_id": "reef_seahorse"}],
	}
	var migrated: Dictionary = SaveMigrations.migrate_10_to_11({"tanks": [tank]})
	assert_eq(
		_ids(migrated, "fish"),
		PackedStringArray(["reef_anchovy", "reef_ray", "reef_shark", "reef_clownfish"]),
		"el cambio es de un solo paso: la raya antigua es tiburón y el globo es raya"
	)
	assert_eq(_ids(migrated, "eggs"), PackedStringArray(["reef_squid"]))


func test_unlocked_and_discovered_follow_without_duplicates() -> void:
	var migrated: Dictionary = (
		SaveMigrations
		. migrate_10_to_11(
			{
				"unlocked": ["reef_butterfly", "reef_clownfish", "reef_tang"],
				"discovered": ["reef_starfish|normal", "reef_ray|golden"],
			}
		)
	)
	var unlocked: Array = migrated["unlocked"]
	assert_eq(unlocked.size(), 2)
	assert_true(unlocked.has("reef_clownfish"))
	assert_true(unlocked.has("reef_tuna"))
	var discovered: Array = migrated["discovered"]
	assert_true(discovered.has("reef_eel|normal"))
	assert_true(discovered.has("reef_shark|golden"))


func test_the_chain_reaches_the_current_format() -> void:
	assert_gte(SaveMigrations.CURRENT_FORMAT, 11)
	var migrated: Dictionary = SaveMigrations.migrate({"wallet": {}}, 9)
	assert_false(migrated.has("unlocked"))
