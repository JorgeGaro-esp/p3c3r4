class_name GameStats
extends RefCounted
## Contadores de lo que el jugador ha hecho en la partida (compras, ventas, cuidados...).
##
## Son la base de los logros (Fase 11B). Solo se admiten los identificadores de
## [constant IDS]: lo que venga de un archivo con otro nombre se descarta.

const FISH_BOUGHT: String = "fish_bought"
const FISH_SOLD: String = "fish_sold"
const EGGS_HATCHED: String = "eggs_hatched"
const PEARLS_COLLECTED: String = "pearls_collected"
const SPOTS_CLEANED: String = "spots_cleaned"
const FISH_FED: String = "fish_fed"
const DECORATIONS_BOUGHT: String = "decorations_bought"
const EQUIPMENT_BOUGHT: String = "equipment_bought"

const IDS: PackedStringArray = [
	FISH_BOUGHT,
	FISH_SOLD,
	EGGS_HATCHED,
	PEARLS_COLLECTED,
	SPOTS_CLEANED,
	FISH_FED,
	DECORATIONS_BOUGHT,
	EQUIPMENT_BOUGHT,
]
const MAX_VALUE: float = 1.0e12

var _values: Dictionary[String, float] = {}


## Suma [param amount] al contador [param id]. Ignora ids desconocidos y cantidades
## no positivas.
func add(id: String, amount: float = 1.0) -> void:
	if not IDS.has(id) or not is_finite(amount) or amount <= 0.0:
		return
	_values[id] = minf(value(id) + amount, MAX_VALUE)


## Valor del contador [param id] (0 si no existe).
func value(id: String) -> float:
	return _values.get(id, 0.0)


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for id: String in IDS:
		if _values.has(id):
			result[id] = _values[id]
	return result


## Reconstruye los contadores desde un archivo; lo inválido se descarta con aviso.
static func from_dict(source: Variant, warnings: PackedStringArray) -> GameStats:
	var stats: GameStats = GameStats.new()
	if typeof(source) != TYPE_DICTIONARY:
		if source != null:
			warnings.append("stats: no es un objeto")
		return stats
	var data: Dictionary = source
	for id: String in IDS:
		if data.has(id):
			var loaded: float = SaveFields.read_float(data, id, 0.0, 0.0, MAX_VALUE, warnings)
			if loaded > 0.0:
				stats._values[id] = loaded
	return stats
