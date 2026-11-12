class_name AsciiDrawable
extends RefCounted
## Elemento visible de la pecera: un objeto ligero que se actualiza y se dibuja
## sobre un [AsciiCanvas]. No es un nodo (T06).
##
## Las posiciones se expresan en celdas de la rejilla de la fuente, con decimales,
## para que el movimiento sea fluido por píxel (D14).

## Orden de dibujo: las capas menores se dibujan antes (quedan detrás).
var layer: int = 0
var is_shown: bool = true


## Avanza el estado visual [param _delta] segundos.
func update(_delta: float, _canvas: AsciiCanvas) -> void:
	pass


## Dibuja el elemento usando [method AsciiCanvas.put_char] y similares.
func draw(_canvas: AsciiCanvas) -> void:
	pass
