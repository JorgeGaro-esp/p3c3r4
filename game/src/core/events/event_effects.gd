class_name EventEffects
extends RefCounted
## Lo que hace cada evento sobre el estado (GDD §12). Funciones puras sobre
## [GameState]: avisar al jugador y pagar las conchas lo hace [EventDirector].
##
## Ningún efecto quita nada de forma permanente: lo peor que pasa es una plaga de
## algas, que se arregla limpiando.

## Limpieza a la que baja una plaga de algas.
const BLOOM_CLEANLINESS: float = 35.0
## Con esta limpieza (o más) la plaga se da por terminada.
const BLOOM_DONE_CLEANLINESS: float = 90.0
## Manchas que hay que limpiar con el ratón para cobrar la recompensa de la plaga.
const BLOOM_CLEANS_FOR_REWARD: int = 3
## Se parte de la rareza "rara" para elegir al visitante.
const VISITOR_MIN_RARITY: SpeciesDef.Rarity = SpeciesDef.Rarity.RARE


## Especies del bioma [param biome_id] que pueden pasar de visita: las raras o
## mejores (o todas, si el bioma no tiene ninguna).
static func visitor_candidates(biome_id: String, content: ContentDB) -> PackedStringArray:
	var rare: PackedStringArray = PackedStringArray()
	var all: PackedStringArray = PackedStringArray()
	for species_id: String in content.species_ids():
		var species: SpeciesDef = content.get_species(species_id)
		if species.biome_id != biome_id:
			continue
		all.append(species_id)
		if species.rarity >= VISITOR_MIN_RARITY:
			rare.append(species_id)
	return rare if not rare.is_empty() else all


## Pone en marcha [param def] en la pecera activa. Devuelve falso si no se pudo.
static func start(
	def: EventDef, state: GameState, content: ContentDB, rng: RandomNumberGenerator
) -> bool:
	var events: EventState = state.events
	var tank: Tank = state.active()
	if def.is_pickup():
		if events.has_pickup():
			return false
		events.pickup = def
		events.pickup_seconds = def.duration
		events.pickup_tank = state.active_tank
		if def.kind == EventDef.Kind.VISITOR:
			var options: PackedStringArray = visitor_candidates(tank.biome_id, content)
			if options.is_empty():
				events.clear_pickup()
				return false
			events.pickup_species_id = options[rng.randi_range(0, options.size() - 1)]
		return true
	match def.kind:
		EventDef.Kind.FOOD_RAIN:
			for fish: Fish in tank.fish:
				fish.hunger = Care.MAX_HUNGER
		EventDef.Kind.WARM_CURRENT:
			events.warm_def = def
			events.warm_seconds = def.duration
			state.mark_production_dirty()
		EventDef.Kind.ALGAE_BLOOM:
			if events.has_bloom():
				return false
			events.bloom_def = def
			events.bloom_tank = state.active_tank
			events.bloom_cleans = 0
			tank.cleanliness = minf(tank.cleanliness, BLOOM_CLEANLINESS)
	return true


## Conchas que vale [param def] con la producción de ahora.
static func shells_for(def: EventDef, state: GameState) -> float:
	return maxf(def.reward_min, state.production_rate * def.reward_seconds)


## Cobra el clicable que espera. Devuelve null si no había ninguno. La botella da
## una decoración al azar (si el inventario de ese tipo está lleno, conchas).
static func claim(state: GameState, content: ContentDB, rng: RandomNumberGenerator) -> EventReward:
	var def: EventDef = state.events.pickup
	if def == null:
		return null
	state.events.clear_pickup()
	if def.kind != EventDef.Kind.BOTTLE:
		return EventReward.new(shells_for(def, state))
	var ids: PackedStringArray = DecorationShelf.sellable_ids(content)
	if ids.is_empty():
		return EventReward.new(shells_for(def, state))
	var decoration_id: String = ids[rng.randi_range(0, ids.size() - 1)]
	var owned: int = state.decoration_stock.get(decoration_id, 0)
	if owned >= GameState.MAX_STOCK:
		return EventReward.new(shells_for(def, state))
	state.decoration_stock[decoration_id] = owned + 1
	return EventReward.new(0.0, decoration_id)


## Anota una mancha limpiada durante la plaga y comprueba si ya acabó. Devuelve
## la recompensa si el jugador la limpió con sus manos, o null.
static func bloom_progress(state: GameState, cleaned_one: bool) -> EventReward:
	var events: EventState = state.events
	if not events.has_bloom():
		return null
	if cleaned_one:
		events.bloom_cleans += 1
	var tank: Tank = state.tanks[events.bloom_tank]
	if tank.cleanliness < BLOOM_DONE_CLEANLINESS:
		return null
	var def: EventDef = events.bloom_def
	var earned: bool = events.bloom_cleans >= BLOOM_CLEANS_FOR_REWARD
	events.clear_bloom()
	if earned and def != null:
		return EventReward.new(shells_for(def, state))
	return EventReward.new(0.0)
