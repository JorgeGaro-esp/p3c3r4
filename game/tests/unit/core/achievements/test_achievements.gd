extends GutTest
## Reglas de los logros: métricas, desbloqueo, bonus con tope y datos del contenido.

var _content: ContentDB = ContentDB.new()


func before_all() -> void:
	assert_true(_content.load_variants_dir())
	assert_true(_content.load_species_dir())
	assert_true(_content.load_equipment_dir())
	assert_true(_content.load_decorations_dir())
	assert_true(_content.biomes.load_dir())
	assert_true(_content.achievements.load_dir())
	assert_true(AchievementCatalog.check_references(_content))


func _def(
	metric: AchievementDef.Metric, target: float, reward: float = 1.0, stat: String = ""
) -> AchievementDef:
	var def: AchievementDef = AchievementDef.new()
	def.id = "probe"
	def.name_key = "ACH_PROBE"
	def.metric = metric
	def.target = target
	def.reward_percent = reward
	def.stat_id = stat
	return def


func test_a_stat_achievement_reads_its_counter() -> void:
	var state: GameState = GameState.new()
	var def: AchievementDef = _def(AchievementDef.Metric.STAT, 3.0, 1.0, GameStats.FISH_SOLD)
	assert_false(Achievements.is_met(def, state, _content))
	state.stats.add(GameStats.FISH_SOLD, 3.0)
	assert_true(Achievements.is_met(def, state, _content))


func test_progress_ratio_is_clamped() -> void:
	var state: GameState = GameState.new()
	var def: AchievementDef = _def(AchievementDef.Metric.TOTAL_EARNED, 100.0)
	assert_eq(Achievements.progress_ratio(def, state, _content), 0.0)
	state.wallet.add(25.0)
	assert_almost_eq(Achievements.progress_ratio(def, state, _content), 0.25, 0.0001)
	state.wallet.add(1000.0)
	assert_eq(Achievements.progress_ratio(def, state, _content), 1.0)


func test_play_time_and_fish_metrics() -> void:
	var state: GameState = GameState.new()
	state.sim_time = 3600.0
	assert_true(Achievements.is_met(_def(AchievementDef.Metric.PLAY_TIME, 3600.0), state, _content))
	state.tanks[0].add_fish(Fish.new("pond_guppy"))
	assert_true(Achievements.is_met(_def(AchievementDef.Metric.FISH_NOW, 1.0), state, _content))
	assert_false(Achievements.is_met(_def(AchievementDef.Metric.FISH_NOW, 2.0), state, _content))


func test_species_and_rare_variants_count_discoveries() -> void:
	var state: GameState = GameState.new()
	state.discover("pond_guppy", "normal")
	state.discover("pond_guppy", "golden")
	state.discover("reef_clownfish", "normal")
	var species: AchievementDef = _def(AchievementDef.Metric.SPECIES_FOUND, 2.0)
	assert_true(Achievements.is_met(species, state, _content))
	var pond: AchievementDef = _def(AchievementDef.Metric.SPECIES_FOUND, 2.0)
	pond.biome_id = "pond"
	assert_false(Achievements.is_met(pond, state, _content))
	var rare: AchievementDef = _def(AchievementDef.Metric.VARIANTS_FOUND, 1.0)
	assert_true(Achievements.is_met(rare, state, _content))
	rare.target = 2.0
	assert_false(Achievements.is_met(rare, state, _content))


func test_newly_met_skips_the_ones_already_unlocked() -> void:
	var state: GameState = GameState.new()
	state.stats.add(GameStats.FISH_BOUGHT, 1.0)
	var first: Array[AchievementDef] = Achievements.newly_met(state, _content)
	var ids: PackedStringArray = PackedStringArray()
	for def: AchievementDef in first:
		ids.append(def.id)
	assert_true(ids.has("first_fish"))
	state.achievements["first_fish"] = true
	for def: AchievementDef in Achievements.newly_met(state, _content):
		assert_ne(def.id, "first_fish")


func test_bonus_adds_up_and_has_a_cap() -> void:
	var state: GameState = GameState.new()
	assert_eq(Achievements.bonus_percent(state, _content), 0.0)
	assert_eq(Achievements.multiplier(state, _content), 1.0)
	state.achievements["first_fish"] = true
	var reward: float = _content.achievements.get_achievement("first_fish").reward_percent
	assert_almost_eq(Achievements.bonus_percent(state, _content), reward, 0.0001)
	for achievement_id: String in _content.achievements.ids():
		state.achievements[achievement_id] = true
	assert_eq(Achievements.bonus_percent(state, _content), Achievements.MAX_BONUS_PERCENT)
	assert_almost_eq(
		Achievements.multiplier(state, _content),
		1.0 + Achievements.MAX_BONUS_PERCENT / 100.0,
		0.0001
	)


