class_name BiomeDirector
extends RefCounted
## Las peceras como conjunto: cuál se ve, qué biomas se pueden abrir y cuánto
## cuestan. Cuelga de `Game.biomes`; el estado y el monedero siguen siendo de
## [GameService].

enum Result { OK, UNKNOWN, ALREADY_OPEN, REQUIRES, NOT_ENOUGH_SHELLS, TOO_MANY }

var _game: GameService = null


func _init(game: GameService) -> void:
	_game = game


## Cambia de pecera. Devuelve falso si el índice no existe.
func set_active(tank_index: int) -> bool:
	var state: GameState = _game.state
	if tank_index < 0 or tank_index >= state.tanks.size():
		return false
	if tank_index == state.active_tank:
		return true
	state.active_tank = tank_index
	EventBus.active_tank_changed.emit(tank_index)
	return true


## Conchas que cuesta abrir la pecera de [param biome_id] (INF si no existe).
func cost(biome_id: String) -> float:
	var biome: BiomeDef = _game.content.biomes.get_biome(biome_id)
	if biome == null:
		return INF
	return biome.unlock_cost


## Abre la pecera del bioma [param biome_id] y pasa a verla.
func unlock(biome_id: String) -> Result:
	var state: GameState = _game.state
	var biome: BiomeDef = _game.content.biomes.get_biome(biome_id)
	if biome == null:
		return Result.UNKNOWN
	if state.tank_index_of(biome_id) >= 0:
		return Result.ALREADY_OPEN
	if not biome.requires_biome_id.is_empty() and state.tank_index_of(biome.requires_biome_id) < 0:
		return Result.REQUIRES
	if state.tanks.size() >= GameState.MAX_TANKS:
		return Result.TOO_MANY
	if not state.wallet.spend(biome.unlock_cost):
		return Result.NOT_ENOUGH_SHELLS
	var tank: Tank = Tank.new()
	tank.biome_id = biome_id
	tank.refresh_bonuses(_game.content)
	state.tanks.append(tank)
	state.mark_production_dirty()
	EventBus.tank_unlocked.emit(state.tanks.size() - 1)
	EventBus.purchase_made.emit()
	set_active(state.tanks.size() - 1)
	return Result.OK
