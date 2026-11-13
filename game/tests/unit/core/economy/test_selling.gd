extends GutTest
## Valor de venta y venta de sobrantes.

var _content: ContentDB = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()
	_content.load_species_dir()


func _fish(species_id: String, variant_id: String, maturity: float) -> Fish:
	var fish: Fish = Fish.new(species_id)
	fish.variant_id = variant_id
	fish.maturity = maturity
	return fish


func test_an_adult_sells_for_half_its_base_cost_times_the_variant() -> void:
	var base: float = _content.get_species("pond_goldfish").base_cost
	assert_eq(Selling.value_of(_fish("pond_goldfish", "normal", 1.0), _content), floorf(base * 0.5))
	assert_eq(Selling.value_of(_fish("pond_goldfish", "golden", 1.0), _content), floorf(base * 7.5))
	assert_eq(Selling.value_of(_fish("pond_goldfish", "prismatic", 1.0), _content), base * 25.0)


func test_young_fish_sell_for_less() -> void:
	var adult: float = Selling.value_of(_fish("pond_koi", "normal", 1.0), _content)
	var juvenile: float = Selling.value_of(_fish("pond_koi", "normal", 0.5), _content)
	var fry: float = Selling.value_of(_fish("pond_koi", "normal", 0.0), _content)
	assert_lt(fry, juvenile)
	assert_lt(juvenile, adult)
	assert_eq(juvenile, adult * 0.5)


func test_a_sale_is_never_worth_less_than_one_shell() -> void:
	assert_gte(Selling.value_of(_fish("pond_guppy", "normal", 0.0), _content), 1.0)


func test_surplus_keeps_the_two_most_mature_fish_of_the_group() -> void:
	var tank: Tank = Tank.new()
	var oldest: Fish = _fish("pond_guppy", "normal", 1.0)
	var second: Fish = _fish("pond_guppy", "normal", 0.8)
	var young: Fish = _fish("pond_guppy", "normal", 0.1)
	var younger: Fish = _fish("pond_guppy", "normal", 0.0)
	for fish: Fish in [young, oldest, younger, second]:
		tank.add_fish(fish)
	var extra: Array[Fish] = Selling.surplus(tank, "pond_guppy", "normal")
	assert_eq(extra.size(), 2)
	assert_true(extra.has(young))
	assert_true(extra.has(younger))
	assert_false(extra.has(oldest))
	assert_false(extra.has(second))


func test_surplus_only_looks_at_the_same_species_and_variant() -> void:
	var tank: Tank = Tank.new()
	for _index: int in range(3):
		tank.add_fish(_fish("pond_guppy", "normal", 1.0))
	tank.add_fish(_fish("pond_guppy", "golden", 1.0))
	tank.add_fish(_fish("pond_minnow", "normal", 1.0))
	assert_eq(Selling.surplus(tank, "pond_guppy", "normal").size(), 1)
	assert_eq(Selling.surplus(tank, "pond_guppy", "golden").size(), 0)
	assert_eq(Selling.surplus(tank, "pond_minnow", "normal").size(), 0)
