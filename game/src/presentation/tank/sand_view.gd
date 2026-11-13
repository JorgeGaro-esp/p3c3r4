class_name SandView
extends AsciiDrawable
## Arena del fondo: dos filas de puntos y comas. El dibujo se decide con una
## semilla fija, así no cambia al redimensionar la ventana.

const SEED: int = 4242
const GRAINS: String = ".:,.'.·.,"

var _first_row: int = 0
var _color: Color = AsciiColors.SAND
var _lines: PackedStringArray = PackedStringArray()


## Rehace la arena: [param new_columns] columnas, [param row_count] filas de
## arena que empiezan en [param first_row].
func configure(
	new_columns: int,
	first_row: int,
	row_count: int,
	grains: String = GRAINS,
	color: Color = AsciiColors.SAND,
	seed_offset: int = 0
) -> void:
	_first_row = first_row
	_color = color
	_lines = PackedStringArray()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	for _row: int in range(row_count):
		var line: String = ""
		for _column: int in range(new_columns):
			line += grains[rng.randi_range(0, grains.length() - 1)]
		_lines.append(line)


func draw(canvas: AsciiCanvas) -> void:
	for index: int in range(_lines.size()):
		canvas.put_string(_lines[index], Vector2(0.0, float(_first_row + index)), _color)
