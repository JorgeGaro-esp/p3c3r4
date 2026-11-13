class_name ParticleField
extends AsciiDrawable
## Partículas que flotan en el agua de un bioma: nieve marina que cae, motas
## que suben. Dan vida al fondo sin tocar la simulación.

const SEED: int = 5521
const SWAY_AMPLITUDE: float = 0.5
const SWAY_SPEED: float = 0.9

var _area: Rect2 = Rect2()
var _fall: float = 0.0
var _color: Color = Color.WHITE
var _items: Array[Particle] = []
var _clock: float = 0.0


## Reparte las partículas de [param look] por [param area] (celdas).
func configure(area: Rect2i, look: BiomeDef, seed_offset: int = 0) -> void:
	_items.clear()
	if look == null or look.particle_count <= 0 or look.particle_chars.is_empty():
		return
	if not area.has_area():
		return
	_area = Rect2(area)
	_fall = look.particle_fall
	_color = look.particle_color
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + seed_offset
	for _index: int in range(look.particle_count):
		var particle: Particle = Particle.new()
		particle.x = _area.position.x + rng.randf() * _area.size.x
		particle.y = _area.position.y + rng.randf() * _area.size.y
		particle.speed = _fall * rng.randf_range(0.6, 1.4)
		particle.phase = rng.randf_range(0.0, TAU)
		particle.glyph = look.particle_chars[rng.randi_range(0, look.particle_chars.length() - 1)]
		_items.append(particle)


## Cuántas partículas hay.
func count() -> int:
	return _items.size()


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta
	var top: float = _area.position.y
	var bottom: float = _area.end.y
	for particle: Particle in _items:
		particle.y += particle.speed * delta
		if particle.y >= bottom:
			particle.y = top
		elif particle.y < top:
			particle.y = bottom - 0.01


func draw(canvas: AsciiCanvas) -> void:
	for particle: Particle in _items:
		var sway: float = sin(_clock * SWAY_SPEED + particle.phase) * SWAY_AMPLITUDE
		canvas.put_char(particle.glyph, Vector2(particle.x + sway, particle.y), _color)


## Una partícula: dónde está, cuánto cae y qué carácter es.
class Particle:
	var x: float = 0.0
	var y: float = 0.0
	var speed: float = 0.0
	var phase: float = 0.0
	var glyph: String = "."
