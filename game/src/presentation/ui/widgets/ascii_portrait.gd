class_name AsciiPortrait
extends AsciiWidget
## Retrato de un pez: su sprite animado, quieto en el centro del recuadro, como una
## pecera en miniatura: el pez nada despacio dentro del recuadro con un [SwimMotion]
## de verdad (onda del cuerpo, inclinación y giros al llegar al borde).
##
## Si el pez no se ha descubierto, enseña su silueta (bloques) sin animar. Si se han
## tenido varias variantes de color, las va mostrando una tras otra con su nombre.

## Cada cuántos segundos pasa a la siguiente variante.
const VARIANT_SECONDS: float = 2.5
## Desfase de tono entre columnas contiguas de una variante prismática.
const PRISM_SPREAD: float = 0.08
const SILHOUETTE_CHAR: String = "▓"
## Velocidad de nado respecto a la de la especie: el recuadro es pequeño y a la
## velocidad de la pecera rebotaría sin parar.
const SWIM_SPEED_SCALE: float = 0.22
## La onda se exagera algo: en un recuadro pequeño la de la pecera apenas se ve.
const WAVE_GAIN: float = 3.0
const MAX_WAVE: float = 0.9
## Con imágenes (ver [ImageFishView]) la onda es por píxel y se ve sin exagerarla tanto.
const IMAGE_WAVE_GAIN: float = 1.5
const IMAGE_MAX_WAVE: float = 0.35
## Tamaños (respecto al adulto) que prueba el retrato con imágenes hasta que cabe.
const IMAGE_FACTORS: Array[float] = [1.0, 0.7, 0.4]
## Pestañeo del retrato: cada cuántos segundos y cuánto dura.
const BLINK_EVERY: float = 4.0
const BLINK_SECONDS: float = 0.15
## Cada cuántos segundos se recalcula el color de una variante animada.
const TINT_STEP: float = 0.1
## Marco de la «foto»: esquinas y lados.
const FRAME_CORNERS: String = "┌┐└┘"
const FRAME_HORIZONTAL: String = "─"
const FRAME_VERTICAL: String = "│"

static var _widest_cache: int = -1

## Si dibuja un marco de foto alrededor (el pez nada dentro de él).
var has_frame: bool = true
var frame_color: Color = AsciiColors.TEXT_DIM

var _species_id: String = ""
var _sprite: AsciiSprite = null
var _palette: AsciiPalette = null
var _frame_duration: float = 0.4
var _looks: Array[VariantDef.Look] = []
var _names: PackedStringArray = PackedStringArray()
var _clock: float = 0.0
var _motion: SwimMotion = null
var _mirrored: AsciiSprite = null
var _bounds: Rect2 = Rect2()
var _sprites: Dictionary[String, AsciiSprite] = {}
## Peces de imagen ya creados, por variante y tamaño.
var _images: Dictionary[String, ImageFishView] = {}
var _last_tint: float = 0.0


## Enseña a [param def]. Con [param looks] vacío dibuja la silueta; si no, cada
## aspecto con su nombre de [param names] (misma longitud).
func show_species(def: SpeciesDef, looks: Array[VariantDef.Look], names: PackedStringArray) -> void:
	var changed: bool = def.id != _species_id or looks != _looks
	_species_id = def.id
	_looks = looks.duplicate()
	_names = names
	_frame_duration = maxf(def.frame_duration, 0.05)
	_palette = def.build_palette()
	_sprite = _fitting_sprite(def)
	_mirrored = _sprite.mirrored() if _sprite != null else null
	if changed:
		_images.clear()
	if changed or _motion == null:
		_clock = 0.0
		_motion = SwimMotion.new(
			RandomNumberGenerator.new(),
			def.style as SwimMotion.Style,
			def.speed,
			(
				minf(def.amplitude * IMAGE_WAVE_GAIN, IMAGE_MAX_WAVE)
				if ImageFishView.has_masks(def.id)
				else minf(def.amplitude * WAVE_GAIN, MAX_WAVE)
			),
			def.frequency
		)
		_motion.speed_scale = SWIM_SPEED_SCALE
		_bounds = Rect2(-1.0, -1.0, 0.0, 0.0)
		_motion.scatter()


