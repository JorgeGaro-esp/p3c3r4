class_name SpeciesDef
extends Resource
## Definición de una especie de pez. Añadir una especie consiste en crear un
## sprite en `content/sprites/`, un recurso de este tipo en `content/species/` y
## sus claves de texto en `strings.csv`; no hace falta tocar código.
##
## Los identificadores son estables: las partidas guardadas los referencian, así
## que no se renombran una vez publicados.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Qué hay que cumplir para que la especie aparezca en la tienda (GDD §4.2).
## Una vez cumplido, la especie queda desbloqueada para siempre.
enum UnlockKind {
	NONE,  ## Disponible desde el principio.
	TOTAL_EARNED,  ## Conchas ganadas en total >= `unlock_amount`.
	FISH_COUNT,  ## Peces en total >= `unlock_amount`.
	SPECIES_COUNT,  ## Peces de `unlock_species_id` >= `unlock_amount`.
	DECORATION_TAG,  ## Objetos colocados con la etiqueta `unlock_tag` >= `unlock_amount`.
}
## Cuándo está más activa la especie (Fase 12): las nocturnas producen más de noche,
## las diurnas más de día, y las neutras igual a todas horas.
enum Activity { NEUTRAL, DIURNAL, NOCTURNAL }
## Un símbolo por rareza, para no depender solo del color (GDD §4.2).
const RARITY_SYMBOLS: String = "·+*#@"

@export var id: String = ""
## Clave de traducción del nombre (`SPECIES_POND_GUPPY`).
@export var name_key: String = ""
## Clave de traducción de la descripción (`SPECIES_POND_GUPPY_DESC`).
@export var description_key: String = ""
@export var biome_id: String = "pond"
@export var rarity: Rarity = Rarity.COMMON
@export var activity: Activity = Activity.NEUTRAL
## Coste del primer pez de esta especie, en conchas.
@export var base_cost: float = 10.0
## Conchas por segundo de un adulto con felicidad máxima, sin bonificaciones.
@export var base_production: float = 0.1
@export var unlock_kind: UnlockKind = UnlockKind.NONE
@export var unlock_amount: float = 0.0
## Solo para `SPECIES_COUNT`: la especie que hay que tener.
@export var unlock_species_id: String = ""
@export var unlock_tag: String = ""
## Ruta del archivo de sprite, por ejemplo `res://content/sprites/test_guppy.txt`.
@export_file("*.txt") var sprite_path: String = ""
## Roles de color (`b`, `t`, `e`, `f`, `d`) y su color, en listas paralelas.
@export var palette_roles: PackedStringArray = PackedStringArray()
@export var palette_colors: PackedColorArray = PackedColorArray()
## Segundos que tarda un alevín en ser adulto.
@export var growth_seconds: float = 120.0
## Segundos que tarda una pareja en poner un huevo.
@export var breed_seconds: float = 180.0
## Segundos que tarda un huevo en eclosionar.
@export var hatch_seconds: float = 30.0
## Sprites de alevín y juvenil. Vacíos, se usan los genéricos de `content/sprites/`.
@export_file("*.txt") var fry_sprite_path: String = ""
@export_file("*.txt") var juvenile_sprite_path: String = ""
## Estilo de nado: 0 DART, 1 GLIDE, 2 DRIFT, 3 CRAWL, 4 HOP (ver `SwimMotion.Style`).
@export_range(0, 4) var style: int = 1
## Velocidad de crucero, en celdas por segundo.
@export var speed: float = 6.0
## Amplitud máxima de la onda del cuerpo, en celdas.
@export var amplitude: float = 0.15
## Ondulaciones por segundo.
@export var frequency: float = 1.2
## Radianes de onda a lo largo del cuerpo (1 rígido, 8 serpenteante como una anguila).
@export_range(1.0, 12.0) var wave_number: float = 4.0
## Cuánto tiende el pez a nadar con los de su especie (0 solo, 1 banco muy unido).
@export_range(0.0, 1.0) var school_pull: float = 0.0
## Franja de profundidad donde vive, de 0 (superficie) a 1 (fondo): el siluro va al
## fondo y el arawana junto a la superficie.
@export_range(0.0, 1.0) var depth_min: float = 0.0
@export_range(0.0, 1.0) var depth_max: float = 1.0
## Probabilidad de quedarse parado al llegar a un destino (el rape emboscado casi
## siempre; el tiburón nunca) y segundos medios que dura la parada.
@export_range(0.0, 1.0) var rest_chance: float = 0.0
@export_range(0.5, 20.0) var rest_seconds: float = 3.0
## Carácter ante el cursor y los clics: de -1 (huidizo, se aparta) a 1 (curioso, se
## acerca). Con 0 no le importa.
@export_range(-1.0, 1.0) var temperament: float = 0.0
## Segundos que dura cada fotograma de la animación.
@export var frame_duration: float = 0.4


## Construye la paleta de esta definición.
func build_palette() -> AsciiPalette:
	return AsciiPalette.from_arrays(palette_roles, palette_colors)


## Símbolo de la rareza de esta especie.
func rarity_symbol() -> String:
	return RARITY_SYMBOLS[clampi(int(rarity), 0, RARITY_SYMBOLS.length() - 1)]
