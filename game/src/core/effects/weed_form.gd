class_name WeedForm
extends RefCounted
## La forma de una planta del fondo, leída de un texto `tipo|caracteres` del bioma
## (por ejemplo `fern|()` o `tuft|\|/`). Lógica pura; [SeaweedView] la dibuja.
##
## Tipos:
## - `stalk`: tallo que alterna los dos caracteres (`()` da la alga de siempre).
## - `reed`: caña recta; el primer carácter es el tallo y el segundo, la punta.
## - `fern`: tallo `|` con hojas a un lado y a otro; los dos caracteres son las hojas.
## - `tuft`: mata baja de tres caracteres lado a lado (`\|/`) y, si crece, un tallo encima.
## - `bush`: arbusto ancho: los dos caracteres lado a lado en cada fila.

enum Kind { STALK, REED, FERN, TUFT, BUSH }

const KIND_NAMES: Dictionary[String, Kind] = {
	"stalk": Kind.STALK,
	"reed": Kind.REED,
	"fern": Kind.FERN,
	"tuft": Kind.TUFT,
	"bush": Kind.BUSH,
}
## Altura mínima y máxima de cada tipo (el resto lo limita el alto de la pecera).
const MIN_HEIGHTS: Dictionary[Kind, int] = {
	Kind.STALK: 2, Kind.REED: 3, Kind.FERN: 3, Kind.TUFT: 1, Kind.BUSH: 2
}
const MAX_HEIGHTS: Dictionary[Kind, int] = {
	Kind.STALK: 6, Kind.REED: 6, Kind.FERN: 6, Kind.TUFT: 2, Kind.BUSH: 3
}
## Caracteres que hacen falta para dibujar cada tipo.
const GLYPH_COUNTS: Dictionary[Kind, int] = {
	Kind.STALK: 2, Kind.REED: 2, Kind.FERN: 2, Kind.TUFT: 3, Kind.BUSH: 2
}
const STEM: String = "|"

var kind: Kind = Kind.STALK
var glyphs: String = "()"


## Lee una forma de `tipo|caracteres`. Devuelve null si el tipo no existe o faltan
## caracteres.
static func parse(text: String) -> WeedForm:
	var cut: int = text.find("|")
	if cut <= 0:
		return null
	var name: String = text.substr(0, cut)
	var chars: String = text.substr(cut + 1)
	if not KIND_NAMES.has(name):
		return null
	var form: WeedForm = WeedForm.new()
	form.kind = KIND_NAMES[name]
	if chars.length() < GLYPH_COUNTS[form.kind]:
		return null
	form.glyphs = chars
	return form


## Forma de las algas de siempre: dos caracteres alternados.
static func stalk(chars: String) -> WeedForm:
	var form: WeedForm = WeedForm.new()
	form.kind = Kind.STALK
	form.glyphs = chars if chars.length() >= 2 else "()"
	return form


## Lee todas las formas de [param texts]; las que no valen se ignoran.
static func parse_all(texts: PackedStringArray) -> Array[WeedForm]:
	var result: Array[WeedForm] = []
	for text: String in texts:
		var form: WeedForm = parse(text)
		if form != null:
			result.append(form)
	return result


func min_height() -> int:
	return MIN_HEIGHTS[kind]


func max_height() -> int:
	return MAX_HEIGHTS[kind]


## Columnas de más que ocupa a cada lado del tallo (para separar las plantas).
func half_width() -> int:
	match kind:
		Kind.FERN, Kind.TUFT:
			return 1
		Kind.BUSH:
			return 1
	return 0


## Si el tipo se pinta con una punta propia (la caña).
func has_own_tip() -> bool:
	return kind == Kind.REED
