class_name DaylightDirector
extends RefCounted
## El día y la noche como parte de la partida: lee la hora del reloj inyectado,
## pone la oscuridad en el estado (que ajusta la producción) y avisa al cambiar de
## franja. Cuelga de `Game.daylight`.

## Horas que avanza la herramienta de desarrollo (F6).
const DEBUG_STEP_HOURS: float = 1.0

## Reloj que da la hora. Los tests lo cambian por un [FixedDayClock].
var clock: DayClock = DayClock.new()

var _game: GameService = null
var _phase: int = -1


func _init(game: GameService) -> void:
	_game = game


## Hora de ahora (0 a 24).
func hour() -> float:
	return clock.hour()


## Franja de ahora.
func phase() -> DayCycle.Phase:
	return DayCycle.phase_at(clock.hour())


## Lee el reloj y actualiza el estado. Con [param announce] avisa si cambió la
## franja (al cargar una partida no se avisa).
func refresh(announce: bool = true) -> void:
	var hour_now: float = clock.hour()
	_game.state.set_darkness(DayCycle.darkness(hour_now))
	var phase_now: int = DayCycle.phase_at(hour_now)
	if phase_now == _phase:
		return
	var first: bool = _phase < 0
	_phase = phase_now
	if announce and not first:
		EventBus.phase_changed.emit(phase_now)


## Herramienta de desarrollo (F6): adelanta el reloj una hora.
func debug_advance() -> void:
	clock.offset_hours += DEBUG_STEP_HOURS
	refresh(true)
