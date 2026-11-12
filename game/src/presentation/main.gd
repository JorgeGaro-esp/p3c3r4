extends Control
## Escena principal de la Fase 0: solo muestra el título del juego.

const GAME_TITLE: String = "P3C3R4"

@onready var _title: Label = $Title


func _ready() -> void:
	_title.text = GAME_TITLE
