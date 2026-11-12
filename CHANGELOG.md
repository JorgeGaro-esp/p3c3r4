# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado `0.x.0` por fase hasta la `1.0.0`.

## [0.2.0] - 2026-11-12 · Fase 1

### Añadido
- Motor de render ASCII: `AsciiCanvas` dibuja caracteres en una rejilla que se adapta al tamaño de la ventana.
- Formato de sprites con varios fotogramas, capa de color, anclajes y espejado automático; lector con errores claros.
- Pecera viva: nado con impulsos, ondulación del cuerpo, giro suave e inclinación; superficie con olas, arena, algas y burbujas.
- Tres especies de prueba (una de varias líneas) definidas como datos en `content/`.
- Indicador de depuración (F3; F4 añade 5 peces, Mayús+F4 quita 5).
- Fuente DejaVu Sans Mono incluida.
- 27 tests (lector, espejado, cobertura de la fuente, movimiento).

### Rendimiento
- 40 peces a 30 FPS; dibujo 0,86 ms por fotograma.

## [0.1.0] - 2026-11-12 · Fase 0

### Añadido
- Estructura de carpetas de `docs/02-ARQUITECTURA.md`.
- Proyecto de Godot en `game/` (renderizador Compatibility, tipado estricto y avisos como errores).
- Escena principal que muestra "P3C3R4".
- Test de humo con GUT, configuración de `gdlint` y flujo de CI.
- GUT 9.6.1 instalado y activado; el test de humo pasa (5 aserciones).
- F5 abre la escena principal sin errores ni avisos.
