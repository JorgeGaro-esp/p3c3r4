class_name SwimMotion
extends RefCounted
## Movimiento de nado de un pez: impulsos, ondulación del cuerpo, giro suave e
## inclinación (05-GUIA-ARTE-ASCII §6).
##
## Es lógica visual pura: no dibuja nada y recibe el generador aleatorio desde
## fuera, así que con la misma semilla produce siempre el mismo recorrido.
## Las unidades son celdas de la rejilla y segundos.

## Estilos de nado: `dart` a impulsos, `glide` suave, `drift` flotando, `crawl`
## pegado al fondo y `hop` a saltos (las ranas, en tierra).
enum Style { DART, GLIDE, DRIFT, CRAWL, HOP }

## Aceleración máxima, como múltiplo de la velocidad de la especie por segundo.
const ACCEL_FACTOR: float = 3.0
## Con qué rapidez se apaga el empujón de otros peces (por segundo).
const PUSH_DECAY: float = 5.0
## Velocidad máxima del empujón, en celdas por segundo.
const PUSH_MAX: float = 7.0
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
## Un salto dura esto y sube hasta esta altura, en celdas.
const HOP_DURATION: float = 0.6
const HOP_HEIGHT: float = 1.6
## La espera entre saltos es la parada media por estos factores.
const HOP_WAIT_MIN: float = 0.4
const HOP_WAIT_MAX: float = 1.4
## Una parada dura la media por un factor entre estos dos.
const REST_MIN_FACTOR: float = 0.5
const REST_MAX_FACTOR: float = 1.5
## Hasta dónde nota el cursor un pez huidizo (celdas) y cuánto más nada al asustarse.
## Cuánto se ensancha por arriba la franja de profundidad de cada especie (0 = la
## suya exacta, 1 = hasta la superficie). Por abajo todos llegan hasta el fondo.
const BAND_FREEDOM: float = 0.5
## Proporción de velocidad vertical al ir tras comida (si no, [constant VERTICAL_RATIO]).
const SEEK_VERTICAL_RATIO: float = 0.9
const SHY_RADIUS: float = 6.0
const CURIOUS_RADIUS: float = 14.0
## Un curioso se queda a esta distancia del cursor, sin llegar a tocarlo.
const CURIOUS_KEEP: float = 3.0
## Por debajo de este carácter (en valor absoluto) el pez ignora el cursor.
const TEMPERAMENT_MIN: float = 0.3
## Alcance de un susto por clic y lo que dura la huida, en celdas y segundos.
const STARTLE_RADIUS: float = 12.0
const STARTLE_SECONDS: float = 1.2
const FLEE_DISTANCE: float = 14.0
const FLEE_BOOST: float = 2.0
## Dormido, el pez nada hasta esta fracción más despacio y se para casi siempre.
const SLEEP_SLOWDOWN: float = 0.6
const SLEEP_REST_CHANCE: float = 0.85
const SLEEP_REST_STRETCH: float = 2.0
## Cuánto se hunde hacia el fondo un pez dormido (0 nada, 1 del todo).
const SLEEP_SINK: float = 0.8
## Sueño por encima del cual el pez no hace caso del cursor.
const SLEEP_DEEP: float = 0.7
## Un pez de banco vuelve hacia el centro de sus compañeros si se aleja más que esto.
const SCHOOL_RADIUS: float = 5.0
## Los de banco cambian de destino más a menudo, para seguirse unos a otros.
const SCHOOL_RETARGET_MAX: float = 3.0
## Cuánto se desvía cada pez del centro del banco, en celdas.
const SCHOOL_SPREAD: float = 3.0

## Esquina superior izquierda del sprite, en celdas.
var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
## 1 mira a la derecha, -1 a la izquierda.
var facing: int = 1
## Fase de la onda del cuerpo, en radianes.
var phase: float = 0.0
## Zona permitida para la esquina superior izquierda del sprite.
var bounds: Rect2 = Rect2()
## Toda el agua nadable (sin recortar por profundidad). Un pez que va tras comida
## puede salir de su franja y bajar o subir hasta ella.
var full_bounds: Rect2 = Rect2()
var style: Style = Style.GLIDE
var speed: float = 6.0
## Amplitud máxima de la onda, en celdas.
var amplitude: float = 0.15
var frequency: float = 1.2
## Multiplicador de velocidad (un pez triste nada más despacio).
var speed_scale: float = 1.0
## Radianes de onda a lo largo del cuerpo: una anguila serpentea más que un atún.
var wave_number: float = WAVE_NUMBER
## Segundos que dura un giro; los peces grandes giran más despacio.
var turn_seconds: float = TURN_DURATION
## Cuánto tira del pez el centro de su banco (0 nada solo, 1 siempre pegado).
var school_pull: float = 0.0
## Franja de profundidad que ocupa, de 0 (superficie) a 1 (fondo).
var depth_min: float = 0.0
var depth_max: float = 1.0
## Probabilidad de pararse al llegar a un destino y segundos medios de la parada.
var rest_chance: float = 0.0
var rest_seconds: float = 3.0
## Carácter ante el cursor, de -1 (huidizo) a 1 (curioso).
var temperament: float = 0.0
## Sueño actual, de 0 (despierto) a 1 (dormido del todo).
var sleepiness: float = 0.0

