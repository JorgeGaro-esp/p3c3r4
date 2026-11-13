class_name AchievementDef
extends Resource
## Definición de un logro: una condición declarativa sobre una estadística o una
## cifra de la partida, y una recompensa. Añadir uno consiste en crear un recurso
## de este tipo en `content/achievements/` y su nombre en `strings.csv`; la
## descripción se compone sola con la plantilla de su métrica.

## Qué se mide. [constant STAT] lee un contador de [GameStats] (ver
## [member stat_id]); el resto son cifras que se calculan de la partida.
enum Metric {
	STAT,
	TOTAL_EARNED,
	FISH_NOW,
	SPECIES_FOUND,
	VARIANTS_FOUND,
	LEGENDARY_FOUND,
	BIOMES_OPENED,
	DECORATIONS_PLACED,
	PLAY_TIME,
	PRODUCTION_RATE,
	COLLECTION_PERCENT,
}

@export var id: String = ""
## Clave de traducción del nombre (`ACH_FIRST_FISH`).
@export var name_key: String = ""
## Posición en la lista (de menor a mayor).
@export var order: int = 0
@export var metric: Metric = Metric.STAT
## Contador de [GameStats] cuando la métrica es STAT.
@export var stat_id: String = ""
## Limita SPECIES_FOUND y VARIANTS_FOUND a un bioma ("" = todos).
@export var biome_id: String = ""
## Valor que hay que alcanzar (en segundos para PLAY_TIME, 0 a 100 para
## COLLECTION_PERCENT).
@export var target: float = 1.0
## Producción extra permanente, en porcentaje (1,5 = +1,5 %), mientras no se pase
## del tope de [constant Achievements.MAX_BONUS_PERCENT].
@export var reward_percent: float = 0.5
