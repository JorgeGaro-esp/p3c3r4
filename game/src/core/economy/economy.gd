class_name Economy
extends RefCounted
## Fórmulas de la economía (GDD §3.2). Todas son funciones puras: mismos datos,
## mismo resultado, sin estado.

const FISH_COST_GROWTH: float = 1.15
const EQUIPMENT_COST_GROWTH: float = 1.6
const SELL_FACTOR: float = 0.5
const MIN_HAPPINESS_FACTOR: float = 0.25
const MAX_HAPPINESS_FACTOR: float = 1.25
const MAX_HAPPINESS: float = 100.0
## Evita que el ruido de coma flotante (128,00000000000003) suba un coste entero.
const ROUNDING_TOLERANCE: float = 1.0e-9


## Coste del siguiente pez de una especie cuando ya se tienen [param owned].
static func fish_cost(base_cost: float, owned: int) -> float:
	return ceilf(base_cost * pow(FISH_COST_GROWTH, float(maxi(owned, 0))) - ROUNDING_TOLERANCE)


## Coste de subir un equipo al nivel [param level] (el nivel 0 es el primero).
static func equipment_cost(base_cost: float, level: int) -> float:
	return ceilf(base_cost * pow(EQUIPMENT_COST_GROWTH, float(maxi(level, 0))) - ROUNDING_TOLERANCE)


## Valor de venta de un adulto.
static func sale_value(base_cost: float, variant_multiplier: float = 1.0) -> float:
	return floorf(SELL_FACTOR * base_cost * variant_multiplier)


## Multiplicador de producción según la felicidad (0 a 100): de ×0,25 a ×1,25.
static func happiness_factor(happiness: float) -> float:
	var ratio: float = clampf(happiness / MAX_HAPPINESS, 0.0, 1.0)
	return lerpf(MIN_HAPPINESS_FACTOR, MAX_HAPPINESS_FACTOR, ratio)


## Conchas por segundo de un pez adulto.
static func fish_rate(base_rate: float, happiness: float, bonus: float = 1.0) -> float:
	return base_rate * happiness_factor(happiness) * bonus
