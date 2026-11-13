class_name DecorationText
extends RefCounted
## Texto de la bonificación de un objeto de decoración.


static func bonus(def: DecorationDef) -> String:
	var percent: String = String.num(snappedf(def.amount * 100.0, 0.1))
	var key: String = "BONUS_COMFORT"
	match def.bonus:
		DecorationDef.Bonus.PRODUCTION:
			key = "BONUS_PRODUCTION"
		DecorationDef.Bonus.RARE_VARIANT:
			key = "BONUS_RARE"
		_:
			pass
	return TranslationServer.translate(key) % percent
