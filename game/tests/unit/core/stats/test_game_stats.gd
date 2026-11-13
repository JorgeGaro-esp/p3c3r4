extends GutTest
## Contadores de la partida: suma, límites, guardado y datos dañados.


func test_a_new_counter_starts_at_zero() -> void:
	var stats: GameStats = GameStats.new()
	for id: String in GameStats.IDS:
		assert_eq(stats.value(id), 0.0)


func test_add_accumulates() -> void:
	var stats: GameStats = GameStats.new()
	stats.add(GameStats.FISH_BOUGHT)
	stats.add(GameStats.FISH_BOUGHT, 4.0)
	assert_eq(stats.value(GameStats.FISH_BOUGHT), 5.0)


func test_unknown_ids_and_bad_amounts_are_ignored() -> void:
	var stats: GameStats = GameStats.new()
	stats.add("hacks")
	stats.add(GameStats.FISH_SOLD, -3.0)
	stats.add(GameStats.FISH_SOLD, 0.0)
	stats.add(GameStats.FISH_SOLD, NAN)
	stats.add(GameStats.FISH_SOLD, INF)
	assert_eq(stats.value("hacks"), 0.0)
	assert_eq(stats.value(GameStats.FISH_SOLD), 0.0)
	assert_eq(stats.to_dict().size(), 0)


func test_counters_never_pass_the_cap() -> void:
	var stats: GameStats = GameStats.new()
	stats.add(GameStats.PEARLS_COLLECTED, GameStats.MAX_VALUE)
	stats.add(GameStats.PEARLS_COLLECTED, 10.0)
	assert_eq(stats.value(GameStats.PEARLS_COLLECTED), GameStats.MAX_VALUE)


func test_round_trip_keeps_values() -> void:
	var stats: GameStats = GameStats.new()
	stats.add(GameStats.EGGS_HATCHED, 7.0)
	stats.add(GameStats.SPOTS_CLEANED, 2.0)
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameStats = GameStats.from_dict(stats.to_dict(), warnings)
	assert_eq(loaded.value(GameStats.EGGS_HATCHED), 7.0)
	assert_eq(loaded.value(GameStats.SPOTS_CLEANED), 2.0)
	assert_eq(warnings.size(), 0)


func test_damaged_data_is_discarded_with_warnings() -> void:
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: GameStats = (
		GameStats
		. from_dict(
			{
				GameStats.FISH_BOUGHT: -5.0,
				GameStats.FISH_SOLD: "mucho",
				GameStats.FISH_FED: 1.0e30,
				"invented": 9.0,
			},
			warnings
		)
	)
	assert_eq(loaded.value(GameStats.FISH_BOUGHT), 0.0)
	assert_eq(loaded.value(GameStats.FISH_SOLD), 0.0)
	assert_eq(loaded.value(GameStats.FISH_FED), GameStats.MAX_VALUE)
	assert_eq(loaded.value("invented"), 0.0)
	assert_gt(warnings.size(), 0)


func test_missing_or_wrong_type_gives_empty_stats() -> void:
	var warnings: PackedStringArray = PackedStringArray()
	assert_eq(GameStats.from_dict(null, warnings).to_dict().size(), 0)
	assert_eq(warnings.size(), 0)
	assert_eq(GameStats.from_dict([1, 2], warnings).to_dict().size(), 0)
	assert_eq(warnings.size(), 1)
