extends Control
## Escena principal. En la Fase 1 muestra la pecera ASCII viva.

## Límite de fotogramas por segundo (T07).
const TARGET_FPS: int = 30


func _ready() -> void:
	Engine.max_fps = TARGET_FPS
	RenderingServer.set_default_clear_color(Color.BLACK)
