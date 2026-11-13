class_name Fish
extends RefCounted
## Un pez del modelo. Solo datos de juego: el dibujo vive en `FishView`.
##
## Las etapas de vida y la variante de color llegan en la Fase 7; por ahora todos
## los peces son adultos.

var species_id: String = ""
## 0 (muy triste) a 100 (radiante). Los cuidados la modificarán en la Fase 6.
var happiness: float = 100.0


func _init(new_species_id: String = "") -> void:
	species_id = new_species_id
