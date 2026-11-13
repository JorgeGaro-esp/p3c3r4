extends GutTest
## Pruebas de codificación, validación y migración de partidas.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_species_dir())


func _sample_state() -> GameState:
	var state: GameState = GameState.new()
	state.rng_seed = 7
	state.rng_state = 123456789
	state.wallet.add(250.0)
	state.tanks[0].add_fish(Fish.new("test_guppy"))
	state.tanks[0].add_fish(Fish.new("test_minnow"))
	state.mark_production_dirty()
	return state


func _envelope(text: String) -> Dictionary:
	var parser: JSON = JSON.new()
	parser.parse(text)
	return parser.data


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
