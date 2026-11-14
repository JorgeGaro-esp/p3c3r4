class_name FixedDayClock
extends DayClock
## Reloj con la hora fija, para tests y pruebas.

var value: float = 12.0


func _init(start_hour: float = 12.0) -> void:
	super()
	value = start_hour


func hour() -> float:
	return DayCycle.normalize(value + offset_hours)
