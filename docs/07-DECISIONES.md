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
| D09 | Colección | Especies con rarezas, Enciclopedia y logros. Sin genética heredada |
| D10 | Pecera y progreso | Decoración colocable, equipamiento mejorable, varias peceras o biomas, prestigio |
| D11 | Ambiente | Día/noche con hora real y eventos aleatorios. **Sin progreso con el juego cerrado** |
| D12 | Final | Meta final y después modo infinito |
| D13 | Meta final | Completar el Enciclopedia |
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
| D27 | Cría | Cría con variantes de color raras que valen más y cuentan en el Enciclopedia |
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
| P02 | Cómo se abren tienda y Enciclopedia dentro de la franja: panel lateral o ventana que crece hacia arriba | Prototipo hecho en Fase 2 con ambos modos (Ajustes → modo de paneles). **Pendiente de que Jorge elija** |
| P11 | Pasada de estilo al terminar la Fase 16: acercar las animaciones y la estética al HTML del primer prototipo, más pequeñas mejoras estéticas | Jorge aportará la documentación y el HTML de referencia; no antes de la 1.0 funcional |
| P03 | Lista definitiva de biomas y especies (el GDD trae una propuesta) | Fase 5 y Fase 10 |
| P04 | Nombre de la moneda y de la moneda de prestigio | Fase 3 |
| P05 | Qué conserva exactamente el prestigio | Resuelta en la Fase 13 (T128) |
| P06 | Estilo concreto de la música y origen de los sonidos | Fase 14 |
| P07 | Título definitivo | Antes de cualquier publicación |
| P08 | Fuente definitiva | Resuelta en Fase 1: T17 |
| P09 | ¿Arranque automático con Windows como opción? | Resuelta en Fase 2: D33 |
| P10 | Franja en varios monitores: en cuál se coloca | Resuelta en Fase 2: D34 |

| T38 | El guardado solo es JSON; nunca `load()` ni `ResourceLoader` sobre `user://` | 06-SEGURIDAD: un archivo ajeno no puede ejecutar código |
| T39 | Escritura atómica: `save.tmp` → releer y comparar → rotar copias → renombrar | Matar el proceso en cualquier punto deja el guardado anterior intacto |
| T40 | La suma SHA-256 va sobre `data` canónico (pasado por JSON); detecta corrupción y ediciones torpes, no a un tramposo decidido | Es un juego de un jugador; la validación de rangos es la defensa real |
| T41 | Un archivo de `format_version` mayor nunca se carga ni se sobrescribe; se bloquea el guardado | Evita destruir una partida de una versión futura |
| T42 | Los archivos ilegibles se apartan (`corrupt_<unix>_<nombre>`), máximo 5 | No se pierden por si Jorge quiere inspeccionarlos |
| T43 | `SaveService` no arranca solo: lo inicia `StripController`; los tests nunca tocan `user://saves` | Proteger la partida real del jugador |
| T44 | `rng_seed` y `rng_state` se guardan como cadenas | JSON usa decimales de 64 bits y perdería enteros grandes |

| T45 | Las condiciones de desbloqueo son datos en la especie: una sola condición por especie (conchas totales, peces totales o peces de otra especie) | Declarativo y sin código por especie; combinaciones más ricas (equipo, bioma) llegan con las fases 8 a 10 |
| T46 | Una especie desbloqueada no se vuelve a bloquear; la lista se guarda en la partida | Vender peces no debe quitar lo conseguido |
| T47 | Ids de especie definitivos con prefijo de bioma (`pond_guppy`…); la migración 1→2 renombra las de prueba | Las partidas de las fases 3 y 4 siguen funcionando |
| T48 | Los peces se detectan con `_input` en `TankView` (no `_unhandled_input`) y solo si `UiRoot` no consumió el clic | En Godot 4.6 el clic no llegaba a `_unhandled_input` |
| T49 | La ficha del pez es una superposición sobre la pecera, no un panel que sustituye la pecera | El clic sobre un pez no debe hacer desaparecer la pecera en el modo A de P02 |
| T50 | Producciones de partida a ~0,3× de la primera propuesta; un jugador óptimo desbloquea la koi hacia el minuto 27 | Simulación rápida en la sesión; el ajuste real es de la Fase 16 |

