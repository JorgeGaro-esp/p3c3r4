class_name PrestigeDirector
extends RefCounted
## La Gran marea como parte de la partida: reinicia el ciclo, compra mejoras con
## perlas negras y detecta el final. Cuelga de `Game.prestige`; las reglas puras
## están en [Prestige].

## Objeto de decoración que regala completar la Enciclopedia.
const FINAL_REWARD_DECORATION: String = "tide_trophy"

var _game: GameService = null


func _init(game: GameService) -> void:
	_game = game


## Perlas negras que daría ahora hacer la Gran marea.
func pending_pearls() -> int:
	return Prestige.pending_pearls(_game.state)


func can_reset() -> bool:
	return Prestige.can_reset(_game.state)


## Hace la Gran marea: reinicia el ciclo (ver [method Prestige.next_run]) y da las
## perlas negras ganadas. Devuelve cuántas, o -1 si aún no se puede.
func reset() -> int:
	var state: GameState = _game.state
	if not Prestige.can_reset(state):
		return -1
	var gained: int = Prestige.pending_pearls(state)
	for tank_index: int in range(state.tanks.size()):
		for fish: Fish in state.tanks[tank_index].fish.duplicate():
			EventBus.fish_removed.emit(tank_index, fish)
	state.rng_state = _game.rng.state
	var fresh: GameState = Prestige.next_run(
		state, _game.content, GameService.START_SHELLS, GameService.START_FISH, gained
	)
	_game.adopt_state(fresh)
	EventBus.prestiged.emit(gained)
	EventBus.purchase_made.emit()
	return gained


## Compra un nivel de la mejora [param upgrade_id] con perlas negras.
func buy_upgrade(upgrade_id: String) -> bool:
	var def: PrestigeUpgradeDef = _game.content.prestige.get_upgrade(upgrade_id)
	if def == null or not Prestige.buy(_game.state, def):
		return false
	EventBus.prestige_upgrade_bought.emit(upgrade_id, _game.state.prestige.level_of(upgrade_id))
	EventBus.purchase_made.emit()
	return true


## Si la Enciclopedia se acaba de completar: da el premio y avisa (una sola vez).
## Después el juego sigue en modo infinito.
func check_final() -> void:
	var state: GameState = _game.state
	if state.prestige.final_reached or not Prestige.is_collection_complete(state, _game.content):
		return
	state.prestige.final_reached = true
	if _game.content.has_decoration(FINAL_REWARD_DECORATION):
		var owned: int = state.decoration_stock.get(FINAL_REWARD_DECORATION, 0)
		state.decoration_stock[FINAL_REWARD_DECORATION] = mini(owned + 1, GameState.MAX_STOCK)
		EventBus.decoration_changed.emit(state.active_tank)
	EventBus.final_reached.emit()
	EventBus.purchase_made.emit()


## Herramienta de desarrollo (F8): da por descubiertas todas las especies y variantes.
func debug_complete_collection() -> void:
	for species_id: String in _game.content.species_ids():
		for variant_id: String in _game.content.variant_ids():
			_game.state.discover(species_id, variant_id)


## Herramienta de desarrollo (F9): gana [param amount] conchas, que cuentan para el ciclo.
func debug_earn(amount: float) -> void:
	_game.state.wallet.add(amount)
