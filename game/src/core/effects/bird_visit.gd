class_name BirdVisit
extends RefCounted
## La visita de un pájaro a la superficie de la pecera: espera un rato, llega
## volando, se posa, descansa y se va. Solo es decorado: no toca la partida.
## Lógica pura (sin nodos); [BirdView] la dibuja.

enum Phase { WAITING, ARRIVING, PERCHED, LEAVING }

## Segundos entre visitas (al azar entre ambos).
const MIN_WAIT: float = 100.0
const MAX_WAIT: float = 260.0
const MIN_PERCH: float = 18.0
const MAX_PERCH: float = 40.0
## Celdas por segundo al volar y distancia desde la que llega.
const FLY_SPEED: float = 11.0
const APPROACH: float = 28.0
## Margen (celdas) del posadero respecto a los bordes del mundo.
const EDGE_MARGIN: float = 10.0

var phase: Phase = Phase.WAITING
## Posición (celdas) de la esquina izquierda del dibujo y sentido (1 derecha, -1 izquierda).
var x: float = 0.0
var direction: int = 1
## Segundos que lleva en la fase actual.
var phase_time: float = 0.0

var _wait_left: float = 0.0
var _perch_left: float = 0.0
var _perch_x: float = 0.0
var _world_left: float = 0.0
var _world_right: float = 0.0


## Fija el ancho del mundo (celdas) y reinicia la espera. [param first_wait]
## acorta la primera espera (al cambiar de pecera).
func configure(
	world_left: float, world_right: float, rng: RandomNumberGenerator, first_wait: float = -1.0
) -> void:
	_world_left = world_left
	_world_right = world_right
	phase = Phase.WAITING
	phase_time = 0.0
	_wait_left = first_wait if first_wait >= 0.0 else rng.randf_range(MIN_WAIT, MAX_WAIT)


## Segundos que faltan para la próxima visita (0 si ya hay un pájaro).
func seconds_until_visit() -> float:
	return _wait_left if phase == Phase.WAITING else 0.0


## Si hay un pájaro a la vista (llegando, posado o yéndose).
func is_visible() -> bool:
	return phase != Phase.WAITING


## Si está volando (para elegir el dibujo con las alas).
func is_flying() -> bool:
	return phase == Phase.ARRIVING or phase == Phase.LEAVING


## Hace que llegue un pájaro ahora (herramienta de desarrollo y tests).
func call_bird(rng: RandomNumberGenerator) -> void:
	_wait_left = 0.0
	_start_arrival(rng)


## Avanza [param delta] segundos.
func step(delta: float, rng: RandomNumberGenerator) -> void:
	phase_time += delta
	match phase:
		Phase.WAITING:
			_wait_left -= delta
			if _wait_left <= 0.0:
				_start_arrival(rng)
		Phase.ARRIVING:
			x += float(direction) * FLY_SPEED * delta
			if (_perch_x - x) * float(direction) <= 0.0:
				x = _perch_x
				_set_phase(Phase.PERCHED)
				_perch_left = rng.randf_range(MIN_PERCH, MAX_PERCH)
		Phase.PERCHED:
			_perch_left -= delta
			if _perch_left <= 0.0:
				_set_phase(Phase.LEAVING)
		Phase.LEAVING:
			x += float(direction) * FLY_SPEED * delta
			if x < _world_left - APPROACH or x > _world_right + APPROACH:
				configure(_world_left, _world_right, rng)


func _start_arrival(rng: RandomNumberGenerator) -> void:
	var span: float = maxf(_world_right - _world_left - 2.0 * EDGE_MARGIN, 1.0)
	_perch_x = _world_left + EDGE_MARGIN + rng.randf() * span
	direction = 1 if rng.randf() < 0.5 else -1
	x = _perch_x - float(direction) * APPROACH
	_set_phase(Phase.ARRIVING)


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_time = 0.0
