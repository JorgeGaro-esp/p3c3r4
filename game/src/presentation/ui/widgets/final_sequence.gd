class_name FinalSequence
extends AsciiWidget
## Secuencia final en ASCII: un mar de olas con peces que cruzan, el título y unas
## líneas que se escriben solas, una tras otra. Un clic la cierra ([signal activated]).

const CHARS_PER_SECOND: float = 24.0
const FIRST_DELAY: float = 1.0
const LINE_PAUSE: float = 0.9
const WAVE_ROWS: int = 2
const WAVE_SPEED: float = 3.0
const WAVE_PATTERN: String = "~≈~~≈~~~≈≈~"
const SPARKLE_SECONDS: float = 0.5
const FISH_RIGHT: String = "><(((°>"
const FISH_LEFT: String = "<°)))><"
## Peces que cruzan: fila (fracción de la altura), velocidad y desfase.
const FISH_TRACKS: Array[Vector3] = [
	Vector3(0.55, 6.0, 0.0), Vector3(0.7, -4.5, 9.0), Vector3(0.4, 3.0, 21.0)
]

## Título de arriba y líneas que se escriben solas.
var title: String = ""
var lines: PackedStringArray = PackedStringArray()

var _time: float = 0.0


## Vuelve a empezar la secuencia.
func restart() -> void:
	_time = 0.0


## Segundos que tarda en escribirse todo el texto.
func total_seconds() -> float:
	return _line_start(lines.size())


func update(delta: float, _canvas: AsciiCanvas) -> void:
	if is_shown:
		_time += delta


func handle_click(_cell: Vector2i, _is_double: bool) -> bool:
	activated.emit()
	return true


func draw(canvas: AsciiCanvas) -> void:
	if rect.size.x < 4 or rect.size.y < 4:
		return
	_draw_fish(canvas)
	_draw_waves(canvas)
	_draw_title(canvas)
	_draw_lines(canvas)


## Segundo en que empieza a escribirse la línea [param index].
func _line_start(index: int) -> float:
	var start: float = FIRST_DELAY
	for previous: int in range(mini(index, lines.size())):
		start += float(lines[previous].length()) / CHARS_PER_SECOND + LINE_PAUSE
	return start


func _draw_waves(canvas: AsciiCanvas) -> void:
	var width: int = rect.size.x
	var shift: int = floori(_time * WAVE_SPEED)
	for row: int in range(WAVE_ROWS):
		var text: String = ""
		for column: int in range(width):
			var index: int = (column + shift * (row * 2 + 1)) % WAVE_PATTERN.length()
			text += WAVE_PATTERN[index]
		var y: int = rect.end.y - 1 - WAVE_ROWS + row
		var color: Color = AsciiColors.WATER if row == 0 else AsciiColors.BUBBLE
		canvas.put_string(text, Vector2(rect.position.x, y), color)


func _draw_fish(canvas: AsciiCanvas) -> void:
	var width: float = float(rect.size.x)
	for track: Vector3 in FISH_TRACKS:
		var sprite: String = FISH_RIGHT if track.y > 0.0 else FISH_LEFT
		var span: float = width + float(sprite.length())
		var travel: float = fposmod(_time * absf(track.y) + track.z, span)
		var x: float = travel - float(sprite.length()) if track.y > 0.0 else width - travel
		var y: int = rect.position.y + floori(float(rect.size.y) * track.x)
		_put_clipped(canvas, sprite, x, y, AsciiColors.SAND)


func _draw_title(canvas: AsciiCanvas) -> void:
	var y: int = rect.position.y + 1
	var sparkle: String = "*" if floori(_time / SPARKLE_SECONDS) % 2 == 0 else "·"
	var text: String = "%s  %s  %s" % [sparkle, title, sparkle]
	var alpha: float = clampf(_time / FIRST_DELAY, 0.0, 1.0)
	canvas.put_string(
		UiText.center(text, rect.size.x),
		Vector2(rect.position.x, y),
		Color(AsciiColors.AMBER, alpha)
	)


func _draw_lines(canvas: AsciiCanvas) -> void:
	var last_row: int = rect.end.y - WAVE_ROWS - 2
	for index: int in range(lines.size()):
		var y: int = rect.position.y + 3 + index
		if y > last_row:
			return
		var line: String = lines[index]
		var shown: int = floori((_time - _line_start(index)) * CHARS_PER_SECOND)
		if shown <= 0:
			continue
		var visible: String = line.substr(0, mini(shown, line.length()))
		var left: int = rect.position.x + maxi(floori(float(rect.size.x - line.length()) / 2.0), 0)
		canvas.put_string(UiText.fit(visible, rect.size.x), Vector2(left, y), AsciiColors.TEXT)


func _put_clipped(canvas: AsciiCanvas, text: String, x: float, y: int, color: Color) -> void:
	var first: int = maxi(ceili(float(rect.position.x) - x), 0)
	var last: int = mini(text.length(), floori(float(rect.end.x) - x))
	if last <= first:
		return
	canvas.put_string(text.substr(first, last - first), Vector2(x + float(first), y), color)
