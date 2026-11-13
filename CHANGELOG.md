# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado `0.x.0` por fase hasta la `1.0.0`.

## [0.10.0] - 2026-11-13 · Fase 9

### Añadido
- Decoración colocable: 20 objetos (`DecorationDef`, `content/decorations/`) con arte ASCII y animación, en capas detrás y delante de los peces.
- Pestaña «Decoración» en la tienda (compra al inventario) y modo decorar (`D`): vista previa verde/roja, colocar, recoger y mover, guardar con clic derecho, cambiar de objeto con la rueda o `C`.
- Bonificaciones de decoración: comodidad, producción y variantes raras, con tope; `TankBonuses` las suma con las del equipo.
- La lota se desbloquea colocando una cueva (`UnlockKind.DECORATION_TAG`).
- Reglas de colocación (`DecorationLayout`): límite de 12 objetos por pecera, límites del agua y solapes por capa.
- Guardado formato 5 (decoración colocada e inventario) con migración 4→5; la posición no depende del tamaño de la ventana.

## [0.9.0] - 2026-11-13 · Fase 8

### Añadido
- Equipamiento mejorable (`EquipmentDef`, `content/equipment/`): filtro, comedero, calentador, lámpara, aireador, incubadora e imán de perlas, de 5 niveles cada uno; el nivel k cuesta base × 1,6^k.
- `TankBonuses`: suma los efectos del equipo de una pecera (suciedad, limpieza automática, comida automática, comodidad, crecimiento, capacidad, eclosión, variantes raras e imán).
- Tienda con pestaña «Equipo»: nivel, efecto actual y coste del siguiente nivel; se compra con el botón o con Intro.
- Los equipos se dibujan en la pecera con animación; el aireador suelta burbujas y el imán recoge solo las perlas que llevan un rato en el suelo.
- `Game.buy_equipment`, `Game.equipment_cost`, `EventBus.equipment_changed`.
- Guardado formato 4 (equipo por pecera) con migración 3→4.

### Cambiado
- `Care.cleanliness_after` y `Care.happiness` aceptan los bonos del equipo; `Lifecycle` usa velocidad de crecimiento, de eclosión y peso de variantes raras.
- La capacidad mostrada en la tienda incluye el aireador (`Tank.total_capacity()`).

## [0.8.0] - 2026-11-13 · Fase 7

### Añadido
- Etapas de vida: alevín, juvenil y adulto (`LifeStage`). Solo los adultos producen conchas y crían; las crías crecen con el tiempo (cada especie tiene `growth_seconds`) y cambian de sprite al madurar.
- Cría: dos adultos de la misma especie con felicidad media de 60 o más ponen un huevo cada `breed_seconds` si hay hueco (el huevo ocupa capacidad). Más parejas ponen más deprisa (hasta 4).
- Huevos en el fondo de la pecera; se mueven poco antes de eclosionar (`hatch_seconds`).
- Variantes de color (`VariantDef`, `content/variants/`): Normal 93 %, Albina 4 %, Melánica 2 %, Dorada 0,9 % y Prismática 0,1 %, con venta ×1, ×3, ×5, ×15 y ×50. La prismática cambia de color con el tiempo.
- Venta desde la ficha del pez, con confirmación («¿Seguro?»). El valor depende de la especie, la variante y la etapa. «Sobrantes» vende todos los peces normales de la especie salvo los dos más maduros.
- Aviso al conseguir por primera vez una variante rara de una especie, y registro de combinaciones descubiertas (`GameState.discovered`).
- Ajustes: «Vender todos los peces» (con tres pulsaciones de confirmación) para vaciar la pecera; descarta también los huevos.
- Guardado formato 3 con migración desde el 2 (peces antiguos: adultos y de variante normal).

## [0.7.0] - 2026-11-13 · Fase 6

### Corregido
- (nuevo) La limpieza de la pecera se muestra en el panel lateral (`Limpieza 85 %`, verde/ámbar/rojo); se oculta si la franja tiene menos de 11 filas.
- Las manchas del cristal no se podían quitar: con suciedad mínima reaparecían al instante. Ahora hay una mancha por cada 10 puntos de suciedad completos.

### Añadido
- Hambre por pez (se vacía en 10 minutos) y limpieza por pecera (baja con el número de peces); la felicidad sale de ambas (`Care`).
- Alimentar: clic en el agua suelta copos; los peces hambrientos nadan hacia el más cercano y se lo comen.
- Manchas de alga en el cristal que aparecen al ensuciarse el agua y se limpian arrastrando el ratón.
- Perlas: cada pez suelta una de vez en cuando; caen al fondo y dan conchas al hacer clic (si hay muchas, la más antigua se recoge sola).
- Efecto visual de la felicidad: un pez triste nada más despacio y pierde saturación.
- La ficha del pez muestra también la saciedad.
- Guardado: se guardan la saciedad de cada pez y la limpieza de la pecera (las partidas antiguas empiezan limpias y saciadas).

## [0.6.0] - 2026-11-13 · Fase 5

### Añadido
- Las 8 especies del estanque con arte definitivo y dos fotogramas: guppy, pececillo, tetra neón, locha, caracol, pez dorado, pez ángel y carpa koi (`content/species/pond_*.tres`).
- Rarezas con color, símbolo y texto (`RarityStyle`) y condiciones de desbloqueo declarativas en `SpeciesDef` (`unlock_kind`, `unlock_amount`, `unlock_species_id`) evaluadas por `Unlocks`.
- Tienda real: lista las especies por precio, muestra «???» y la condición mientras están bloqueadas, avisa al desbloquear y compra con `Game.buy_fish` (valida conchas, capacidad y desbloqueo).
- Ficha de pez al hacer clic sobre él (nombre, rareza, producción y felicidad); se cierra con Esc.
- Migración del guardado 1→2: las especies de prueba pasan a las definitivas; se guardan las especies desbloqueadas.

### Cambiado
- La partida nueva empieza con 20 conchas y dos guppys.
- Eliminadas las especies de prueba `test_*` y el prototipo de tienda de la Fase 2.

## [0.5.0] - 2026-11-13 · Fase 4

### Añadido
- Guardado en `user://saves/save.json` (JSON con `format_version`, suma SHA-256 y `data`), escritura atómica (temporal → comprobación → renombrar) y 3 copias rotativas.
- Carga con validación de tipos y rangos; si el principal está dañado se recupera la copia más reciente válida y el archivo dañado se aparta (`corrupt_*`, máximo 5).
- Migraciones por versión (`SaveMigrations`) con un ejemplo 0→1.
- Autoguardado cada 60 s, al cerrar, al minimizar y tras comprar (con mínimo de 5 s entre guardados).
- Avisos en la barra lateral: partida recuperada, dañada, de versión más nueva o error al guardar.
- Autoload `SaveService`; `Game.adopt_state`; señales `purchase_made` y `notice_requested`.

### Cambiado
- La secuencia aleatoria (`rng_seed`, `rng_state`) se guarda como texto para no perder precisión.

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
