class_name DaylightView
extends AsciiDrawable
## Tinte del agua según la hora (GDD §12): azul oscuro de noche, un velo cálido en el
## amanecer y el atardecer y, con la corriente cálida, un toque anaranjado. Es un
## rectángulo translúcido sobre la pecera; la interfaz queda por encima y no se ve
## afectada. La lámpara de la pecera lo aclara.

const NIGHT_COLOR: Color = Color(0.04, 0.07, 0.22)
## Opacidad máxima de la noche cerrada.
const NIGHT_ALPHA: float = 0.4
const TWILIGHT_COLOR: Color = Color(1.0, 0.5, 0.2)
const TWILIGHT_ALPHA: float = 0.11
const WARM_COLOR: Color = Color(1.0, 0.45, 0.1)
const WARM_ALPHA: float = 0.07
## Cuánto aclara la lámpara al máximo (fracción de la opacidad nocturna).
const LAMP_RELIEF: float = 0.5

var area: Rect2i = Rect2i()

var _darkness: float = 0.0
var _shield: float = 0.0
var _warm: bool = false


## Fija lo que hay que pintar: oscuridad (0 a 1), escudo de la lámpara y si hay
## corriente cálida.
func set_conditions(darkness: float, shield: float, warm: bool) -> void:
	_darkness = clampf(darkness, 0.0, 1.0)
	_shield = clampf(shield, 0.0, 1.0)
	_warm = warm


## Opacidad de la capa nocturna con las condiciones actuales.
func night_alpha() -> float:
	return NIGHT_ALPHA * _darkness * (1.0 - LAMP_RELIEF * _shield)


## Opacidad del velo del amanecer y el atardecer (máxima a mitad de transición).
func twilight_alpha() -> float:
	return TWILIGHT_ALPHA * sin(PI * _darkness)


func draw(canvas: AsciiCanvas) -> void:
	if not area.has_area():
		return
	_fill(canvas, NIGHT_COLOR, night_alpha())
	_fill(canvas, TWILIGHT_COLOR, twilight_alpha())
	if _warm:
		_fill(canvas, WARM_COLOR, WARM_ALPHA)


func _fill(canvas: AsciiCanvas, color: Color, alpha: float) -> void:
	if alpha <= 0.004:
		return
	canvas.fill_rect_cells(area, Color(color.r, color.g, color.b, alpha))
