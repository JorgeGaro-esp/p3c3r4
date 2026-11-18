class_name Currency
extends RefCounted
## Símbolo con el que se dibuja la moneda del juego (las conchas). Los textos se
## escriben siempre con [constant DEFAULT_SYMBOL] y el lienzo lo cambia al dibujar,
## así que cambiar de símbolo no toca ninguna cadena ni ningún cálculo.

const DEFAULT_SYMBOL: String = "¢"
## Símbolos a elegir en Ajustes (todos de una sola celda).
const SYMBOLS: Array[String] = ["¢", "$", "€", "£", "¥"]

## Símbolo que se ve ahora mismo.
static var symbol: String = DEFAULT_SYMBOL


## Elige el símbolo por su posición en [constant SYMBOLS] (se recorta al rango).
static func use_index(index: int) -> void:
	symbol = SYMBOLS[clampi(index, 0, SYMBOLS.size() - 1)]


## [param text] con la moneda por defecto cambiada por el símbolo elegido.
static func apply(text: String) -> String:
	if symbol == DEFAULT_SYMBOL or not text.contains(DEFAULT_SYMBOL):
		return text
	return text.replace(DEFAULT_SYMBOL, symbol)
