shader_type canvas_item;
// Efecto de monitor CRT sobre toda la pecera: brillo (los caracteres «sangran»
// luz como en una pantalla de fósforo), líneas de barrido, viñeta, un ligero
// desajuste de color en los bordes y un parpadeo casi imperceptible.
// Se dibuja encima de todo y no toca el ratón.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float glow : hint_range(0.0, 1.5) = 0.5;
uniform float scanlines : hint_range(0.0, 1.0) = 0.25;
uniform float scanline_pixels : hint_range(2.0, 8.0) = 3.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.3;
uniform float fringe : hint_range(0.0, 0.01) = 0.0006;
uniform float flicker : hint_range(0.0, 0.1) = 0.015;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - vec2(0.5);

	// Desajuste de color que crece hacia los bordes.
	vec2 shift = vec2(fringe, 0.0) * (centered.x * 2.0);
	float red = texture(screen_tex, uv + shift).r;
	float green = texture(screen_tex, uv).g;
	float blue = texture(screen_tex, uv - shift).b;
	vec3 base = vec3(red, green, blue);

	// Brillo: mezcla de versiones desenfocadas de la pantalla.
	vec3 halo = textureLod(screen_tex, uv, 1.5).rgb * 0.5
		+ textureLod(screen_tex, uv, 2.5).rgb * 0.35
		+ textureLod(screen_tex, uv, 3.5).rgb * 0.25;
	vec3 color = base + halo * glow;

	// Líneas de barrido.
	float row = FRAGCOORD.y * 6.2831853 / scanline_pixels;
	float line = 0.5 + 0.5 * cos(row);
	color *= 1.0 - scanlines * line;

	// Viñeta: se oscurecen las esquinas.
	float edge = dot(centered, centered) * 2.2;
	color *= 1.0 - vignette * edge;

	// Parpadeo muy suave.
	color *= 1.0 + flicker * sin(TIME * 47.0);

	COLOR = vec4(color, 1.0);
}
