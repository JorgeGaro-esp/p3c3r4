extends GutTest
## Migración 9 → 10: las especies del Estanque cambian (Enciclopedia 2).


func _fish_ids(migrated: Dictionary, key: String) -> PackedStringArray:
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
			{"species_id": "pond_minnow"},
			{"species_id": "pond_loach"},
			{"species_id": "pond_guppy"},
		],
		"eggs": [{"species_id": "pond_snail"}],
	}
	var migrated: Dictionary = SaveMigrations.migrate_9_to_10({"tanks": [tank]})
	assert_eq(
		_fish_ids(migrated, "fish"), PackedStringArray(["pond_carp", "pond_catfish", "pond_guppy"])
	)
	assert_eq(_fish_ids(migrated, "eggs"), PackedStringArray(["pond_trout"]))


func test_unlocked_and_discovered_follow_without_duplicates() -> void:
	var migrated: Dictionary = (
		SaveMigrations
		. migrate_9_to_10(
			{
				"unlocked": ["pond_guppy", "pond_tetra", "pond_goldfish", "pond_tetra"],
				"discovered": ["pond_angelfish|normal", "pond_minnow|golden", "pond_salmon|normal"],
			}
		)
	)
	var unlocked: Array = migrated["unlocked"]
	assert_eq(unlocked.size(), 2)
	assert_true(unlocked.has("pond_goldfish"))
	var discovered: Array = migrated["discovered"]
	assert_true(discovered.has("pond_salmon|normal"))
	assert_true(discovered.has("pond_carp|golden"))
	assert_eq(discovered.size(), 2)


func test_a_save_without_those_lists_stays_without_them() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_9_to_10({"wallet": {}})
	assert_false(migrated.has("unlocked"))
	assert_false(migrated.has("discovered"))
