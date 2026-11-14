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


## Enseña a [param def]. Con [param looks] vacío dibuja la silueta; si no, cada
## aspecto con su nombre de [param names] (misma longitud).
func show_species(def: SpeciesDef, looks: Array[VariantDef.Look], names: PackedStringArray) -> void:
	var changed: bool = def.id != _species_id or looks != _looks
	_species_id = def.id
	_looks = looks.duplicate()
	_names = names
	_frame_duration = maxf(def.frame_duration, 0.05)
	_palette = def.build_palette()
	_sprite = _sprite_for(def)
	_mirrored = _sprite.mirrored() if _sprite != null else null
	if changed or _motion == null:
		_clock = 0.0
		_motion = SwimMotion.new(
			RandomNumberGenerator.new(),
			def.style as SwimMotion.Style,
			def.speed,
			minf(def.amplitude * WAVE_GAIN, MAX_WAVE),
			def.frequency
		)
		_motion.speed_scale = SWIM_SPEED_SCALE
		_bounds = Rect2(-1.0, -1.0, 0.0, 0.0)
		_motion.scatter()


## Quita el retrato.
func clear() -> void:
	_species_id = ""
	_sprite = null
	_looks = []
	_names = PackedStringArray()


## Variante que se está viendo ahora (índice en la lista dada a [method show_species]).
func current_index() -> int:
	if _looks.is_empty():
		return -1
	return int(_clock / VARIANT_SECONDS) % _looks.size()


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
	if _sprite == null or rect.size.x < _sprite.width or rect.size.y < _sprite.height:
		return
	var caption_rows: int = _caption_rows()
	if _looks.is_empty():
		var origin: Vector2i = (
			rect.position
			+ Vector2i(
				(rect.size.x - _sprite.width) / 2, (rect.size.y - caption_rows - _sprite.height) / 2
			)
		)
		_draw_silhouette(canvas, origin)
		return
	_fit_bounds()
	_draw_sprite(canvas, Vector2(rect.position) + _motion.position)
	_draw_caption(canvas)


## Filas que ocupa el nombre de la variante bajo el pez.
func _caption_rows() -> int:
	if not _looks.is_empty() and rect.size.y > _sprite.height:
		return 1
	return 0


## Ajusta la zona de nado al recuadro y al tamaño del sprite si han cambiado.
func _fit_bounds() -> void:
	var area: Rect2 = Rect2(
		0.0,
		0.0,
		float(maxi(rect.size.x - _sprite.width, 0)),
		float(maxi(rect.size.y - _caption_rows() - _sprite.height, 0))
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
	var top: float = float(rect.position.y)
	var bottom: float = float(rect.end.y - _caption_rows() - 1)
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
			var wave: float = (
				_motion.body_offset(column, shown.width) + _motion.tilt_offset(column, shown.width)
			)
			var y: float = clampf(origin.y + float(row) + wave, top, bottom)
			var across: float = half + (float(column) - half) * squash
			if squash < FishView.EDGE_ON_SCALE:
				character = FishView.EDGE_CHARACTER
			canvas.put_char(character, Vector2(origin.x + across, y), color)


func _draw_caption(canvas: AsciiCanvas) -> void:
	var index: int = current_index()
	if index < 0 or index >= _names.size() or rect.size.y <= _sprite.height:
		return
	var text: String = _names[index]
	var x: int = rect.position.x + maxi((rect.size.x - text.length()) / 2, 0)
	canvas.put_string(text, Vector2(x, rect.position.y + rect.size.y - 1), AsciiColors.TEXT_DIM)


func _sprite_for(def: SpeciesDef) -> AsciiSprite:
	if _sprites.has(def.id):
		return _sprites[def.id]
	var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
	if not sprite.is_valid():
		push_error("AsciiPortrait: invalid sprite %s: %s" % [def.sprite_path, sprite.errors])
		return null
	_sprites[def.id] = sprite
	return sprite
