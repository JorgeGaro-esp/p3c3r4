class_name SwimMotion
extends RefCounted
## Movimiento de nado de un pez: impulsos, ondulación del cuerpo, giro suave e
## inclinación (05-GUIA-ARTE-ASCII §6).
##
## Es lógica visual pura: no dibuja nada y recibe el generador aleatorio desde
## fuera, así que con la misma semilla produce siempre el mismo recorrido.
## Las unidades son celdas de la rejilla y segundos.

## Estilos de nado: `dart` a impulsos, `glide` suave, `drift` flotando y `crawl`
## pegado al fondo.
enum Style { DART, GLIDE, DRIFT, CRAWL }

## Aceleración máxima, como múltiplo de la velocidad de la especie por segundo.
const ACCEL_FACTOR: float = 3.0
## Pulsos de impulso por segundo.
const BEAT_RATE: float = 1.4
const DART_MIN_THRUST: float = 0.2
const DART_GAIN: float = 1.6
const GLIDE_THRUST: float = 0.9
const GLIDE_WOBBLE: float = 0.1
const DRIFT_THRUST: float = 0.4
const CRAWL_THRUST: float = 0.5
## Empuje máximo posible (el pico de un impulso `dart`).
const MAX_THRUST: float = DART_MIN_THRUST + DART_GAIN
## Los movimientos verticales son más lentos que los horizontales.
const VERTICAL_RATIO: float = 0.45
## Por debajo de esta velocidad horizontal el pez puede darse la vuelta.
const TURN_SPEED: float = 0.4
const SLOW_RADIUS: float = 6.0
const ARRIVE_DISTANCE: float = 0.6
const MIN_TRAVEL: float = 10.0
const RETARGET_MIN: float = 3.0
const RETARGET_MAX: float = 7.0
## Cuántos radianes de onda caben a lo largo del cuerpo.
const WAVE_NUMBER: float = 4.0
const WAVE_BASE_SPEED: float = 0.4
const MAX_TILT: float = 0.6
const MIN_TILT_SPEED: float = 0.5
const TILT_RESPONSE: float = 4.0
## Segundos que se mantiene un destino fijado con [method seek].
const SEEK_HOLD: float = 0.4
## Segundos que dura un giro completo: el pez se aplana de canto (como una moneda,
## o Paper Mario), se da la vuelta en el punto más plano y se abre al otro lado.
const TURN_DURATION: float = 0.45
## Un destino que queda detrás solo provoca un giro si está al menos a esta
## distancia horizontal; si no, el pez no se da la vuelta por tan poco.
const MIN_TURN_DISTANCE: float = 2.5
## Con comida a la vista el pez se da la vuelta aunque esté muy cerca.
const SEEK_TURN_DISTANCE: float = 0.5
## Un bicho de fondo se arrastra en tandas: este es el ritmo de sus pasos.
const CRAWL_STEP_RATE: float = 0.5

## Esquina superior izquierda del sprite, en celdas.
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
## 1 mira a la derecha, -1 a la izquierda.
var facing: int = 1
## Fase de la onda del cuerpo, en radianes.
var phase: float = 0.0
## Zona permitida para la esquina superior izquierda del sprite.
var bounds: Rect2 = Rect2()
var style: Style = Style.GLIDE
var speed: float = 6.0
## Amplitud máxima de la onda, en celdas.
var amplitude: float = 0.15
var frequency: float = 1.2
## Multiplicador de velocidad (un pez triste nada más despacio).
var speed_scale: float = 1.0

var _rng: RandomNumberGenerator
var _target: Vector2 = Vector2.ZERO
var _retarget_in: float = 0.0
var _beat: float = 0.0
var _tilt: float = 0.0
## Segundos de giro transcurridos; negativo si no está girando.
var _turn_time: float = -1.0
var _turn_flipped: bool = false
var _seek_left: float = 0.0


func _init(
	new_rng: RandomNumberGenerator,
	new_style: Style,
	new_speed: float,
	new_amplitude: float,
	new_frequency: float
) -> void:
	_rng = new_rng
	style = new_style
	speed = new_speed
	amplitude = new_amplitude
	frequency = new_frequency


## Fija la zona permitida y mete dentro al pez si se había salido.
func set_bounds(new_bounds: Rect2) -> void:
	bounds = new_bounds
	_confine()
	_retarget_in = 0.0


## Coloca al pez en un punto, un sentido y una fase aleatorios dentro de la zona.
func scatter() -> void:
	position = Vector2(
		_rng.randf_range(bounds.position.x, bounds.end.x),
		_rng.randf_range(bounds.position.y, bounds.end.y)
	)
	if style == Style.CRAWL:
		position.y = bounds.end.y
	facing = 1 if _rng.randf() < 0.5 else -1
	phase = _rng.randf_range(0.0, TAU)
	_beat = _rng.randf()
	_pick_target()


