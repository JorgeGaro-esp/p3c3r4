class_name ImageFishView
extends FishView
## Pez dibujado con imágenes en lugar de caracteres sueltos.
##
## Usa una máscara PNG (glifos blancos sobre transparente) por cada rol de color
## de la paleta, generada a partir del sprite de texto con la misma fuente. El
## pez se corta en tiras verticales finas; cada tira se desplaza según la
## ondulación de su [SwimMotion] (ondulación por píxel, no por carácter), se
## encoge al girar y se tiñe con el color de la paleta, la variante y el ánimo.
##
## El sprite de texto que recibe el constructor sigue mandando en el tamaño
## (en celdas), los puntos de anclaje y las miniaturas.
##
## Alevines y juveniles usan las mismas máscaras que el adulto: solo cambia el
## tamaño ([constant STAGE_SCALES]).

## Carpeta de las máscaras: `<carpeta>/<id_especie>_<rol>.png`.
const MASK_DIR: String = "res://content/sprites_png/"
const ROLES: String = "btdfe"
## Tamaño de la celda con la que se generaron las máscaras, en píxeles.
const REF_CELL: Vector2 = Vector2(19.265625, 38.0)
## Ancho de cada tira, en píxeles de la máscara.
const STRIP_PX: int = 3
## Tamaño del pez respecto al de las máscaras (1 = original, 0,8 = un 80 %).
const BODY_SCALE: float = 0.8
## Tamaño propio de cada especie respecto a su sprite (1 si no aparece aquí).
## Pendiente máxima (altura/ancho en píxeles) de la inclinación al subir o bajar.
## Con más, el pez se estira en diagonal y se deforma; el resto se recorta.
const MAX_TILT_SLOPE: float = 0.35
const SPECIES_SCALES: Dictionary[String, float] = {"reef_anchovy": 0.6, "pond_wels": 1.0}
## Tamaño de cada etapa respecto al adulto (1 = igual).
const STAGE_SCALES: Dictionary[LifeStage.Stage, float] = {
	LifeStage.Stage.FRY: 0.4,
	LifeStage.Stage.JUVENILE: 0.7,
	LifeStage.Stage.ADULT: 1.0,
}

## Largo (en celdas) de la parte que ondula en las especies que solo mueven una
## zona del final del cuerpo, como los tentáculos del calamar. El resto va rígido.
const TAIL_ONLY_CELLS: Dictionary[String, float] = {"reef_squid": 2.0}
## Celdas en las que la zona que ondula se funde con la rígida.
const TAIL_ONLY_FADE: float = 1.0

var _text_width: int = 1
## 0 = ondula todo el cuerpo; si no, solo esas celdas del final.
var _tail_only: float = 0.0
## BODY_SCALE por el tamaño de la etapa.
var _scale: float = BODY_SCALE
var _strip_count: int = 0
var _mask_width_cells: float = 1.0
var _strip_height_px: float = 1.0
var _role_names: PackedStringArray = PackedStringArray()
var _role_base: PackedColorArray = PackedColorArray()
var _role_right: Array[Texture2D] = []
var _role_left: Array[Texture2D] = []
## Segundo dibujo de un rol (`<especie>_<rol>2.png`), o null. El pez alterna entre
## el primero y este al aletear, como los dos fotogramas de un sprite de texto.
var _role_alt_right: Array[Texture2D] = []
var _role_alt_left: Array[Texture2D] = []
## Por rol: qué tiras tienen algo que dibujar.
var _role_strips: Array[PackedByteArray] = []
## Por rol: color actual de cada tira.
var _role_colors: Array[PackedColorArray] = []
var _applied_desaturation: float = -1.0


## ¿Hay máscaras para [param species_id]? Sin ellas se usa el pez de texto.
static func has_masks(species_id: String) -> bool:
	return ResourceLoader.exists(_mask_path(species_id, "b"))


## Tamaño relativo de [param stage] (el adulto es 1).
static func species_scale(species_id: String) -> float:
	if SPECIES_SCALES.has(species_id):
		return SPECIES_SCALES[species_id]
	return 1.0


static func stage_scale(stage: LifeStage.Stage) -> float:
	if STAGE_SCALES.has(stage):
		return STAGE_SCALES[stage]
	return 1.0


static func _mask_path(species_id: String, role: String) -> String:
	return "%s%s_%s.png" % [MASK_DIR, species_id, role]


