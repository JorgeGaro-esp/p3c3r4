class_name GameState
extends RefCounted
## Estado completo de la partida: la raíz del modelo (02-ARQUITECTURA §3.1).
##

const MAX_TANKS: int = 16
const MAX_SIM_TIME: float = 1.0e12
## Perlas sin publicar que se aceptan como máximo (por si nadie las recoge).
const MAX_PENDING_PEARLS: int = 20
## Cantidad máxima de un mismo objeto de decoración en el inventario.
const MAX_STOCK: int = 99
## Cambio de oscuridad que merece recalcular la producción.
const DARKNESS_EPSILON: float = 0.01

var wallet: Wallet = Wallet.new()
var tanks: Array[Tank] = [Tank.new()]
## Pecera que se ve y sobre la que actúa el jugador (índice en [member tanks]).
var active_tank: int = 0
var sim_time: float = 0.0
var rng_seed: int = 0
## Estado interno del generador aleatorio, para continuar la secuencia al cargar.
var rng_state: int = 0
## Producción total en conchas por segundo; se recalcula solo si cambia algo.
var production_rate: float = 0.0
## Verdadero cuando hay que recalcular [member production_rate].
var production_dirty: bool = true
## Perlas que la simulación ha soltado y `Game` aún no ha publicado.
var pending_pearls: Array[PearlSpawn] = []
## Especies que ya se pueden comprar. Una vez desbloqueada, no se vuelve a bloquear.
var unlocked: Dictionary[String, bool] = {}
## Combinaciones de especie y variante que el jugador ya ha tenido (clave
## `especie|variante`). Es la base de la Enciclopedia.
var discovered: Dictionary[String, bool] = {}
## Decoración comprada y sin colocar (id → cantidad). Se guarda.
var decoration_stock: Dictionary[String, int] = {}
## Contadores de lo hecho en la partida (base de los logros). Se guardan.
var stats: GameStats = GameStats.new()
## Logros conseguidos (id → verdadero). Se guardan.
var achievements: Dictionary[String, bool] = {}
## Huevos que han eclosionado y `Game` aún no ha publicado.
var pending_hatched: Array[HatchEvent] = []
## Perlas negras, mejoras permanentes y final de la Gran marea. Se guardan.
var prestige: PrestigeState = PrestigeState.new()
## Eventos en curso (no se guardan).
var events: EventState = EventState.new()
## Oscuridad del día de 0 a 1 (no se guarda; la pone el reloj, ver [DaylightDirector]).
var darkness: float = 0.0


## La pecera activa.
func active() -> Tank:
	return tanks[clampi(active_tank, 0, tanks.size() - 1)]


## Índice de la pecera del bioma [param biome_id], o -1 si aún no se ha abierto.
func tank_index_of(biome_id: String) -> int:
	for index: int in range(tanks.size()):
		if tanks[index].biome_id == biome_id:
			return index
	return -1


## Cuántos objetos con la etiqueta [param tag] hay colocados en todas las peceras.
func count_tag(tag: String) -> int:
	var total: int = 0
	if tag.is_empty():
		return total
	for tank: Tank in tanks:
		for placed: PlacedDecoration in tank.decorations:
			if placed.def.tag == tag:
				total += 1
	return total


## Cuántos objetos de [param decoration_id] se han comprado (colocados y guardados).
func decoration_owned(decoration_id: String) -> int:
	var total: int = decoration_stock.get(decoration_id, 0)
	for tank: Tank in tanks:
		for placed: PlacedDecoration in tank.decorations:
			if placed.def.id == decoration_id:
				total += 1
	return total


## Cuántos objetos de decoración hay colocados en todas las peceras.
func decorations_placed() -> int:
	var total: int = 0
	for tank: Tank in tanks:
		total += tank.decorations.size()
	return total


## Avisa de que compra, venta o cambio de felicidad alteran la producción.
func mark_production_dirty() -> void:
	production_dirty = true


## Cuántos peces de [param species_id] hay en todas las peceras.
func count_of(species_id: String) -> int:
	var total: int = 0
	for tank: Tank in tanks:
		total += tank.count_of(species_id)
	return total


func is_unlocked(species_id: String) -> bool:
	return unlocked.has(species_id)


## Clave de una combinación de especie y variante en [member discovered].
static func discovery_key(species_id: String, variant_id: String) -> String:
	return "%s|%s" % [species_id, variant_id]


func is_discovered(species_id: String, variant_id: String) -> bool:
	return discovered.has(discovery_key(species_id, variant_id))


## Anota la combinación. Devuelve verdadero si era nueva.
func discover(species_id: String, variant_id: String) -> bool:
	var key: String = discovery_key(species_id, variant_id)
	if discovered.has(key):
		return false
	discovered[key] = true
	return true


