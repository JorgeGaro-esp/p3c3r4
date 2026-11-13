class_name HatchEvent
extends RefCounted
## Un huevo que acaba de eclosionar. La simulación lo deja en la cola de
## [GameState] y `Game` lo publica para que las vistas dibujen al pez nuevo.

var tank_index: int = 0
var fish: Fish = null


func _init(new_tank_index: int, new_fish: Fish) -> void:
	tank_index = new_tank_index
	fish = new_fish
