class_name GameState
extends RefCounted
## Estado completo de la partida: la raíz del modelo (02-ARQUITECTURA §3.1).
##
## Más sistemas colgarán de aquí en fases posteriores (Pecedex, logros, prestigio).

const MAX_TANKS: int = 16
const MAX_SIM_TIME: float = 1.0e12

var wallet: Wallet = Wallet.new()
var tanks: Array[Tank] = [Tank.new()]
var sim_time: float = 0.0
var rng_seed: int = 0
## Estado interno del generador aleatorio, para continuar la secuencia al cargar.
var rng_state: int = 0
## Producción total en conchas por segundo; se recalcula solo si cambia algo.
var production_rate: float = 0.0
## Verdadero cuando hay que recalcular [member production_rate].
var production_dirty: bool = true
## Especies que ya se pueden comprar. Una vez desbloqueada, no se vuelve a bloquear.
var unlocked: Dictionary[String, bool] = {}


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
		"sim_time": sim_time,
		# 64 bits no caben en un número JSON sin perder precisión: van como texto.
		"rng_seed": str(rng_seed),
		"rng_state": str(rng_state),
		"unlocked": unlocked.keys(),
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
		if tank != null:
			state.tanks.append(tank)
	if state.tanks.is_empty():
		warnings.append("no hay ninguna pecera válida")
		return null
	state.sim_time = SaveFields.read_float(data, "sim_time", 0.0, 0.0, MAX_SIM_TIME, warnings)
	state.rng_seed = SaveFields.read_big_int(data, "rng_seed", 0, warnings)
	state.rng_state = SaveFields.read_big_int(data, "rng_state", 0, warnings)
	_read_unlocked(state, data, content, warnings)
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
