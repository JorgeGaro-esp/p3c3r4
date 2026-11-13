class_name DecorationDef
extends Resource
## Objeto decorativo que el jugador coloca en la pecera (GDD §8). Añadir uno
## consiste en crear un recurso de este tipo en `content/decorations/`, su sprite y
## sus claves de texto.

## Capa de dibujo: detrás o delante de los peces.
enum Layer { BACK, FRONT }
## Dónde se puede colocar: solo en el suelo, o también flotando en el agua.
enum Anchor { FLOOR, WATER }
## Qué bonificación da.
enum Bonus { COMFORT, PRODUCTION, RARE_VARIANT }

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var layer: Layer = Layer.BACK
@export var anchor: Anchor = Anchor.FLOOR
@export var bonus: Bonus = Bonus.COMFORT
## Cuánto da: fracción de comodidad, fracción extra de producción o peso extra de
## variantes raras (ver [TankBonuses]).
@export var amount: float = 0.0
## Etiqueta que algunas especies piden para desbloquearse (por ejemplo `cave`).
@export var tag: String = ""
## Bioma en el que se vende ("" si vale para todos).
@export var biome_id: String = ""
@export var base_cost: float = 50.0
@export var sprite_path: String = ""
## Tamaño en celdas; una prueba comprueba que coincide con el sprite.
@export var cells_wide: int = 1
@export var cells_high: int = 1
@export var palette_roles: PackedStringArray = PackedStringArray()
@export var palette_colors: PackedColorArray = PackedColorArray()
@export var frame_duration: float = 0.6


func build_palette() -> AsciiPalette:
	return AsciiPalette.from_arrays(palette_roles, palette_colors)
