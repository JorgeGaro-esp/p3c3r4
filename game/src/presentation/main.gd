extends Control
## Escena principal. Monta la pecera ASCII viva y la interfaz en la franja; el
## tamaño y la posición de la ventana los gestiona [StripController].


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