func _init(
	species_id: String,
	sprite: AsciiSprite,
	palette: AsciiPalette,
	swim: SwimMotion,
	new_frame_duration: float,
	variant_look: VariantDef.Look = VariantDef.Look.NONE,
	size_factor: float = 1.0
) -> void:
	super._init(sprite, palette, swim, new_frame_duration, variant_look)
	# El sprite de texto es el tamaño completo; el pez ocupa BODY_SCALE de él.
	_text_width = sprite.width
	if TAIL_ONLY_CELLS.has(species_id):
		_tail_only = TAIL_ONLY_CELLS[species_id]
	_scale = BODY_SCALE * size_factor * species_scale(species_id)
	width = maxi(roundi(float(sprite.width) * _scale), 1)
	height = maxi(roundi(float(sprite.height) * _scale), 1)
	for index: int in range(ROLES.length()):
		var role: String = ROLES[index]
		var path: String = _mask_path(species_id, role)
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path) as Texture2D
		if texture == null:
			continue
		var alt_path: String = _mask_path(species_id, role + "2")
		var alt: Texture2D = null
		if ResourceLoader.exists(alt_path):
			alt = load(alt_path) as Texture2D
		_add_role(role, texture, palette.color_for(role), alt)
	_recolor(0.0)


## `true` si se cargó alguna máscara y el pez se puede dibujar con ellas.
func is_ready() -> bool:
	return not _role_names.is_empty()


func draw(canvas: AsciiCanvas) -> void:
	if not is_ready():
		super.draw(canvas)
		return
	var cell: Vector2 = canvas.cell_size
	var pixel_scale: Vector2 = cell / REF_CELL * _scale
	var strip_cells: float = float(STRIP_PX) / REF_CELL.x
	var squash: float = motion.turn_scale()
	var half: float = _mask_width_cells * 0.5
	var facing_right: bool = motion.facing > 0
	var origin: Vector2 = motion.position
	var dest_height: float = _strip_height_px * pixel_scale.y
	# Inclinación limitada y, para que el pez no se alargue, el cuerpo se acorta en
	# horizontal lo que se estira en diagonal.
	var tilt_step: float = motion.tilt_offset(1, 2) - motion.tilt_offset(0, 2)
	var slope: float = tilt_step * cell.y / cell.x
	var tilt_scale: float = clampf(MAX_TILT_SLOPE / maxf(absf(slope), 0.0001), 0.0, 1.0)
	slope *= tilt_scale
	var along: float = 1.0 / sqrt(1.0 + slope * slope)
	for strip: int in range(_strip_count):
		var left_cell: float = float(strip * STRIP_PX) / REF_CELL.x
		var centre: float = left_cell + strip_cells * 0.5
		var wave: float = _wave_at(centre, tilt_scale)
		var across: float = (half + (left_cell - half) * squash * along) * _scale
		var dest: Rect2 = Rect2(
			(origin.x + across) * cell.x,
			(origin.y + wave) * cell.y,
			strip_cells * squash * along * _scale * cell.x,
			dest_height
		)
		var source: Rect2 = Rect2(
			float(strip * STRIP_PX), 0.0, float(STRIP_PX), _strip_height_px
		)
		for role_index: int in range(_role_names.size()):
			if _role_strips[role_index][strip] == 0:
				continue
			var texture: Texture2D = (
				_role_right[role_index] if facing_right else _role_left[role_index]
			)
			var alt_texture: Texture2D = (
				_role_alt_right[role_index] if facing_right else _role_alt_left[role_index]
			)
			# El segundo dibujo del ojo es el párpado; el de los demás roles, el otro aleteo.
			var use_alt: bool = (
				blinking if _role_names[role_index] == "e" else _frame_index % 2 == 1
			)
			if alt_texture != null and use_alt:
				texture = alt_texture
			canvas.draw_texture_rect_region(
				texture, dest, source, _role_colors[role_index][strip]
			)


func set_mood(happiness: float) -> void:
	super.set_mood(happiness)
	if _desaturation != _applied_desaturation and is_ready():
		_recolor(_animated_clock)


## Los colores de las tiras se recalculan con los del sprite de texto (variante
## animada y ánimo) para que ambos aspectos cambien a la vez.
func _retint(time: float) -> void:
	super._retint(time)
	if is_ready():
		_recolor(time)


