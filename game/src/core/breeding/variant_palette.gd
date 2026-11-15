class_name VariantPalette
extends RefCounted
## Cambia el color de un carácter según la variante. Solo cambia la paleta, nunca
## la forma (GDD §6), así que el coste de arte de una variante es cero.

## Cuánto cambia el tono de la prismática por segundo (vueltas completas).
const PRISM_SPEED: float = 0.25
const ALBINO_TARGET: Color = Color(1.0, 0.93, 0.95)
const ALBINO_AMOUNT: float = 0.7
const MELANISTIC_DARKEN: float = 0.65
## Luminancia mínima de la melánica: sobre el fondo negro tiene que seguir viéndose.
const MELANISTIC_FLOOR: float = 0.4
const MELANISTIC_LIFT: Color = Color(0.62, 0.62, 0.7)
const GOLDEN_BASE: Color = Color(0.95, 0.74, 0.12)
const GOLDEN_SHINE: float = 0.45
const PRISM_SATURATION: float = 0.75


## Color de [param source] en la variante [param look] en el instante [param time].
## [param phase] desfasa el tono de la prismática entre caracteres.
static func tint(
	source: Color, look: VariantDef.Look, time: float = 0.0, phase: float = 0.0
) -> Color:
	var luminance: float = source.get_luminance()
	match look:
		VariantDef.Look.ALBINO:
			var pale: Color = source.lerp(ALBINO_TARGET, ALBINO_AMOUNT)
			return Color(pale.r, pale.g, pale.b, source.a)
		VariantDef.Look.MELANISTIC:
			var dark: Color = source.darkened(MELANISTIC_DARKEN)
			var gray: float = dark.get_luminance()
			var muted: Color = dark.lerp(Color(gray, gray, gray * 1.4), 0.5)
			var shine: float = muted.get_luminance()
			if shine < MELANISTIC_FLOOR:
				var lift: float = (
					(MELANISTIC_FLOOR - shine) / (MELANISTIC_LIFT.get_luminance() - shine)
				)
				muted = muted.lerp(MELANISTIC_LIFT, clampf(lift, 0.0, 1.0))
			return Color(muted.r, muted.g, clampf(muted.b, 0.0, 1.0), source.a)
		VariantDef.Look.GOLDEN:
			var gold: Color = GOLDEN_BASE.lerp(Color.WHITE, luminance * GOLDEN_SHINE)
			return Color(gold.r, gold.g, gold.b, source.a)
		VariantDef.Look.PRISMATIC:
			var hue: float = fposmod(time * PRISM_SPEED + phase, 1.0)
			var value: float = clampf(0.55 + luminance * 0.45, 0.0, 1.0)
			var shifted: Color = Color.from_hsv(hue, PRISM_SATURATION, value)
			return Color(shifted.r, shifted.g, shifted.b, source.a)
		_:
			return source


## Verdadero si el aspecto de la variante cambia con el tiempo.
static func is_animated(look: VariantDef.Look) -> bool:
	return look == VariantDef.Look.PRISMATIC
