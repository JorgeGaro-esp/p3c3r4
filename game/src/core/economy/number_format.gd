class_name NumberFormat
extends RefCounted
## Formato abreviado de números grandes: `12,4K`, `3,1M`, `1,25B`.
##
## Tres cifras significativas, sin ceros sobrantes, y el separador decimal según
## el idioma (coma en español, punto en inglés). Más allá de las abreviaturas se
## usa notación científica (`1,2e40`).

const SUFFIXES: PackedStringArray = [
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
]
const GROUP_DIGITS: int = 3
const SIGNIFICANT_DIGITS: int = 3
const INFINITY_TEXT: String = "inf"
const INVALID_TEXT: String = "?"


## Devuelve [param value] abreviado para el idioma [param locale] (`es` o `en`).
static func compact(value: float, locale: String = "es") -> String:
	if is_nan(value):
		return INVALID_TEXT
	if is_inf(value):
		return ("-" if value < 0.0 else "") + INFINITY_TEXT
	if value == 0.0:
		return "0"
	var sign_text: String = "-" if value < 0.0 else ""
	var magnitude: float = absf(value)
	var exponent: int = _exponent10(magnitude)
	var group: int = floori(float(maxi(exponent, 0)) / float(GROUP_DIGITS))
	var scaled: float = magnitude / pow(10.0, float(group * GROUP_DIGITS))
	var text: String = _round_significant(scaled)
	if text.to_float() >= 1000.0:
		# 999,96K se redondea a 1000K: pasa al grupo siguiente.
		group += 1
		scaled = magnitude / pow(10.0, float(group * GROUP_DIGITS))
		text = _round_significant(scaled)
	if group >= SUFFIXES.size():
		return sign_text + _scientific(magnitude, locale)
	return sign_text + _localize(text, locale) + SUFFIXES[group]


## Velocidad de producción: igual que [method compact] más `/s`.
static func per_second(value: float, locale: String = "es") -> String:
	return compact(value, locale) + "/s"


## Exponente de la potencia de 10 de [param magnitude] (mayor que 0), corregido
## contra el error de `log`: 1000 debe dar 3, no 2.
static func _exponent10(magnitude: float) -> int:
	var exponent: int = floori(log(magnitude) / log(10.0))
	if pow(10.0, float(exponent + 1)) <= magnitude:
		exponent += 1
	elif pow(10.0, float(exponent)) > magnitude:
		exponent -= 1
	return exponent


static func _round_significant(scaled: float) -> String:
	var digits_before: int = 1
	if scaled >= 1.0:
		digits_before = _exponent10(scaled) + 1
	var decimals: int = clampi(SIGNIFICANT_DIGITS - digits_before, 0, SIGNIFICANT_DIGITS)
	var text: String = String.num(scaled, decimals)
	if text.contains("."):
		text = text.rstrip("0").rstrip(".")
	return text


static func _scientific(magnitude: float, locale: String) -> String:
	var exponent: int = _exponent10(magnitude)
	var mantissa: float = magnitude / pow(10.0, float(exponent))
	var text: String = _round_significant(mantissa)
	return _localize(text, locale) + "e" + str(exponent)


static func _localize(text: String, locale: String) -> String:
	if locale.begins_with("es"):
		return text.replace(".", ",")
	return text
