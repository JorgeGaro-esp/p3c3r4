class_name EggField
extends AsciiDrawable
## Huevos en el fondo de la pecera. Es solo vista: `TankView` le pasa los huevos del
## modelo en cada fotograma. Cuando falta poco para eclosionar el huevo se mueve.

const EGG: String = "o"
const WIGGLE: String = "O"
const COLOR: Color = Color(0.93, 0.88, 0.7)
const WIGGLE_SECONDS: float = 6.0
const WIGGLE_PERIOD: float = 0.5

var floor_row: float = 0.0
var width: int = 0

var _eggs: Array[Egg] = []
var _clock: float = 0.0


## Huevos que se dibujan ahora, y ancho de la zona (en celdas) donde reparte las posiciones.
func set_eggs(eggs: Array[Egg], area_width: int) -> void:
	_eggs = eggs
	width = area_width


func count() -> int:
	return _eggs.size()


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	var span: float = float(maxi(width - 2, 1))
	for egg: Egg in _eggs:
		var wiggling: bool = (
			egg.remaining < WIGGLE_SECONDS and fmod(_clock, WIGGLE_PERIOD * 2.0) < WIGGLE_PERIOD
		)
		var glyph: String = WIGGLE if wiggling else EGG
		canvas.put_char(glyph, Vector2(1.0 + floorf(egg.position_x * span), floor_row), COLOR)
