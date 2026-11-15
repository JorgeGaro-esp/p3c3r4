class_name TitleText
extends RefCounted
## Textos de la pantalla de título: el resumen de cada ranura de guardado.

const SECONDS_PER_HOUR: int = 3600
const SECONDS_PER_MINUTE: int = 60


## Duración de juego como «12 h 05 min».
static func play_time(seconds: float) -> String:
	var total: int = maxi(int(seconds), 0)
	var hours: int = total / SECONDS_PER_HOUR
	var minutes: int = (total / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	return "%d h %02d min" % [hours, minutes]


## Línea de una ranura: «Ranura 1 · 79,4 k conchas · 23 peces · 12 h 05 min».
## [param info] viene de [method SaveController.slot_info].
static func slot_line(slot: int, info: Dictionary, locale: String) -> String:
	var head: String = TranslationServer.translate("TITLE_SLOT") % slot
	var exists: bool = info.get("exists", false)
	if not exists:
		return "%s · %s" % [head, TranslationServer.translate("TITLE_SLOT_EMPTY")]
	var damaged: bool = info.get("damaged", false)
	if damaged:
		return "%s · %s" % [head, TranslationServer.translate("TITLE_SLOT_DAMAGED")]
	var shells: float = info.get("shells", 0.0)
	var fish: int = info.get("fish", 0)
	var seconds: float = info.get("time", 0.0)
	var stats: String = (
		TranslationServer.translate("TITLE_SLOT_STATS")
		% [NumberFormat.compact(shells, locale), fish, play_time(seconds)]
	)
	return "%s · %s" % [head, stats]
