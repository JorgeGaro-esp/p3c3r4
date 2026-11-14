class_name PrestigeText
extends RefCounted
## Textos de la Gran marea para la tienda. Solo formatea: las cifras salen del
## núcleo ([Prestige], [PrestigeState]).

const PEARL_SYMBOL: String = "●"


## Efecto de [param def] con [param level] niveles («Producción +30 %»).
static func effect(def: PrestigeUpgradeDef, level: int, locale: String) -> String:
	if level <= 0:
		return _tr("PRESTIGE_EFFECT_NONE")
	match def.kind:
		PrestigeUpgradeDef.Kind.PRODUCTION:
			var gain: float = def.per_level * float(level) * 100.0
			return _tr("PRESTIGE_EFFECT_PRODUCTION") % NumberFormat.percent(gain, locale)
		PrestigeUpgradeDef.Kind.HEAD_START:
			var shells: float = def.per_level * pow(Prestige.HEAD_START_GROWTH, float(level - 1))
			return _tr("PRESTIGE_EFFECT_HEAD_START") % NumberFormat.compact(shells, locale)
		PrestigeUpgradeDef.Kind.VARIANT_LUCK:
			var luck: float = def.per_level * float(level) * 100.0
			return _tr("PRESTIGE_EFFECT_VARIANT") % NumberFormat.percent(luck, locale)
		_:
			var value: float = def.per_level * float(level) * 100.0
			return _tr("PRESTIGE_EFFECT_PEARL") % NumberFormat.percent(value, locale)


## «Nivel 2/25 · efecto» o «Nivel máximo · efecto».
static func level_line(def: PrestigeUpgradeDef, level: int, locale: String) -> String:
	var shown: String = effect(def, level, locale)
	if level >= def.max_level:
		return "%s · %s" % [_tr("PRESTIGE_MAXED"), shown]
	return _tr("PRESTIGE_LEVEL") % [level, def.max_level, shown]


## Coste del siguiente nivel con el saldo («Coste: 3 perlas negras (tienes 5)»).
static func cost_line(def: PrestigeUpgradeDef, state: GameState) -> String:
	var cost: int = Prestige.upgrade_cost(def, state.prestige.level_of(def.id))
	if cost < 0:
		return _tr("PRESTIGE_MAXED")
	return "%s ·  %s %d" % [_tr("PRESTIGE_COST") % cost, PEARL_SYMBOL, state.prestige.pearls]


## Perlas negras y ciclos («Perlas negras: 12 · Ciclos: 3»).
static func held_line(state: GameState) -> String:
	return _tr("PRESTIGE_HELD") % [str(state.prestige.pearls), state.prestige.count]


## Lo que daría reiniciar ahora.
static func gain_line(state: GameState) -> String:
	var pending: int = Prestige.pending_pearls(state)
	if pending < Prestige.MIN_PEARLS_TO_RESET:
		return _tr("PRESTIGE_GAIN_NONE")
	return _tr("PRESTIGE_GAIN_NOW") % pending


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)
