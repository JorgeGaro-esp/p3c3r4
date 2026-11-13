class_name PearlSpawn
extends RefCounted
## Aviso de que un pez ha soltado una perla. La simulación los deja en una cola
## y `Game` los publica; la vista dibuja la perla y el jugador la recoge.

var tank_index: int = 0
var fish: Fish = null
## Conchas que da al recogerla.
var value: float = 0.0


func _init(new_tank_index: int, new_fish: Fish, new_value: float) -> void:
	tank_index = new_tank_index
	fish = new_fish
	value = new_value
