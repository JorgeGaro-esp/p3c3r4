class_name Tank
extends RefCounted
## Una pecera: sus peces y su capacidad.

const DEFAULT_CAPACITY: int = 40

var biome_id: String = "pond"
var capacity: int = DEFAULT_CAPACITY
var fish: Array[Fish] = []


func is_full() -> bool:
	return fish.size() >= capacity


## Añade [param new_fish] si hay sitio. Devuelve falso si la pecera está llena.
func add_fish(new_fish: Fish) -> bool:
	if is_full():
		return false
	fish.append(new_fish)
	return true


## Quita [param target]. Devuelve falso si no estaba.
func remove_fish(target: Fish) -> bool:
	var index: int = fish.find(target)
	if index < 0:
		return false
	fish.remove_at(index)
	return true


## Cuántos peces de la especie [param species_id] hay.
func count_of(species_id: String) -> int:
	var total: int = 0
	for item: Fish in fish:
		if item.species_id == species_id:
			total += 1
	return total
