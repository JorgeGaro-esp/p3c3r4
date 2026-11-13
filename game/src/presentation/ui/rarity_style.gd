class_name RarityStyle
extends RefCounted
## Cómo se presenta cada rareza: nombre traducible, símbolo y color. El color
## nunca es la única señal (GDD §4.2): siempre va acompañado del símbolo y del texto.

const KEYS: Array[String] = [
	"RARITY_COMMON",
	"RARITY_UNCOMMON",
	"RARITY_RARE",
	"RARITY_EPIC",
	"RARITY_LEGENDARY",
]
const COLORS: Array[Color] = [
	Color(0.9, 0.9, 0.9),
	Color(0.4, 0.85, 0.45),
	Color(0.35, 0.6, 1.0),
	Color(0.72, 0.45, 0.95),
	Color(1.0, 0.8, 0.25),
]


static func name_key(rarity: SpeciesDef.Rarity) -> String:
	return KEYS[clampi(int(rarity), 0, KEYS.size() - 1)]


static func color(rarity: SpeciesDef.Rarity) -> Color:
	return COLORS[clampi(int(rarity), 0, COLORS.size() - 1)]
