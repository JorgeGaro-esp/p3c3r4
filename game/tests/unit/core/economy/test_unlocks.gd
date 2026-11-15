extends GutTest
## Pruebas de las condiciones de desbloqueo.

var _state: GameState = null


func before_each() -> void:
	_state = GameState.new()


func _def(kind: SpeciesDef.UnlockKind, amount: float, species: String = "") -> SpeciesDef:
	var def: SpeciesDef = SpeciesDef.new()
	def.unlock_kind = kind
	def.unlock_amount = amount
	def.unlock_species_id = species
	return def


func test_no_condition_is_always_met() -> void:
	var def: SpeciesDef = _def(SpeciesDef.UnlockKind.NONE, 0.0)
	assert_true(Unlocks.is_met(def, _state))
	assert_eq(Unlocks.progress_ratio(def, _state), 1.0)


func test_total_earned_uses_the_lifetime_total_not_the_balance() -> void:
	var def: SpeciesDef = _def(SpeciesDef.UnlockKind.TOTAL_EARNED, 100.0)
	_state.wallet.add(150.0)
	_state.wallet.spend(140.0)
	assert_true(Unlocks.is_met(def, _state))


func test_total_earned_not_met_yet_reports_partial_progress() -> void:
	var def: SpeciesDef = _def(SpeciesDef.UnlockKind.TOTAL_EARNED, 100.0)
	_state.wallet.add(25.0)
	assert_false(Unlocks.is_met(def, _state))
	assert_almost_eq(Unlocks.progress_ratio(def, _state), 0.25, 0.0001)


func test_fish_count_counts_every_tank() -> void:
	var def: SpeciesDef = _def(SpeciesDef.UnlockKind.FISH_COUNT, 3.0)
	for _index: int in range(2):
		_state.tanks[0].add_fish(Fish.new("pond_guppy"))
	assert_false(Unlocks.is_met(def, _state))
	_state.tanks[0].add_fish(Fish.new("pond_carp"))
	assert_true(Unlocks.is_met(def, _state))


func test_species_count_only_counts_that_species() -> void:
	var def: SpeciesDef = _def(SpeciesDef.UnlockKind.SPECIES_COUNT, 2.0, "pond_goldfish")
	_state.tanks[0].add_fish(Fish.new("pond_goldfish"))
	_state.tanks[0].add_fish(Fish.new("pond_guppy"))
	assert_false(Unlocks.is_met(def, _state))
	_state.tanks[0].add_fish(Fish.new("pond_goldfish"))
	assert_true(Unlocks.is_met(def, _state))


func test_every_real_species_has_a_reachable_condition() -> void:
	var content: ContentDB = ContentDB.new()
	assert_true(content.load_species_dir(), str(content.errors))
	for species_id: String in content.species_ids():
		var def: SpeciesDef = content.get_species(species_id)
		if def.unlock_kind == SpeciesDef.UnlockKind.SPECIES_COUNT:
			assert_true(content.has_species(def.unlock_species_id), species_id)
			assert_ne(def.unlock_species_id, species_id, "no puede pedirse a sí misma")
