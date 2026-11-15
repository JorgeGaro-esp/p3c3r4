class_name BiomeDef
extends Resource
## Definición de un bioma: una pecera con su propio aspecto (GDD §9). Añadir uno
## consiste en crear un recurso de este tipo en `content/biomes/` y sus claves de
## texto; las especies lo eligen con [member SpeciesDef.biome_id].

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
## Posición en la fila de pestañas (de menor a mayor).
@export var order: int = 0
## Conchas que cuesta abrir la pecera de este bioma (0 si se tiene desde el principio).
@export var unlock_cost: float = 0.0
## Bioma que hay que tener antes ("" si ninguno).
@export var requires_biome_id: String = ""

@export_group("Superficie y suelo")
@export var surface_pattern: String = "~^~^"
@export var surface_color: Color = Color(0.2471, 0.6549, 1.0)
@export var sand_grains: String = ".:,.'.·.,"
@export var sand_color: Color = Color(0.7608, 0.651, 0.4196)
## Piedrecitas, conchas… que salpican la arena ("" si no hay) y su color.
@export var sand_accents: String = ""
@export var sand_accent_color: Color = Color(0.85, 0.8, 0.7)

@export_group("Plantas")
## Dos caracteres que se alternan por segmento (izquierda y derecha).
@export var weed_chars: String = "()"
@export var weed_light: Color = Color(0.1804, 0.8, 0.4431)
@export var weed_dark: Color = Color(0.1176, 0.5569, 0.3059)
## Separación entre plantas: 1 es la normal, más es más escasas.
@export var weed_gap_scale: float = 1.0
## Remates que lucen algunas plantas en la punta (flores, bulbos…) y su color ("" si no hay).
@export var weed_tips: String = ""
@export var weed_tip_color: Color = Color(1.0, 0.8, 0.4)
## Colores extra: cada planta elige uno de la paleta (luz; la sombra se oscurece sola)
## y cada remate otro de la paleta de remates. Vacías: se usan los colores de arriba.
@export var weed_palette: PackedColorArray = PackedColorArray()
@export var weed_tip_palette: PackedColorArray = PackedColorArray()
## Formas de planta (`tipo|caracteres`, ver [WeedForm]). Cada planta elige una al azar,
## así que repetir una forma la hace más frecuente. Vacío: solo tallos de `weed_chars`.
@export var weed_forms: PackedStringArray = PackedStringArray()

@export_group("Ambiente")
@export var bubble_color: Color = Color(0.6039, 0.8471, 1.0)
## Carácter de relleno del fondo del agua ("" si no hay) y la fracción de celdas que ocupa.
@export var backdrop_char: String = ""
@export var backdrop_color: Color = Color(0.1, 0.2, 0.3)
@export_range(0.0, 0.3) var backdrop_density: float = 0.0
## Partículas flotantes: caracteres posibles, color, cuántas hay y su caída en
## celdas por segundo (negativa, suben).
@export var particle_chars: String = ""
@export var particle_color: Color = Color(0.8, 0.8, 0.8)
@export_range(0, 60) var particle_count: int = 0
@export var particle_fall: float = 0.0

@export_group("Visitante del cielo")
## Dibujos del pájaro del bioma mirando a la derecha; las filas se separan con `|`.
## Posado (dos posturas) y volando (dos posiciones de las alas). Vacío: sin pájaro.
@export var bird_perch_a: String = ""
@export var bird_perch_b: String = ""
@export var bird_fly_a: String = ""
@export var bird_fly_b: String = ""
@export var bird_color: Color = Color(0.9, 0.9, 0.9)
