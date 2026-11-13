class_name SpeciesDef
extends Resource
## Definición de una especie de pez. Añadir una especie consiste en crear un
## sprite en `content/sprites/`, un recurso de este tipo en `content/species/` y
## sus claves de texto en `strings.csv`; no hace falta tocar código.
##
## Los identificadores son estables: las partidas guardadas los referencian, así
## que no se renombran una vez publicados.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Un símbolo por rareza, para no depender solo del color (GDD §4.2).
const RARITY_SYMBOLS: String = "·+*#@"

@export var id: String = ""
## Clave de traducción del nombre (`SPECIES_POND_GUPPY`).
@export var name_key: String = ""
@export var biome_id: String = "pond"
@export var rarity: Rarity = Rarity.COMMON
## Coste del primer pez de esta especie, en conchas.
@export var base_cost: float = 10.0
## Conchas por segundo de un adulto con felicidad máxima, sin bonificaciones.
@export var base_production: float = 0.1
## Ruta del archivo de sprite, por ejemplo `res://content/sprites/test_guppy.txt`.
@export_file("*.txt") var sprite_path: String = ""
## Roles de color (`b`, `t`, `e`, `f`, `d`) y su color, en listas paralelas.
@export var palette_roles: PackedStringArray = PackedStringArray()
@export var palette_colors: PackedColorArray = PackedColorArray()
## Estilo de nado: 0 DART, 1 GLIDE, 2 DRIFT, 3 CRAWL (ver `SwimMotion.Style`).
@export_range(0, 3) var style: int = 1
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


## Símbolo de la rareza de esta especie.
func rarity_symbol() -> String:
	return RARITY_SYMBOLS[clampi(int(rarity), 0, RARITY_SYMBOLS.length() - 1)]
