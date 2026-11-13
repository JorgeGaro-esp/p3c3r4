class_name Simulation
extends RefCounted
## Un paso de la simulación. Lo llama `Game` con un paso fijo.
##
## Recibe el contenido y el generador aleatorio desde fuera (principio 3), de
## modo que con la misma semilla y los mismos pasos el resultado sea idéntico.
## Por ahora solo hay un sistema (la producción pasiva); cuidados, crecimiento,
## cría, eventos y logros se añadirán aquí, por orden, en sus fases.


## Avanza [param state] [param dt] segundos y devuelve las conchas ganadas.
## [param _rng] queda reservado para los sistemas que lo necesitarán.
static func step(
	state: GameState, dt: float, content: ContentDB, _rng: RandomNumberGenerator
) -> float:
	state.sim_time += dt
	if state.production_dirty:
		state.production_rate = total_production(state, content)
		state.production_dirty = false
	var earned: float = state.production_rate * dt
	state.wallet.add(earned)
	return earned


## Conchas por segundo de todas las peceras con el estado actual.
static func total_production(state: GameState, content: ContentDB) -> float:
	var total: float = 0.0
	for tank: Tank in state.tanks:
		for fish: Fish in tank.fish:
			var species: SpeciesDef = content.get_species(fish.species_id)
			if species != null:
				total += Economy.fish_rate(species.base_production, fish.happiness)
	return total
