class_name SpriteLoader
extends RefCounted
## Lee archivos de sprite (formato en `docs/05-GUIA-ARTE-ASCII.md` §4.4).
##
## Nunca falla con una excepción: los problemas se acumulan en
## [member AsciiSprite.errors] y el llamante decide qué hacer.

const SECTION_FRAME: String = "[frame]"
const SECTION_COLORS: String = "[colors]"
const SECTION_ANCHOR: String = "[anchor]"
const _ID_SEPARATOR: String = " · "


## Carga un sprite desde un archivo. El identificador por defecto es el nombre
## del archivo sin extensión.
static func load_file(path: String) -> AsciiSprite:
	var default_id: String = path.get_file().get_basename()
	if not FileAccess.file_exists(path):
		var missing: AsciiSprite = AsciiSprite.new()
		missing.id = default_id
		missing.errors.append("file not found: %s" % path)
		return missing
	return parse(FileAccess.get_file_as_string(path), default_id)


## Interpreta el texto de un sprite. [param default_id] se usa si el archivo no
## trae cabecera `# id · etapa`.
static func parse(text: String, default_id: String = "") -> AsciiSprite:
	var sprite: AsciiSprite = AsciiSprite.new()
	sprite.id = default_id
	var sections: Array[Section] = _split_sections(text, sprite)

	var raw_frames: Array[PackedStringArray] = []
	var raw_colors: Array[PackedStringArray] = []
	var has_colors: Array[bool] = []
	var anchor_lines: PackedStringArray = PackedStringArray()

	for section: Section in sections:
		if section.name == SECTION_FRAME:
			raw_frames.append(section.lines)
			raw_colors.append(PackedStringArray())
			has_colors.append(false)
		elif section.name == SECTION_COLORS:
			var last: int = raw_frames.size() - 1
			if last < 0:
				sprite.errors.append("[colors] found before any [frame]")
			elif has_colors[last]:
				sprite.errors.append("frame %d has more than one [colors]" % last)
			else:
				raw_colors[last] = section.lines
				has_colors[last] = true
		else:
			anchor_lines.append_array(section.lines)

	if raw_frames.is_empty():
		sprite.errors.append("no [frame] section")
		return sprite

	_build_frames(sprite, raw_frames, raw_colors, has_colors)
	_parse_anchors(sprite, anchor_lines)
	return sprite


static func _split_sections(text: String, sprite: AsciiSprite) -> Array[Section]:
	var sections: Array[Section] = []
	var current: Section = null
	var header_read: bool = false
	for line: String in text.replace("\r\n", "\n").split("\n"):
		var trimmed: String = line.strip_edges(false, true)
		if _is_section_header(trimmed):
			current = Section.new()
			current.name = trimmed
			sections.append(current)
		elif current != null:
			current.lines.append(line)
		elif trimmed.is_empty():
			continue
		elif trimmed.begins_with("#") and not header_read:
			header_read = true
			_read_header(trimmed, sprite)
		else:
			sprite.errors.append("unexpected text before the first section: %s" % trimmed)
	for section: Section in sections:
		_trim_trailing_blank_lines(section.lines)
	return sections


static func _is_section_header(trimmed: String) -> bool:
	return trimmed == SECTION_FRAME or trimmed == SECTION_COLORS or trimmed == SECTION_ANCHOR


static func _read_header(header: String, sprite: AsciiSprite) -> void:
	var content: String = header.trim_prefix("#").strip_edges()
	var parts: PackedStringArray = content.split(_ID_SEPARATOR)
	var header_id: String = parts[0].strip_edges()
	if not header_id.is_empty():
		sprite.id = header_id


static func _trim_trailing_blank_lines(lines: PackedStringArray) -> void:
	while not lines.is_empty() and lines[lines.size() - 1].strip_edges().is_empty():
		lines.remove_at(lines.size() - 1)


static func _build_frames(
	sprite: AsciiSprite,
	raw_frames: Array[PackedStringArray],
	raw_colors: Array[PackedStringArray],
	has_colors: Array[bool]
) -> void:
	for raw_frame: PackedStringArray in raw_frames:
		sprite.width = maxi(sprite.width, _max_line_length(raw_frame))
		sprite.height = maxi(sprite.height, raw_frame.size())

	for index: int in range(raw_frames.size()):
		var frame: PackedStringArray = raw_frames[index]
		if frame.is_empty():
			sprite.errors.append("frame %d is empty" % index)
			continue
		for line: String in frame:
			var bad: String = AsciiCharset.first_disallowed(line)
			if not bad.is_empty():
				sprite.errors.append("frame %d uses a disallowed character: '%s'" % [index, bad])
		sprite.frames.append(_pad_block(frame, sprite.width, sprite.height))
		sprite.colors.append(
			_build_colors(sprite, index, frame.size(), raw_colors[index], has_colors[index])
		)


static func _build_colors(
	sprite: AsciiSprite,
	index: int,
	frame_height: int,
	color_lines: PackedStringArray,
	has_own_colors: bool
) -> PackedStringArray:
	if not has_own_colors:
		# Sin capa propia hereda la del fotograma anterior; el primero queda sin color.
		if not sprite.colors.is_empty():
			return sprite.colors[sprite.colors.size() - 1]
		return _pad_block(PackedStringArray(), sprite.width, sprite.height)
	if color_lines.size() != frame_height:
		sprite.errors.append(
			(
				"frame %d: [colors] has %d lines, expected %d"
				% [index, color_lines.size(), frame_height]
			)
		)
	for line: String in color_lines:
		if line.length() > sprite.width:
			sprite.errors.append("frame %d: a [colors] line is wider than the sprite" % index)
		for position: int in range(line.length()):
			if not _is_color_letter(line[position]):
				sprite.errors.append(
					"frame %d: invalid color letter '%s'" % [index, line[position]]
				)
	return _pad_block(color_lines, sprite.width, sprite.height)


static func _parse_anchors(sprite: AsciiSprite, lines: PackedStringArray) -> void:
	for line: String in lines:
		var text: String = line.strip_edges()
		if text.is_empty():
			continue
		var halves: PackedStringArray = text.split("=")
		var coordinates: PackedStringArray = PackedStringArray()
		if halves.size() == 2:
			coordinates = halves[1].split(",")
		if (
			coordinates.size() != 2
			or not _is_integer(coordinates[0])
			or not _is_integer(coordinates[1])
		):
			sprite.errors.append("invalid anchor line: %s" % text)
			continue
		var point: Vector2i = Vector2i(coordinates[0].to_int(), coordinates[1].to_int())
		if point.x < 0 or point.x >= sprite.width or point.y < 0 or point.y >= sprite.height:
			sprite.errors.append("anchor outside the sprite: %s" % text)
			continue
		sprite.anchors[halves[0].strip_edges()] = point


static func _max_line_length(lines: PackedStringArray) -> int:
	var longest: int = 0
	for line: String in lines:
		longest = maxi(longest, line.length())
	return longest


static func _pad_block(lines: PackedStringArray, width: int, height: int) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for line: String in lines:
		result.append(line + " ".repeat(maxi(width - line.length(), 0)))
	while result.size() < height:
		result.append(" ".repeat(width))
	return result


static func _is_color_letter(character: String) -> bool:
	return character == " " or (character >= "a" and character <= "z")


static func _is_integer(text: String) -> bool:
	return text.strip_edges().is_valid_int()


## Trozo de archivo entre dos cabeceras de sección.
class Section:
	var name: String = ""
	var lines: PackedStringArray = PackedStringArray()
