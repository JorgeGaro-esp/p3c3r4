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
## El jugador hizo una compra importante (pide un guardado).
signal purchase_made
## Hay algo que contarle al jugador; [param key] es una clave de traducción.
signal notice_requested(key: String)
