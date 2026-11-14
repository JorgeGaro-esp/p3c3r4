class_name DayClock
extends RefCounted
## Reloj del día. Devuelve la hora local del sistema (0 a 24, con decimales). Es la
## única pieza que lee el reloj real: se inyecta en [DaylightDirector] y los tests
## la sustituyen por [FixedDayClock].
##
## No da ventaja por cambiar la hora del sistema: solo mueve la franja del día y
## con ella un ajuste suave de la producción; nunca "salta" tiempo de juego.

## Variable de entorno que fuerza la hora (para probar sin cambiar el reloj del
## sistema): `set P3C3R4_HOUR=23` en cmd antes de lanzar el juego.
const ENV_HOUR: String = "P3C3R4_HOUR"

## Horas que se suman a la hora del sistema (herramienta de desarrollo, F6).
var offset_hours: float = 0.0

var _forced_hour: float = -1.0


func _init() -> void:
	var text: String = OS.get_environment(ENV_HOUR)
	if text.is_valid_float():
		_forced_hour = DayCycle.normalize(text.to_float())


## Hora actual, de 0 (incluido) a 24 (excluido).
func hour() -> float:
	if _forced_hour >= 0.0:
		return DayCycle.normalize(_forced_hour + offset_hours)
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var hours: int = now.get("hour", 12)
	var minutes: int = now.get("minute", 0)
	var seconds: int = now.get("second", 0)
	var total: float = float(hours) + float(minutes) / 60.0 + float(seconds) / 3600.0
	return DayCycle.normalize(total + offset_hours)