## Avanza el movimiento [param delta] segundos.
func step(delta: float) -> void:
	_retarget_in -= delta
	_seek_left = maxf(_seek_left - delta, 0.0)
	if _retarget_in <= 0.0 or position.distance_to(_target) < ARRIVE_DISTANCE:
		_pick_target()

	var to_target: Vector2 = _target - position
	var distance: float = to_target.length()
	var direction: Vector2 = Vector2.ZERO
	if distance > 0.0001:
		direction = to_target / distance

	var ahead: float = to_target.x * float(facing)
	var turning: bool = _turn_time >= 0.0
	if turning:
		_advance_turn(delta)
	elif -ahead > _turn_distance() and absf(velocity.x) < TURN_SPEED:
		_turn_time = 0.0
		_turn_flipped = false
		turning = true

	var arrive: float = clampf(distance / SLOW_RADIUS, 0.25, 1.0)
	var cruise: float = speed * speed_scale * _thrust(delta) * arrive
	# Un pez solo nada hacia delante: si el destino queda detrás, frena, se da la
	# vuelta y entonces arranca en el otro sentido.
	var forward: float = direction.x if (ahead >= 0.0 and not turning) else 0.0
	var vertical: float = direction.y * VERTICAL_RATIO if style != Style.CRAWL else 0.0
	var desired: Vector2 = Vector2(forward, vertical) * cruise
	velocity = velocity.move_toward(desired, speed * ACCEL_FACTOR * delta)
	if velocity.x * float(facing) < 0.0:
		velocity.x = 0.0
	position += velocity * delta
	if style == Style.CRAWL:
		velocity.y = 0.0
		position.y = bounds.end.y
	_confine()

	var speed_ratio: float = velocity.length() / maxf(speed, 0.001)
	phase += delta * frequency * TAU * (WAVE_BASE_SPEED + speed_ratio)
	_update_tilt(delta)


## Cuánto se ve de ancho el pez ahora, de 0 (de canto, a mitad de un giro) a 1.
func turn_scale() -> float:
	if _turn_time < 0.0:
		return 1.0
	return absf(cos(PI * clampf(_turn_time / TURN_DURATION, 0.0, 1.0)))


## Si el pez está dándose la vuelta.
func is_turning() -> bool:
	return _turn_time >= 0.0


## Dirige al pez hacia [param point] (esquina superior izquierda deseada) durante
## un momento; hay que repetirlo cada fotograma mientras siga habiendo interés.
func seek(point: Vector2) -> void:
	_target = Vector2(
		clampf(point.x, bounds.position.x, bounds.end.x),
		clampf(point.y, bounds.position.y, bounds.end.y)
	)
	_retarget_in = SEEK_HOLD
	_seek_left = SEEK_HOLD


## Desplazamiento vertical, en celdas, de la columna [param column] del sprite
## por la ondulación del cuerpo. Vale 0 en la cabeza y crece hacia la cola.
func body_offset(column: int, width: int) -> float:
	if width <= 1 or amplitude <= 0.0 or style == Style.CRAWL:
		return 0.0
	var along: float = float(column) / float(width - 1)
	var from_head: float = along if facing < 0 else 1.0 - along
	var envelope: float = from_head * from_head
	return sin(phase - from_head * WAVE_NUMBER) * amplitude * envelope


## Desplazamiento vertical, en celdas, de la columna [param column] por la
## inclinación al subir o bajar.
func tilt_offset(column: int, width: int) -> float:
	var from_center: float = float(column) - float(width - 1) * 0.5
	return from_center * float(facing) * _tilt


## A cuántas celdas por detrás tiene que quedar el destino para que merezca un giro.
func _turn_distance() -> float:
	return SEEK_TURN_DISTANCE if _seek_left > 0.0 else MIN_TURN_DISTANCE


func _advance_turn(delta: float) -> void:
	_turn_time += delta
	if not _turn_flipped and _turn_time >= TURN_DURATION * 0.5:
		facing = -facing
		_turn_flipped = true
	if _turn_time >= TURN_DURATION:
		_turn_time = -1.0
		_turn_flipped = false


func _thrust(delta: float) -> float:
	_beat += delta * BEAT_RATE
	var wave: float = sin(_beat * TAU)
	if style == Style.DART:
		var pulse: float = 0.5 + 0.5 * wave
		return DART_MIN_THRUST + DART_GAIN * pulse * pulse
	if style == Style.GLIDE:
		return GLIDE_THRUST + GLIDE_WOBBLE * wave
	if style == Style.DRIFT:
		return DRIFT_THRUST
	# Los bichos de fondo avanzan a pasos: arrancan, se paran y vuelven a arrancar.
	var step: float = 0.5 + 0.5 * sin(_beat * TAU * CRAWL_STEP_RATE)
	return CRAWL_THRUST * 1.6 * step


func _pick_target() -> void:
	var target_x: float = _rng.randf_range(bounds.position.x, bounds.end.x)
	for _attempt: int in range(3):
		if absf(target_x - position.x) >= MIN_TRAVEL:
			break
		target_x = _rng.randf_range(bounds.position.x, bounds.end.x)
	var target_y: float = _rng.randf_range(bounds.position.y, bounds.end.y)
	if style == Style.CRAWL:
		target_y = bounds.end.y
	elif style == Style.DRIFT:
		target_y = clampf(position.y + _rng.randf_range(-2.5, 2.5), bounds.position.y, bounds.end.y)
	_target = Vector2(target_x, target_y)
	_retarget_in = _rng.randf_range(RETARGET_MIN, RETARGET_MAX)


func _confine() -> void:
	var clamped: Vector2 = Vector2(
		clampf(position.x, bounds.position.x, bounds.end.x),
		clampf(position.y, bounds.position.y, bounds.end.y)
	)
	if clamped.x != position.x:
		velocity.x = 0.0
	if clamped.y != position.y:
		velocity.y = 0.0
	position = clamped


func _update_tilt(delta: float) -> void:
	var target_tilt: float = 0.0
	if style != Style.CRAWL and absf(velocity.x) > MIN_TILT_SPEED:
		target_tilt = clampf(velocity.y / absf(velocity.x), -MAX_TILT, MAX_TILT)
	_tilt = lerpf(_tilt, target_tilt, minf(1.0, delta * TILT_RESPONSE))
