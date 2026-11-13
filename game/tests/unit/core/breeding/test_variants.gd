extends GutTest
## Variantes de color: contenido, sorteo (estadístico) y paletas.

const SAMPLES: int = 200000
const IDS: PackedStringArray = ["normal", "albino", "melanistic", "golden", "prismatic"]
const EXPECTED: Array[float] = [0.93, 0.04, 0.02, 0.009, 0.001]
const MULTIPLIERS: Array[float] = [1.0, 3.0, 5.0, 15.0, 50.0]

var _content: ContentDB = null


func before_all() -> void:
	_content = ContentDB.new()
	_content.load_variants_dir()


func _frequencies(rare_multiplier: float, seed_value: int) -> Dictionary[String, float]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts: Dictionary[String, int] = {}
	for _index: int in range(SAMPLES):
		var id: String = VariantRoll.pick(_content, rng, rare_multiplier)
		counts[id] = counts.get(id, 0) + 1
	var result: Dictionary[String, float] = {}
	for id: String in IDS:
		var count: int = counts.get(id, 0)
		result[id] = float(count) / float(SAMPLES)
	return result


func test_the_five_variants_load_with_the_gdd_values() -> void:
	assert_eq(_content.errors.size(), 0, str(_content.errors))
	assert_eq(_content.variant_ids().size(), IDS.size())
	var total_weight: float = 0.0
	for index: int in range(IDS.size()):
		var def: VariantDef = _content.get_variant(IDS[index])
		assert_not_null(def, IDS[index])
		assert_almost_eq(def.weight / 100.0, EXPECTED[index], 1.0e-9)
		assert_eq(def.sale_multiplier, MULTIPLIERS[index])
		total_weight += def.weight
	assert_almost_eq(total_weight, 100.0, 1.0e-9)


func test_observed_frequencies_match_the_configured_ones() -> void:
	var observed: Dictionary[String, float] = _frequencies(1.0, 20261113)
	for index: int in range(IDS.size()):
		var expected: float = EXPECTED[index]
		# Cinco desviaciones típicas de una binomial: falla por azar casi nunca.
		var tolerance: float = 5.0 * sqrt(expected * (1.0 - expected) / float(SAMPLES))
		assert_almost_eq(observed[IDS[index]], expected, tolerance, IDS[index])


func test_the_same_seed_gives_the_same_variants() -> void:
	var first: RandomNumberGenerator = RandomNumberGenerator.new()
	var second: RandomNumberGenerator = RandomNumberGenerator.new()
	first.seed = 7
	second.seed = 7
	for _index: int in range(500):
		assert_eq(VariantRoll.pick(_content, first), VariantRoll.pick(_content, second))


func test_a_rare_multiplier_makes_rare_variants_more_common() -> void:
	var plain: Dictionary[String, float] = _frequencies(1.0, 5)
	var boosted: Dictionary[String, float] = _frequencies(3.0, 5)
	assert_gt(boosted["albino"], plain["albino"] * 2.0)
	assert_lt(boosted["normal"], plain["normal"])


func test_a_zero_multiplier_only_gives_normal() -> void:
	var observed: Dictionary[String, float] = _frequencies(0.0, 9)
	assert_eq(observed["normal"], 1.0)


func test_a_variant_needs_a_valid_definition() -> void:
	var bad: VariantDef = VariantDef.new()
	bad.id = "Bad Id"
	bad.weight = 0.0
	bad.sale_multiplier = 0.5
	assert_gt(ContentDB.validate_variant(bad).size(), 3)


func test_content_without_the_normal_variant_is_reported() -> void:
	var content: ContentDB = ContentDB.new()
	assert_false(content.load_variants_dir("res://tests/fixtures/no_variants"))


func test_albino_is_lighter_and_melanistic_darker() -> void:
	var source: Color = Color(0.9, 0.4, 0.2)
	var albino: Color = VariantPalette.tint(source, VariantDef.Look.ALBINO)
	var dark: Color = VariantPalette.tint(source, VariantDef.Look.MELANISTIC)
	assert_gt(albino.get_luminance(), source.get_luminance())
	assert_lt(dark.get_luminance(), source.get_luminance() * 0.6)


func test_golden_is_warm_whatever_the_source_colour() -> void:
	for source: Color in [Color(0.2, 0.4, 0.9), Color(0.5, 0.5, 0.5), Color(0.9, 0.1, 0.1)]:
		var gold: Color = VariantPalette.tint(source, VariantDef.Look.GOLDEN)
		assert_gt(gold.r, gold.b + 0.2)


func test_normal_keeps_the_colour_and_keeps_alpha() -> void:
	var source: Color = Color(0.3, 0.6, 0.9, 0.5)
	assert_eq(VariantPalette.tint(source, VariantDef.Look.NONE), source)
	for look: VariantDef.Look in [VariantDef.Look.ALBINO, VariantDef.Look.PRISMATIC]:
		assert_eq(VariantPalette.tint(source, look, 1.0).a, 0.5)


func test_prismatic_changes_over_time_and_along_the_body() -> void:
	var source: Color = Color(0.9, 0.4, 0.2)
	var now: Color = VariantPalette.tint(source, VariantDef.Look.PRISMATIC, 0.0)
	var later: Color = VariantPalette.tint(source, VariantDef.Look.PRISMATIC, 1.5)
	var shifted: Color = VariantPalette.tint(source, VariantDef.Look.PRISMATIC, 0.0, 0.3)
	assert_ne(now, later)
	assert_ne(now, shifted)
	assert_true(VariantPalette.is_animated(VariantDef.Look.PRISMATIC))
	assert_false(VariantPalette.is_animated(VariantDef.Look.GOLDEN))
