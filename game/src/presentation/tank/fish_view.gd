class_name FishView
extends AsciiDrawable
## Vista de un pez: dibuja su sprite carácter a carácter con la ondulación y la
## inclinación de su [SwimMotion].
##
## Al crearse precalcula las celdas de cada fotograma y sentido, de modo que
## dibujar un pez es solo recorrer listas (sin reservar memoria por fotograma).

## Cada cuántos puntos de felicidad cambia el aspecto del pez.
const MOOD_STEP: float = 5.0
## Cada cuántos segundos se recalculan los colores de una variante animada.
const ANIMATED_STEP: float = 0.1
## Desfase de tono entre columnas contiguas de una variante prismática.
const PRISM_SPREAD: float = 0.08
## Por debajo de este ancho (0 a 1) el pez está «de canto»: se dibuja como una
## línea vertical, el instante plano del giro.
const EDGE_ON_SCALE: float = 0.2
const EDGE_CHARACTER: String = "|"

var motion: SwimMotion
var width: int = 0
var height: int = 0
## Etapa y variante con las que se dibujó; `TankView` lo usa para detectar cambios.
var stage: LifeStage.Stage = LifeStage.Stage.ADULT
var variant_id: String = VariantDef.NORMAL_ID

var _cells: Array[FishCells] = []
var _frame_count: int = 1
var _frame_duration: float = 0.4
var _clock: float = 0.0
var _frame_index: int = 0
var _mood_level: int = -1
var _look: VariantDef.Look = VariantDef.Look.NONE
var _animated_clock: float = 0.0
var _last_animated: float = 0.0
var _desaturation: float = 0.0
var _right: AsciiSprite
var _left: AsciiSprite


func _init(
	sprite: AsciiSprite,
	palette: AsciiPalette,
	swim: SwimMotion,
	new_frame_duration: float,
	variant_look: VariantDef.Look = VariantDef.Look.NONE
) -> void:
	motion = swim
	_look = variant_look
	width = sprite.width
	height = sprite.height
	_right = sprite
	_left = sprite.mirrored()
	_frame_count = maxi(sprite.frame_count(), 1)
	_frame_duration = maxf(new_frame_duration, 0.05)
	_cells.append_array(_build_cells(_right, palette))
	_cells.append_array(_build_cells(_left, palette))
	if _look != VariantDef.Look.NONE:
		_retint(0.0)


func update(delta: float, _canvas: AsciiCanvas) -> void:
	motion.step(delta)
	_clock += delta
	_frame_index = int(_clock / _frame_duration) % _frame_count
	if VariantPalette.is_animated(_look):
		_animated_clock += delta
		if _animated_clock - _last_animated >= ANIMATED_STEP:
			_last_animated = _animated_clock
			_retint(_animated_clock)


func draw(canvas: AsciiCanvas) -> void:
	var facing_index: int = 0 if motion.facing > 0 else 1
	var cells: FishCells = _cells[facing_index * _frame_count + _frame_index]
	var origin: Vector2 = motion.position
	var squash: float = motion.turn_scale()
	var half: float = float(width - 1) * 0.5
	var edge_on: bool = squash < EDGE_ON_SCALE
	for index: int in range(cells.chars.size()):
		var column: int = cells.columns[index]
		var wave: float = motion.body_offset(column, width) + motion.tilt_offset(column, width)
		# Al girar, las columnas se acercan al centro del cuerpo.
		var across: float = half + (float(column) - half) * squash
		var cell: Vector2 = Vector2(origin.x + across, origin.y + float(cells.rows[index]) + wave)
		var character: String = EDGE_CHARACTER if edge_on else cells.chars[index]
		if character == AsciiSprite.OPAQUE_MARKER:
			canvas.fill_cell(cell, Color.BLACK)
		else:
			canvas.put_char(character, cell, cells.colors[index])


## Ajusta el aspecto a la felicidad [param happiness] (0 a 100): un pez triste nada
## más despacio y pierde saturación de color (GDD §4.4). Solo trabaja cuando la
## felicidad cambia de nivel.
func set_mood(happiness: float) -> void:
	var level: int = roundi(happiness / MOOD_STEP)
	if level == _mood_level:
		return
	_mood_level = level
	var value: float = float(level) * MOOD_STEP
	motion.speed_scale = Care.speed_factor(value)
	_desaturation = Care.desaturation(value)
	for cells: FishCells in _cells:
		cells.apply_desaturation(_desaturation)


## Cuánto color perdió el pez ahora (0 a 0,8).
func desaturation() -> float:
	return _desaturation


## Posición actual, en celdas, del punto de anclaje [param anchor_name]
## (por ejemplo `eye`). Si el sprite no lo define, devuelve su centro.
func anchor_cell(anchor_name: String) -> Vector2:
	var sprite: AsciiSprite = _right if motion.facing > 0 else _left
	var point: Vector2 = Vector2(float(width) * 0.5, float(height) * 0.5)
	if sprite.anchors.has(anchor_name):
		point = Vector2(sprite.anchors[anchor_name])
	return motion.position + point


## Recalcula los colores de la variante en el instante [param time] y vuelve a
## aplicar la desaturación del ánimo actual.
func _retint(time: float) -> void:
	for cells: FishCells in _cells:
		for index: int in range(cells.source_colors.size()):
			var phase: float = float(cells.columns[index]) * PRISM_SPREAD
			cells.base_colors[index] = VariantPalette.tint(
				cells.source_colors[index], _look, time, phase
			)
		cells.apply_desaturation(_desaturation)


func _build_cells(sprite: AsciiSprite, palette: AsciiPalette) -> Array[FishCells]:
	var result: Array[FishCells] = []
	for frame_index: int in range(sprite.frame_count()):
		var cells: FishCells = FishCells.new()
		var lines: PackedStringArray = sprite.frames[frame_index]
		var color_lines: PackedStringArray = sprite.colors[frame_index]
		for row: int in range(lines.size()):
			for column: int in range(lines[row].length()):
				var character: String = lines[row][column]
				if character == " ":
					continue
				var role: String = color_lines[row][column]
				if role == " ":
					role = AsciiSprite.DEFAULT_COLOR_ROLE
				cells.columns.append(column)
				cells.rows.append(row)
				cells.chars.append(character)
				var color: Color = palette.color_for(role)
				cells.source_colors.append(color)
				cells.base_colors.append(color)
				cells.colors.append(color)
		result.append(cells)
	return result


## Celdas visibles de un fotograma, en listas paralelas.
class FishCells:
	var columns: PackedInt32Array = PackedInt32Array()
	var rows: PackedInt32Array = PackedInt32Array()
	var chars: PackedStringArray = PackedStringArray()
	var source_colors: PackedColorArray = PackedColorArray()
	var base_colors: PackedColorArray = PackedColorArray()
	var colors: PackedColorArray = PackedColorArray()

	## Recalcula los colores apagando los de la paleta hacia su gris.
	func apply_desaturation(amount: float) -> void:
		for index: int in range(base_colors.size()):
			var base: Color = base_colors[index]
			var gray: float = base.get_luminance()
			colors[index] = base.lerp(Color(gray, gray, gray, base.a), amount)
