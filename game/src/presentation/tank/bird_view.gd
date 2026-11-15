class_name BirdView
extends AsciiDrawable
## El pájaro de cada bioma (pato, gaviota, garza…) que de vez en cuando se posa
## en la superficie. La lógica está en [BirdVisit]; aquí solo se elige el dibujo.

const SEED: int = 3131
## Segundos hasta la primera visita tras abrir una pecera (al azar entre ambos).
const FIRST_MIN: float = 25.0
const FIRST_MAX: float = 90.0
const FLAP_SPEED: float = 5.0
const IDLE_SWAP: float = 3.2
## Cambio de lado de los caracteres al mirar a la izquierda.
const MIRROR: Dictionary[String, String] = {
	"(": ")",
	")": "(",
	"<": ">",
	">": "<",
	"/": "\\",
	"\\": "/",
	"{": "}",
	"}": "{",
	"[": "]",
	"]": "[",
}

var visit: BirdVisit = BirdVisit.new()

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _row: int = 0
var _color: Color = Color.WHITE
var _perched: Array[PackedStringArray] = []
var _flying: Array[PackedStringArray] = []
var _has_bird: bool = false
var _clock: float = 0.0


func _init() -> void:
	_rng.seed = SEED


## Deja listo el pájaro de [param look] para un mundo que va de [param left] a
## [param right] y una superficie en la fila [param surface_row].
func configure(look: BiomeDef, left: float, right: float, surface_row: int) -> void:
	_row = surface_row
	_perched.clear()
	_flying.clear()
	_has_bird = look != null and not look.bird_perch_a.is_empty()
	if _has_bird:
		_color = look.bird_color
		_perched.append(_rows(look.bird_perch_a))
		_perched.append(
			_rows(look.bird_perch_b if not look.bird_perch_b.is_empty() else look.bird_perch_a)
		)
		_flying.append(
			_rows(look.bird_fly_a if not look.bird_fly_a.is_empty() else look.bird_perch_a)
		)
		_flying.append(
			_rows(look.bird_fly_b if not look.bird_fly_b.is_empty() else look.bird_fly_a)
		)
	visit.configure(left, right, _rng, _rng.randf_range(FIRST_MIN, FIRST_MAX))


## Si el bioma tiene pájaro.
func has_bird() -> bool:
	return _has_bird


## Hace que llegue el pájaro del bioma ahora (la tecla F12). Si ya hay uno a la vista
## no hace nada. Devuelve si llegó uno.
func summon() -> bool:
	if not _has_bird or visit.is_visible():
		return false
	visit.call_bird(_rng)
	return true


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	if _has_bird:
		visit.step(delta, _rng)


func draw(canvas: AsciiCanvas) -> void:
	if not _has_bird or not visit.is_visible():
		return
	var frame: int
	var frames: Array[PackedStringArray]
	if visit.is_flying():
		frames = _flying
		frame = int(_clock * FLAP_SPEED * MotionScale.factor()) % 2
	else:
		frames = _perched
		frame = int(_clock / IDLE_SWAP) % 2
	var rows: PackedStringArray = frames[frame]
	# Con los pies sobre la ola (la fila de la superficie); volando, una fila más arriba.
	var top: int = _row - (rows.size() - 1) - (1 if visit.is_flying() else 0)
	for index: int in range(rows.size()):
		var line: String = rows[index]
		if visit.direction < 0:
			line = _mirror(line)
		canvas.put_string(line, Vector2(visit.x, float(top + index)), _color)


## Pinta el dibujo mirando a la izquierda: invierte la fila y cambia `(` por `)`, etc.
static func _mirror(line: String) -> String:
	var result: String = ""
	for index: int in range(line.length() - 1, -1, -1):
		var character: String = line[index]
		result += MIRROR.get(character, character)
	return result


static func _rows(art: String) -> PackedStringArray:
	var width: int = 0
	var parts: PackedStringArray = art.split("|")
	for part: String in parts:
		width = maxi(width, part.length())
	var rows: PackedStringArray = PackedStringArray()
	for part: String in parts:
		rows.append(part + " ".repeat(width - part.length()))
	return rows
