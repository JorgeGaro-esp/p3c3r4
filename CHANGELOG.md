# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado `0.x.0` por fase hasta la `1.0.0`.

## [0.14.0] - 2026-11-13 · Fase 11B

### Añadido
- **60 logros** como datos (`content/achievements/*.tres`, `AchievementDef`): compras, ventas, eclosiones, perlas, limpieza, comida, decoración, equipo, conchas ganadas, peces a la vez, especies por bioma, variantes raras, legendarias, biomas abiertos, decoración colocada, tiempo de juego, producción y porcentaje de colección. Cada uno lleva su nombre; la descripción se compone sola con la plantilla de su métrica (es/en).
- **Recompensa**: cada logro suma entre +0,25 % y +2 % de producción permanente; el total tiene un tope de +50 % (`Achievements.MAX_BONUS_PERCENT`). Se aplica en `Simulation.total_production`.
- `Achievements` (núcleo): valor, progreso, cumplimiento y bonus de cada logro. `AchievementCatalog` (`content.achievements`) carga y valida (ids únicos, metas > 0, estadísticas y biomas existentes).
- `Game` comprueba los logros cada 0,5 s y al cargar una partida (en silencio, de forma retroactiva); nueva señal `EventBus.achievement_unlocked` y aviso «¡Logro: …!».
- Pestañas **Logros** y **Estadísticas** en la tienda (tecla `L` abre Logros): lista con `[x]`/`[ ]` y recompensa, detalle con estado, descripción, progreso y barra, y resumen «Logros: n/60 · +x %». Estadísticas: contadores, conchas ganadas, tiempo, peces, producción, especies, variantes, biomas, logros y bonus.
- `NumberFormat.percent`, `Encyclopedia.rare_variants_found` y `legendary_found`, `GameState.decorations_placed`, `Simulation.refresh_production`.
- Guardado formato 8 (`achievements`) con migración 7→8; los ids desconocidos o con valor distinto de `true` se descartan.

## [0.13.0] - 2026-11-13 · Fase 11A

### Añadido
- Estadísticas de la partida (`GameStats`): peces comprados y vendidos, huevos eclosionados, perlas recogidas, manchas limpiadas, copos dados, decoración y equipo comprados. Se guardan y serán la base de los logros (11B).
- Colección (`Encyclopedia`): consultas de especies y variantes descubiertas, con progreso por bioma y total, y detección de colección completa.
- Pestaña «Enciclopedia» en la tienda: todas las especies de todos los biomas, de la más barata a la más cara; las que aún no se han tenido salen como «???» (con su rareza), y las vistas muestran descripción, bioma y las variantes conseguidas. Tecla `P` y botón de la barra lateral.
- Guardado formato 7 (`stats`) con migración 6→7. Las partidas antiguas empiezan con las estadísticas a cero; el Enciclopedia se rellena solo con los peces que ya tengan.

- Retrato animado del pez en la ficha (`AsciiPortrait`): su sprite quieto en el centro (como una foto que se mueve), con los mismos fotogramas y el mismo movimiento que al nadar en la pecera (un `SwimMotion` real: ondulación, inclinación y giros) en una pecera en miniatura: nada despacio dentro del recuadro y se da la vuelta al llegar al borde; recorre las variantes que se han tenido, con su color y su nombre, y las de colores animados (prismática) brillan. Las especies sin descubrir enseñan su silueta.

### Cambiado
- El Pecedex se llama **Enciclopedia** (texto, código y documentos): clase `Encyclopedia`, atajo `E`. El botón de la barra lateral abre la pestaña en lugar de avisar de que llegará pronto (se quita `TOAST_DEX_SOON`).
- Ficha de la Enciclopedia reorganizada para la franja baja: nombre, rareza y bioma, descripción, variantes en una fila y total descubierto junto a la barra.

## [0.12.0] - 2026-11-13 · Fase 10B

### Añadido
- **Manglar** (90 000 ¢, pide el Arrecife): agua turbia, arena de barro, raíces, motas de polen. 8 especies (pez arquero, cangrejo violinista, gamba, siluro, pargo, saltarín del fango, barracuda y pez sierra) y 4 decoraciones propias (raíz de mangle, montículo de fango, lianas colgantes, roca de percebes).
- **Abismo** (700 000 ¢, pide el Manglar): sin fondo decorado, plantas luminosas y nieve marina brillante. 8 especies (pez linterna, medusa, pez hacha, calamar vampiro, pez víbora, rape abisal, pez remo y calamar gigante) y 4 decoraciones propias (tubo luminoso, fumarola, huesos de ballena, orbe señuelo).
- Nuevas etiquetas de desbloqueo: raíz, fango, brillo, fumarola, huesos y señuelo. Cada bioma tiene sus 5 rarezas, sus desbloqueos y su economía creciente.
- Tests: cadena de desbloqueo (Abismo ← Manglar ← Arrecife) y compra de especies solo en su bioma.

### Cambiado
- `test_biome_content` y la pestaña «Biomas» cubren ya los cuatro biomas. Fase 10 completa.

## [0.11.0] - 2026-11-13 · Fase 10A

### Añadido
- Biomas (`BiomeDef`, `content/biomes/`, `BiomeCatalog`): cada uno define superficie, suelo, plantas, burbujas, fondo y partículas flotantes. Estanque (el de siempre) y **Arrecife** (coral, agua turquesa, motas que suben).
- Varias peceras: `GameState.active_tank`; todas las acciones (comprar, equipar, decorar, vender, limpiar) van a la pecera activa. `Game.biomes` (`BiomeDirector`) cambia de pecera y abre biomas.
- Pestaña «Biomas» en la tienda (Arrecife: 6000 ¢, pide tener el Estanque) y pestañas de pecera sobre la superficie del agua; teclas `1`–`8` para cambiar.
- Arrecife completo: 8 especies (pez payaso, damisela, pez mariposa, estrella de mar, cirujano, caballito de mar, pez globo, manta raya) y 4 decoraciones propias (coral cerebro, abanico, anémona, coral cuerno de ciervo). El caballito pide una anémona y la estrella un coral.
- Las peceras que no se ven se simulan con las mismas reglas (hambre, limpieza, cría, producción); sus perlas se cobran solas y al cambiar de pecera se cobran las perlas que quedaban sin recoger.
- Guardado formato 6 (pecera activa) con migración 5→6; los biomas repetidos al cargar se descartan.

### Cambiado
- La tienda enseña solo las especies y la decoración del bioma de la pecera activa (`DecorationDef.biome_id`; vacío = todos).
- Contenido: `ContentDB.biomes` y `BiomeCatalog.check_references` validan que especies y decoración apuntan a biomas que existen.
- `test_pond_content` pasa a `test_biome_content` y comprueba cada bioma.

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
