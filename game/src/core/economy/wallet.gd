class_name Wallet
extends RefCounted
## Monedero: conchas actuales y total ganado en la partida.
##
## Rechaza cantidades negativas o no numéricas y nunca baja de cero ni supera
## [constant MAX_SHELLS], para que un fallo de balance no rompa la partida.

const MAX_SHELLS: float = 1.0e300

var shells: float = 0.0
## Conchas ganadas desde el principio de la partida (no baja al gastar).
var total_earned: float = 0.0


## Suma [param amount]. Devuelve falso si la cantidad no es válida.
func add(amount: float) -> bool:
	if is_nan(amount) or is_inf(amount) or amount < 0.0:
		return false
	shells = minf(shells + amount, MAX_SHELLS)
	total_earned = minf(total_earned + amount, MAX_SHELLS)
	return true


func can_afford(amount: float) -> bool:
	return not is_nan(amount) and amount >= 0.0 and shells >= amount


## Gasta [param amount] si alcanza. Devuelve falso, sin cambios, si no.
func spend(amount: float) -> bool:
	if not can_afford(amount):
		return false
	shells -= amount
	return true


func to_dict() -> Dictionary:
	return {"shells": shells, "total_earned": total_earned}


## Lee un monedero de [param source]; null si no es un objeto.
static func from_dict(source: Variant, warnings: PackedStringArray) -> Wallet:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("wallet: no es un objeto")
		return null
	var data: Dictionary = source
	var wallet: Wallet = Wallet.new()
	wallet.shells = SaveFields.read_float(data, "shells", 0.0, 0.0, MAX_SHELLS, warnings)
	wallet.total_earned = maxf(
		SaveFields.read_float(data, "total_earned", 0.0, 0.0, MAX_SHELLS, warnings), wallet.shells
	)
	return wallet
