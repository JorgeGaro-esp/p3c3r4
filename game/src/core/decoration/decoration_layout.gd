class_name DecorationLayout
extends RefCounted
## Reglas de colocación (funciones puras): límite de objetos, que quepan en el
## agua y que no se solapen con otro de su misma capa.

enum Result { OK, TOO_MANY, OUT_OF_BOUNDS, OVERLAP }


## Comprueba si se puede dejar [param def] en la columna [param x_permille] y a
## [param lift] filas del suelo. [param water_rows] son las filas de agua libres y
## [param ignore] un objeto que se está moviendo (no cuenta para el solape).
static func check(
	tank: Tank,
	def: DecorationDef,
	x_permille: int,
	lift: int,
	tank_width: int,
	water_rows: int,
	ignore: PlacedDecoration = null
) -> Result:
	var count: int = tank.decorations.size()
	if ignore != null and tank.decorations.has(ignore):
		count -= 1
	if count >= Tank.MAX_DECORATIONS:
		return Result.TOO_MANY
	if tank_width < def.cells_wide or lift < 0 or lift + def.cells_high > water_rows:
		return Result.OUT_OF_BOUNDS
	if def.anchor == DecorationDef.Anchor.FLOOR and lift != 0:
		return Result.OUT_OF_BOUNDS
	var candidate: Rect2i = PlacedDecoration.new(def, x_permille, lift).rect(tank_width)
	for other: PlacedDecoration in tank.decorations:
		if other == ignore or other.def.layer != def.layer:
			continue
		if other.rect(tank_width).intersects(candidate):
			return Result.OVERLAP
	return Result.OK


## Milésimas que corresponden a poner el objeto con su columna izquierda en
## [param column] (se recorta a los bordes de la pecera).
static func permille_for_column(column: int, def: DecorationDef, tank_width: int) -> int:
	var span: int = maxi(tank_width - def.cells_wide, 0)
	if span == 0:
		return 0
	var ratio: float = clampf(float(column) / float(span), 0.0, 1.0)
	return roundi(ratio * float(PlacedDecoration.MAX_PERMILLE))
