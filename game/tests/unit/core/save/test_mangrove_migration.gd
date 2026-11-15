extends GutTest
## Migración 11 → 12: las especies del Manglar cambian (Enciclopedia 2).


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
			{"species_id": "mangrove_archer"},
			{"species_id": "mangrove_shrimp"},
			{"species_id": "mangrove_snapper"},
			{"species_id": "mangrove_sawfish"},
		],
		"eggs": [{"species_id": "mangrove_catfish"}],
	}
	var migrated: Dictionary = SaveMigrations.migrate_11_to_12({"tanks": [tank]})
	assert_eq(
		_ids(migrated, "fish"),
		PackedStringArray(
			["mangrove_tadpole", "mangrove_crab", "mangrove_archer", "mangrove_crocodile"]
		),
		"un solo paso: el arquero antiguo es renacuajo y el pargo es el arquero nuevo"
	)
	assert_eq(_ids(migrated, "eggs"), PackedStringArray(["mangrove_mudskipper"]))


func test_unlocked_and_discovered_follow_without_duplicates() -> void:
	var migrated: Dictionary = (
		SaveMigrations
		. migrate_11_to_12(
			{
				"unlocked": ["mangrove_crab", "mangrove_shrimp", "mangrove_crab"],
				"discovered": ["mangrove_barracuda|normal", "mangrove_sawfish|golden"],
			}
		)
	)
	var unlocked: Array = migrated["unlocked"]
	assert_eq(unlocked.size(), 2)
	assert_true(unlocked.has("mangrove_frog"))
	assert_true(unlocked.has("mangrove_crab"))
	var discovered: Array = migrated["discovered"]
	assert_true(discovered.has("mangrove_arawana|normal"))
	assert_true(discovered.has("mangrove_crocodile|golden"))


func test_the_chain_reaches_the_current_format() -> void:
	assert_gte(SaveMigrations.CURRENT_FORMAT, 12)
