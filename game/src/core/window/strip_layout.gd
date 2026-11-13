class_name StripLayout
extends RefCounted
## Geometría de la franja: dónde va la ventana y cuánto mide. Funciones puras,
## sin Godot de por medio, para probarlas con cualquier resolución o escala.
##
## Todas las medidas de ventana están en píxeles físicos del escritorio.

## DPI que Windows considera "100 %".
const BASE_DPI: float = 96.0
const MIN_SCALE: float = 1.0
const MAX_SCALE: float = 4.0


## Escala de interfaz (1,0 = 100 %) a partir de los puntos por pulgada de la
## pantalla. Windows no da la escala directamente: 96 DPI = 100 %, 120 = 125 %,
## 144 = 150 %. Un valor imposible (0 o negativo) cuenta como 100 %.
static func scale_from_dpi(dpi: int) -> float:
	if dpi <= 0:
		return MIN_SCALE
	return clampf(snappedf(float(dpi) / BASE_DPI, 0.05), MIN_SCALE, MAX_SCALE)


## Tamaño de fuente en píxeles para [param scale], a partir del tamaño base.
static func scaled_font_px(base_px: int, scale: float) -> int:
	return maxi(1, roundi(float(base_px) * scale))


## Índice de pantalla que se usa de verdad. [param preferred] es el elegido por
## el jugador ([constant SettingsData.PRIMARY_SCREEN] = el principal). Si ya no
## existe (monitor desconectado), se cae al principal.
static func resolve_screen(preferred: int, screen_count: int, primary: int) -> int:
	if preferred < 0 or preferred >= screen_count:
		return primary
	return preferred


## Filas que caben de verdad: [param requested] recortado a la altura libre de la
## pantalla. Nunca baja de 1.
static func fit_rows(requested: int, available_height: int, cell_height: float) -> int:
	if cell_height <= 0.0:
		return maxi(requested, 1)
	var fitting: int = int(floorf(float(available_height) / cell_height))
	return clampi(requested, 1, maxi(fitting, 1))


## Altura en píxeles de [param rows] filas. Se redondea hacia arriba para que, al
## dividir la altura entre la celda, salgan exactamente esas filas.
static func height_for_rows(rows: int, cell_height: float) -> int:
	return ceili(float(rows) * cell_height)


## Rectángulo de la ventana: todo el ancho del área útil, pegado a su borde
## inferior (por encima de la barra de tareas, que ya queda fuera del área útil).
static func window_rect(usable: Rect2i, rows: int, cell_height: float) -> Rect2i:
	var fitted: int = fit_rows(rows, usable.size.y, cell_height)
	var height: int = mini(height_for_rows(fitted, cell_height), usable.size.y)
	return Rect2i(usable.position.x, usable.end.y - height, usable.size.x, height)


## Siguiente opción del selector de monitor. Las opciones son: el principal
## ([constant SettingsData.PRIMARY_SCREEN]), el monitor 0, el 1… y vuelta al
## principio. [param step] = 1 avanza y -1 retrocede.
static func cycle_screen(current: int, step: int, screen_count: int) -> int:
	var options: int = maxi(screen_count, 0) + 1
	var position: int = current + 1 if current >= 0 and current < screen_count else 0
	return posmod(position + step, options) - 1
