class_name FishView
extends AsciiDrawable
## Vista de un pez: dibuja su sprite carácter a carácter con la ondulación y la
## inclinación de su [SwimMotion].
##
## Al crearse precalcula las celdas de cada fotograma y sentido, de modo que
## dibujar un pez es solo recorrer listas (sin reservar memoria por fotograma).

var motion: SwimMotion
var width: int = 0
var height: int = 0

var _cells: Array[FishCells] = []
var _frame_count: int = 1
var _frame_duration: float = 0.4
var _clock: float = 0.0
var _frame_index: int = 0
var _right: AsciiSprite
var _left: AsciiSprite


func _init(
	sprite: AsciiSprite, palette: AsciiPalette, swim: SwimMotion, new_frame_duration: float
) -> void:
	motion = swim
	width = sprite.width
	height = sprite.height
	_right = sprite
	_left = sprite.mirrored()
	_frame_count = maxi(sprite.frame_count(), 1)
	_frame_duration = maxf(new_frame_duration, 0.05)
	_cells.append_array(_build_cells(_right, palette))
	_cells.append_array(_build_cells(_left, palette))


func update(delta: float, _canvas: AsciiCanvas) -> void:
	motion.step(delta)
	_clock += delta
	_frame_index = int(_clock / _frame_duration) % _frame_count


func draw(canvas: AsciiCanvas) -> void:
	var facing_index: int = 0 if motion.facing > 0 else 1
	var cells: FishCells = _cells[facing_index * _frame_count + _frame_index]
	var origin: Vector2 = motion.position
	for index: int in range(cells.chars.size()):
		var column: int = cells.columns[index]
		var wave: float = motion.body_offset(column, width) + motion.tilt_offset(column, width)
		var cell: Vector2 = Vector2(
			origin.x + float(column), origin.y + float(cells.rows[index]) + wave
		)
		var character: String = cells.chars[index]
		if character == AsciiSprite.OPAQUE_MARKER:
			canvas.fill_cell(cell, Color.BLACK)
		else:
			canvas.put_char(character, cell, cells.colors[index])


## Posición actual, en celdas, del punto de anclaje [param anchor_name]
## (por ejemplo `eye`). Si el sprite no lo define, devuelve su centro.
func anchor_cell(anchor_name: String) -> Vector2:
	var sprite: AsciiSprite = _right if motion.facing > 0 else _left
	var point: Vector2 = Vector2(float(width) * 0.5, float(height) * 0.5)
	if sprite.anchors.has(anchor_name):
		point = Vector2(sprite.anchors[anchor_name])
	return motion.position + point


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
				cells.colors.append(palette.color_for(role))
		result.append(cells)
	return result


## Celdas visibles de un fotograma, en listas paralelas.
class FishCells:
	var columns: PackedInt32Array = PackedInt32Array()
	var rows: PackedInt32Array = PackedInt32Array()
	var chars: PackedStringArray = PackedStringArray()
	var colors: PackedColorArray = PackedColorArray()