## Cambia la oscuridad del día. Si cambia lo bastante, recalcula la producción.
func set_darkness(value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	if absf(clamped - darkness) < DARKNESS_EPSILON:
		return
	darkness = clamped
	production_dirty = true


## Entrega y vacía la cola de eclosiones.
func take_hatched() -> Array[HatchEvent]:
	var taken: Array[HatchEvent] = pending_hatched
	pending_hatched = []
	return taken


## Entrega y vacía la cola de perlas nuevas.
func take_pearls() -> Array[PearlSpawn]:
	var taken: Array[PearlSpawn] = pending_pearls
	pending_pearls = []
	return taken


## Total de peces en todas las peceras.
func fish_total() -> int:
	var total: int = 0
	for tank: Tank in tanks:
		total += tank.fish.size()
	return total


func to_dict() -> Dictionary:
	var tank_data: Array = []
	for tank: Tank in tanks:
		tank_data.append(tank.to_dict())
	return {
		"wallet": wallet.to_dict(),
		"tanks": tank_data,
		"active_tank": active_tank,
		"sim_time": sim_time,
		# 64 bits no caben en un número JSON sin perder precisión: van como texto.
		"rng_seed": str(rng_seed),
		"rng_state": str(rng_state),
		"unlocked": unlocked.keys(),
		"discovered": discovered.keys(),
		"decoration_stock": decoration_stock.duplicate(),
		"stats": stats.to_dict(),
		"achievements": achievements.duplicate(),
		"prestige": prestige.to_dict(),
	}


## Reconstruye una partida. Devuelve null si falta lo imprescindible (monedero y
## al menos una pecera); lo demás se corrige o se descarta con aviso.
static func from_dict(
	source: Variant, content: ContentDB, warnings: PackedStringArray
) -> GameState:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("data: no es un objeto")
		return null
	var data: Dictionary = source
	var loaded_wallet: Wallet = Wallet.from_dict(data.get("wallet"), warnings)
	if loaded_wallet == null:
		return null
	var raw_tanks: Variant = SaveFields.read_array(data, "tanks", warnings)
	if raw_tanks == null:
		return null
	var state: GameState = GameState.new()
	state.wallet = loaded_wallet
	state.tanks.clear()
	var tank_list: Array = raw_tanks
	for entry: Variant in tank_list:
		if state.tanks.size() >= MAX_TANKS:
			warnings.append("pecera descartada: demasiadas")
			break
		var tank: Tank = Tank.from_dict(entry, content, warnings)
		if tank == null:
			continue
		if state.tank_index_of(tank.biome_id) >= 0:
			warnings.append("pecera descartada: bioma repetido '%s'" % tank.biome_id)
			continue
		state.tanks.append(tank)
	if state.tanks.is_empty():
		warnings.append("no hay ninguna pecera válida")
		return null
	state.active_tank = SaveFields.read_int(
		data, "active_tank", 0, 0, state.tanks.size() - 1, warnings
	)
	state.sim_time = SaveFields.read_float(data, "sim_time", 0.0, 0.0, MAX_SIM_TIME, warnings)
	state.rng_seed = SaveFields.read_big_int(data, "rng_seed", 0, warnings)
	state.rng_state = SaveFields.read_big_int(data, "rng_state", 0, warnings)
	_read_unlocked(state, data, content, warnings)
	_read_discovered(state, data, content, warnings)
	_read_stock(state, data, content, warnings)
	state.stats = GameStats.from_dict(data.get("stats"), warnings)
	_read_achievements(state, data, content, warnings)
	state.prestige = PrestigeState.from_dict(data.get("prestige"), content, warnings)
	state.prestige.run_start_earned = minf(
		state.prestige.run_start_earned, state.wallet.total_earned
	)
	return state


## Lee la lista de especies desbloqueadas; ignora las que no existen. Si falta,
## `Game` la recalcula al adoptar la partida.
static func _read_unlocked(
	state: GameState, data: Dictionary, content: ContentDB, warnings: PackedStringArray
) -> void:
	if not data.has("unlocked"):
		return
	var raw: Variant = SaveFields.read_array(data, "unlocked", warnings)
	if raw == null:
		return
	var items: Array = raw
	for item: Variant in items:
		if typeof(item) != TYPE_STRING:
			continue
		var species_id: String = item
		if content.has_species(species_id):
			state.unlocked[species_id] = true


## Lee las combinaciones descubiertas; ignora las de especies o variantes que no existen.
static func _read_discovered(
	state: GameState, data: Dictionary, content: ContentDB, warnings: PackedStringArray
) -> void:
	if not data.has("discovered"):
		return
	var raw: Variant = SaveFields.read_array(data, "discovered", warnings)
	if raw == null:
		return
	var items: Array = raw
	for item: Variant in items:
		if typeof(item) != TYPE_STRING:
			continue
		var key: String = item
		var parts: PackedStringArray = key.split("|")
		if parts.size() != 2:
			continue
		if content.has_species(parts[0]) and content.has_variant(parts[1]):
			state.discovered[key] = true


## Lee los logros conseguidos; ignora los que no existen.
static func _read_achievements(
	state: GameState, data: Dictionary, content: ContentDB, warnings: PackedStringArray
) -> void:
	if not data.has("achievements"):
		return
	var raw: Variant = SaveFields.read_dict(data, "achievements", warnings)
	if raw == null:
		return
	var entries: Dictionary = raw
	for key: Variant in entries:
		var flag: Variant = entries[key]
		if typeof(key) == TYPE_STRING and typeof(flag) == TYPE_BOOL and flag:
			var achievement_id: String = key
			if content.achievements.has(achievement_id):
				state.achievements[achievement_id] = true


## Lee la decoración sin colocar; ignora las que no existen y limita las cantidades.
static func _read_stock(
	state: GameState, data: Dictionary, content: ContentDB, warnings: PackedStringArray
) -> void:
	if not data.has("decoration_stock"):
		return
	var raw: Variant = SaveFields.read_dict(data, "decoration_stock", warnings)
	if raw == null:
		return
	var entries: Dictionary = raw
	for key: Variant in entries:
		if typeof(key) != TYPE_STRING:
			continue
		var decoration_id: String = key
		if not content.has_decoration(decoration_id):
			continue
		var count: int = SaveFields.read_int(entries, decoration_id, 0, 0, MAX_STOCK, warnings)
		if count > 0:
			state.decoration_stock[decoration_id] = count
