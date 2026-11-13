extends Node
## Señales globales. Las emiten los servicios y las escuchan las vistas.
##
## Nombres en pasado y datos tipados (02-ARQUITECTURA §5). No guarda estado.

## Cambió la cantidad de conchas (no se emite en cada paso, sino una vez por fotograma).
signal shells_changed(shells: float)
## Cambió la producción total, en conchas por segundo.
signal production_changed(rate: float)
## Se añadió un pez a la pecera [param tank_index].
signal fish_added(tank_index: int, fish: Fish)
## Se quitó un pez de la pecera [param tank_index].
signal fish_removed(tank_index: int, fish: Fish)
## Un pez soltó una perla que vale [param value] conchas.
signal pearl_spawned(tank_index: int, fish: Fish, value: float)
## El jugador recogió una perla de [param value] conchas.
signal pearl_collected(value: float)
## Una especie se desbloqueó y ya está en la tienda.
signal species_unlocked(species_id: String)
## Se ha desbloqueado un logro.
signal achievement_unlocked(achievement_id: String)
## El jugador hizo una compra importante (pide un guardado).
signal purchase_made
## Hay algo que contarle al jugador; [param key] es una clave de traducción.
signal notice_requested(key: String)
## El jugador vendió un pez por [param value] conchas.
signal fish_sold(value: float)
## Salió por primera vez una variante de una especie (no se emite para la normal).
signal variant_discovered(species_id: String, variant_id: String)
## Un equipo de la pecera [param tank_index] subió al nivel [param level].
signal equipment_changed(tank_index: int, equipment_id: String, level: int)
## Cambió la decoración o el inventario de decoración de la pecera [param tank_index].
signal decoration_changed(tank_index: int)
## Se ha cambiado de pecera (índice en `GameState.tanks`).
signal active_tank_changed(tank_index: int)
## Se ha abierto la pecera de un bioma nuevo.
signal tank_unlocked(tank_index: int)
