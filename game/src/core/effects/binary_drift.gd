class_name BinaryDrift
extends RefCounted
## Unos y ceros que flotan: el fondo de cada pecera y la estela del puntero.
## Lógica pura (sin nodos): cada glifo nace, sube despacio y se desvanece.

const GLYPHS: String = "01"
## Carácter de los puntitos que acompañan a los dígitos del fondo.
const DOT: String = "·"
## Parte de los glifos del fondo que son puntitos.
const DOT_SHARE: float = 0.3
const MIN_SCALE: float = 0.55
const MAX_SCALE: float = 1.5
## Glifos del fondo por celda de agua.
const DEFAULT_DENSITY: float = 0.07
const MIN_LIFE: float = 7.0
const MAX_LIFE: float = 14.0
const MIN_RISE: float = 0.25
const MAX_RISE: float = 0.9
## Probabilidad por segundo de que un glifo cambie de 0 a 1 o al revés.
const FLIP_RATE: float = 0.08
const TRAIL_LIFE: float = 0.55
const TRAIL_RISE: float = 0.4
const MAX_TRAIL: int = 14
## Distancia (celdas) que hay que mover el puntero para soltar otro glifo.
const TRAIL_STEP: float = 1.8

var area: Rect2 = Rect2()
var density: float = DEFAULT_DENSITY
## Multiplica la velocidad de subida (la accesibilidad la reduce).
var speed_scale: float = 1.0

var _glyphs: Array[Glyph] = []
var _trail: Array[Glyph] = []
var _last_cursor: Vector2 = Vector2(-1000.0, -1000.0)
var _carry: float = 0.0


## Fija la zona (celdas) y reparte los glifos del fondo por ella.
func configure(new_area: Rect2, new_density: float, rng: RandomNumberGenerator) -> void:
	area = new_area
	density = new_density
	_glyphs.clear()
	_trail.clear()
	_last_cursor = Vector2(-1000.0, -1000.0)
	if not area.has_area():
		return
	for _index: int in range(target_count()):
		var glyph: Glyph = _spawn(rng)
		glyph.age = rng.randf() * glyph.life
		glyph.y = area.end.y - rng.randf() * area.size.y
		_glyphs.append(glyph)


## Cuántos glifos de fondo debe haber.
func target_count() -> int:
	if not area.has_area():
		return 0
	return roundi(area.size.x * area.size.y * density)


## Número de glifos del fondo vivos.
func count() -> int:
	return _glyphs.size()


## Número de glifos de la estela vivos.
func trail_count() -> int:
	return _trail.size()


func glyphs() -> Array[Glyph]:
	return _glyphs


func trail() -> Array[Glyph]:
	return _trail


## Avanza el tiempo: suben, envejecen y los que terminan se reponen.
func update(delta: float, rng: RandomNumberGenerator) -> void:
	if area.has_area():
		_advance(_glyphs, delta, rng, true)
		while _glyphs.size() < target_count():
			_glyphs.append(_spawn(rng))
	_advance(_trail, delta, rng, false)


## El puntero está en [param cursor] (celdas): suelta glifos según lo que se movió.
## Sin moverse no sale nada.
func move_cursor(cursor: Vector2, rng: RandomNumberGenerator) -> void:
	if _last_cursor.x < -500.0:
		_last_cursor = cursor
		return
	_carry += cursor.distance_to(_last_cursor)
	_last_cursor = cursor
	while _carry >= TRAIL_STEP:
		_carry -= TRAIL_STEP
		if _trail.size() >= MAX_TRAIL:
			_trail.remove_at(0)
		var glyph: Glyph = Glyph.new()
		glyph.x = cursor.x + rng.randf_range(-0.3, 0.3)
		glyph.y = cursor.y + rng.randf_range(-0.25, 0.25)
		glyph.speed = TRAIL_RISE * rng.randf_range(0.6, 1.4)
		glyph.life = TRAIL_LIFE * rng.randf_range(0.8, 1.2)
		glyph.character = GLYPHS[rng.randi_range(0, GLYPHS.length() - 1)]
		_trail.append(glyph)


## El puntero salió de la zona: la próxima vez no se dibuja una línea desde aquí.
func lose_cursor() -> void:
	_last_cursor = Vector2(-1000.0, -1000.0)
	_carry = 0.0


## Vacía la estela (por ejemplo al abrir un panel).
func clear_trail() -> void:
	_trail.clear()
	lose_cursor()


## Opacidad (0 a 1) del glifo: sube y baja suave durante su vida.
static func fade(glyph: Glyph) -> float:
	if glyph.life <= 0.0:
		return 0.0
	return sin(PI * clampf(glyph.age / glyph.life, 0.0, 1.0))


func _spawn(rng: RandomNumberGenerator) -> Glyph:
	var glyph: Glyph = Glyph.new()
	glyph.x = area.position.x + rng.randf() * area.size.x
	glyph.y = area.end.y
	glyph.speed = rng.randf_range(MIN_RISE, MAX_RISE)
	glyph.life = rng.randf_range(MIN_LIFE, MAX_LIFE)
	glyph.character = GLYPHS[rng.randi_range(0, GLYPHS.length() - 1)]
	# Como en losdelaia.com: muchos pequeños y apagados, pocos grandes y más claros.
	var size: float = pow(rng.randf(), 1.8)
	glyph.scale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * size
	glyph.bright = rng.randf_range(0.35, 1.0)
	if rng.randf() < DOT_SHARE:
		glyph.character = DOT
		glyph.is_dot = true
		glyph.scale = rng.randf_range(0.9, 1.6)
	return glyph


func _advance(
	list: Array[Glyph], delta: float, rng: RandomNumberGenerator, is_background: bool
) -> void:
	var index: int = list.size() - 1
	while index >= 0:
		var glyph: Glyph = list[index]
		glyph.age += delta
		glyph.y -= glyph.speed * speed_scale * delta
		if is_background and not glyph.is_dot and rng.randf() < FLIP_RATE * delta:
			glyph.character = "1" if glyph.character == "0" else "0"
		var gone: bool = glyph.age >= glyph.life
		if is_background and glyph.y < area.position.y:
			gone = true
		if gone:
			list[index] = list[list.size() - 1]
			list.pop_back()
		index -= 1


## Un glifo: posición, subida, vida y qué carácter es.
class Glyph:
	var x: float = 0.0
	var y: float = 0.0
	var speed: float = 0.0
	var age: float = 0.0
	var life: float = 1.0
	var character: String = "0"
	var scale: float = 1.0
	var bright: float = 1.0
	var is_dot: bool = false
