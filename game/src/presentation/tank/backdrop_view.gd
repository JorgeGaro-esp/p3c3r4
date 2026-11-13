class_name BackdropView
extends AsciiDrawable
## Fondo del agua: caracteres sueltos muy tenues que dan textura a cada bioma
## (limo en el manglar, motas en el abismo). Se decide con semilla fija.

const SEED: int = 9137

var _cells: Array[Vector2i] = []
var _chars: PackedStringArray = PackedStringArray()
var _color: Color = Color.WHITE


## Rehace el fondo de [param area] con el aspecto de [param look]. Sin
## densidad no se dibuja nada.
func configure(area: Rect2i, look: BiomeDef, seed_offset: int = 0) -> void:
	_cells.clear()
	_chars = PackedStringArray()
	if look == null or look.backdrop_density <= 0.0 or look.backdrop_char.is_empty():
		return
	_color = look.backdrop_color
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	for row: int in range(area.size.y):
		for column: int in range(area.size.x):
			if rng.randf() < look.backdrop_density:
				_cells.append(Vector2i(area.position.x + column, area.position.y + row))
				_chars.append(look.backdrop_char)


## Cuántos caracteres de fondo hay.
func count() -> int:
	return _cells.size()


func draw(canvas: AsciiCanvas) -> void:
	for index: int in range(_cells.size()):
		canvas.put_char(_chars[index], Vector2(_cells[index]), _color)
