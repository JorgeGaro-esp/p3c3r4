class_name EventField
extends AsciiDrawable
## Lo clicable de los eventos que no es un pez: el pez dorado fugaz y la botella
## a la deriva. Hay uno a la vez (ver [EventState]).

const GOLD: Color = Color(1.0, 0.82, 0.25)
const GLASS: Color = Color(0.55, 0.95, 0.8)
const SPARK_COLOR: Color = Color(1.0, 0.95, 0.6)
const FISH_TEXT_RIGHT: String = "><>"
const FISH_TEXT_LEFT: String = "<><"
const BOTTLE_TEXT: String = "(o]"
const FISH_SPEED: float = 11.0
const BOTTLE_SPEED: float = 1.6
const BOB_SPEED: float = 3.0
## Margen del clic, en celdas, alrededor del dibujo.
const HIT_MARGIN: float = 1.0

## Rejilla por la que se mueve: filas de agua y columnas.
var bounds: Rect2 = Rect2()

var _kind: EventDef.Kind = EventDef.Kind.GOLDEN_FISH
var _active: bool = false
var _position: Vector2 = Vector2.ZERO
var _direction: float = 1.0
var _clock: float = 0.0
var _base_row: float = 0.0
## Marcador brillante extra sobre otro elemento (el visitante), en celdas; (-1,-1) sin él.
var _marker: Vector2 = Vector2(-1.0, -1.0)


func is_active() -> bool:
	return _active


## Dónde está el marcador brillante ((-1, -1) si no hay).
func marker_cell() -> Vector2:
	return _marker


## Esquina superior izquierda del elemento, en celdas.
func cell_position() -> Vector2:
	return _position


## Aparece un elemento del tipo [param kind] (pez dorado o botella).
func spawn(kind: EventDef.Kind, rng: RandomNumberGenerator) -> void:
	_kind = kind
	_active = true
	_direction = 1.0 if rng.randf() < 0.5 else -1.0
	var left: float = bounds.position.x
	var right: float = bounds.end.x
	_position.x = left if _direction > 0.0 else right
	if kind == EventDef.Kind.BOTTLE:
		_base_row = bounds.position.y
	else:
		_base_row = rng.randf_range(bounds.position.y, bounds.end.y)
	_position.y = _base_row
	_clock = 0.0


func clear() -> void:
	_active = false


## Fija el marcador brillante (la posición del visitante) o lo quita con (-1, -1).
func set_marker(cell: Vector2) -> void:
	_marker = cell


## Si la celda [param cell] toca el elemento.
func hit(cell: Vector2i) -> bool:
	if not _active:
		return false
	var point: Vector2 = Vector2(cell) + Vector2(0.5, 0.5)
	var width: float = float(_text().length())
	return (
		point.x >= _position.x - HIT_MARGIN
		and point.x <= _position.x + width + HIT_MARGIN
		and absf(point.y - (_position.y + 0.5)) <= HIT_MARGIN + 0.5
	)


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	if not _active:
		return
	var speed: float = BOTTLE_SPEED if _kind == EventDef.Kind.BOTTLE else FISH_SPEED
	_position.x += _direction * speed * delta
	if _position.x > bounds.end.x:
		_direction = -1.0
	elif _position.x < bounds.position.x:
		_direction = 1.0
	var bob: float = sin(_clock * BOB_SPEED) * (0.25 if _kind == EventDef.Kind.BOTTLE else 0.6)
	_position.y = clampf(_base_row + bob, bounds.position.y, maxf(bounds.end.y, bounds.position.y))


func draw(canvas: AsciiCanvas) -> void:
	if _active:
		var color: Color = GOLD if _kind == EventDef.Kind.GOLDEN_FISH else GLASS
		canvas.put_string(_text(), _position, color)
		_sparkle(canvas, _position + Vector2(float(_text().length()) * 0.5 - 0.5, -1.0))
	if _marker.x >= 0.0:
		_sparkle(canvas, _marker)


func _text() -> String:
	if _kind == EventDef.Kind.BOTTLE:
		return BOTTLE_TEXT
	return FISH_TEXT_RIGHT if _direction > 0.0 else FISH_TEXT_LEFT


func _sparkle(canvas: AsciiCanvas, cell: Vector2) -> void:
	if MotionScale.is_reduced() or int(_clock * 3.0) % 2 == 0:
		canvas.put_char("✦", cell, SPARK_COLOR)
	else:
		canvas.put_char("+", cell, SPARK_COLOR)
