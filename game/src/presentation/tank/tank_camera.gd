class_name TankCamera
extends RefCounted
## Cámara horizontal de la pecera: el mundo es más ancho que la ventana y se ve a
## través de ella. No sabe de nodos ni de píxeles de la pantalla, solo de celdas.
## Se arrastra con el botón derecho (ver [method TankView._handle_pan]).

## Lo que hay que mover el ratón, en píxeles, para que el gesto cuente como
## arrastre y no como un clic derecho.
const DRAG_THRESHOLD_PX: float = 5.0

## Desplazamiento actual en celdas (0 = el borde izquierdo del mundo).
var x: float = 0.0
var view_columns: int = 0
var world_columns: int = 0
var is_panning: bool = false

var _moved_px: float = 0.0


## Fija el ancho visible y el del mundo; la cámara se mantiene dentro.
func configure(view: int, world: int) -> void:
	view_columns = maxi(view, 0)
	world_columns = maxi(world, view_columns)
	x = clampf(x, 0.0, max_x())


## Máximo desplazamiento posible, en celdas.
func max_x() -> float:
	return float(maxi(world_columns - view_columns, 0))


## Verdadero si el mundo es más ancho que la ventana.
func is_scrollable() -> bool:
	return max_x() > 0.0


## Mueve la cámara [param cells] celdas a la derecha (negativo, a la izquierda).
func pan_by(cells: float) -> void:
	x = clampf(x + cells, 0.0, max_x())


## Centra la cámara sobre la columna [param column] del mundo.
func center_on(column: float) -> void:
	x = clampf(column - float(view_columns) / 2.0, 0.0, max_x())


## Posición de la cámara como fracción del recorrido (0 a 1).
func fraction() -> float:
	if not is_scrollable():
		return 0.0
	return x / max_x()


func begin_pan() -> void:
	is_panning = true
	_moved_px = 0.0


## El ratón se movió [param pixels] en horizontal mientras se arrastraba: el mundo
## sigue al puntero, como si se agarrase.
func drag(pixels: float, cell_width: float) -> void:
	if not is_panning or cell_width <= 0.0:
		return
	_moved_px += absf(pixels)
	pan_by(-pixels / cell_width)


## Suelta la cámara. Devuelve verdadero si fue un arrastre de verdad.
func end_pan() -> bool:
	var was_drag: bool = is_panning and _moved_px >= DRAG_THRESHOLD_PX
	is_panning = false
	_moved_px = 0.0
	return was_drag
