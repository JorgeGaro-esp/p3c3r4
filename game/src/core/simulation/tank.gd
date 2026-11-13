class_name Tank
extends RefCounted
## Una pecera: sus peces y su capacidad.

const DEFAULT_CAPACITY: int = 40
## Límites al leer una partida (06-SEGURIDAD §3.4).
const MAX_CAPACITY: int = 200

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


func to_dict() -> Dictionary:
	var fish_data: Array = []
	for item: Fish in fish:
		fish_data.append(item.to_dict())
	return {"biome_id": biome_id, "capacity": capacity, "fish": fish_data}


## Lee una pecera de [param source]; null si no es un objeto. Los peces inválidos
## o sobrantes se descartan con aviso.
static func from_dict(source: Variant, content: ContentDB, warnings: PackedStringArray) -> Tank:
	if typeof(source) != TYPE_DICTIONARY:
		warnings.append("pecera: no es un objeto")
		return null
	var data: Dictionary = source
	var tank: Tank = Tank.new()
	tank.biome_id = SaveFields.read_string(data, "biome_id", "pond", warnings)
	tank.capacity = SaveFields.read_int(
		data, "capacity", DEFAULT_CAPACITY, 1, MAX_CAPACITY, warnings
	)
	var raw_fish: Variant = SaveFields.read_array(data, "fish", warnings)
	if raw_fish == null:
		return tank
	var list: Array = raw_fish
	for entry: Variant in list:
		var fish_item: Fish = Fish.from_dict(entry, content, warnings)
		if fish_item == null:
			continue
		if not tank.add_fish(fish_item):
			warnings.append("pez descartado: la pecera está llena")
			break
	return tank
