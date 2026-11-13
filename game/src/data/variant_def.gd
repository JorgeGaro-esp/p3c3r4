class_name VariantDef
extends Resource
## Variante de color de un pez (GDD §6). Solo cambia la paleta, no la forma. Añadir
## una variante consiste en crear un recurso de este tipo en `content/variants/` y
## sus claves de texto en `strings.csv`.

## Aspecto de la variante; [VariantPalette] lo convierte en colores.
enum Look { NONE, ALBINO, MELANISTIC, GOLDEN, PRISMATIC }

## Identificador de la variante normal: siempre debe existir.
const NORMAL_ID: String = "normal"

@export var id: String = ""
## Clave de traducción del nombre (`VARIANT_ALBINO`).
@export var name_key: String = ""
## Peso en el sorteo, en porcentaje de partida (93, 4, 2, 0,9 y 0,1 suman 100).
@export var weight: float = 1.0
## Multiplica el valor de venta (×1, ×3, ×5, ×15, ×50).
@export var sale_multiplier: float = 1.0
@export var look: Look = Look.NONE
