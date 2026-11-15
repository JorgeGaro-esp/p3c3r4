class_name SandView
extends AsciiDrawable
## Arena del fondo: dos filas de puntos y comas. El dibujo se decide con una
## semilla fija, así no cambia al redimensionar la ventana.

const SEED: int = 4242
const GRAINS: String = ".:,.'.·.,"
## Probabilidad de que una celda de arena sea una piedrecita o concha.
const ACCENT_CHANCE: float = 0.07

var _first_row: int = 0
var _color: Color = AsciiColors.SAND
var _lines: PackedStringArray = PackedStringArray()
## Color de cada celda (por filas): los granos varían de claro a oscuro y hay motas.
var _colors: Array[PackedColorArray] = []


## Rehace la arena: [param new_columns] columnas, [param row_count] filas de
## arena que empiezan en [param first_row].
func configure(
	new_columns: int,
	first_row: int,
	row_count: int,
	grains: String = GRAINS,
	color: Color = AsciiColors.SAND,
	seed_offset: int = 0,
	accents: String = "",
	accent_color: Color = Color(0.85, 0.8, 0.7)
) -> void:
	_first_row = first_row
	_color = color
	_lines = PackedStringArray()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	_colors.clear()
	for row: int in range(row_count):
		var line: String = ""
		var tints: PackedColorArray = PackedColorArray()
		for _column: int in range(new_columns):
			var grain: String = grains[rng.randi_range(0, grains.length() - 1)]
			var tint: Color = color
			var shade: float = rng.randf_range(0.72, 1.18)
			tint = Color(tint.r * shade, tint.g * shade, tint.b * shade, 1.0)
			# La fila de abajo es más oscura: da sensación de profundidad.
			if row == row_count - 1 and row_count > 1:
				tint = tint.darkened(0.25)
			if not accents.is_empty() and rng.randf() < ACCENT_CHANCE:
				grain = accents[rng.randi_range(0, accents.length() - 1)]
				tint = accent_color.darkened(rng.randf_range(0.0, 0.25))
			line += grain
			tints.append(tint)
		_lines.append(line)
		_colors.append(tints)


func draw(canvas: AsciiCanvas) -> void:
	for index: int in range(_lines.size()):
		var line: String = _lines[index]
		for column: int in range(line.length()):
			canvas.put_char(
				line[column],
				Vector2(float(column), float(_first_row + index)),
				_colors[index][column]
			)
