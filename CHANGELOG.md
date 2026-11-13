# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado `0.x.0` por fase hasta la `1.0.0`.

## [0.4.0] - 2026-11-13 · Fase 3

### Añadido
- Modelo de juego en `core/`: `GameState`, `Tank`, `Fish`, `Wallet`, `Simulation` y `FixedStepper` (10 pasos por segundo).
- Economía: costes ×1,15 por pez y ×1,6 por nivel de equipo, valor de venta, multiplicador por felicidad (×0,25 a ×1,25) y producción pasiva.
- `SpeciesDef` y `ContentDB` con validación de identificadores, rangos, sprites y paletas.
- Formato de números grandes según idioma (`12,4K`, `3,1M`, `1.25B`).
- Autoloads `Game` y `EventBus`; la pecera dibuja los peces del modelo.
- Contador de conchas y producción por segundo en la barra lateral.
- 196 tests (economía, simulación, determinismo, contenido, integración).

### Cambiado
- `SwimmerDef` se sustituye por `SpeciesDef`.
- F4 y Mayús+F4 añaden y quitan peces del modelo.
- La simulación se pausa al minimizar.

## [0.3.0] - 2026-11-13 · Fase 2

### Añadido
- Ventana en franja: sin bordes, siempre visible, anclada al área útil sobre la barra de tareas, sin robar el foco al arrancar.
- Se adapta a cambios de resolución, escala de Windows (100/125/150 %), monitor y barra de tareas.
- Ajustes persistentes (`user://settings.json`): altura de la franja (10-24 filas, 12 por defecto), monitor, siempre visible, límite de FPS, arranque con Windows (desactivado por defecto) y modo de paneles.
- Componentes de interfaz ASCII: marco, botón, lista, barra de progreso, pestañas, aviso y etiqueta.
- Ratón y teclado (Tab, flechas, Intro, Esc, atajos); minimizar `[_]`, cerrar `[X]` y Ctrl+Q.
- Prototipo de tienda y ajustes con los dos modos de apertura de paneles (P02).
- Textos en `strings.csv` (es/en) con test de claves.
- Bajo consumo al minimizar.

### Decisiones
- D32, D33, D34 (P01, P09, P10) y T23-T31.

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
