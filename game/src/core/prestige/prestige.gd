class_name Prestige
extends RefCounted
## Reglas de la Gran marea (GDD §13, decisiones de la Fase 13): cuántas perlas
## negras da reiniciar, qué se conserva, qué cuestan y qué dan las mejoras, y cuándo
## se completa la Enciclopedia. Funciones puras: [GameService] las aplica.

## Conchas del ciclo que valen una perla negra al cuadrado: perlas = ⌊√(conchas / este)⌋.
const SHELLS_PER_PEARL_SQUARED: float = 1.0e5
## Perlas negras mínimas para poder hacer la Gran marea.
const MIN_PEARLS_TO_RESET: int = 1
## Cada nivel de [constant PrestigeUpgradeDef.Kind.HEAD_START] multiplica por esto.
const HEAD_START_GROWTH: float = 3.0
## Porcentaje de la colección (especies × variantes) que cuenta como completa.
const FINAL_PERCENT: float = 100.0


## Conchas ganadas desde que empezó el ciclo actual.
static func run_earned(state: GameState) -> float:
	return maxf(state.wallet.total_earned - state.prestige.run_start_earned, 0.0)


## Perlas negras que daría reiniciar ahora.
static func pearls_for(run_shells: float) -> int:
	if is_nan(run_shells) or run_shells <= 0.0:
		return 0
	return int(floorf(sqrt(run_shells / SHELLS_PER_PEARL_SQUARED)))


## Perlas negras que daría reiniciar ahora la partida [param state].
static func pending_pearls(state: GameState) -> int:
	return pearls_for(run_earned(state))


static func can_reset(state: GameState) -> bool:
	return pending_pearls(state) >= MIN_PEARLS_TO_RESET


## Coste del siguiente nivel de [param def] (-1 si ya está al máximo).
static func upgrade_cost(def: PrestigeUpgradeDef, current_level: int) -> int:
	if current_level >= def.max_level:
		return -1
	return maxi(
		ceili(float(def.base_cost) * pow(def.cost_growth, float(current_level)) - 1.0e-9), 1
	)


## Si se puede comprar un nivel más de [param def] con las perlas actuales.
static func can_buy(state: GameState, def: PrestigeUpgradeDef) -> bool:
	var cost: int = upgrade_cost(def, state.prestige.level_of(def.id))
	return cost > 0 and state.prestige.pearls >= cost


## Gasta perlas y sube un nivel [param def]. Devuelve falso, sin cambios, si no se puede.
static func buy(state: GameState, def: PrestigeUpgradeDef) -> bool:
	if not can_buy(state, def):
		return false
	var current: int = state.prestige.level_of(def.id)
	state.prestige.pearls -= upgrade_cost(def, current)
	state.prestige.levels[def.id] = current + 1
	state.mark_production_dirty()
	return true


## Efecto total de las mejoras de tipo [param kind] con sus niveles actuales.
static func effect(state: GameState, content: ContentDB, kind: PrestigeUpgradeDef.Kind) -> float:
	var total: float = 0.0
	for upgrade_id: String in content.prestige.ids():
		var def: PrestigeUpgradeDef = content.prestige.get_upgrade(upgrade_id)
		if def.kind != kind:
			continue
		var level: int = state.prestige.level_of(upgrade_id)
		if level <= 0:
			continue
		if kind == PrestigeUpgradeDef.Kind.HEAD_START:
			total += def.per_level * pow(HEAD_START_GROWTH, float(level - 1))
		else:
			total += def.per_level * float(level)
	return total


## Factor de producción de las mejoras (1 sin ninguna).
static func production_multiplier(state: GameState, content: ContentDB) -> float:
	return 1.0 + effect(state, content, PrestigeUpgradeDef.Kind.PRODUCTION)


## Factor del peso de las variantes raras (1 sin mejoras).
static func variant_multiplier(state: GameState, content: ContentDB) -> float:
	return 1.0 + effect(state, content, PrestigeUpgradeDef.Kind.VARIANT_LUCK)


## Factor del valor de las perlas recogibles (1 sin mejoras).
static func pearl_multiplier(state: GameState, content: ContentDB) -> float:
	return 1.0 + effect(state, content, PrestigeUpgradeDef.Kind.PEARL_VALUE)


## Conchas extra con las que empieza un ciclo por la mejora de arranque.
static func head_start_shells(state: GameState, content: ContentDB) -> float:
	return floorf(effect(state, content, PrestigeUpgradeDef.Kind.HEAD_START))


## Si la colección (todas las especies con todas sus variantes) está completa.
static func is_collection_complete(state: GameState, content: ContentDB) -> bool:
	var progress: Vector2i = Encyclopedia.variant_progress(state, content)
	if progress.y <= 0:
		return false
	return 100.0 * float(progress.x) / float(progress.y) >= FINAL_PERCENT


## Qué conserva y qué reinicia la Gran marea (P05). Devuelve la partida del nuevo
## ciclo, construida a partir de [param old], que ya no debe usarse:
## - Se conservan: Enciclopedia, logros, estadísticas, especies desbloqueadas,
##   peceras (biomas) abiertas, decoración (colocada y guardada), mejoras y perlas.
## - Se reinician: conchas, peces, huevos y equipamiento (y la limpieza del agua).
## [param start_shells] son las conchas iniciales, [param start_fish] los peces con
## los que empieza la primera pecera y [param gained] las perlas negras que se suman.
static func next_run(
	old: GameState,
	content: ContentDB,
	start_shells: float,
	start_fish: PackedStringArray,
	gained: int
) -> GameState:
	var fresh: GameState = GameState.new()
	fresh.tanks = old.tanks
	fresh.active_tank = old.active_tank
	fresh.sim_time = old.sim_time
	fresh.rng_seed = old.rng_seed
	fresh.rng_state = old.rng_state
	fresh.unlocked = old.unlocked
	fresh.discovered = old.discovered
	fresh.decoration_stock = old.decoration_stock
	fresh.stats = old.stats
	fresh.achievements = old.achievements
	fresh.prestige = old.prestige
	fresh.prestige.add_pearls(gained)
	fresh.prestige.count += 1
	fresh.wallet.total_earned = old.wallet.total_earned
	fresh.prestige.run_start_earned = old.wallet.total_earned
	fresh.wallet.shells = start_shells + head_start_shells(fresh, content)
	for tank: Tank in fresh.tanks:
		tank.fish.clear()
		tank.eggs.clear()
		tank.breed_timers.clear()
		tank.equipment.clear()
		tank.cleanliness = Care.MAX_CLEANLINESS
		tank.pearl_timer = Care.PEARL_MAX_SECONDS
		tank.feeder_timer = 0.0
		tank.refresh_bonuses(content)
	for species_id: String in start_fish:
		if content.has_species(species_id):
			fresh.tanks[0].add_fish(Fish.new(species_id))
	return fresh