## Quita el retrato.
func clear() -> void:
	_species_id = ""
	_sprite = null
	_images.clear()
	_looks = []
	_names = PackedStringArray()


## Variante que se está viendo ahora (índice en la lista dada a [method show_species]).
func current_index() -> int:
	if _looks.is_empty():
		return -1
	return int(_clock / VARIANT_SECONDS) % _looks.size()


## Ancho del sprite que se enseña ahora (0 sin retrato).
func shown_width() -> int:
	return 0 if _sprite == null else _sprite.width


## Si se dibuja la silueta (el pez no se ha descubierto).
func is_silhouette() -> bool:
	return _sprite != null and _looks.is_empty()


## Desplazamiento vertical actual de la cola, en celdas.
func tail_offset() -> float:
	if _motion == null or _sprite == null:
		return 0.0
	var column: int = 0 if _motion.facing > 0 else _sprite.width - 1
	return _motion.body_offset(column, _sprite.width)


## Desplazamiento vertical actual de la cabeza (siempre 0).
func head_offset() -> float:
	if _motion == null or _sprite == null:
		return 0.0
	var column: int = _sprite.width - 1 if _motion.facing > 0 else 0
	return _motion.body_offset(column, _sprite.width)


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if is_shown and _sprite != null and _motion != null:
		_clock += delta
		_fit_bounds()
		_motion.step(delta)


func draw(canvas: AsciiCanvas) -> void:
	if _sprite == null:
		return
	_draw_frame(canvas)
	var area: Rect2i = _inner()
	var fish_size: Vector2i = _fish_size()
	if area.size.x < fish_size.x or area.size.y < fish_size.y:
		return
	var caption_rows: int = _caption_rows()
	if _looks.is_empty():
		var origin: Vector2i = (
			area.position
			+ Vector2i(
				(area.size.x - _sprite.width) / 2, (area.size.y - caption_rows - _sprite.height) / 2
			)
		)
		_draw_silhouette(canvas, origin)
		return
	_fit_bounds()
	var origin_cell: Vector2 = Vector2(area.position) + _motion.position
	if not _draw_image(canvas, origin_cell):
		_draw_sprite(canvas, origin_cell)
	_draw_caption(canvas)


## Zona donde se ve el pez: el rectángulo menos el marco.
func _inner() -> Rect2i:
	return rect.grow(-1) if has_frame else rect


func _draw_frame(canvas: AsciiCanvas) -> void:
	if not has_frame or rect.size.x < 3 or rect.size.y < 3:
		return
	var left: float = float(rect.position.x)
	var top: float = float(rect.position.y)
	var right: float = float(rect.end.x - 1)
	var bottom: float = float(rect.end.y - 1)
	var middle: int = rect.size.x - 2
	canvas.put_string(
		FRAME_CORNERS[0] + FRAME_HORIZONTAL.repeat(middle) + FRAME_CORNERS[1],
		Vector2(left, top),
		frame_color
	)
	canvas.put_string(
		FRAME_CORNERS[2] + FRAME_HORIZONTAL.repeat(middle) + FRAME_CORNERS[3],
		Vector2(left, bottom),
		frame_color
	)
	for row: int in range(1, rect.size.y - 1):
		canvas.put_char(FRAME_VERTICAL, Vector2(left, top + float(row)), frame_color)
		canvas.put_char(FRAME_VERTICAL, Vector2(right, top + float(row)), frame_color)


## Filas que ocupa el nombre de la variante bajo el pez.
func _caption_rows() -> int:
	if not _looks.is_empty() and _inner().size.y > _fish_size().y:
		return 1
	return 0


