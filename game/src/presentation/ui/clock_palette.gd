class_name ClockPalette
extends RefCounted
## Color del reloj de la barra según la hora del juego: cálido al amanecer, claro a
## mediodía, anaranjado al atardecer y frío (azulado) por la noche.

## Pares (hora, color) en orden creciente; de 24 h vuelve al primero.
const KEYS: Array[float] = [0.0, 5.0, 6.0, 9.0, 13.0, 17.0, 19.0, 21.0, 24.0]
const COLORS: Array[Color] = [
	Color(0.42, 0.52, 0.95),
	Color(0.5, 0.6, 0.98),
	Color(1.0, 0.6, 0.32),
	Color(1.0, 0.82, 0.45),
	Color(1.0, 0.95, 0.72),
	Color(1.0, 0.8, 0.42),
	Color(1.0, 0.52, 0.36),
	Color(0.58, 0.55, 0.92),
	Color(0.42, 0.52, 0.95),
]


## Color para una hora (cualquier valor; se normaliza a 0..24).
static func color_at(hour: float) -> Color:
	var h: float = fposmod(hour, 24.0)
	for i: int in range(1, KEYS.size()):
		if h <= KEYS[i]:
			var span: float = KEYS[i] - KEYS[i - 1]
			var t: float = (h - KEYS[i - 1]) / span
			return COLORS[i - 1].lerp(COLORS[i], t)
	return COLORS[COLORS.size() - 1]
