class_name DecorationField
extends AsciiDrawable
## Decoración colocada en la pecera, en una capa (detrás o delante de los peces).
## Es solo vista: `TankView` le pasa los objetos del modelo. La instancia de la
## capa delantera dibuja además la vista previa del modo decorar.

const GHOST_OK: Color = Color(0.45, 0.95, 0.55)
const GHOST_BAD: Color = Color(1.0, 0.4, 0.35)

## Texto de ayuda que se dibuja arriba del agua en el modo decorar (vacío = nada).
var hint: String = ""
var hint_cell: Vector2 = Vector2.ZERO

var _front: bool = false
var _items: Array[PlacedDecoration] = []
var _looks: Dictionary[String, Look] = {}
var _width: int = 0
var _origin_x: int = 0
var _floor_row: int = 0
var _clock: float = 0.0
var _ghost: DecorationDef = null
var _ghost_column: int = 0
var _ghost_lift: int = 0
var _ghost_valid: bool = false


func _init(is_front: bool) -> void:
	_front = is_front


## Zona: columna izquierda y ancho de la pecera, y fila de la arena.
func configure(origin_x: int, width: int, floor_row: int) -> void:
	_origin_x = origin_x
	_width = width
	_floor_row = floor_row


func set_items(items: Array[PlacedDecoration]) -> void:
	_items = items


## Cuántos objetos de esta capa se dibujan.
func count() -> int:
	var total: int = 0
	for placed: PlacedDecoration in _items:
		if _is_mine(placed.def):
			total += 1
	return total


## Vista previa: [param def] con su columna izquierda en [param column] (de la pecera).
func set_ghost(def: DecorationDef, column: int, lift: int, valid: bool) -> void:
	_ghost = def
	_ghost_column = column
	_ghost_lift = lift
	_ghost_valid = valid


func clear_ghost() -> void:
	_ghost = null


func has_ghost() -> bool:
	return _ghost != null


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	for placed: PlacedDecoration in _items:
		if not _is_mine(placed.def):
			continue
		var rect: Rect2i = placed.rect(_width)
		_draw_sprite(canvas, placed.def, rect.position.x, rect.position.y, Color.TRANSPARENT)
	if _front and _ghost != null:
		var tint: Color = GHOST_OK if _ghost_valid else GHOST_BAD
		_draw_sprite(canvas, _ghost, _ghost_column, _ghost_lift, tint)
	if _front and not hint.is_empty():
		canvas.put_string(hint, hint_cell, AsciiColors.AMBER)


## Celdas que ocupan todos los objetos colocados (de las dos capas), en la rejilla
## del agua. Sirve para que la vegetación del fondo quede tapada por la decoración.
func covered_cells() -> Array[Rect2i]:
	var cells: Array[Rect2i] = []
	for placed: PlacedDecoration in _items:
		var rect: Rect2i = placed.rect(_width)
		var top: int = _floor_row - rect.position.y - rect.size.y
		cells.append(Rect2i(_origin_x + rect.position.x, top, rect.size.x, rect.size.y))
	return cells


func _is_mine(def: DecorationDef) -> bool:
	return (def.layer == DecorationDef.Layer.FRONT) == _front


func _draw_sprite(
	canvas: AsciiCanvas, def: DecorationDef, column: int, lift: int, tint: Color
) -> void:
	var look: Look = _look_for(def)
	if look == null:
		return
	var frame: int = int(_clock / def.frame_duration) % look.sprite.frame_count()
	var lines: PackedStringArray = look.sprite.frames[frame]
	var roles: PackedStringArray = look.sprite.colors[frame]
	var top: int = _floor_row - lift - lines.size()
	for row: int in range(lines.size()):
		for index: int in range(lines[row].length()):
			var glyph: String = lines[row][index]
			if glyph == " ":
				continue
			var color: Color = tint
			if tint.a == 0.0:
				var role: String = roles[row][index] if index < roles[row].length() else " "
				color = look.palette.color_for(role)
			var cell: Vector2 = Vector2(float(_origin_x + column + index), float(top + row))
			canvas.put_char(glyph, cell, color)


func _look_for(def: DecorationDef) -> Look:
	if _looks.has(def.id):
		return _looks[def.id]
	var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
	if not sprite.is_valid():
		push_error("DecorationField: invalid sprite %s: %s" % [def.sprite_path, sprite.errors])
		return null
	var look: Look = Look.new(sprite, def.build_palette())
	_looks[def.id] = look
	return look


class Look:
	extends RefCounted
	var sprite: AsciiSprite
	var palette: AsciiPalette

	func _init(new_sprite: AsciiSprite, new_palette: AsciiPalette) -> void:
		sprite = new_sprite
		palette = new_palette
