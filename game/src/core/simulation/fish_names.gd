class_name FishNames
extends RefCounted
## Apodos que se pueden poner a un pez. Se eligen de una lista (no hay teclado en la
## interfaz ASCII) y son los mismos en todos los idiomas.

const NAMES: Array[String] = [
	"Burbuja",
	"Coral",
	"Perla",
	"Neptuno",
	"Sol",
	"Luna",
	"Bruma",
	"Pipo",
	"Mochi",
	"Tinta",
	"Nube",
	"Kiwi",
	"Gota",
	"Canela",
	"Ambar",
	"Trebol",
	"Chispa",
	"Fideo",
	"Tormenta",
	"Brisa",
]


## El apodo que sigue a [param current] en la lista. Tras el último vuelve a no
## tener apodo (cadena vacía); un apodo que no esté en la lista pasa al primero.
static func next(current: String) -> String:
	if current.is_empty():
		return NAMES[0]
	var index: int = NAMES.find(current)
	if index < 0:
		return NAMES[0]
	if index + 1 >= NAMES.size():
		return ""
	return NAMES[index + 1]
