class_name SwimmerDef
extends Resource
## Definición de un pez de prueba: qué sprite usa, de qué colores y cómo nada.
##
## Es el germen de `SpeciesDef` (Fase 3). Añadir un pez consiste en crear un
## sprite en `content/sprites/` y un recurso de este tipo en `content/species/`;
## no hace falta tocar código de dibujo.

@export var id: String = ""
## Ruta del archivo de sprite, por ejemplo `res://content/sprites/test_guppy.txt`.
@export_file("*.txt") var sprite_path: String = ""
## Roles de color (`b`, `t`, `e`, `f`, `d`) y su color, en listas paralelas.
@export var palette_roles: PackedStringArray = PackedStringArray()
@export var palette_colors: PackedColorArray = PackedColorArray()
@export var style: SwimMotion.Style = SwimMotion.Style.GLIDE
## Velocidad de crucero, en celdas por segundo.
@export var speed: float = 6.0
## Amplitud máxima de la onda del cuerpo, en celdas.
@export var amplitude: float = 0.15
## Ondulaciones por segundo.
@export var frequency: float = 1.2
## Segundos que dura cada fotograma de la animación.
@export var frame_duration: float = 0.4


## Construye la paleta de esta definición.
func build_palette() -> AsciiPalette:
	return AsciiPalette.from_arrays(palette_roles, palette_colors)