func test_the_bonus_multiplies_the_production() -> void:
	var state: GameState = GameState.new()
	state.tanks[0].add_fish(_adult("pond_guppy"))
	state.tanks[0].refresh_bonuses(_content)
	var base: float = Simulation.total_production(state, _content)
	assert_gt(base, 0.0)
	state.achievements["fish_bought_500"] = true
	var reward: float = _content.achievements.get_achievement("fish_bought_500").reward_percent
	assert_almost_eq(
		Simulation.total_production(state, _content), base * (1.0 + reward / 100.0), 0.0001
	)


func _adult(species_id: String) -> Fish:
	return Fish.new(species_id)


func test_every_achievement_is_well_formed() -> void:
	var ids: PackedStringArray = _content.achievements.ids()
	assert_gt(ids.size(), 40)
	var last_order: int = -1
	for achievement_id: String in ids:
		var def: AchievementDef = _content.achievements.get_achievement(achievement_id)
		assert_gt(def.target, 0.0, achievement_id)
		assert_gt(def.reward_percent, 0.0, achievement_id)
		assert_gt(def.order, last_order, achievement_id)
		last_order = def.order


func test_rewards_can_reach_the_cap_but_not_by_much() -> void:
	var total: float = 0.0
	for achievement_id: String in _content.achievements.ids():
		total += _content.achievements.get_achievement(achievement_id).reward_percent
	assert_gte(total, Achievements.MAX_BONUS_PERCENT)
	assert_lte(total, Achievements.MAX_BONUS_PERCENT * 1.5)


func test_achievements_are_reachable_with_the_content() -> void:
	# Ningún logro puede pedir más de lo que existe.
	var species_total: int = Encyclopedia.species_of(_content).size()
	var variants_total: int = _content.variant_ids().size() - 1
	for achievement_id: String in _content.achievements.ids():
		var def: AchievementDef = _content.achievements.get_achievement(achievement_id)
		if def.metric == AchievementDef.Metric.SPECIES_FOUND:
			var limit: int = Encyclopedia.species_of(_content, def.biome_id).size()
			assert_lte(def.target, float(limit), achievement_id)
		if def.metric == AchievementDef.Metric.BIOMES_OPENED:
			assert_lte(def.target, float(_content.biomes.ids().size()), achievement_id)
		if def.metric == AchievementDef.Metric.VARIANTS_FOUND:
			assert_lte(def.target, float(species_total * variants_total), achievement_id)
		if def.metric == AchievementDef.Metric.FISH_NOW:
			assert_lte(def.target, 100.0, achievement_id)


func test_names_and_descriptions_exist_in_both_languages() -> void:
	var csv: String = FileAccess.get_file_as_string("res://assets/i18n/strings.csv")
	var keys: Dictionary[String, bool] = {}
	for line: String in csv.split("\n"):
		keys[line.get_slice(",", 0)] = true
	for achievement_id: String in _content.achievements.ids():
		var def: AchievementDef = _content.achievements.get_achievement(achievement_id)
		assert_true(keys.has(def.name_key), def.name_key)
		var metric: String = AchievementDef.Metric.keys()[def.metric]
		var desc_key: String = "ACH_DESC_%s" % metric
		if def.metric == AchievementDef.Metric.STAT:
			desc_key = "ACH_DESC_STAT_%s" % def.stat_id.to_upper()
		assert_true(keys.has(desc_key), desc_key)


func test_invalid_definitions_are_rejected() -> void:
	var catalog: AchievementCatalog = AchievementCatalog.new()
	var bad_stat: AchievementDef = _def(AchievementDef.Metric.STAT, 1.0, 1.0, "nope")
	assert_false(catalog.add(bad_stat))
	var bad_target: AchievementDef = _def(AchievementDef.Metric.FISH_NOW, 0.0)
	assert_false(catalog.add(bad_target))
	var bad_biome: AchievementDef = _def(AchievementDef.Metric.FISH_NOW, 1.0)
	bad_biome.biome_id = "pond"
	assert_false(catalog.add(bad_biome))
	var ok: AchievementDef = _def(AchievementDef.Metric.FISH_NOW, 1.0)
	assert_true(catalog.add(ok))
	assert_false(catalog.add(ok), "id repetido")