| T51 | Hambre: 600 s de lleno a vacío; limpieza: −0,003 por pez y segundo; cada mancha limpiada da +10; felicidad = 55 % saciedad + 45 % limpieza (la comodidad entrará con la decoración) | Valores de partida; se ajustan en la Fase 16. Con todo a cero la producción es ×0,25, nunca 0 |
| T52 | Las manchas de alga no son estado propio: su número sale de la limpieza (`Care.spots_for`) y sus posiciones son fijas por semilla | Menos estado que guardar y la pecera no «baila» al ensuciarse |
| T53 | Las perlas las decide la simulación con el generador de la partida (cola `pending_pearls`) y las dibuja la vista; no se guardan | Determinismo; una perla sin recoger al cerrar no merece guardarse |
| T54 | Perla = 30 s de producción del pez que la suelta (mínimo 1 concha); con más de 12 en pantalla la más antigua se recoge sola | Nada se pierde (pilar 1 del GDD) |
| T55 | Orden del clic en el agua: limpiar mancha, recoger perla, abrir ficha de pez y, si no, echar comida | La mancha está «delante» del cristal; la comida es la acción por defecto |
| T56 | Una mancha por cada 10 puntos de suciedad completos (`floor`, no `ceil`) | Con `ceil`, cualquier suciedad mínima mostraba una mancha que reaparecía al instante tras limpiarla (bug visto en pruebas manuales) |
| T57 | La limpieza se muestra como texto con color en la fila 9 del panel lateral, solo con 11+ filas | Con 10 filas (mínimo) no hay hueco; las manchas siguen avisando |
| T58 | La etapa sale de la **madurez** (0 a 1): alevín <0,3, juvenil <1, adulto 1; el tiempo de crecimiento es un dato por especie | Cambiar tiempos o umbrales no toca el resto del código |
| T59 | El huevo no es un pez: es un `Egg` aparte que ocupa un hueco de capacidad y eclosiona en un pez de madurez 0 | La capacidad se respeta siempre y la variante se sortea al poner |
| T60 | Cría por especie: felicidad media de adultos >= 60, al menos 2 adultos, hueco libre; cada pareja (hasta 4) acelera la puesta | Cumple el criterio de la Fase 7 sin pares explícitos |
| T61 | Peces comprados y partidas antiguas: adultos de variante normal; solo la cría sortea variante | Comprar no da variantes raras; la cría es el camino |
| T62 | Valor de venta = 0,5 × coste base × variante × etapa (alevín 0,2; juvenil 0,5), mínimo 1 | Criar y vender solo rinde un poco: queda para el balance de la Fase 16 |
| T63 | Venta con doble pulsación («¿Seguro?»). «Sobrantes» solo para variante normal y conserva los 2 peces más maduros | Evita vender por error variantes raras o la pareja de cría |
| T64 | Sprites de alevín y juvenil genéricos con la paleta de cada especie; una especie puede traer los suyos (`fry_sprite_path`, `juvenile_sprite_path`; el caracol los trae) | Coste de arte bajo ahora; la pasada de estilo puede afinarlos |
| T65 | Variantes = transformación de color de la paleta (`VariantPalette`), no paletas escritas a mano | Una variante nueva no necesita arte; la prismática se anima con el tiempo |
| T66 | `GameState.discovered` guarda las combinaciones especie+variante vistas | Base del Enciclopedia (Fase 11) y del aviso de variante nueva |
| T67 | Guardado formato 3: peces con `maturity` y `variant_id`, peceras con `eggs`, estado con `discovered` | Migración 2→3 rellena los valores por defecto |
| T68 | Vaciar la pecera = botón «Vender todos los peces» en Ajustes, con tres pulsaciones (pedir, confirmar, vender); paga el valor de venta y descarta los huevos | Jorge quería una forma de vaciar la pecera persistente; vender evita perder conchas |
| T69 | Equipo = `EquipmentDef` (recurso en `content/equipment/`) con efecto, niveles (máx. 5), coste base y fuerza por nivel; el nivel k cuesta base × 1,6^k | Añadir un equipo no toca código salvo un efecto nuevo |
| T70 | Los efectos se suman en `TankBonuses` (calculado al comprar o cargar, no se guarda); la partida solo guarda `equipment` (id → nivel) por pecera | Una sola fuente de verdad y bonos que se acumulan sin errores |
| T71 | Efectos: filtro (suciedad −20 %/nivel hasta ×0,2 y limpia 0,36 pts/min por nivel), comedero (+30 de saciedad cada 300/nivel s), calentador (+12 % de comodidad/nivel), lámpara (crecimiento +25 %/nivel), aireador (+4 huecos/nivel), incubadora (eclosión +30 % y variantes raras +40 %/nivel), imán (recoge perlas tras 24/nivel s en el suelo) | Con filtro 5 y comedero 3 una pecera llena se mantiene sola (test); cifras finales en la Fase 16 |
| T72 | El calentador sube la felicidad de todos los peces (no hay especies tropicales aún) y la lámpara aún no atenúa la noche (llega con el día/noche, Fase 12) | Se completa en la Fase 12 |
| T73 | Capacidad = `capacity` (guardada) + hueco del aireador (`Tank.total_capacity()`) | Quitar el aireador nunca expulsa peces ya guardados: la pecera solo queda «llena» |
| T74 | Tienda con pestañas Peces / Equipo; los equipos se dibujan en la pecera con animación de 2 fotogramas y el aireador suelta burbujas | Feedback visual de cada compra |
| T75 | Guardado formato 4: peceras con `equipment`; migración 3→4 la crea vacía; ids desconocidos se descartan y niveles se limitan al máximo | Seguridad al cargar (06-SEGURIDAD §3.4) |
| T76 | Decoración = `DecorationDef` (recurso en `content/decorations/`, 20 objetos): capa (fondo o delante de los peces), ancla (suelo o flotando), bonificación (comodidad, producción o variantes raras), etiqueta y tamaño en celdas | Añadir un objeto no toca código; una prueba comprueba que el tamaño coincide con el sprite |
| T77 | La posición se guarda en milésimas del hueco libre (`x`) y filas sobre el suelo (`y`), no en celdas | Sobrevive a cambiar de monitor, escala o altura de la franja |
| T78 | Reglas de colocación (`DecorationLayout`): máx. 12 objetos por pecera, que quepa en el agua, solo en el suelo si el ancla es suelo, y sin solape dentro de la misma capa (objetos de capas distintas pueden compartir celdas) | Legibilidad y rendimiento (GDD §8) |
| T79 | Bonificaciones con tope: comodidad hasta 0,9 (suma la del calentador), producción hasta +50 %, variantes raras sumadas | Que la decoración ayude sin romper el equilibrio |
| T80 | Inventario global `decoration_stock`: comprar guarda el objeto sin colocar; el coste sube ×1,3 por cada objeto del mismo tipo (colocado o guardado) | Comprar y colocar son pasos separados, como en el GDD |
| T81 | Modo decorar (tecla `D` o botón en la pestaña de decoración): vista previa verde/roja, clic = colocar o recoger, clic derecho = guardar, rueda o `C` = cambiar de objeto, `Esc` = salir. Recoger un objeto lo devuelve al inventario y lo lleva en la mano; si se cancela, queda guardado | Cómodo dentro de la franja sin abrir paneles que tapen la pecera |
| T82 | Algunas especies piden una etiqueta de decoración (`UnlockKind.DECORATION_TAG`): la lota ahora requiere una cueva (`cave`) | Es la idea del GDD §8; las partidas que ya la tenían la conservan |
| T83 | Guardado formato 5: peceras con `decorations`, estado con `decoration_stock`; migración 4→5 los crea vacíos | Seguridad al cargar: ids desconocidos descartados, cantidades limitadas |
| T84 | Bioma = `BiomeDef` (recurso en `content/biomes/`) cargado por `BiomeCatalog`; una pecera pertenece a un bioma por su `biome_id`, y tener la pecera es tener el bioma desbloqueado (no hay lista aparte) | Una sola fuente de verdad; el prestigio (Fase 13) conservará las peceras abiertas |
| T85 | Nueva partida con solo el Estanque; el Arrecife se abre en la tienda (pestaña «Biomas») por 6000 ¢ y pide el Estanque. Una pecera por bioma (los biomas repetidos al cargar se descartan) | Progresión clara; coste provisional hasta la Fase 16 |
| T86 | Pecera activa (`GameState.active_tank`, guardada). Todas las órdenes de `Game` actúan sobre ella; las especies solo se compran en la pecera de su bioma (`WRONG_BIOME`) | Evita peces en el bioma equivocado |
| T87 | Las peceras ocultas usan **exactamente** la misma simulación que la visible (no una versión aparte): la producción ya sumaba todas y los cuidados, la cría y las perlas ya iban por pecera | Garantiza por construcción que oculta = visible; un test lo comprueba (Fase 10.6) |
| T88 | Perlas de una pecera oculta: se cobran solas al soltarse. Al salir de una pecera se cobran las perlas que quedaban sin recoger | Nada se pierde (pilar «no castigar»); evita acumular perlas que nadie ve |
| T89 | Pestañas de pecera sobre la fila de la superficie (sin gastar altura), solo con 2 o más peceras y ocultas mientras un panel tapa la pecera; teclas `1`–`8` para cambiar | La franja es baja: no se puede perder una fila |
| T90 | Cada bioma define su aspecto con datos: patrón y color de la superficie, granos de arena, caracteres de plantas, color de burbujas, relleno de fondo y partículas flotantes con caída propia | Un bioma nuevo no toca código; cumple «identidad visual clara» |
| T91 | Decoración con `biome_id` opcional: vacío vale para todos; la tienda filtra por el bioma activo. Las etiquetas de desbloqueo cuentan en todas las peceras | Equipo y decoración específicos de bioma (10.5) sin duplicar los objetos universales |
| T92 | Guardado formato 6: `active_tank`; migración 5→6 la pone a 0 | Seguridad al cargar: se limita al rango de peceras |
| T93 | Entrega en dos partes: 10A (sistema + Arrecife) y 10B (Manglar y Abismo, 16 especies) | Decisión de Jorge: revisar el sistema antes de multiplicar el contenido |
| T94 | Cadena de biomas: Estanque → Arrecife (6 000) → Manglar (90 000) → Abismo (700 000), cada uno exige el anterior | Progresión clara; el coste sigue la curva de la economía (cada bioma ~10-15× el anterior) |
| T95 | Las especies de cada bioma repiten la estructura (2 comunes, 2 poco comunes, 2 raras, 1 épica, 1 legendaria) y la economía del bioma nuevo empieza por encima del final del anterior | Los tests de contenido lo exigen; el balance fino queda para la Fase 16 |
| T96 | Etiquetas propias por bioma (raíz, fango, brillo, fumarola, huesos, señuelo): las especies de más rareza piden decoración de su bioma | Da sentido a decorar y a la tienda de decoración |
| T97 | El Abismo no tiene relleno de fondo (`backdrop_char` vacío): la oscuridad es la identidad visual y las partículas luminosas hacen de «nieve marina» | Contraste máximo con los otros biomas |
| T98 | Fase 11 en dos entregas: 11A (estadísticas y Enciclopedia) y 11B (logros y recompensas) | Decisión de Jorge: revisar la colección antes de añadir los 40-60 logros |
| T99 | El Enciclopedia es una pestaña de la tienda (tecla `E` y botón de la barra lateral), no un panel aparte | Decisión de Jorge; reutiliza el panel lateral y su navegación |
| T100 | Una especie se descubre al tener un pez suyo; cada variante cuenta aparte. El Enciclopedia está completo con todas las variantes de todas las especies | Coherente con D13 y D27 (las variantes raras cuentan) |
| T101 | Las especies no descubiertas se ven como «???» con su rareza (silueta de texto) en vez de ocultarse | Muestra cuánto queda por descubrir sin revelar el nombre |
| T102 | `GameStats` solo admite una lista cerrada de contadores y los limita a 1e12; lo desconocido de un archivo se descarta | Cumple 06-SEGURIDAD: nada del archivo se usa como nombre libre |
| T103 | Guardado formato 7: `stats`. Las partidas antiguas no pueden reconstruir sus estadísticas y empiezan a cero; el Enciclopedia sí es retroactivo (se rellena con los peces presentes al cargar) | Honestidad con los datos que no existen |
| T104 | Los logros darán un bonus de producción permanente pequeño con tope total | Decisión de Jorge para la 11B |
| T105 | El Pecedex pasa a llamarse **Enciclopedia** (clase `Encyclopedia`, tecla `E`, también en inglés) para no chocar con una marca ajena | Decisión de Jorge |
| T106 | Retrato animado en la Enciclopedia: pecera en miniatura. Un `SwimMotion` real (onda, inclinación, giros) con la amplitud ×3 (máx. 0,9 celdas) nada despacio (×0,22 de la velocidad de su especie) dentro del recuadro; muestra por turnos las variantes tenidas y la silueta (`▓`) si no se ha descubierto | Decisión de Jorge: «moverse como en la pecera». Descartado recolocar el pez en cada fotograma: rompía el cuerpo (cola desencajada) y vibraba |
| T107 | Los logros son datos (`AchievementDef`): una métrica de un conjunto cerrado (contador de `GameStats` u otra cifra de la partida), una meta y una recompensa. La descripción se genera con la plantilla de la métrica; en `strings.csv` solo va el nombre | Añadir un logro no toca código ni obliga a escribir dos frases |
| T108 | Bonus de logros (concreta T104): +0,25 % a +2 % de producción cada uno, suma con tope de +50 %. Los 60 logros suman 62 %, así que el tope se alcanza antes de tenerlos todos | Recompensa permanente pero acotada; el balance fino queda para la Fase 16 |
| T109 | Los logros se comprueban cada 0,5 s y al cargar. Al cargar se conceden en silencio (retroactivo); la producción se recalcula hasta que no salga ninguno nuevo | Una partida antigua no inunda de avisos; un logro de producción puede cumplirse gracias al bonus de otro |
| T110 | Guardado formato 8: `achievements` (id → `true`). Lo desconocido se descarta; los contadores antiguos ya eran retroactivos o empezaban a cero (T103) | 06-SEGURIDAD: nada del archivo se usa como nombre libre |
| T111 | Logros y Estadísticas son pestañas de la tienda (5 y 6); tecla `L` para Logros. `AchievementText` formatea y `ShopPanel` solo muestra | Decisión de Jorge (T99); mantiene `ShopPanel` y `ContentDB` por debajo de los límites del linter |
| T112 | El pez solo avanza en el sentido en que mira; para ir al otro lado frena, gira y arranca (`velocity.x * facing >= 0` siempre) | Decisión de Jorge: nadar hacia atrás no tenía sentido |
| T113 | Giro de canto: `turn_scale` baja de 1 a 0 y vuelve a 1 en 0,45 s; el sentido cambia en el punto más plano y a ese ancho se dibuja una línea `|` | Decisión de Jorge (referencia: Paper Mario); es de presentación, no cambia la simulación |
| T114 | Los estilos `CRAWL` se anclan al suelo (`position.y = bounds.end.y`), sin onda ni inclinación, con pasos y paradas | Antes aparecían a media agua y descendían despacio: «flotaban» |
| T115 | Efecto CRT con sombreador sobre toda la ventana (`hint_screen_texture`), tres niveles guardados en ajustes; el 2 (completo) es el valor por defecto. Sin curvatura de pantalla | Decisión de Jorge (CRT completo); la curvatura recortaría la franja baja. La Fase 15 solo afinará y añadirá accesibilidad |
| T116 | `AsciiToast` mantiene una cola corta en vez de pisar el aviso visible | Con los logros pueden coincidir varios avisos |
| T117 | Cuando algo no sale como Jorge espera y no está claro el motivo, se le hace una pregunta concreta antes de probar soluciones a ciegas | Petición de Jorge (ahorra tokens) |
| T118 | El día se divide en amanecer (6–8), día (8–18), atardecer (18–21) y noche (21–6) con una «oscuridad» de 0 a 1 que varía con `smoothstep` en los tramos de transición | GDD §12: cuatro franjas con transición suave |
| T119 | Las especies tienen `activity` (neutra, diurna, nocturna). Efecto de ±15 % en la producción según la oscuridad (respuesta de Jorge: «suave»); se compensa a lo largo de un día. Nocturnas: peces de hábitos nocturnos (lota, tetra, raya, caballito, bagre, cangrejo, camarón, barracuda); diurnas: los de colores y de superficie (carpa, koi, escalar, piscardo, payaso, mariposa, damisela, cirujano, globo). El guppy inicial y el Abismo son neutros | GDD §12; evita castigar a quien juega a una sola hora |
| T120 | La lámpara solo quita la parte negativa del efecto nocturno (`night_shield` = 0,8 × fuerza, tope 1) y aclara el tinte hasta un 50 % | «Efecto suave, la lámpara compensa» (D11); no resta el bonus, así no hay decisión absurda |
| T121 | El reloj es inyectable (`DayClock`; `FixedDayClock` en tests). `P3C3R4_HOUR` fuerza la hora al arrancar y F6 la adelanta 1 h | Probar sin tocar el reloj de Windows; tests deterministas |
| T122 | Anti-abuso de la hora: cambiar el reloj del sistema no genera tiempo de juego ni conchas; solo mueve la franja, con un límite de ±15 % en la producción de una especie y casi neutro con peces mixtos | Criterio de aceptación de la Fase 12 |
| T123 | Los eventos no se guardan; el planificador usa su propio generador (semilla de la partida + sal) y espera entre 240 y 480 s con el juego abierto (reintento a los 30 s si no hay evento posible). Solo un evento clicable a la vez | Respuesta de Jorge (cada 4–8 min); no altera las secuencias de perlas y crías; D11 |
| T124 | Recompensas: visitante, pez dorado y botella pagan `max(mínimo, producción × segundos)`; la botella da una decoración al azar (conchas si el inventario está lleno); la plaga de algas paga solo si el jugador limpia al menos 3 manchas hasta dejarla ≥ 90 % (si el filtro la limpia sola, termina sin premio ni castigo) | Los eventos deben valer la pena al empezar y al final de la partida |
| T125 | El *Visitante raro* es un pez raro o mejor del bioma activo con aspecto prismático/dorado que da conchas; no cuenta para la Enciclopedia ni para los logros | Respuesta de Jorge («Conchas y aviso»); mantiene las 32 especies y los 60 logros |
| T126 | El tinte es un rectángulo translúcido sobre la zona de la pecera (capa 22) y la corriente cálida añade un velo anaranjado | La interfaz queda por encima sin tinte; barato de dibujar |
| T127 | Barra lateral: conchas y producción en la misma fila, reloj debajo con color por hora (`ClockPalette`, gradiente cálido→frío), botones a la izquierda y fila en blanco si hay ≥ 10 filas | Petición de Jorge; el reloj se lee de un vistazo sin añadir texto |
| T128 | P05 resuelta (respuesta de Jorge): el reinicio conserva Enciclopedia, logros, decoración y peceras abiertas; reinicia conchas, peces, huevos y equipamiento. Siguen siendo suyos las estadísticas, las especies ya desbloqueadas, las mejoras y las perlas negras | Es la propuesta del GDD §13; el ciclo nuevo empieza rápido pero con la colección intacta |
| T129 | Perlas negras = ⌊√(conchas ganadas en el ciclo ÷ 10⁵)⌋; el ciclo se mide con `Wallet.total_earned` menos `PrestigeState.run_start_earned` (el total de por vida no se reinicia, así logros y desbloqueos no se ven afectados) | Respuesta de Jorge (raíz cuadrada); crece despacio, conviene esperar |
| T130 | Mejoras: producción, arranque rápido, suerte de variantes y valor de perlas (los cuatro efectos que Jorge eligió); coste en perlas negras = `base × crecimiento^nivel` con tope de nivel por mejora | Datos en `content/prestige/`; el balance fino queda para la Fase 16 |
| T131 | El final se dispara al tener las 160 combinaciones especie × variante (mismo criterio que el logro `collection_100`); regala el Trofeo de la Gran marea y no bloquea nada: sigue el modo infinito con prestigio ilimitado | GDD §13 y D12/D13; respuesta de Jorge («secuencia ASCII + decoración dorada») |
| T132 | `PrestigeDirector` (`Game.prestige`) agrupa reinicio, compra de mejoras y detección del final; el reinicio construye un `GameState` nuevo (`Prestige.next_run`) y lo adopta con `adopt_state` | `GameService` ya llegaba al máximo de métodos públicos; reutiliza el camino de carga |
| T133 | Los símbolos del reloj son `▲ ○ ▼ ●` (de la tabla de `AsciiCharset`) | `☀ ☾ ◐` no están en la fuente y se veían como `*` |

## Cómo añadir decisiones

Añadir una fila con el siguiente identificador libre, la fecha si no es del 2026-11-12 y el motivo. No borrar decisiones antiguas: si una cambia, marcarla como "sustituida por Dxx".
