class_name AchievementText
extends RefCounted
## Textos de los logros y de las estadísticas para la tienda. Solo formatea: las
## cifras salen del núcleo ([Achievements], [GameStats]).

const SECONDS_PER_HOUR: float = 3600.0
const STAT_ROWS: PackedStringArray = [
	"fish_bought",
	"fish_sold",
	"eggs_hatched",
	"pearls_collected",
	"spots_cleaned",
	"fish_fed",
	"decorations_bought",
	"equipment_bought",
]


## Frase de lo que pide [param def], compuesta con la plantilla de su métrica.
static func description(def: AchievementDef, content: ContentDB, locale: String) -> String:
	var target: String = _amount(def, def.target, locale)
	var metric: String = AchievementDef.Metric.keys()[def.metric]
	match def.metric:
		AchievementDef.Metric.STAT:
			return _tr("ACH_DESC_STAT_%s" % def.stat_id.to_upper()) % target
		AchievementDef.Metric.SPECIES_FOUND:
			if def.biome_id.is_empty():
				return _tr("ACH_DESC_SPECIES_FOUND") % target
			var biome: BiomeDef = content.biomes.get_biome(def.biome_id)
			return _tr("ACH_DESC_SPECIES_FOUND_BIOME") % [target, _tr(biome.name_key)]
		_:
			return _tr("ACH_DESC_%s" % metric) % target


## Lo que lleva el jugador, con las mismas unidades que la meta.
static func progress_text(
	def: AchievementDef, state: GameState, content: ContentDB, locale: String
) -> String:
	var value: float = minf(Achievements.value_of(def, state, content), def.target)
	return _tr("ACH_PROGRESS") % [_amount(def, value, locale), _amount(def, def.target, locale)]


## Línea de la recompensa («Recompensa: +1,5 % producción»).
static func reward_text(def: AchievementDef, locale: String) -> String:
	return _tr("ACH_REWARD") % NumberFormat.percent(def.reward_percent, locale)


## Resumen del jugador («Logros: 3/60 · +2 %»).
static func summary(state: GameState, content: ContentDB, locale: String) -> String:
	var bonus: float = Achievements.bonus_percent(state, content)
	return (
		_tr("ACH_SUMMARY")
		% [
			state.achievements.size(),
			content.achievements.ids().size(),
			NumberFormat.percent(bonus, locale)
		]
	)


## Filas de la pestaña de estadísticas: etiqueta y valor ya formateados.
static func stat_rows(
	state: GameState, content: ContentDB, locale: String
) -> Array[PackedStringArray]:
	var rows: Array[PackedStringArray] = []
	for stat_id: String in STAT_ROWS:
		rows.append(
			_row("STAT_%s" % stat_id.to_upper(), _compact(state.stats.value(stat_id), locale))
		)
	rows.append(_row("STAT_TOTAL_EARNED", _compact(state.wallet.total_earned, locale)))
	var hours: String = _compact(state.sim_time / SECONDS_PER_HOUR, locale)
	rows.append(_row("STAT_PLAY_TIME", _tr("STAT_HOURS") % hours))
	rows.append(_row("STAT_FISH_NOW", str(state.fish_total())))
	rows.append(_row("STAT_PRODUCTION", NumberFormat.per_second(state.production_rate, locale)))
	var species: Vector2i = Encyclopedia.species_progress(state, content)
	rows.append(_row("STAT_SPECIES", "%d/%d" % [species.x, species.y]))
	var variants: Vector2i = Encyclopedia.variant_progress(state, content)
	rows.append(_row("STAT_VARIANTS", "%d/%d" % [variants.x, variants.y]))
	var biomes_total: int = content.biomes.ids().size()
	rows.append(_row("STAT_BIOMES", "%d/%d" % [state.tanks.size(), biomes_total]))
	var achievements_total: int = content.achievements.ids().size()
	rows.append(
		_row("STAT_ACHIEVEMENTS", "%d/%d" % [state.achievements.size(), achievements_total])
	)
	var bonus: float = Achievements.bonus_percent(state, content)
	rows.append(_row("STAT_BONUS", NumberFormat.percent(bonus, locale)))
	return rows


static func _row(label_key: String, value: String) -> PackedStringArray:
	return PackedStringArray([_tr(label_key), value])


## Cifra de [param value] con las unidades de la métrica de [param def].
static func _amount(def: AchievementDef, value: float, locale: String) -> String:
	if def.metric == AchievementDef.Metric.PLAY_TIME:
		return _compact(value / SECONDS_PER_HOUR, locale)
	return _compact(value, locale)


static func _compact(value: float, locale: String) -> String:
	return NumberFormat.compact(value, locale)


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
