class_name TankBonuses
extends RefCounted
## Bonificaciones de una pecera sumando todo su equipo. Se calculan (no se guardan)
## cada vez que cambia el equipo; sin equipo, todo vale lo neutro.

## Límite de la rebaja de suciedad del filtro: nunca llega a cero.
const MIN_DIRT_FACTOR: float = 0.2
## Limpieza por segundo y nivel que recupera el filtro por sí solo.
const FILTER_REGEN_PER_LEVEL: float = 0.006
## Segundos entre comidas del comedero con un nivel, y saciedad que da cada una.
const FEEDER_BASE_SECONDS: float = 300.0
const FEEDER_AMOUNT: float = 30.0
## Cuánto sube cada nivel de incubadora el peso de las variantes raras.
const RARE_PER_LEVEL: float = 0.4
## Segundos que espera una perla en el suelo antes de que el imán la recoja (nivel 1).
const MAGNET_BASE_SECONDS: float = 24.0
## Máximo de la comodidad (fracción de felicidad que falta para el 100).
const MAX_COMFORT: float = 0.9

## Multiplica la suciedad que producen los peces (1 sin filtro).
var dirt_factor: float = 1.0
## Limpieza que se recupera por segundo.
var clean_regen: float = 0.0
## Segundos entre comidas del comedero (0 si no hay).
var feed_interval: float = 0.0
var feed_amount: float = 0.0
## Fracción de la felicidad que falta para 100 que cubre el calentador.
var comfort: float = 0.0
## Multiplica la velocidad de crecimiento.
var growth_speed: float = 1.0
var capacity_bonus: int = 0
## Multiplica la velocidad de eclosión.
var hatch_speed: float = 1.0
## Multiplica el peso de las variantes que no son la normal.
var rare_multiplier: float = 1.0
## Segundos hasta que el imán recoge una perla (0 si no hay).
var magnet_delay: float = 0.0


## Calcula las bonificaciones de [param levels] (id de equipo → nivel).
static func compute(levels: Dictionary[String, int], content: ContentDB) -> TankBonuses:
	var result: TankBonuses = TankBonuses.new()
	for equipment_id: String in levels:
		var def: EquipmentDef = content.get_equipment(equipment_id)
		var level: int = clampi(levels[equipment_id], 0, 99)
		if def != null and level > 0:
			result._apply(def, mini(level, def.max_level))
	return result


func _apply(def: EquipmentDef, level: int) -> void:
	var strength: float = def.per_level * float(level)
	match def.effect:
		EquipmentDef.Effect.FILTER:
			dirt_factor = maxf(dirt_factor - strength, MIN_DIRT_FACTOR)
			clean_regen += FILTER_REGEN_PER_LEVEL * float(level)
		EquipmentDef.Effect.FEEDER:
			feed_interval = FEEDER_BASE_SECONDS / maxf(strength, 0.001)
			feed_amount = FEEDER_AMOUNT
		EquipmentDef.Effect.HEATER:
			comfort = minf(comfort + strength, MAX_COMFORT)
		EquipmentDef.Effect.LAMP:
			growth_speed += strength
		EquipmentDef.Effect.AERATOR:
			capacity_bonus += roundi(strength)
		EquipmentDef.Effect.INCUBATOR:
			hatch_speed += strength
			rare_multiplier += RARE_PER_LEVEL * float(level)
		EquipmentDef.Effect.PEARL_MAGNET:
			magnet_delay = MAGNET_BASE_SECONDS / maxf(strength, 0.001)
