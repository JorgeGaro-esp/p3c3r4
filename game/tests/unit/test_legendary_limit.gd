extends GutTest
## Un solo ejemplar de cada legendario por pecera.


func _legendary() -> SpeciesDef:
	return load("res://content/species/pond_wels.tres") as SpeciesDef


func _common() -> SpeciesDef:
	return load("res://content/species/pond_guppy.tres") as SpeciesDef


func test_legendary_is_accepted_only_once() -> void:
	var tank: Tank = Tank.new()
	var def: SpeciesDef = _legendary()
	assert_true(tank.accepts_species(def))
	tank.add_fish(Fish.new(def.id))
	assert_false(tank.accepts_species(def))


func test_common_species_have_no_limit() -> void:
	var tank: Tank = Tank.new()
	var def: SpeciesDef = _common()
	for _i: int in range(5):
		tank.add_fish(Fish.new(def.id))
	assert_true(tank.accepts_species(def))