var _rng: RandomNumberGenerator
var _target: Vector2 = Vector2.ZERO
var _retarget_in: float = 0.0
var _beat: float = 0.0
var _tilt: float = 0.0
## Segundos de giro transcurridos; negativo si no está girando.
var _turn_time: float = -1.0
var _turn_flipped: bool = false
var _seek_left: float = 0.0
var _school_center: Vector2 = Vector2.ZERO
var _has_school: bool = false
var _school_offset: Vector2 = Vector2.ZERO
var _rest_left: float = 0.0
## Segundos que lleva en el aire un salto; negativo si está posado.
var _hop_time: float = -1.0
var _hop_wait: float = 0.0
var _startle_left: float = 0.0
## Velocidad extra que le dan otros peces al apartarlo (celdas por segundo).
var _push: Vector2 = Vector2.ZERO


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
func set_bounds(new_bounds: Rect2, full: Rect2 = Rect2()) -> void:
	bounds = new_bounds
	full_bounds = full if full.size != Vector2.ZERO else new_bounds
	_confine()
	_retarget_in = 0.0


## Coloca al pez en un punto, un sentido y una fase aleatorios dentro de la zona.
## Con [param zone] (por ejemplo lo que ve la cámara) elige el punto dentro de la
## parte de la zona que cae en esa región.
func scatter(zone: Rect2 = Rect2()) -> void:
	var area: Rect2 = bounds
	if zone.has_area():
		var clipped: Rect2 = bounds.intersection(zone)
		if clipped.has_area():
			area = clipped
	position = Vector2(
		_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y)
	)
	if _is_grounded():
		position.y = bounds.end.y
	_hop_wait = _rng.randf_range(HOP_WAIT_MIN, HOP_WAIT_MAX) * rest_seconds
	_school_offset = Vector2(
		_rng.randf_range(-SCHOOL_SPREAD, SCHOOL_SPREAD),
		_rng.randf_range(-SCHOOL_SPREAD, SCHOOL_SPREAD) * 0.5
	)
	facing = 1 if _rng.randf() < 0.5 else -1
	phase = _rng.randf_range(0.0, TAU)
	_beat = _rng.randf()
	_pick_target()


## Avanza el movimiento [param delta] segundos.
func step(delta: float) -> void:
	_retarget_in -= delta
	_seek_left = maxf(_seek_left - delta, 0.0)
	_startle_left = maxf(_startle_left - delta, 0.0)
	var fleeing: bool = _startle_left > 0.0
	if (_retarget_in <= 0.0 and not fleeing) or position.distance_to(_target) < ARRIVE_DISTANCE:
		_pick_target()
	_follow_school()

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

	if style == Style.HOP:
		_step_hop(delta, ahead, turning)
		return
	var resting: bool = _rest_left > 0.0
	_rest_left = maxf(_rest_left - delta, 0.0)
	var arrive: float = clampf(distance / SLOW_RADIUS, 0.25, 1.0)
	var cruise: float = speed * _pace() * _thrust(delta) * arrive
	# Un pez solo nada hacia delante: si el destino queda detrás, frena, se da la
	# vuelta y entonces arranca en el otro sentido.
	var forward: float = direction.x if (ahead >= 0.0 and not turning) else 0.0
	var vertical_ratio: float = SEEK_VERTICAL_RATIO if _seek_left > 0.0 else VERTICAL_RATIO
	var vertical: float = direction.y * vertical_ratio if style != Style.CRAWL else 0.0
	var desired: Vector2 = Vector2(forward, vertical) * cruise
	if resting:
		desired = Vector2.ZERO
	velocity = velocity.move_toward(desired, speed * ACCEL_FACTOR * delta)
	if velocity.x * float(facing) < 0.0:
		velocity.x = 0.0
	position += velocity * delta
	position += _push_step(delta)
	if style == Style.CRAWL:
		velocity.y = 0.0
		position.y = bounds.end.y
	_confine()

	var speed_ratio: float = velocity.length() / maxf(speed, 0.001)
	phase += delta * frequency * TAU * (WAVE_BASE_SPEED + speed_ratio)
	_update_tilt(delta)


