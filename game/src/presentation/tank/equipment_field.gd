class_name EquipmentField
extends AsciiDrawable
## Equipo comprado dentro de la pecera: filtro, comedero, lámpara… Es solo vista:
## `TankView` le pasa los niveles del modelo y la zona de agua. Cada equipo se
## anima alternando los fotogramas de su sprite.

## Fila de agua (bajo la superficie) donde cuelgan los equipos de pared.
const WALL_ROW_OFFSET: int = 3

var _items: Dictionary[String, Item] = {}
var _signature: Dictionary[String, int] = {}
var _width: int = 0
var _top: int = 0
var _floor_row: int = 0
var _clock: float = 0.0


## Fija la zona: ancho, primera fila de agua y fila de la arena.
func configure(width: int, water_top: int, floor_row: int) -> void:
	_width = width
	_top = water_top
	_floor_row = floor_row
	for item: Item in _items.values():
		_place(item)


## Dibuja el equipo de [param levels] (id → nivel); los de nivel 0 no se ven.
func set_equipment(levels: Dictionary[String, int], content: ContentDB) -> void:
	if levels == _signature:
		return
	_signature = levels.duplicate()
	_items.clear()
	for equipment_id: String in levels:
		var def: EquipmentDef = content.get_equipment(equipment_id)
		if def == null or levels[equipment_id] <= 0:
			continue
		var sprite: AsciiSprite = SpriteLoader.load_file(def.sprite_path)
		if not sprite.is_valid():
			push_error("EquipmentField: invalid sprite %s: %s" % [def.sprite_path, sprite.errors])
			continue
		var item: Item = Item.new(def, sprite)
		_place(item)
		_items[equipment_id] = item


func count() -> int:
	return _items.size()


## Esquina superior izquierda del equipo (celdas), o (-1, -1) si no está.
func position_of(equipment_id: String) -> Vector2:
	if not _items.has(equipment_id):
		return Vector2(-1.0, -1.0)
	return _items[equipment_id].position


func update(delta: float, _canvas: AsciiCanvas) -> void:
	_clock += delta


func draw(canvas: AsciiCanvas) -> void:
	for item: Item in _items.values():
		var frame: int = int(_clock / item.def.frame_duration) % item.sprite.frame_count()
		var lines: PackedStringArray = item.sprite.frames[frame]
		var roles: PackedStringArray = item.sprite.colors[frame]
		for row: int in range(lines.size()):
			for column: int in range(lines[row].length()):
				var glyph: String = lines[row][column]
				if glyph == " ":
					continue
				var role: String = roles[row][column] if column < roles[row].length() else " "
				var color: Color = item.palette.color_for(role)
				var cell: Vector2 = item.position + Vector2(float(column), float(row))
				canvas.put_char(glyph, cell, color)


func _place(item: Item) -> void:
	var span: float = float(maxi(_width - item.sprite.width, 0))
	var column: float = floorf(item.def.place_x * span)
	var row: float = float(_floor_row - item.sprite.height)
	match item.def.placement:
		EquipmentDef.Placement.SURFACE:
			row = float(_top)
		EquipmentDef.Placement.WALL_LEFT:
			column = 1.0
			row = float(_top + WALL_ROW_OFFSET)
		EquipmentDef.Placement.WALL_RIGHT:
			column = maxf(span - 1.0, 0.0)
			row = float(_top + WALL_ROW_OFFSET)
		_:
			pass
	item.position = Vector2(column, row)


class Item:
	extends RefCounted
	var def: EquipmentDef
	var sprite: AsciiSprite
	var palette: AsciiPalette
	var position: Vector2 = Vector2.ZERO

	func _init(new_def: EquipmentDef, new_sprite: AsciiSprite) -> void:
		def = new_def
		sprite = new_sprite
		palette = new_def.build_palette()
