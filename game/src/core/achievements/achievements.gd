class_name Achievements
extends RefCounted
## Reglas de los logros: cuánto lleva el jugador de cada uno, cuáles se acaban de
## cumplir y cuánta producción extra dan los conseguidos.
##
## Solo lee la partida; quien desbloquea y avisa es `Game`.

## Tope de la producción extra que suman todos los logros, en porcentaje.
const MAX_BONUS_PERCENT: float = 50.0


## Valor actual de la métrica de [param def] en [param state].
static func value_of(def: AchievementDef, state: GameState, content: ContentDB) -> float:
	var value: float = 0.0
	match def.metric:
		AchievementDef.Metric.STAT:
			value = state.stats.value(def.stat_id)
		AchievementDef.Metric.TOTAL_EARNED:
			value = state.wallet.total_earned
		AchievementDef.Metric.FISH_NOW:
			value = float(state.fish_total())
		AchievementDef.Metric.SPECIES_FOUND:
			value = float(Encyclopedia.species_progress(state, content, def.biome_id).x)
		AchievementDef.Metric.VARIANTS_FOUND:
			value = float(Encyclopedia.rare_variants_found(state, content, def.biome_id))
		AchievementDef.Metric.LEGENDARY_FOUND:
			value = float(Encyclopedia.legendary_found(state, content))
		AchievementDef.Metric.BIOMES_OPENED:
			value = float(state.tanks.size())
		AchievementDef.Metric.DECORATIONS_PLACED:
			value = float(state.decorations_placed())
		AchievementDef.Metric.PLAY_TIME:
			value = state.sim_time
		AchievementDef.Metric.PRODUCTION_RATE:
			value = state.production_rate
		AchievementDef.Metric.COLLECTION_PERCENT:
			var progress: Vector2i = Encyclopedia.variant_progress(state, content)
			value = 100.0 * float(progress.x) / float(maxi(progress.y, 1))
	return value


## Si [param def] ya se cumple.
static func is_met(def: AchievementDef, state: GameState, content: ContentDB) -> bool:
	return value_of(def, state, content) >= def.target


## Progreso de 0 a 1 hacia [param def].
static func progress_ratio(def: AchievementDef, state: GameState, content: ContentDB) -> float:
	return clampf(value_of(def, state, content) / def.target, 0.0, 1.0)


## Logros que se cumplen y aún no están desbloqueados.
static func newly_met(state: GameState, content: ContentDB) -> Array[AchievementDef]:
	var found: Array[AchievementDef] = []
	for achievement_id: String in content.achievements.ids():
		if state.achievements.has(achievement_id):
			continue
		var def: AchievementDef = content.achievements.get_achievement(achievement_id)
		if is_met(def, state, content):
			found.append(def)
	return found


## Producción extra de los logros conseguidos, en porcentaje y con tope.
static func bonus_percent(state: GameState, content: ContentDB) -> float:
	var total: float = 0.0
	for achievement_id: String in state.achievements:
		var def: AchievementDef = content.achievements.get_achievement(achievement_id)
		if def != null:
			total += def.reward_percent
	return minf(total, MAX_BONUS_PERCENT)


## Factor por el que se multiplica la producción (1 sin logros).
static func multiplier(state: GameState, content: ContentDB) -> float:
	return 1.0 + bonus_percent(state, content) / 100.0
