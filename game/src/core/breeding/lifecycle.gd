class_name Lifecycle
extends RefCounted
## Crecimiento, puesta y eclosión (GDD §4.3 y §6). Lo llama [Simulation] en cada
## paso para cada pecera.
##
## Reglas: solo los adultos crían; dos adultos de la misma especie con felicidad
## media suficiente ponen un huevo cada cierto tiempo, y solo si hay un hueco libre
## (el huevo ya ocupa capacidad). No hay herencia: la cría es de la misma especie y
## la variante se sortea al poner el huevo.

## Felicidad media mínima de los adultos de una especie para que críen.
const MIN_HAPPINESS: float = 60.0
## Cuántas parejas aceleran la puesta de una misma especie como máximo.
const MAX_PAIRS: int = 4
## Para que ni un error de datos ni una partida manipulada eclosionen sin fin.
const MIN_GROWTH_SECONDS: float = 0.001


static func step(
	state: GameState, tank_index: int, dt: float, content: ContentDB, rng: RandomNumberGenerator
) -> void:
	var tank: Tank = state.tanks[tank_index]
	_grow(state, tank, dt * tank.bonuses.growth_speed, content)
	_hatch(state, tank_index, dt * tank.bonuses.hatch_speed, content)
	_breed(tank, dt, content, rng, Prestige.variant_multiplier(state, content))


## Verdadero si [param species_id] puede poner un huevo ahora mismo en [param tank]:
## al menos dos adultos, felicidad media suficiente y un hueco libre.
static func can_breed(tank: Tank, species_id: String) -> bool:
	if tank.is_full():
		return false
	var adults: int = 0
	var happiness: float = 0.0
	for fish: Fish in tank.fish:
		if fish.species_id == species_id and fish.is_adult():
			adults += 1
			happiness += fish.happiness
	return adults >= 2 and happiness / float(adults) >= MIN_HAPPINESS


static func _grow(state: GameState, tank: Tank, dt: float, content: ContentDB) -> void:
	for fish: Fish in tank.fish:
		if fish.is_adult():
			continue
		var species: SpeciesDef = content.get_species(fish.species_id)
		var seconds: float = MIN_GROWTH_SECONDS
		if species != null:
			seconds = maxf(species.growth_seconds, MIN_GROWTH_SECONDS)
		fish.maturity = minf(fish.maturity + dt / seconds, LifeStage.ADULT_FROM)
		if fish.is_adult():
			state.mark_production_dirty()


static func _hatch(state: GameState, tank_index: int, dt: float, content: ContentDB) -> void:
	var tank: Tank = state.tanks[tank_index]
	if tank.eggs.is_empty():
		return
	var waiting: Array[Egg] = []
	for egg: Egg in tank.eggs:
		egg.remaining -= dt
		if egg.remaining > 0.0:
			waiting.append(egg)
			continue
		if not content.has_species(egg.species_id):
			continue
		var baby: Fish = Fish.new(egg.species_id)
		baby.maturity = 0.0
		baby.variant_id = egg.variant_id
		baby.coat = egg.coat
		tank.fish.append(baby)
		state.pending_hatched.append(HatchEvent.new(tank_index, baby))
	tank.eggs = waiting


static func _breed(
	tank: Tank, dt: float, content: ContentDB, rng: RandomNumberGenerator, luck: float
) -> void:
	var adults: Dictionary[String, int] = {}
	var happiness: Dictionary[String, float] = {}
	for fish: Fish in tank.fish:
		if not fish.is_adult():
			continue
		adults[fish.species_id] = adults.get(fish.species_id, 0) + 1
		happiness[fish.species_id] = happiness.get(fish.species_id, 0.0) + fish.happiness
	for species_id: String in adults:
		var count: int = adults[species_id]
		var species: SpeciesDef = content.get_species(species_id)
		if species == null or count < 2:
			continue
		if float(happiness[species_id]) / float(count) < MIN_HAPPINESS:
			continue
		var interval: float = maxf(species.breed_seconds, MIN_GROWTH_SECONDS)
		var pairs: int = mini(count / 2, MAX_PAIRS)
		var previous: float = tank.breed_timers.get(species_id, 0.0)
		var timer: float = minf(previous + dt * float(pairs), interval)
		if timer >= interval and not tank.is_full():
			_lay_egg(tank, species, content, rng, luck)
			timer = 0.0
		tank.breed_timers[species_id] = timer


static func _lay_egg(
	tank: Tank, species: SpeciesDef, content: ContentDB, rng: RandomNumberGenerator, luck: float
) -> void:
	var variant_id: String = VariantRoll.pick(content, rng, tank.bonuses.rare_multiplier * luck)
	var egg: Egg = Egg.new(species.id, variant_id, species.hatch_seconds, rng.randf())
	egg.coat = species.random_coat(rng)
	tank.eggs.append(egg)
