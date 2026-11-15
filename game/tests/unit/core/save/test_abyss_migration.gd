extends GutTest
## Migración 12 → 13: las especies del Abismo cambian (Enciclopedia 2).


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
			{"species_id": "abyss_lantern"},
			{"species_id": "abyss_hatchet"},
			{"species_id": "abyss_viperfish"},
			{"species_id": "abyss_oarfish"},
			{"species_id": "abyss_giant_squid"},
		],
		"eggs": [{"species_id": "abyss_squid"}],
	}
	var migrated: Dictionary = SaveMigrations.migrate_12_to_13({"tanks": [tank]})
	assert_eq(
		_ids(migrated, "fish"),
		PackedStringArray(
			[
				"abyss_lantern",
				"abyss_viperfish",
				"abyss_anglerfish",
				"abyss_giant_squid",
				"abyss_sperm_whale",
			]
		),
		"un solo paso: el pez víbora antiguo es rape y el pez hacha es el víbora nuevo"
	)
	assert_eq(_ids(migrated, "eggs"), PackedStringArray(["abyss_blobfish"]))


func test_unlocked_and_discovered_follow_without_duplicates() -> void:
	var migrated: Dictionary = (
		SaveMigrations
		. migrate_12_to_13(
			{
				"unlocked": ["abyss_viperfish", "abyss_hatchet", "abyss_viperfish"],
				"discovered": ["abyss_anglerfish|normal", "abyss_giant_squid|golden"],
			}
		)
	)
	var unlocked: Array = migrated["unlocked"]
	assert_eq(unlocked.size(), 2)
	assert_true(unlocked.has("abyss_anglerfish"))
	assert_true(unlocked.has("abyss_viperfish"))
	var discovered: Array = migrated["discovered"]
	assert_true(discovered.has("abyss_pelican|normal"))
	assert_true(discovered.has("abyss_sperm_whale|golden"))


func test_the_chain_reaches_the_current_format() -> void:
	assert_eq(SaveMigrations.CURRENT_FORMAT, 13)
