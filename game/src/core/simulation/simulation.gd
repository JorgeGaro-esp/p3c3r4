class_name Simulation
extends RefCounted
## Un paso de la simulación. Lo llama `Game` con un paso fijo.
##
## Recibe el contenido y el generador aleatorio desde fuera (principio 3), de
## modo que con la misma semilla y los mismos pasos el resultado sea idéntico.
## Sistemas, por orden: cuidados (hambre, limpieza, felicidad y perlas) y producción
## pasiva, más el ciclo de vida (crecimiento, puesta y eclosión, ver [Lifecycle]).
## Eventos y logros se añadirán aquí en sus fases.

## Cambio mínimo de felicidad que se tiene en cuenta (evita recalcular a cada paso).
const HAPPINESS_EPSILON: float = 0.5


## Avanza [param state] [param dt] segundos y devuelve las conchas ganadas.
## [param rng] decide cuándo y quién suelta una perla.
static func step(
	state: GameState, dt: float, content: ContentDB, rng: RandomNumberGenerator
) -> float:
	state.sim_time += dt
	_care(state, dt, content, rng)
	refresh_production(state, content)
	var earned: float = state.production_rate * dt
	state.wallet.add(earned)
	return earned


## Recalcula la producción por segundo si algo la ha cambiado.
static func refresh_production(state: GameState, content: ContentDB) -> void:
	if state.production_dirty:
		state.production_rate = total_production(state, content)
		state.production_dirty = false


## Conchas por segundo de todas las peceras con el estado actual.
static func total_production(state: GameState, content: ContentDB) -> float:
	var total: float = 0.0
	for tank: Tank in state.tanks:
		for fish: Fish in tank.fish:
			if not fish.is_adult():
				continue
			var species: SpeciesDef = content.get_species(fish.species_id)
			if species != null:
				total += Economy.fish_rate(
					species.base_production, fish.happiness, tank.bonuses.production_multiplier
				)
	return total * Achievements.multiplier(state, content)


## Hambre, limpieza, felicidad y perlas de todas las peceras.
static func _care(
	state: GameState, dt: float, content: ContentDB, rng: RandomNumberGenerator
) -> void:
	for tank_index: int in range(state.tanks.size()):
		var tank: Tank = state.tanks[tank_index]
		if tank.fish.is_empty():
			continue
		var bonuses: TankBonuses = tank.bonuses
		tank.cleanliness = Care.cleanliness_after(
			tank.cleanliness, tank.fish.size(), dt, bonuses.dirt_factor, bonuses.clean_regen
		)
		_feeder_tick(tank, dt)
		for fish: Fish in tank.fish:
			fish.hunger = Care.hunger_after(fish.hunger, dt)
			var mood: float = Care.happiness(fish.hunger, tank.cleanliness, bonuses.comfort)
			if absf(mood - fish.happiness) >= HAPPINESS_EPSILON:
				fish.happiness = mood
				state.mark_production_dirty()
		_pearl_tick(state, tank_index, dt, content, rng)
		Lifecycle.step(state, tank_index, dt, content, rng)


## El comedero da de comer a todos los peces cada cierto tiempo.
static func _feeder_tick(tank: Tank, dt: float) -> void:
	if tank.bonuses.feed_interval <= 0.0:
		return
	tank.feeder_timer += dt
	if tank.feeder_timer < tank.bonuses.feed_interval:
		return
	tank.feeder_timer = 0.0
	for fish: Fish in tank.fish:
		fish.feed(tank.bonuses.feed_amount)


static func _pearl_tick(
	state: GameState, tank_index: int, dt: float, content: ContentDB, rng: RandomNumberGenerator
) -> void:
	var tank: Tank = state.tanks[tank_index]
	tank.pearl_timer -= dt
	if tank.pearl_timer > 0.0:
		return
	tank.pearl_timer = rng.randf_range(Care.PEARL_MIN_SECONDS, Care.PEARL_MAX_SECONDS)
	var adults: Array[Fish] = []
	for candidate: Fish in tank.fish:
		if candidate.is_adult():
			adults.append(candidate)
	if adults.is_empty():
		return
	var fish: Fish = adults[rng.randi_range(0, adults.size() - 1)]
	var species: SpeciesDef = content.get_species(fish.species_id)
	if species == null or state.pending_pearls.size() >= GameState.MAX_PENDING_PEARLS:
		return
	var rate: float = Economy.fish_rate(species.base_production, fish.happiness)
	state.pending_pearls.append(PearlSpawn.new(tank_index, fish, Care.pearl_value(rate)))