## Aparta al pez de otro: [param away_speed] es la velocidad (celdas por segundo)
## a la que debería alejarse y [param interval] los segundos desde la última vez
## que se llamó. Hay que repetirlo mientras sigan solapados.
func push(away_speed: Vector2, interval: float) -> void:
	_push += away_speed * PUSH_DECAY * interval
	if _push.length() > PUSH_MAX:
		_push = _push.normalized() * PUSH_MAX


## Cuánto se desplaza el pez por el empujón en [param delta] segundos.
func _push_step(delta: float) -> Vector2:
	var moved: Vector2 = _push * delta
	_push *= maxf(1.0 - PUSH_DECAY * delta, 0.0)
	return moved


## Indica dónde está el centro del banco (el de los peces de su especie). Con
## [member school_pull] a 0 no tiene efecto.
func set_school_center(center: Vector2) -> void:
	_school_center = center
	_has_school = true


## Fija el sueño actual (0 despierto, 1 dormido del todo).
func set_sleepiness(value: float) -> void:
	sleepiness = clampf(value, 0.0, 1.0)


## Si el pez está parado descansando.
func is_resting() -> bool:
	return _rest_left > 0.0 or (style == Style.HOP and _hop_time < 0.0 and sleepiness > 0.5)


## El cursor está en [param cursor] y el pez tiene la boca en [param mouth] (ambos
## en celdas del mundo). Un huidizo se aparta si el cursor se acerca; un curioso se
## acerca hasta una distancia prudente. Hay que llamarlo cada fotograma.
func react_to_cursor(cursor: Vector2, mouth: Vector2) -> void:
	if absf(temperament) < TEMPERAMENT_MIN or sleepiness >= SLEEP_DEEP:
		return
	var distance: float = mouth.distance_to(cursor)
	if temperament < 0.0:
		if distance < SHY_RADIUS * absf(temperament) + 2.0:
			_flee_from(cursor, mouth, 0.0)
	elif distance < CURIOUS_RADIUS and distance > CURIOUS_KEEP and _seek_left <= 0.0:
		seek(position + (cursor - mouth))


## Un clic en [param origin]: los peces huidizos cercanos salen huyendo.
func startle(origin: Vector2, mouth: Vector2) -> void:
	if temperament > -TEMPERAMENT_MIN or mouth.distance_to(origin) > STARTLE_RADIUS:
		return
	_flee_from(origin, mouth, STARTLE_SECONDS)


## Si el pez está huyendo de un susto.
func is_startled() -> bool:
	return _startle_left > 0.0


func _flee_from(origin: Vector2, mouth: Vector2, boost_seconds: float) -> void:
	var away: Vector2 = mouth - origin
	if away.length() < 0.001:
		away = Vector2(float(facing), 0.0)
	var goal: Vector2 = position + away.normalized() * FLEE_DISTANCE
	seek(goal)
	if boost_seconds > 0.0:
		_startle_left = boost_seconds


## Cuánto se mueve el pez respecto a su velocidad: ánimo, sueño y sustos.
func _pace() -> float:
	var pace: float = speed_scale * (1.0 - SLEEP_SLOWDOWN * sleepiness)
	if _startle_left > 0.0:
		pace *= FLEE_BOOST
	return pace


func _hop_pause() -> float:
	var stretch: float = 1.0 + sleepiness * SLEEP_REST_STRETCH
	return _rng.randf_range(HOP_WAIT_MIN, HOP_WAIT_MAX) * rest_seconds * stretch


## Cuánto se ve de ancho el pez ahora, de 0 (de canto, a mitad de un giro) a 1.
func turn_scale() -> float:
	if _turn_time < 0.0:
		return 1.0
	return absf(cos(PI * clampf(_turn_time / turn_seconds, 0.0, 1.0)))


## Si el pez está dándose la vuelta.
func is_turning() -> bool:
	return _turn_time >= 0.0


## Dirige al pez hacia [param point] (esquina superior izquierda deseada) durante
## un momento; hay que repetirlo cada fotograma mientras siga habiendo interés.
func seek(point: Vector2) -> void:
	var area: Rect2 = full_bounds if not _is_grounded() else bounds
	_target = Vector2(
		clampf(point.x, area.position.x, area.end.x), clampf(point.y, area.position.y, area.end.y)
	)
	_retarget_in = SEEK_HOLD
	_seek_left = SEEK_HOLD
	_rest_left = 0.0
	_hop_wait = 0.0


