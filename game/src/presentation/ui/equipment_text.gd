class_name EquipmentText
extends RefCounted
## Texto de lo que hace un equipo a un nivel dado, a partir de [TankBonuses]. Solo
## formatea: los números salen del núcleo, así la tienda nunca los inventa.


## Frase del efecto de [param def] al nivel [param level] (con el nivel 0, el efecto
## del primer nivel, que es lo que se compraría).
static func effect(def: EquipmentDef, level: int, content: ContentDB) -> String:
	var shown: int = maxi(level, 1)
	var levels: Dictionary[String, int] = {def.id: shown}
	var bonus: TankBonuses = TankBonuses.compute(levels, content)
	var key: String = "EQ_EFFECT_%s" % EquipmentDef.Effect.keys()[def.effect]
	match def.effect:
		EquipmentDef.Effect.FILTER:
			var cut: int = roundi((1.0 - bonus.dirt_factor) * 100.0)
			var per_minute: float = bonus.clean_regen * 60.0
			return TranslationServer.translate(key) % [cut, _number(per_minute)]
		EquipmentDef.Effect.FEEDER:
			return TranslationServer.translate(key) % _number(bonus.feed_interval)
		EquipmentDef.Effect.HEATER:
			return TranslationServer.translate(key) % roundi(bonus.comfort * 100.0)
		EquipmentDef.Effect.LAMP:
			return TranslationServer.translate(key) % _number(bonus.growth_speed)
		EquipmentDef.Effect.AERATOR:
			return TranslationServer.translate(key) % bonus.capacity_bonus
		EquipmentDef.Effect.INCUBATOR:
			var pair: Array = [_number(bonus.hatch_speed), _number(bonus.rare_multiplier)]
			return TranslationServer.translate(key) % pair
		EquipmentDef.Effect.PEARL_MAGNET:
			return TranslationServer.translate(key) % _number(bonus.magnet_delay)
		_:
			return ""


static func _number(value: float) -> String:
	return String.num(snappedf(value, 0.01))