## Ajusta la zona de nado al recuadro y al tamaño del sprite si han cambiado.
func _fit_bounds() -> void:
	var inner: Rect2i = _inner()
	var area: Rect2 = Rect2(
		0.0,
		0.0,
		float(maxi(inner.size.x - _fish_size().x, 0)),
		float(maxi(inner.size.y - _caption_rows() - _fish_size().y, 0))
	)
	if area == _bounds:
		return
	var first: bool = _bounds.position.x < 0.0
	_bounds = area
	_motion.set_bounds(area)
	if first:
		_motion.position = area.get_center()


func _draw_silhouette(canvas: AsciiCanvas, origin: Vector2i) -> void:
	var lines: PackedStringArray = _sprite.frames[0]
	for row: int in range(lines.size()):
		for column: int in range(lines[row].length()):
			if lines[row][column] != " ":
				canvas.put_char(
					SILHOUETTE_CHAR, Vector2(origin + Vector2i(column, row)), AsciiColors.TEXT_DIM
				)


func _draw_sprite(canvas: AsciiCanvas, origin: Vector2) -> void:
	var shown: AsciiSprite = _sprite if _motion.facing > 0 else _mirrored
	var frame: int = int(_clock / _frame_duration) % shown.frame_count()
	var look: VariantDef.Look = _looks[current_index()]
	var lines: PackedStringArray = shown.frames[frame]
	var color_lines: PackedStringArray = shown.colors[frame]
	var inner: Rect2i = _inner()
	var top: float = float(inner.position.y)
	var bottom: float = float(inner.end.y - _caption_rows() - 1)
	var squash: float = _motion.turn_scale()
	var half: float = float(shown.width - 1) * 0.5
	for row: int in range(lines.size()):
		for column: int in range(lines[row].length()):
			var character: String = lines[row][column]
			if character == " ":
				continue
			var role: String = color_lines[row][column]
			if role == " ":
				role = AsciiSprite.DEFAULT_COLOR_ROLE
			var color: Color = _palette.color_for(role)
			if look != VariantDef.Look.NONE:
				var phase: float = float(column) * PRISM_SPREAD
				color = VariantPalette.tint(color, look, _clock, phase)
			if character == AsciiSprite.OPAQUE_MARKER:
				continue
			if role == "e":
				character = FishView.EYE_CLOSED if _is_blinking() else FishView.EYE_OPEN
			var wave: float = (
				_motion.body_offset(column, shown.width) + _motion.tilt_offset(column, shown.width)
			)
			var y: float = clampf(origin.y + float(row) + wave, top, bottom)
			var across: float = half + (float(column) - half) * squash
			if squash < FishView.EDGE_ON_SCALE:
				character = FishView.EDGE_CHARACTER
			canvas.put_char(character, Vector2(origin.x + across, y), color)


## Si el pez tiene los ojos cerrados en este instante del retrato.
func _is_blinking() -> bool:
	return fmod(_clock, BLINK_EVERY) < BLINK_SECONDS


## Si el pez se dibuja con imágenes en lugar de caracteres.
func _uses_images() -> bool:
	return _sprite != null and ImageFishView.has_masks(_species_id)


## Tamaño en celdas con el que se ve el pez ahora (el de su sprite, o el de la
## imagen ya escalada para que quepa).
func _fish_size() -> Vector2i:
	if not _uses_images():
		return Vector2i(_sprite.width, _sprite.height)
	return _image_size(_image_factor())


func _image_size(factor: float) -> Vector2i:
	var body: float = (
		ImageFishView.BODY_SCALE * factor * ImageFishView.species_scale(_species_id)
	)
	return Vector2i(
		maxi(roundi(float(_sprite.width) * body), 1), maxi(roundi(float(_sprite.height) * body), 1)
	)


