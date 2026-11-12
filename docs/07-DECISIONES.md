# 07 · Registro de decisiones

Cada decisión lleva un identificador para poder citarla. Las de la sección A las tomó Jorge en el cuestionario del 2026-11-12. Las de la sección B son técnicas, derivadas de las anteriores, y pueden revisarse. La sección C recoge lo que falta por decidir.

## A. Decisiones de Jorge

| ID | Tema | Decisión |
|---|---|---|
| D01 | Plataforma | Escritorio y navegador; el navegador se deja para más adelante (D25) |
| D02 | Publicación | Solo para uso propio por ahora |
| D03 | Ventana | Solo franja inferior, estilo Rusty's Retirement |
| D04 | Sistema operativo | Solo Windows |
| D05 | Motor y lenguaje | Godot 4 + GDScript |
| D06 | Economía | Producción pasiva de monedas + cría y venta de peces |
| D07 | Interacción | Pasivo con tareas ligeras |
| D08 | Muerte | Los peces no mueren; se entristecen y producen menos |
| D09 | Colección | Especies con rarezas, Pecedex y logros. Sin genética heredada |
| D10 | Pecera y progreso | Decoración colocable, equipamiento mejorable, varias peceras o biomas, prestigio |
| D11 | Ambiente | Día/noche con hora real y eventos aleatorios. **Sin progreso con el juego cerrado** |
| D12 | Final | Meta final y después modo infinito |
| D13 | Meta final | Completar el Pecedex |
| D14 | Movimiento | Fluido por píxel |
| D15 | Caracteres | ASCII + Unicode (marcos de caja, bloques, `°`) |
| D16 | Color | Color por especie sobre fondo negro, con efecto CRT |
| D17 | Sprites | De una línea y multilínea |
| D18 | Interfaz | También en ASCII |
| D19 | Audio | Ambiente acuático y efectos suaves, más música chiptune |
| D20 | Título | "P3C3R4" es provisional |
| D21 | Alcance | La primera versión jugable es la completa |
| D22 | Idiomas del juego | Español e inglés |
| D23 | Idioma del código | Código en inglés; documentación y comentarios en español |
| D24 | Versiones | Git + GitHub privado |
| D25 | Versión web | Arquitectura preparada, entrega aplazada |
| D26 | Papel de Jorge | Entender y poder tocar el código |
| D27 | Cría | Cría con variantes de color raras que valen más y cuentan en el Pecedex |
| D28 | Pruebas | Tests automáticos + CI en GitHub |
| D29 | Guardado | Autoguardado con copia de seguridad y versión de formato |
| D30 | Carpeta | `Proyecto P3C3R4` en el escritorio, creada por Claude |
| D31 | Forma de preguntar | Preguntas interactivas de opciones, también en futuros proyectos |

## B. Decisiones técnicas derivadas

| ID | Decisión | Motivo |
|---|---|---|
| T01 | Última versión estable de Godot 4.x, fijada en la Fase 0 y anotada aquí | Evitar cambios de versión a mitad de desarrollo |
| T02 | Renderizador "Compatibility" (OpenGL) | El más ligero, suficiente para 2D, y el único válido para web (D25) |
| T03 | GDScript con tipado estático obligatorio y avisos tratados como errores | Mantenibilidad; Jorge viene de lenguajes tipados |
| T04 | Tres capas: `core` (lógica pura), `data` (contenido), `presentation` (nodos) | Lógica testeable y contenido ampliable sin tocar código |
| T05 | Simulación a paso fijo (10 pasos por segundo), independiente del dibujado | Resultados reproducibles y tests deterministas |
| T06 | Dibujado de todo el arte en un único lienzo con `draw_string`, no un nodo por carácter | Rendimiento |
| T07 | Límite de 30 FPS y modo de bajo consumo de procesador | El juego convive con otras aplicaciones |
| T08 | Números de la economía en `float` de 64 bits con formato abreviado (K, M, B…) | Simple; alcanza hasta 1e308 |
| T09 | Guardado en JSON dentro de `user://`, validado al cargar | Seguro y legible; ver doc 06 |
| T10 | GUT 9.x para tests | Estándar en proyectos solo GDScript |
| T11 | gdtoolkit (`gdlint`, `gdformat`) para estilo | Estándar de la comunidad |
| T12 | Textos en CSV con el sistema de traducción de Godot | D22 |
| T13 | Commits convencionales, versionado semántico y `CHANGELOG.md` | Historial claro |
| T14 | Sin red, sin telemetría, sin cuentas | D02; privacidad |
| T15 | Ventana sin transparencia | D03 pide solo franja; simplifica y evita problemas de clics |
| T16 | Fuente monoespaciada con licencia libre incluida en el juego | Aspecto idéntico en cualquier equipo |
| T17 | Fuente: DejaVu Sans Mono (resuelve P08) | Única candidata que cubre marcos, bloques y formas; elegida por Jorge el 2026-11-12 |
| T18 | Un solo `AsciiCanvas` dibuja todo con `draw_string`; los elementos son `AsciiDrawable` ordenados por capa | Menos nodos, control total de la rejilla (T06) |
| T19 | Los peces de prueba son recursos `SwimmerDef` en `content/species/`; son el germen de `SpeciesDef` (Fase 3) | Añadir un pez no toca código de dibujo |
| T20 | El texto del indicador de depuración (F3) no pasa por `strings.csv` | Herramienta de desarrollo, no se muestra al jugador |
| T21 | Los nodos se enlazan con `NodePath` y `get_node` en `_ready`, no con `@export` de tipo nodo | Con `@export` de tipo nodo el valor llegaba nulo en ejecución |
| T22 | Para exportar (Fase 16) hará falta incluir `content/sprites/*.txt` en el filtro de exportación | Godot no empaqueta .txt por defecto |

## C. Pendientes (no bloquean el inicio)

| ID | Pregunta | Cuándo hace falta |
|---|---|---|
| P01 | Altura de la franja y si es ajustable por el jugador | Fase 2 |
| P02 | Cómo se abren tienda y Pecedex dentro de la franja: panel lateral o ventana que crece hacia arriba | Fase 2, con prototipo |
| P03 | Lista definitiva de biomas y especies (el GDD trae una propuesta) | Fase 5 y Fase 10 |
| P04 | Nombre de la moneda y de la moneda de prestigio | Fase 3 |
| P05 | Qué conserva exactamente el prestigio | Fase 13 |
| P06 | Estilo concreto de la música y origen de los sonidos | Fase 14 |
| P07 | Título definitivo | Antes de cualquier publicación |
| P08 | Fuente definitiva | Resuelta en Fase 1: T17 |
| P09 | ¿Arranque automático con Windows como opción? | Fase 2 |
| P10 | Franja en varios monitores: en cuál se coloca | Fase 2 |

## Cómo añadir decisiones

Añadir una fila con el siguiente identificador libre, la fecha si no es del 2026-11-12 y el motivo. No borrar decisiones antiguas: si una cambia, marcarla como "sustituida por Dxx".
