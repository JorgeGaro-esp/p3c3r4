class_name GameState
extends RefCounted
## Estado completo de la partida: la raíz del modelo (02-ARQUITECTURA §3.1).
##
## Más sistemas colgarán de aquí en fases posteriores (Pecedex, logros, prestigio).

var wallet: Wallet = Wallet.new()
var tanks: Array[Tank] = [Tank.new()]
var sim_time: float = 0.0
var rng_seed: int = 0
## Producción total en conchas por segundo; se recalcula solo si cambia algo.
var production_rate: float = 0.0
## Verdadero cuando hay que recalcular [member production_rate].
var production_dirty: bool = true


## Avisa de que compra, venta o cambio de felicidad alteran la producción.
func mark_production_dirty() -> void:
	production_dirty = true


## Total de peces en todas las peceras.
func fish_total() -> int:
	var total: int = 0
	for tank: Tank in tanks:
		total += tank.fish.size()
	return total