## Desplazamiento vertical, en celdas, de la tira centrada en [param centre]
## (en celdas de sprite): mezcla las dos columnas vecinas para ondular suave.
func _wave_at(centre: float, tilt_scale: float = 1.0) -> float:
	var low: int = clampi(floori(centre), 0, _text_width - 1)
	var high: int = mini(low + 1, _text_width - 1)
	var mix: float = clampf(centre - float(low), 0.0, 1.0)
	var first: float = (
		motion.body_offset(low, _text_width) + motion.tilt_offset(low, _text_width) * tilt_scale
	)
	var second: float = (
		motion.body_offset(high, _text_width) + motion.tilt_offset(high, _text_width) * tilt_scale
	)
	var wave: float = lerpf(first, second, mix)
	if _tail_only > 0.0:
		# Distancia al final del cuerpo (la cola va detrás: a la izquierda si mira a la derecha).
		var from_tail: float = centre if motion.facing > 0 else _mask_width_cells - centre
		wave *= clampf((_tail_only + TAIL_ONLY_FADE - from_tail) / TAIL_ONLY_FADE, 0.0, 1.0)
	return wave


func _add_role(role: String, texture: Texture2D, color: Color, alt: Texture2D = null) -> void:
	var image: Image = texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var mirror: Image = image.duplicate() as Image
	mirror.flip_x()
	if _role_names.is_empty():
		_strip_height_px = float(image.get_height())
		_mask_width_cells = float(image.get_width()) / REF_CELL.x
		_strip_count = ceili(float(image.get_width()) / float(STRIP_PX))
	var used: PackedByteArray = PackedByteArray()
	used.resize(_strip_count)
	for strip: int in range(_strip_count):
		var x: int = strip * STRIP_PX
		var w: int = mini(STRIP_PX, image.get_width() - x)
		var piece: Image = image.get_region(Rect2i(x, 0, w, image.get_height()))
		used[strip] = 0 if piece.is_invisible() else 1
	var used_mirror: PackedByteArray = PackedByteArray()
	used_mirror.resize(_strip_count)
	for strip: int in range(_strip_count):
		var x: int = strip * STRIP_PX
		var w: int = mini(STRIP_PX, mirror.get_width() - x)
		var piece: Image = mirror.get_region(Rect2i(x, 0, w, mirror.get_height()))
		used_mirror[strip] = 0 if piece.is_invisible() else 1
	_role_names.append(role)
	_role_base.append(color)
	_role_right.append(texture)
	_role_left.append(ImageTexture.create_from_image(mirror))
	if alt != null and alt.get_image() != null:
		var alt_image: Image = alt.get_image()
		if alt_image.is_compressed():
			alt_image.decompress()
		var alt_mirror: Image = alt_image.duplicate() as Image
		alt_mirror.flip_x()
		_role_alt_right.append(alt)
		_role_alt_left.append(ImageTexture.create_from_image(alt_mirror))
		# Una tira se dibuja si tiene algo en cualquiera de los dos dibujos.
		for strip: int in range(_strip_count):
			var x: int = strip * STRIP_PX
			var w: int = mini(STRIP_PX, alt_image.get_width() - x)
			if (
				not alt_image.get_region(Rect2i(x, 0, w, alt_image.get_height())).is_invisible()
				or not alt_mirror.get_region(Rect2i(x, 0, w, alt_mirror.get_height())).is_invisible()
			):
				used[strip] = 1
	else:
		_role_alt_right.append(null)
		_role_alt_left.append(null)
	# Una tira cuenta como usada si lo está en cualquiera de los dos sentidos.
	for strip: int in range(_strip_count):
		if used_mirror[strip] != 0:
			used[strip] = 1
	_role_strips.append(used)
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(_strip_count)
	_role_colors.append(colors)


## Recalcula el color de cada tira: paleta, variante en el instante [param time]
## y pérdida de color por el ánimo.
func _recolor(time: float) -> void:
	_applied_desaturation = _desaturation
	for role_index: int in range(_role_names.size()):
		var source: Color = _role_base[role_index]
		var colors: PackedColorArray = _role_colors[role_index]
		for strip: int in range(_strip_count):
			var column: float = float(strip * STRIP_PX) / REF_CELL.x
			var tinted: Color = VariantPalette.tint(source, _look, time, column * PRISM_SPREAD)
			var gray: float = tinted.get_luminance()
			colors[strip] = tinted.lerp(Color(gray, gray, gray, tinted.a), _desaturation)
		_role_colors[role_index] = colors


## Anclaje del sprite de texto llevado a la escala del pez.
func anchor_cell(anchor_name: String) -> Vector2:
	return motion.position + (super.anchor_cell(anchor_name) - motion.position) * _scale
