extends GutTest
## Varias peceras en el guardado: pecera activa, biomas repetidos y migración 5 → 6.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())


func _two_tank_state() -> GameState:
	var state: GameState = GameState.new()
	state.wallet.add(50.0)
	var reef: Tank = Tank.new()
	reef.biome_id = "reef"
	reef.add_fish(Fish.new("reef_krill"))
	state.tanks.append(reef)
	state.active_tank = 1
	return state


func _envelope(text: String) -> Dictionary:
	var parser: JSON = JSON.new()
	parser.parse(text)
	var parsed: Dictionary = parser.data
	return parsed


func _reseal(envelope: Dictionary) -> String:
	var data: Dictionary = envelope["data"]
	envelope["checksum"] = SaveCodec.checksum_of(data)
	return JSON.stringify(envelope)


func test_two_tanks_and_the_active_one_survive_a_round_trip() -> void:
	var text: String = SaveCodec.encode(_two_tank_state(), "0.11.0", 1000)
	var result: DecodeResult = SaveCodec.decode(text, _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks.size(), 2)
	assert_eq(result.state.active_tank, 1)
	assert_eq(result.state.active().biome_id, "reef")
	assert_eq(result.state.tanks[1].count_of("reef_krill"), 1)


func test_an_out_of_range_active_tank_is_clamped() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_two_tank_state(), "0.11.0", 1000))
	var data: Dictionary = envelope["data"]
	data["active_tank"] = 9.0
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.active_tank, 1)
	assert_false(result.warnings.is_empty())


func test_a_repeated_biome_is_dropped() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_two_tank_state(), "0.11.0", 1000))
	var data: Dictionary = envelope["data"]
	var tanks: Array = data["tanks"]
	var second: Dictionary = tanks[1]
	tanks.append(second.duplicate(true))
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.tanks.size(), 2)


func test_format_5_saves_get_the_first_tank_as_active() -> void:
	var envelope: Dictionary = _envelope(SaveCodec.encode(_two_tank_state(), "0.10.0", 1000))
	var data: Dictionary = envelope["data"]
	data.erase("active_tank")
	envelope["format_version"] = 5
	var result: DecodeResult = SaveCodec.decode(_reseal(envelope), _content)
	assert_true(result.is_ok(), result.reason)
	assert_eq(result.state.active_tank, 0)
	assert_eq(result.state.tanks.size(), 2)


func test_migration_5_to_6_adds_the_active_tank_once() -> void:
	var migrated: Dictionary = SaveMigrations.migrate_5_to_6({"tanks": []})
	var added: int = migrated["active_tank"]
	assert_eq(added, 0)
	var again: Dictionary = SaveMigrations.migrate_5_to_6({"active_tank": 1})
	var kept: int = again["active_tank"]
	assert_eq(kept, 1)