## El mayor tamaño (respecto al adulto) con el que el pez cabe en el recuadro,
## dejando una fila para el nombre de la variante.
func _image_factor() -> float:
	var inner: Rect2i = _inner()
	for factor: float in IMAGE_FACTORS:
		var size: Vector2i = _image_size(factor)
		if inner.size.x >= size.x and inner.size.y - 1 >= size.y:
			return factor
	return IMAGE_FACTORS[IMAGE_FACTORS.size() - 1]


## Dibuja el pez con sus imágenes en [param origin]. Devuelve `false` si no hay
## (entonces se dibuja con caracteres).
func _draw_image(canvas: AsciiCanvas, origin: Vector2) -> bool:
	if not _uses_images():
		return false
	var index: int = current_index()
	var factor: float = _image_factor()
	var key: String = "%d_%s" % [index, str(factor)]
	if not _images.has(key):
		var view: ImageFishView = ImageFishView.new(
			_species_id, _sprite, _palette, _motion, _frame_duration, _looks[index], factor
		)
		_images[key] = view
	var fish: ImageFishView = _images[key]
	if not fish.is_ready():
		return false
	if VariantPalette.is_animated(_looks[index]) and _clock - _last_tint >= TINT_STEP:
		_last_tint = _clock
		fish.retint_at(_clock)
	var saved: Vector2 = _motion.position
	_motion.position = origin
	fish.blinking = _is_blinking()
	fish.draw(canvas)
	_motion.position = saved
	return true


func _draw_caption(canvas: AsciiCanvas) -> void:
	var index: int = current_index()
	var inner: Rect2i = _inner()
	if index < 0 or index >= _names.size() or inner.size.y <= _fish_size().y:
		return
	var text: String = UiText.fit(_names[index], inner.size.x)
	var x: int = inner.position.x + maxi((inner.size.x - text.length()) / 2, 0)
	canvas.put_string(text, Vector2(x, inner.end.y - 1), AsciiColors.TEXT_DIM)


## El sprite adulto si cabe en el recuadro; si no, el juvenil o la cría, y como último
## recurso el adulto (se dibuja recortado). Así nunca queda el recuadro vacío.
func _fitting_sprite(def: SpeciesDef) -> AsciiSprite:
	var adult: AsciiSprite = _sprite_for(def.sprite_path)
	# Con imágenes siempre se usa el adulto (el tamaño se ajusta aparte).
	if adult == null or _fits(adult) or ImageFishView.has_masks(def.id):
		return adult
	for path: String in [def.juvenile_sprite_path, def.fry_sprite_path]:
		var smaller: AsciiSprite = _sprite_for(path)
		if smaller != null and _fits(smaller):
			return smaller
	return adult


func _fits(sprite: AsciiSprite) -> bool:
	var area: Rect2i = _inner()
	return area.size.x >= sprite.width and area.size.y >= sprite.height


func _sprite_for(path: String) -> AsciiSprite:
	if path.is_empty():
		return null
	if _sprites.has(path):
		return _sprites[path]
	var sprite: AsciiSprite = SpriteLoader.load_file(path)
	if not sprite.is_valid():
		push_error("AsciiPortrait: invalid sprite %s: %s" % [path, sprite.errors])
		return null
	_sprites[path] = sprite
	return sprite


## Ancho del sprite adulto más ancho del contenido (se calcula una vez).
static func widest_fish(content: ContentDB) -> int:
	if _widest_cache < 0:
		var defs: Array[SpeciesDef] = []
		for id: String in content.species_ids():
			defs.append(content.get_species(id))
		_widest_cache = widest_sprite(defs)
	return _widest_cache


## Ancho en columnas del sprite adulto más ancho de [param defs].
static func widest_sprite(defs: Array[SpeciesDef]) -> int:
	var widest: int = 0
	for def: SpeciesDef in defs:
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		if sprite.is_valid():
			widest = maxi(widest, sprite.width)
	return widest
