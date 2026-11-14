class_name PrestigeState
extends RefCounted
## Lo que la Gran marea recuerda entre ciclos: perlas negras, mejoras compradas y
## si ya se alcanzó el final. Se guarda (06-SEGURIDAD).

const MAX_PEARLS: int = 1000000000
const MAX_COUNT: int = 1000000

## Perlas negras sin gastar.
var pearls: int = 0
## Perlas negras ganadas en total (para estadísticas).
var pearls_earned: int = 0
## Cuántas veces se ha hecho la Gran marea.
var count: int = 0
## Conchas ganadas (`Wallet.total_earned`) cuando empezó el ciclo actual.
var run_start_earned: float = 0.0
## Nivel de cada mejora comprada (id → nivel).
var levels: Dictionary[String, int] = {}
## Verdadero desde que se completó la Enciclopedia: el juego sigue en modo infinito.
var final_reached: bool = false


## Nivel de la mejora [param upgrade_id] (0 si no se ha comprado).
func level_of(upgrade_id: String) -> int:
	return levels.get(upgrade_id, 0)


## Suma [param amount] perlas negras al saldo y al total ganado.
func add_pearls(amount: int) -> void:
	if amount <= 0:
		return
	pearls = mini(pearls + amount, MAX_PEARLS)
	pearls_earned = mini(pearls_earned + amount, MAX_PEARLS)


func to_dict() -> Dictionary:
	return {
		"pearls": pearls,
		"pearls_earned": pearls_earned,
		"count": count,
		"run_start_earned": run_start_earned,
		"levels": levels.duplicate(),
		"final_reached": final_reached,
	}


## Reconstruye el estado desde un archivo; lo inválido se descarta con aviso. Sin
## datos (partidas antiguas) sale el estado inicial.
static func from_dict(
	source: Variant, content: ContentDB, warnings: PackedStringArray
) -> PrestigeState:
	var state: PrestigeState = PrestigeState.new()
	if typeof(source) != TYPE_DICTIONARY:
		if source != null:
			warnings.append("prestige: no es un objeto")
		return state
	var data: Dictionary = source
	state.pearls = SaveFields.read_int(data, "pearls", 0, 0, MAX_PEARLS, warnings)
	state.pearls_earned = maxi(
		SaveFields.read_int(data, "pearls_earned", 0, 0, MAX_PEARLS, warnings), state.pearls
	)
	state.count = SaveFields.read_int(data, "count", 0, 0, MAX_COUNT, warnings)
	state.run_start_earned = SaveFields.read_float(
		data, "run_start_earned", 0.0, 0.0, Wallet.MAX_SHELLS, warnings
	)
	state.final_reached = data.get("final_reached", false) == true
	var raw: Variant = data.get("levels")
	if typeof(raw) == TYPE_DICTIONARY:
		var entries: Dictionary = raw
		for key: Variant in entries:
			if typeof(key) != TYPE_STRING:
				continue
			var upgrade_id: String = key
			var def: PrestigeUpgradeDef = content.prestige.get_upgrade(upgrade_id)
			if def == null:
				continue
			var level: int = SaveFields.read_int(entries, upgrade_id, 0, 0, def.max_level, warnings)
			if level > 0:
				state.levels[upgrade_id] = level
	return state
