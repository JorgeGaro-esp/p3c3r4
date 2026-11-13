class_name EquipmentDef
extends Resource
## Equipo mejorable de la pecera (GDD §7). Añadir uno consiste en crear un recurso
## de este tipo en `content/equipment/`, su sprite y sus claves de texto.

## Qué hace el equipo. [TankBonuses] convierte nivel y efecto en números.
enum Effect { FILTER, FEEDER, HEATER, LAMP, AERATOR, INCUBATOR, PEARL_MAGNET }
## Dónde se dibuja dentro de la pecera.
enum Placement { SURFACE, FLOOR, WALL_LEFT, WALL_RIGHT }

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var effect: Effect = Effect.FILTER
@export var max_level: int = 5
## Coste del nivel 1; el siguiente cuesta ×1,6 ([method Economy.equipment_cost]).
@export var base_cost: float = 100.0
## Fuerza del efecto por nivel (su significado depende de [member effect]).
@export var per_level: float = 1.0
@export var sprite_path: String = ""
@export var palette_roles: PackedStringArray = PackedStringArray()
@export var palette_colors: PackedColorArray = PackedColorArray()
@export var placement: Placement = Placement.FLOOR
## Posición horizontal como fracción del ancho de la pecera (0 a 1).
@export var place_x: float = 0.5
@export var frame_duration: float = 0.5


func build_palette() -> AsciiPalette:
	return AsciiPalette.from_arrays(palette_roles, palette_colors)
