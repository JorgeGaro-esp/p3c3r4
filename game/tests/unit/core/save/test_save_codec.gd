extends GutTest
## Pruebas de codificación, validación y migración de partidas.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())


func _sample_state() -> GameState:
	var state: GameState = GameState.new()
	state.rng_seed = 7
	state.rng_state = 123456789
	state.wallet.add(250.0)
	state.tanks[0].add_fish(Fish.new("pond_guppy"))
	state.tanks[0].add_fish(Fish.new("pond_carp"))
	state.mark_production_dirty()
	return state


func _envelope(text: String) -> Dictionary:
	var parser: JSON = JSON.new()
	parser.parse(text)
	return parser.data


func _tank_data(data: Dictionary) -> Dictionary:
	var tanks: Array = data["tanks"]
	var tank: Dictionary = tanks[0]
	return tank


func _fish_data(tank: Dictionary) -> Array:
	var fish_list: Array = tank["fish"]
	return fish_list


func _reseal(envelope: Dictionary) -> String:
	var data: Dictionary = envelope["data"]
	envelope["checksum"] = SaveCodec.checksum_of(data)
	return JSON.stringify(envelope)


func test_round_trip_keeps_the_state() -> void:
	var text: String = SaveCodec.encode(_sample_state(), "0.5.0", 1000)
	var result: DecodeResult = SaveCodec.decode(text, _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.wallet.shells, 250.0)
	assert_eq(result.state.fish_total(), 2)
	assert_eq(result.state.rng_seed, 7)
	assert_eq(result.state.rng_state, 123456789)


func test_encode_is_deterministic() -> void:
	var first: String = SaveCodec.encode(_sample_state(), "0.5.0", 1000)
	var second: String = SaveCodec.encode(_sample_state(), "0.5.0", 1000)
	assert_eq(first, second)


func test_truncated_file_is_malformed() -> void:
	var text: String = SaveCodec.encode(_sample_state(), "0.5.0", 1000)
	var result: DecodeResult = SaveCodec.decode(text.substr(0, text.length() / 2), _content)
	assert_eq(result.status, DecodeResult.Status.MALFORMED)


func test_empty_and_non_object_files_are_malformed() -> void:
	assert_eq(SaveCodec.decode("", _content).status, DecodeResult.Status.MALFORMED)
	assert_eq(SaveCodec.decode("[1,2]", _content).status, DecodeResult.Status.MALFORMED)
	assert_eq(SaveCodec.decode("{}", _content).status, DecodeResult.Status.MALFORMED)


func test_tampered_value_fails_the_checksum() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	var wallet: Dictionary = data["wallet"]
	wallet["shells"] = 1.0e15
	var result: DecodeResult = SaveCodec.decode(JSON.stringify(envelope), _content)
	assert_eq(result.status, DecodeResult.Status.CHECKSUM)


func test_newer_format_is_never_loaded() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "9.9.9", 1000))
	envelope["format_version"] = SaveMigrations.CURRENT_FORMAT + 1
	var result: DecodeResult = SaveCodec.decode(JSON.stringify(envelope), _content)
	assert_eq(result.status, DecodeResult.Status.TOO_NEW)


func test_old_version_is_migrated() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.1.0", 1000))
	var data: Dictionary = envelope["data"]
	var wallet: Dictionary = data["wallet"]
	wallet["coins"] = wallet["shells"]
	wallet["lifetime_coins"] = wallet["total_earned"]
	wallet.erase("shells")
	wallet.erase("total_earned")
	envelope["format_version"] = 0
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.wallet.shells, 250.0)


func test_out_of_range_values_are_clamped_or_rejected() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	var wallet: Dictionary = data["wallet"]
	wallet["shells"] = -50.0
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	if result.is_ok():
		assert_gte(result.state.wallet.shells, 0.0)
	else:
		assert_eq(result.status, DecodeResult.Status.INVALID)


func test_unknown_species_are_dropped() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	var tanks: Array = data["tanks"]
	var tank: Dictionary = tanks[0]
	var fish_list: Array = tank["fish"]
	fish_list.append({"species_id": "no_such_species"})
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.fish_total(), 2)


func test_missing_wallet_is_invalid() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	data.erase("wallet")
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_eq(result.status, DecodeResult.Status.INVALID)


func test_format_1_saves_with_test_species_are_migrated() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	var tanks: Array = data["tanks"]
	var tank: Dictionary = tanks[0]
	var fish_list: Array = tank["fish"]
	var first: Dictionary = fish_list[0]
	first["species_id"] = "test_guppy"
	envelope["format_version"] = 1
	data.erase("unlocked")
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.fish_total(), 2)
	assert_eq(result.state.count_of("pond_guppy"), 1)


func test_unlocked_species_round_trip_and_unknown_ones_are_ignored() -> void:
	var state: GameState = _sample_state()
	state.unlocked["pond_goldfish"] = true
	var envelope: Dictionary = _envelope(SaveCodec.encode(state, "0.5.0", 1000))
	var data: Dictionary = envelope["data"]
	var listed: Array = data["unlocked"]
	listed.append("no_such_species")
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_true(result.state.is_unlocked("pond_goldfish"))
	assert_false(result.state.is_unlocked("no_such_species"))


