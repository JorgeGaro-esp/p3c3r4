class_name EventReward
extends RefCounted
## Lo que da cobrar un evento: conchas y, a veces, un objeto de decoración.

var shells: float = 0.0
var decoration_id: String = ""


func _init(new_shells: float = 0.0, new_decoration_id: String = "") -> void:
	shells = new_shells
	decoration_id = new_decoration_id
