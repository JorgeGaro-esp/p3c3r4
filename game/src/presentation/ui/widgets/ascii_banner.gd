class_name AsciiBanner
extends AsciiWidget
## Letrero grande de arte ASCII (el logo del título). Cada carácter no vacío se
## pinta con un degradado de arriba abajo y un brillo que lo recorre en diagonal;
## con «Reducir movimiento» el brillo se queda casi quieto.

const GLYPH_HEIGHT: int = 5
const GLYPH_GAP: String = " "
## Letras de 5×5 hechas con bloques. Solo las que usa el logo.
const GLYPHS: Dictionary[String, PackedStringArray] = {
	"P": ["████ ", "█   █", "████ ", "█    ", "█    "],
	"3": ["████ ", "    █", " ███ ", "    █", "████ "],
	"C": [" ████", "█    ", "█    ", "█    ", " ████"],
	"R": ["████ ", "█   █", "████ ", "█  █ ", "█   █"],
	"4": ["█   █", "█   █", "█████", "    █", "    █"],
}
const SHIMMER_SPEED: float = 2.2
const SHIMMER_SLOPE: Vector2 = Vector2(0.32, 0.7)
const SHIMMER_STRENGTH: float = 0.55
const TOP_COLOR: Color = AsciiColors.AMBER
const BOTTOM_COLOR: Color = AsciiColors.WATER

var lines: PackedStringArray = PackedStringArray()

var _time: float = 0.0


## Arma las filas del letrero para [param text] con [constant GLYPHS]; una letra
## que no existe se deja en blanco.
static func build(text: String) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	for row: int in range(GLYPH_HEIGHT):
		var line: String = ""
		for index: int in range(text.length()):
			var glyph: PackedStringArray = GLYPHS.get(text[index], PackedStringArray())
			line += glyph[row] if glyph.size() == GLYPH_HEIGHT else "     "
			if index < text.length() - 1:
				line += GLYPH_GAP
		rows.append(line)
	return rows


## Ancho del letrero en celdas.
func text_width() -> int:
	var widest: int = 0
	for line: String in lines:
		widest = maxi(widest, line.length())
	return widest


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if is_shown:
		_time += delta


func draw(canvas: AsciiCanvas) -> void:
	var left: int = rect.position.x + maxi((rect.size.x - text_width()) / 2, 0)
	var shimmer: float = SHIMMER_STRENGTH * MotionScale.factor()
	for row: int in range(mini(lines.size(), rect.size.y)):
		var base: Color = TOP_COLOR.lerp(
			BOTTOM_COLOR, float(row) / float(maxi(GLYPH_HEIGHT - 1, 1))
		)
		var line: String = lines[row]
		for column: int in range(line.length()):
			if line[column] == " ":
				continue
			var wave: float = sin(
				(
					float(column) * SHIMMER_SLOPE.x
					+ float(row) * SHIMMER_SLOPE.y
					- _time * SHIMMER_SPEED
				)
			)
			var color: Color = base.lerp(Color.WHITE, maxf(wave, 0.0) * shimmer)
			canvas.put_char(
				line[column], Vector2(float(left + column), float(rect.position.y + row)), color
			)
