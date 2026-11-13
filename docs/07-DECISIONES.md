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
| D32 | Altura de la franja (P01) | Ajustable por el jugador; 12 filas por defecto (entre 10 y 24). 2026-11-13 |
| D33 | Arranque con Windows (P09) | Opción en Ajustes, desactivada por defecto. 2026-11-13 |
| D34 | Varios monitores (P10) | Monitor principal por defecto, con selector en Ajustes para elegir otro. 2026-11-13 |

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
| T23 | Los componentes de interfaz son `AsciiDrawable` propios (`AsciiWidget`), no nodos `Control` | Mantiene un solo lienzo (T06/T18) y estética ASCII exacta; `UiRoot` reparte ratón y teclado |
| T24 | Tamaño de fuente = 17 px × escala de Windows (DPI/96); altura de ventana = filas × alto de celda | `screen_get_scale` no existe en Windows; la franja se ve igual a 100, 125 y 150 % |
| T25 | `Platform` (autoload) consulta pantallas cada 1 s y recoloca la franja (máx. 3 intentos) | `dpi_changed` solo funciona en macOS y Wayland; cubre cambios de resolución, escala, monitor y barra de tareas |
| T26 | Único uso de `OS.execute`: `reg.exe` para la clave `HKCU\...\Run`, solo en Windows con juego exportado, con argumentos fijos de `AutostartCommand` | No hay API de Godot para el arranque con Windows. Excepción a doc 06 §7, acotada y comprobada por tests |
| T27 | La ventana arranca con `no_focus` (no roba el foco); el primer clic llama a `Platform.enable_keyboard_focus()` | Con `no_focus` Godot ignora el teclado; así se ve y se usa sin interrumpir lo que Jorge esté haciendo |
| T28 | Ajustes en `user://settings.json`, validación estricta con límites y valores por defecto; guardado diferido 0,5 s y escritura atómica | Doc 06 §6 |
| T29 | Minimizada, la ventana pone en pausa dibujo y simulación (`PROCESS_MODE_DISABLED`) | Bajo consumo (T07) |
| T30 | Símbolos de rareza accesibles sin depender del color: `· + * # @` | Doc 05 y accesibilidad (Fase 15) |
| T31 | Orden de foco por grupos (`focus_group`): un panel abierto recibe el foco con Tab antes que la barra lateral | Teclado natural al abrir tienda o ajustes |
| T32 | `SpeciesDef` (en `data/`) sustituye a `SwimmerDef`: reúne aspecto y economía de una especie | Una sola definición por especie (T19); `SwimmerDef` se elimina |
| T33 | Los costes se redondean hacia arriba con una tolerancia de 1e-9 | Evita que 50×1,6² = 128,00000000000003 cueste 129 |
| T34 | `FixedStepper`: pasos de 0,1 s, máximo 5 por fotograma, el exceso se descarta; tolerancia de 1e-9 | Sin espiral tras una pausa (D11) y sin pasos perdidos por coma flotante |
| T35 | `Game` y `EventBus` son autoloads; `Game` emite `shells_changed` y `production_changed` una vez por fotograma, no por paso | Evita inundar la interfaz de señales |
| T36 | La partida nueva da 20 conchas y 3 peces de prueba (guppy, pececillo, pez ángel); las especies `test_*` se sustituirán en la Fase 5 | Valores provisionales hasta el balance (Fase 16) |
| T37 | `Simulation.step` recibe el generador aleatorio pero todavía no lo usa | Reservado para cuidados, cría y eventos; el test de determinismo se vuelve estricto cuando entren |

## C. Pendientes (no bloquean el inicio)

| ID | Pregunta | Cuándo hace falta |
|---|---|---|
| P01 | Altura de la franja y si es ajustable por el jugador | Resuelta en Fase 2: D32 |
| P02 | Cómo se abren tienda y Pecedex dentro de la franja: panel lateral o ventana que crece hacia arriba | Prototipo hecho en Fase 2 con ambos modos (Ajustes → modo de paneles). **Pendiente de que Jorge elija** |
| P03 | Lista definitiva de biomas y especies (el GDD trae una propuesta) | Fase 5 y Fase 10 |
| P04 | Nombre de la moneda y de la moneda de prestigio | Fase 3 |
| P05 | Qué conserva exactamente el prestigio | Fase 13 |
| P06 | Estilo concreto de la música y origen de los sonidos | Fase 14 |
| P07 | Título definitivo | Antes de cualquier publicación |
| P08 | Fuente definitiva | Resuelta en Fase 1: T17 |
| P09 | ¿Arranque automático con Windows como opción? | Resuelta en Fase 2: D33 |
| P10 | Franja en varios monitores: en cuál se coloca | Resuelta en Fase 2: D34 |

## Cómo añadir decisiones

Añadir una fila con el siguiente identificador libre, la fecha si no es del 2026-11-12 y el motivo. No borrar decisiones antiguas: si una cambia, marcarla como "sustituida por Dxx".