func test_hunger_and_cleanliness_round_trip() -> void:
	var state: GameState = _sample_state()
	state.tanks[0].cleanliness = 42.5
	state.tanks[0].fish[0].hunger = 17.0
	var result: DecodeResult = SaveCodec.decode(SaveCodec.encode(state, "0.7.0", 1), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks[0].cleanliness, 42.5)
	assert_eq(result.state.tanks[0].fish[0].hunger, 17.0)


func test_older_saves_without_care_data_start_clean_and_fed() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.6.0", 1))
	var data: Dictionary = envelope["data"]
	var tanks: Array = data["tanks"]
	var tank: Dictionary = tanks[0]
	tank.erase("cleanliness")
	var fish_list: Array = tank["fish"]
	var first: Dictionary = fish_list[0]
	first.erase("hunger")
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks[0].cleanliness, Care.MAX_CLEANLINESS)
	assert_eq(result.state.tanks[0].fish[0].hunger, Care.MAX_HUNGER)


func test_out_of_range_care_values_are_clamped() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.7.0", 1))
	var data: Dictionary = envelope["data"]
	var tanks: Array = data["tanks"]
	var tank: Dictionary = tanks[0]
	tank["cleanliness"] = 9999.0
	var fish_list: Array = tank["fish"]
	var first: Dictionary = fish_list[0]
	first["hunger"] = -50.0
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks[0].cleanliness, Care.MAX_CLEANLINESS)
	assert_eq(result.state.tanks[0].fish[0].hunger, 0.0)


func test_life_stage_variant_eggs_and_discoveries_round_trip() -> void:
	var state: GameState = _sample_state()
	var baby: Fish = state.tanks[0].fish[0]
	baby.maturity = 0.4
	baby.variant_id = "golden"
	state.tanks[0].eggs.append(Egg.new("pond_wels", "albino", 12.5, 0.25))
	state.discover("pond_guppy", "golden")
	var result: DecodeResult = SaveCodec.decode(SaveCodec.encode(state, "0.8.0", 1), _content)
	assert_true(result.is_ok(), result.reason)
	var loaded: Fish = result.state.tanks[0].fish[0]
	assert_eq(loaded.maturity, 0.4)
	assert_eq(loaded.variant_id, "golden")
	assert_eq(result.state.tanks[0].eggs.size(), 1)
	var egg: Egg = result.state.tanks[0].eggs[0]
	assert_eq(
		[egg.species_id, egg.variant_id, egg.remaining, egg.position_x],
		["pond_wels", "albino", 12.5, 0.25]
	)
	assert_true(result.state.is_discovered("pond_guppy", "golden"))
	assert_false(result.state.is_discovered("pond_guppy", "albino"))


func test_format_2_saves_load_as_adult_normal_fish_without_eggs() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.7.0", 1000))
	var data: Dictionary = envelope["data"]
	var tank: Dictionary = _tank_data(data)
	tank.erase("eggs")
	for entry: Variant in _fish_data(tank):
		var fish_data: Dictionary = entry
		fish_data.erase("maturity")
		fish_data.erase("variant_id")
	data.erase("discovered")
	envelope["format_version"] = 2
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.fish_total(), 2)
	for fish: Fish in result.state.tanks[0].fish:
		assert_true(fish.is_adult())
		assert_eq(fish.variant_id, VariantDef.NORMAL_ID)
	assert_eq(result.state.tanks[0].eggs.size(), 0)


func test_an_unknown_variant_falls_back_to_normal_with_a_warning() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_sample_state(), "0.8.0", 1000))
	var data: Dictionary = envelope["data"]
	var tank: Dictionary = _tank_data(data)
	var first: Dictionary = _fish_data(tank)[0]
	first["variant_id"] = "rainbow_unicorn"
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks[0].fish[0].variant_id, VariantDef.NORMAL_ID)
	assert_gt(result.warnings.size(), 0)


func test_out_of_range_maturity_and_surplus_eggs_are_clamped_or_dropped() -> void:
	var state: GameState = _sample_state()
	state.tanks[0].capacity = 3
	state.tanks[0].eggs.append(Egg.new("pond_guppy", "normal", 5.0))
	state.tanks[0].eggs.append(Egg.new("pond_guppy", "normal", 5.0))
	var envelope: Dictionary = _envelope(SaveCodec.encode(state, "0.8.0", 1000))
	var data: Dictionary = envelope["data"]
	var tank: Dictionary = _tank_data(data)
	var first: Dictionary = _fish_data(tank)[0]
	first["maturity"] = 7.5
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_lte(result.state.tanks[0].fish[0].maturity, 1.0)
	assert_eq(result.state.tanks[0].eggs.size(), 1, "solo cabe un huevo")
