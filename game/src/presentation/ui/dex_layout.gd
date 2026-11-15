class_name DexLayout
extends RefCounted
## Reparto del detalle de la Enciclopedia en celdas. Con sitio, la foto del pez va
## centrada en la página, con el texto a la izquierda y las variantes a la derecha;
## con menos, el texto a la izquierda y la foto a la derecha; y sin sitio no hay foto.
## También vale para Logros y Estadísticas (sin foto). Lógica pura.

## Ancho de la «foto» (con su marco) y ancho mínimo del detalle para verla.
const PORTRAIT_WIDTH: int = 24
const MIN_DETAIL_FOR_PORTRAIT: int = 44
## Ancho del detalle desde el que la foto va centrada.
const MIN_DETAIL_FOR_CENTERED: int = 76
const COLUMN_GAP: int = 2
const MIN_TEXT_COLUMN: int = 22
const BAR_WIDTH: int = 24

var has_portrait: bool = false
var name_rect: Rect2i = Rect2i()
var rarity: Rect2i = Rect2i()
var description: Rect2i = Rect2i()
var owned: Rect2i = Rect2i()
var price: Rect2i = Rect2i()
var progress: Rect2i = Rect2i()
var portrait: Rect2i = Rect2i()
## Lista de variantes de la página derecha (vacía si no hay página ancha).
var checklist: Rect2i = Rect2i()


## Ancho de la foto para un pez de [param sprite_width] columnas: el marco y un
## margen de nado a cada lado, sin bajar de [constant PORTRAIT_WIDTH].
static func wanted_portrait_width(sprite_width: int) -> int:
	return maxi(PORTRAIT_WIDTH, sprite_width + 4)


## Recorta [param wanted] para que el texto conserve [constant MIN_TEXT_COLUMN]
## columnas en una página de [param full_width]; nunca baja de [constant PORTRAIT_WIDTH].
static func fit_portrait_width(wanted: int, full_width: int) -> int:
	var limit: int = full_width - MIN_TEXT_COLUMN - 1
	if full_width >= MIN_DETAIL_FOR_CENTERED:
		limit = full_width - 2 * (MIN_TEXT_COLUMN + COLUMN_GAP)
	return clampi(wanted, PORTRAIT_WIDTH, maxi(limit, PORTRAIT_WIDTH))


## Calcula el reparto del detalle que empieza en [param detail_x] y mide
## [param full_width]; [param top] es la fila del marco y [param owned_row] la de las
## variantes. [param is_dex] es falso en Logros y Estadísticas.
static func compute(
	is_dex: bool,
	detail_x: int,
	top: int,
	owned_row: int,
	full_width: int,
	portrait_width: int = PORTRAIT_WIDTH
) -> DexLayout:
	var layout: DexLayout = DexLayout.new()
	var photo: int = fit_portrait_width(portrait_width, full_width)
	var rows: int = maxi(owned_row - top, 1)
	var text_width: int = full_width
	layout.has_portrait = is_dex and full_width >= MIN_DETAIL_FOR_PORTRAIT
	var centered: bool = is_dex and full_width >= MIN_DETAIL_FOR_CENTERED
	if centered:
		var side: int = floori(float(full_width - photo) / 2.0)
		text_width = maxi(side - COLUMN_GAP, MIN_TEXT_COLUMN)
		var right_x: int = detail_x + side + photo + COLUMN_GAP
		layout.portrait = Rect2i(detail_x + side, top + 2, photo, rows)
		layout.checklist = Rect2i(right_x, top + 2, maxi(detail_x + full_width - right_x, 1), rows)
	elif layout.has_portrait:
		text_width = full_width - photo - 1
		layout.portrait = Rect2i(detail_x + text_width + 1, top + 2, photo, maxi(rows - 2, 1))
	layout.name_rect = Rect2i(detail_x, top + 2, text_width, 1)
	layout.rarity = Rect2i(detail_x, top + 3, text_width, 1)
	layout.description = Rect2i(detail_x, top + 4, text_width, maxi(owned_row - top - 4, 1))
	var bar_width: int = mini(text_width if centered else full_width, BAR_WIDTH)
	layout.progress = Rect2i(detail_x, owned_row + 1, bar_width, 1)
	if centered:
		layout.owned = Rect2i(detail_x, owned_row, 0, 1)
		layout.price = Rect2i(detail_x, owned_row, text_width, 1)
	else:
		layout.owned = Rect2i(detail_x, owned_row, full_width, 1)
		layout.price = Rect2i(
			detail_x + bar_width + 2, owned_row + 1, maxi(full_width - bar_width - 2, 1), 1
		)
	return layout
