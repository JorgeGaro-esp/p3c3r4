class_name PrestigeUpgradeDef
extends Resource
## Mejora permanente de la Gran marea (GDD §13): se compra con perlas negras y
## sobrevive a los reinicios. Añadir una consiste en crear un recurso de este tipo
## en `content/prestige/` y sus claves de texto en `strings.csv`.

## Qué mejora. El efecto de cada nivel lo calcula [Prestige].
enum Kind {
	## Producción de todas las peceras: +[member per_level] (fracción) por nivel.
	PRODUCTION,
	## Conchas con las que empieza cada ciclo: [member per_level] × 3^(nivel − 1).
	HEAD_START,
	## Peso de las variantes raras: +[member per_level] (fracción) por nivel.
	VARIANT_LUCK,
	## Valor de las perlas que se recogen: +[member per_level] (fracción) por nivel.
	PEARL_VALUE,
}

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var kind: Kind = Kind.PRODUCTION
@export var max_level: int = 10
## Perlas negras que cuesta el primer nivel.
@export var base_cost: int = 1
## Cuánto sube el coste con cada nivel (1,5 = un 50 % más).
@export var cost_growth: float = 1.5
## Efecto de un nivel (ver [enum Kind]).
@export var per_level: float = 0.1