## Desplazamiento vertical, en celdas, de la columna [param column] del sprite
## por la ondulación del cuerpo. Vale 0 en la cabeza y crece hacia la cola.
func body_offset(column: int, width: int) -> float:
	if width <= 1 or amplitude <= 0.0 or _is_grounded():
		return 0.0
	var along: float = float(column) / float(width - 1)
	var from_head: float = along if facing < 0 else 1.0 - along
	var envelope: float = from_head * from_head
	return sin(phase - from_head * wave_number) * amplitude * envelope * MotionScale.factor()


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
	if not _turn_flipped and _turn_time >= turn_seconds * 0.5:
		facing = -facing
		_turn_flipped = true
	if _turn_time >= turn_seconds:
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
	if _is_grounded():
		target_y = bounds.end.y
	elif style == Style.DRIFT:
		target_y = clampf(position.y + _rng.randf_range(-2.5, 2.5), bounds.position.y, bounds.end.y)
	_target = Vector2(target_x, target_y)
	var retarget_max: float = RETARGET_MAX
	if school_pull > 0.0:
		retarget_max = SCHOOL_RETARGET_MAX
	_retarget_in = _rng.randf_range(RETARGET_MIN, maxf(retarget_max, RETARGET_MIN))
	if not _is_grounded():
		_target.y = lerpf(_target.y, bounds.end.y, sleepiness * SLEEP_SINK)
	var chance: float = maxf(rest_chance, sleepiness * SLEEP_REST_CHANCE)
	if chance > 0.0 and _rng.randf() < chance:
		var stretch: float = 1.0 + sleepiness * SLEEP_REST_STRETCH
		_rest_left = rest_seconds * stretch * _rng.randf_range(REST_MIN_FACTOR, REST_MAX_FACTOR)
	if school_pull > 0.0 and _has_school:
		_target = _target.lerp(_school_target(), school_pull)


## Punto del banco al que le toca ir a este pez (el centro más su desvío propio).
func _school_target() -> Vector2:
	var point: Vector2 = _school_center + _school_offset
	return Vector2(
		clampf(point.x, bounds.position.x, bounds.end.x),
		clampf(point.y, bounds.position.y, bounds.end.y)
	)


## Un pez de banco que se queda atrás vuelve con los demás (si no hay comida a la vista).
func _follow_school() -> void:
	if school_pull <= 0.0 or not _has_school or _seek_left > 0.0:
		return
	if position.distance_to(_school_center) > SCHOOL_RADIUS / maxf(school_pull, 0.2):
		_target = _school_target()


## Zona de [param zone] que corresponde a la franja de profundidad de esta especie.
## Los que van pegados al suelo conservan el fondo.
func band_of(zone: Rect2) -> Rect2:
	var low: float = clampf(depth_min, 0.0, 1.0)
	var high: float = clampf(maxf(depth_max, low), 0.0, 1.0)
	low *= 1.0 - BAND_FREEDOM
	high = 1.0
	var top: float = zone.position.y + zone.size.y * low
	return Rect2(zone.position.x, top, zone.size.x, zone.size.y * (high - low))


## Si el pez va pegado al suelo (a pie o a saltos).
func _is_grounded() -> bool:
	return style == Style.CRAWL or style == Style.HOP


## Un salto: el animal espera posado, se da la vuelta si hace falta y salta hacia
## su destino en un arco.
func _step_hop(delta: float, ahead: float, turning: bool) -> void:
	if _hop_time >= 0.0:
		_hop_time += delta
		var progress: float = clampf(_hop_time / HOP_DURATION, 0.0, 1.0)
		position.x += velocity.x * delta
		position.y = bounds.end.y - HOP_HEIGHT * 4.0 * progress * (1.0 - progress)
		if progress >= 1.0:
			_hop_time = -1.0
			velocity = Vector2.ZERO
			position.y = bounds.end.y
			_hop_wait = _hop_pause()
	else:
		velocity = Vector2.ZERO
		position.y = bounds.end.y
		_hop_wait -= delta
		if _hop_wait <= 0.0 and ahead > ARRIVE_DISTANCE and not turning:
			_hop_time = 0.0
			velocity.x = float(facing) * speed * _pace()
	var clamped_x: float = clampf(position.x, bounds.position.x, bounds.end.x)
	if clamped_x != position.x:
		position.x = clamped_x
		velocity.x = 0.0
	phase += delta * frequency * TAU * WAVE_BASE_SPEED
	_tilt = 0.0


func _confine() -> void:
	# Persiguiendo algo (comida), el pez puede salirse de su franja de profundidad.
	var area: Rect2 = full_bounds if (_seek_left > 0.0 and not _is_grounded()) else bounds
	var clamped: Vector2 = Vector2(
		clampf(position.x, area.position.x, area.end.x),
		clampf(position.y, area.position.y, area.end.y)
	)
	if clamped.x != position.x:
		velocity.x = 0.0
	if clamped.y != position.y:
		velocity.y = 0.0
	position = clamped


func _update_tilt(delta: float) -> void:
	var target_tilt: float = 0.0
	if not _is_grounded() and absf(velocity.x) > MIN_TILT_SPEED:
		target_tilt = clampf(velocity.y / absf(velocity.x), -MAX_TILT, MAX_TILT)
	_tilt = lerpf(_tilt, target_tilt, minf(1.0, delta * TILT_RESPONSE))
