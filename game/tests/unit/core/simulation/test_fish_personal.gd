extends GutTest
## Apodo y favorito de un pez: lista de nombres, guardado y protección frente a la venta.

var _content: ContentDB = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()


func test_nickname_cycles_through_the_list_and_back_to_none() -> void:
	var current: String = ""
	var seen: int = 0
	for _i: int in range(FishNames.NAMES.size()):
		current = FishNames.next(current)
		assert_false(current.is_empty())
		seen += 1
	assert_eq(seen, FishNames.NAMES.size())
	assert_eq(FishNames.next(current), "", "after the last name there is none")


func test_unknown_nickname_moves_to_the_first() -> void:
	assert_eq(FishNames.next("Inventado"), FishNames.NAMES[0])


func test_names_are_short_and_unique() -> void:
	var unique: Dictionary[String, bool] = {}
	for entry: String in FishNames.NAMES:
		assert_lte(entry.length(), 10, entry)
		unique[entry] = true
	assert_eq(unique.size(), FishNames.NAMES.size())


func test_nickname_and_favorite_survive_a_save() -> void:
	var fish: Fish = Fish.new("pond_guppy")
	fish.nickname = "Perla"
	fish.favorite = true
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: Fish = Fish.from_dict(fish.to_dict(), _content, warnings)
	assert_not_null(loaded)
	assert_eq(loaded.nickname, "Perla")
	assert_true(loaded.favorite)
	assert_eq(warnings.size(), 0)


func test_old_saves_without_the_fields_load_clean() -> void:
	var warnings: PackedStringArray = PackedStringArray()
	var loaded: Fish = Fish.from_dict({"species_id": "pond_guppy"}, _content, warnings)
	assert_eq(loaded.nickname, "")
	assert_false(loaded.favorite)
	assert_eq(warnings.size(), 0)


func test_surplus_never_includes_a_favorite() -> void:
	var tank: Tank = Tank.new()
	for index: int in range(4):
		var fish: Fish = Fish.new("pond_guppy")
		fish.maturity = 1.0 - float(index) * 0.1
		tank.add_fish(fish)
	tank.fish[3].favorite = true
	var extra: Array[Fish] = Selling.surplus(tank, "pond_guppy", "normal")
	assert_eq(extra.size(), 1)
	assert_false(extra[0].favorite)
