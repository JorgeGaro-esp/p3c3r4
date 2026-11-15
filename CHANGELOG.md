# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado `0.x.0` por fase hasta la `1.0.0`.

## [0.36.0] - 2026-11-15 · Personalización (apodo y favorito)

### Añadido
- **Apodo**: en la ficha, el botón «Apodo ►» recorre una lista de 20 nombres (Burbuja, Coral, Perla…) y vuelve a «sin apodo». Se guarda con el pez.
- **Favorito** (◆): un favorito no se puede vender ni entra en «Sobrantes». Se guarda con el pez; las partidas antiguas cargan sin avisos.
- La ficha crece una fila para los dos botones nuevos.

## [0.35.0] - 2026-11-14 · Pecera con más vida

### Añadido
- **Carácter ante el cursor** (`temperament` en `SpeciesDef`, de -1 huidizo a 1 curioso): sardinas, anchoas, krill, ranas y renacuajos se apartan del puntero; koi, carpas, peces de colores, payasos y rayas se acercan a mirarlo sin llegar a tocarlo.
- **Susto por clic**: al soltar comida en el agua, los peces huidizos cercanos salen disparados un momento.
- **Sueño según la hora**: los diurnos se vuelven lentos, se paran casi siempre y se hunden hacia el fondo de noche; los nocturnos, igual pero de día. Los neutros apenas.
- Tests en `test_swim_reactions.gd`.

## [0.34.0] - 2026-11-14 · Comportamiento realista

### Añadido
- **Franja de profundidad por especie** (`depth_min`/`depth_max`): el Siluro, el Rape, la Anguila o la Raya viven cerca del fondo; el Arawana, el Pez arquero y el Cocodrilo junto a la superficie; el resto, en medio.
- **Paradas** (`rest_chance`/`rest_seconds`): los emboscadores (Siluro, Rape, Pez gota, Cocodrilo) pasan mucho tiempo quietos; el Tiburón, el Atún o el Cachalote nunca paran. La comida los despierta.
- **Estilo «a saltos»** (`HOP`): la Rana espera posada en el suelo y salta en arco, en vez de flotar.
- **Más bancos**: Salmón, Atún, Calamar, Pez payaso, Koi y Pez de colores nadan con los de su especie (menos pegados que sardinas y anchoas).
- `docs/COMPORTAMIENTO.md` con la tabla de todas las especies.

### Cambiado
- Velocidades y estilos de casi todas las especies (Atún y Salmón crucero constante, Cangrejo y Saltarín a pie, Medusa y Pez gota a la deriva, Calamar a chorros).
- La ficha del pez crece una fila: los botones de vender ya no se salen por debajo del marco.

## [0.33.0] - 2026-11-14 · Pecera más calmada y Enciclopedia por biomas

### Cambiado
- **Todos los peces rediseñados con forma de pez**: siguiendo los modelos de Trucha, Sardina, Anguila y Guppy (una o dos filas, cola `><`, cuerpo con textura, ojo fijo), cada especie recibe su toque y su paleta de varios colores: Koi con manchas `◆` rojas, Salmón rosa con rayas plateadas y aleta dorsal, Pez payaso con bandas blancas, Atún azul de vientre plateado, Calamar rosa con tentáculos, Raya `◄ ►`, Tiburón con aleta `▲`, Rana, Pez arquero con chorro, Cocodrilo, Pez linterna con luces amarillas, Rape con señuelo, Calamar gigante rojo, Cachalote… Los juveniles se regeneran con la misma forma.
- **Ajustes tras probarlos**: aletas dorsales centradas sobre el cuerpo (Pez de colores, Salmón, Atún, Manta raya, Arawana, Cocodrilo, Cachalote); Salmón rojo de cabeza verde; Koi con el dibujo de la Carpa y colores de koi; Siluro y Pez gato con bigotes bajo el hocico y sin "visera"; Anchoa diminuta; Krill rojo; Renacuajo verde pardo; el Cangrejo violinista pasa a **Cangrejo de río** (mismo id, mismo hueco); Saltarín del fango rediseñado con el ojo abultado y aletas pectorales; Barracuda anima solo la cola; Anguila ondula con los rizos del cuerpo; Medusa abisal con cúpula cerrada; Pez gota más plano y sin aletas bajas; Calamar gigante sin parte superior, como el calamar.
- **Segunda ronda de retoques**: Salmón con aleta `___`, Tiburón con la `▲` más atrás, Arawana con aleta `_____`, Medusa con cúpula `___`, Cachalote con lomo `,-----.` y Krill con el círculo rojizo.
- Tope de tamaño: ninguna especie pasa de 12 columnas ni de 3 filas.
- **La ficha del pez va por encima de las pestañas de la pecera**, sin mezclarse con los biomas.
- **Enciclopedia dividida por biomas**: una pestaña por bioma bajo el título; al abrir una especie desde la ficha se selecciona su bioma.
- Los peces siguen siendo transparentes (se probó un fondo negro por pez y se descartó, T183).

## [0.32.0] - 2026-11-14 · Enciclopedia 2: Abismo (completa)

### Cambiado
- **Abismo rediseñado** (8 especies): Pez linterna, Medusa abisal, Pez víbora, Pez gota, Rape abisal, Pez pelícano, Calamar gigante (nuevo diseño ASCII vertical) y Cachalote (legendario, grande). Cada una hereda el hueco de rareza, coste, producción y desbloqueo de la que sustituye.
- Cada especie con su cría y juvenil propios; ojo fijo y solo se mueven la cola, las aletas o los tentáculos.
- Formato de guardado 13: hacha→pez víbora, calamar vampiro→pez gota, pez víbora→rape, rape→pez pelícano, pez remo→calamar gigante, calamar gigante→cachalote.

### Eliminado
- Pez hacha, Calamar vampiro y Pez remo.

## [0.31.0] - 2026-11-14 · Enciclopedia 2: Manglar

### Cambiado
- **Manglar rediseñado** (8 especies): Renacuajo (diminuto, en bancos), Rana, Cangrejo violinista, Saltarín del fango, Pez arquero, Barracuda, Arawana y Cocodrilo (legendario, grande). Cada una hereda el hueco de rareza, coste, producción y desbloqueo de la que sustituye.
- Cada especie con su cría y juvenil propios; ojo fijo y solo se mueve la cola, las aletas o las patas.
- Formato de guardado 12: arquero→renacuajo, cangrejo→rana, gamba→cangrejo, siluro→saltarín, pargo→arquero, saltarín→barracuda, barracuda→arawana, pez sierra→cocodrilo.

### Eliminado
- Gamba de manglar, Siluro del manglar, Pargo de manglar y Pez sierra.

## [0.30.0] - 2026-11-14 · Enciclopedia 2: Arrecife

### Cambiado
- **Arrecife rediseñado** (9 especies): Krill (diminuto, la más común, en bancos), Sardina, Anchoa, Pez payaso, Anguila, Atún, Calamar (rediseño ASCII), Manta raya y Tiburón (legendario, grande). Cada una hereda el hueco de rareza, coste, producción y desbloqueo de la que sustituye; el pez payaso se desbloquea con 3 sardinas, el atún con 3 anchoas y la raya con 3 atunes.
- Cada especie con su cría y juvenil propios (la del calamar, `<:≈`); ojo fijo y solo se mueve la cola o las aletas.
- Logro «Experto en arrecifes» pide 9 especies.
- Formato de guardado 11: peces, huevos, desbloqueos y descubrimientos pasan a la especie que ocupa el hueco (damisela→anchoa, mariposa→pez payaso, estrella→anguila, cirujano→atún, caballito→calamar, globo→raya, raya→tiburón).

### Eliminado
- Damisela azul, Pez mariposa, Estrella de mar, Cirujano azul, Caballito de mar y Pez globo.

## [0.29.1] - 2026-11-14 · Foto de la Enciclopedia para peces grandes

### Corregido
- Los peces anchos (Siluro, 24 columnas; luego tiburón, cocodrilo, cachalote) no se veían en la foto de la Enciclopedia: la foto se ensancha según el pez más ancho (sin quitar sitio al texto) y, si aun así no cabe, enseña su juvenil o su cría en vez de quedarse vacía.

## [0.29.0] - 2026-11-14 · Enciclopedia 2: Estanque

### Cambiado
- **Estanque rediseñado** (8 especies): Guppy (diminuto, tamaño de cría), Carpa, Pez de colores, Pez gato, Trucha, Salmón (cabeza verde y cuerpo rojo), Carpa koi y Siluro (gigante, legendario). Cada una hereda el hueco de rareza, coste, producción y desbloqueo de la que sustituye; el Salmón se desbloquea con 3 peces de colores y el Siluro con 3 salmones.
- **Cada especie tiene su cría y su juvenil propios** (antes eran genéricos).
- **Animación**: el ojo es siempre el mismo carácter y solo se mueven la cola o las aletas. Cada especie fija su serpenteo (`wave_number`), su velocidad y su estilo; el Guppy tiende a nadar en pequeños bancos.
- Formato de guardado 10: los peces, huevos, especies desbloqueadas y descubrimientos de las especies que salen pasan a la que ocupa su hueco (pececillo→carpa, tetra→pez de colores, locha→pez gato, caracol→trucha, ángel→salmón).

### Eliminado
- Pececillo, Tetra neón, Locha, Caracol y Pez ángel (sus archivos `.tres` y sprites).

### Tests
- `test_species_animation`: el ojo no cambia entre fotogramas y solo se mueven la cola o las aletas; cada especie tiene cría y juvenil propios. Se amplía bioma a bioma.
- `test_pond_migration`: migración 9 → 10.

## [0.28.0] - 2026-11-14 · Nado más natural

### Añadido
- `SpeciesDef.wave_number` (cuánto serpentea el cuerpo: 1 rígido, 8 como una anguila) y `SpeciesDef.school_pull` (tendencia a nadar en banco). Cada especie los fija en su `.tres`; por defecto todo queda como antes.
- **Bancos**: los peces de una especie con `school_pull > 0` tienden hacia el centro de los de su especie, con un desvío propio, y vuelven si se quedan atrás (la comida a la vista tiene prioridad).

### Cambiado
- El aleteo (cambio de fotograma) va al ritmo del nado: más rápido cuando el pez acelera, más lento cuando flota.
- Los peces grandes giran más despacio (de 0,3 s a 0,9 s según el ancho del sprite).

### Nota
- Es la base de la Enciclopedia 2 (`docs/ENCICLOPEDIA2.md`): hasta que las especies nuevas usen estos valores el efecto visible es solo el aleteo y el giro.

## [0.27.1] - 2026-11-14 · Contraste de los peces

### Cambiado
- Colores de 21 especies aclarados para que se vean sobre el fondo negro: ojos casi blancos (contraste ≥ 10) y el resto de roles con contraste ≥ 4,5 (antes había ojos y colas casi negros).
- La variante melánica ya no se hunde en el negro: tiene una luminancia mínima.
- Nuevo test que vigila el contraste de todas las paletas de especie.

## [0.27.0] - 2026-11-14 · Fondo transparente y Estadísticas en Ajustes

### Añadido
- **Cielo transparente**: las 2 filas sobre el agua se ven transparentes (el pájaro se posa sobre el escritorio). La ventana admite transparencia por píxel.
- Ajuste **Fondo transparente**: quita el negro de todo lo demás (por defecto desactivado).
- `docs/PECES.md`: catálogo de las 32 especies (sprite, rareza, coste, producción, tiempos, desbloqueo) con un hueco «Cambios» por pez.

### Cambiado
- **Estadísticas** pasa de la barra lateral a un botón dentro de **Ajustes** (`Estad[í]sticas`, tecla I con Ajustes abierto). La barra lateral vuelve a tener 4 botones.
- El efecto CRT respeta el canal alfa de la pantalla (sin él anularía la transparencia).

## [0.26.2] - 2026-11-14 · Cielo sobre el agua

### Cambiado
- El pájaro ya no aparece bajo el agua: la ventana gana **2 filas de cielo** sobre la superficie y el pájaro se posa con las patas sobre la línea de olas (si vuela, una fila más arriba). La barra lateral y los paneles también aprovechan esas filas.
- La ficha del pez puede ocupar las filas del cielo, para que quepa igual que antes.

### Nota
- El cielo sigue siendo negro (no es transparencia real de la ventana).

## [0.26.1] - 2026-11-14 · Transición CRT

### Añadido
- **Transición de televisión de tubo** (`CrtTransition`, 0,65 s) al abrir, cerrar o cambiar de panel (Tienda, Enciclopedia, Logros, Estadísticas, Ajustes): un punto blanco se estira en una línea con halo, se abre en vertical con un destello blanco azulado que se apaga y la imagen se asienta con líneas de barrido y una banda de refresco que baja. Se apaga con «Reducir movimiento».

### Cambiado
- Estadísticas vuelve a llevar corchete y tecla rápida: `Estad[í]sticas` / `Stat[i]stics` (tecla I).
- La Enciclopedia ya no pasa página al abrirse (lo hace la transición CRT); el paso de página queda al cambiar de especie.

## [0.26.0] - 2026-11-14 · Enciclopedia de libro y paneles separados

### Añadido
- **Enciclopedia como libro:** lomo entre la lista y la ficha (`DexBook`), paso de página al cambiar de especie o abrirla (se apaga con «Reducir movimiento») y lista de variantes en la página derecha.
- **Foto del pez:** el retrato va dentro de un marco, como una foto de enciclopedia, y centrado en la página (`DexLayout`); con ventanas estrechas pasa a la derecha o desaparece.
- **Botón «Estadísticas»** en la barra lateral.
- **F12** hace llegar el pájaro del bioma al momento (si ya hay uno, no hace nada).
- **Formas de planta** (`WeedForm`, `weed_forms` en cada bioma): tallos, cañas con punta, helechos con hojas, matas bajas y arbustos; cada planta elige una al azar y cada bioma tiene las suyas.

### Cambiado
- Cada acceso de la barra lateral abre **solo sus pestañas**: Tienda (peces, equipo, decoración, biomas y Gran marea), Enciclopedia, Logros y Estadísticas. Las flechas no saltan a pestañas de otro grupo y el marco lleva el nombre del panel.
- El símbolo del reloj queda más pegado a la hora.
- La barra lateral deja una fila en blanco tras las conchas solo con 12 filas o más (con una fila menos caben los cinco botones).

## [0.25.0] - 2026-11-14 · Plantas de colores y pájaros

### Añadido
- **Pájaros en la superficie** (`BirdVisit`, `BirdView`): cada bioma recibe de vez en cuando (cada 100–260 s; la primera vez a los 25–90 s) la visita de un pájaro que llega volando, se posa 18–40 s y se va: pato en el estanque, gaviota en el arrecife, garza en el manglar y un ave luminosa en el abismo. Solo es decorado.
- **Paletas de plantas** por bioma (`weed_palette`, `weed_tip_palette`): cada planta y cada remate eligen su color; el arrecife ya no es solo rosa.

### Cambiado
- El estanque está menos vacío: más plantas (separación 0,6), paleta verde/oliva/turquesa, motas flotantes y fondo de puntitos.

## [0.24.0] - 2026-11-14 · Pulido visual

### Cambiado
- El fondo de unos y ceros se parece más al de losdelaia.com: dígitos de tamaños y brillos distintos (muchos pequeños y apagados, pocos grandes) y puntitos; `AsciiCanvas.put_glyph` dibuja un carácter a otro tamaño.
- Las bolitas de comida son «•» de colores aleatorios (rojo, naranja, amarillo, verde, cian, violeta, rosa).
- El símbolo del reloj (▲ ○ ▼ ●) se centra y se sube a la altura de las cifras.
- Biomas más variados y vistosos: la arena tiene granos de distinto tono, fila inferior más oscura y piedrecitas o conchas; las plantas son de 2 a 6 segmentos, a veces con compañera, con matices de color y remates en la punta (flores, bulbos); campos nuevos `sand_accents`, `sand_accent_color`, `weed_tips`, `weed_tip_color` en los biomas.

## [0.23.0] - 2026-11-14 · Fase 19 (efecto binario)

### Añadido
- **Unos y ceros** muy tenues que suben despacio por el fondo de cada pecera (`BinaryDrift`, `BinaryBackdrop`), con densidad y tinte según el bioma.
- **Estela del puntero** de unos y ceros al mover el ratón sobre la pecera (`BinaryCursor`); no sale con un panel abierto.
- Ajuste «Unos y ceros» (activo por defecto). «Reducir movimiento» frena el fondo y apaga la estela.

## [0.22.1] - 2026-11-14 · Música lofi

### Cambiado
- El ambiente de agua baja de volumen (canal −11 → −20 dB) y suma gritos lejanos de gaviota al mismo nivel que las olas.
- La música de día y de noche se rehace en estilo lofi (piano eléctrico, vibráfono, bajo cálido, pads, batería suave con swing, cinta y vinilo) en lugar de chiptune. `tools/generate_audio.py --music` regenera solo la música.

## [0.22.0] - 2026-11-14 · Fase 18 (cámara y barra lateral ancha)

### Corregido
- La lista de la tienda conserva el desplazamiento de la rueda al refrescarse (antes volvía a la fila seleccionada).

### Añadido
- **Cámara de la pecera** (`TankCamera`, `CameraHint`): el mundo mide el doble que la ventana. Se agarra con el **botón derecho** y se desliza; no pasa de los bordes. Flechas ◄ ► en los bordes con más pecera y una barra de posición que aparece al moverla.
- Los peces nuevos aparecen dentro de lo que ve la cámara; al empezar o cambiar de pecera la cámara se centra en los peces.
- `AsciiCanvas` tiene `camera_x`: lo que está por debajo de la capa 50 (el mundo) sigue a la cámara y no se pinta fuera de la ventana; la interfaz queda fija.

### Cambiado
- La barra lateral pasa de 20 a 28 columnas: ya se ven los ingresos por segundo.
- La versión del título va en la esquina inferior derecha de la ventana.
- Al decorar, el clic derecho guarda el objeto solo si no se arrastra (el arrastre mueve la cámara).

## [0.21.0] - 2026-11-14 · Fase 17 (título, ranuras y paneles modales)

### Añadido
- **Pantalla de título** (`TitlePanel`, `AsciiBanner`): logo «P3C3R4» en letras de bloques con degradado y brillo, sobre una pecera de adorno con ocho peces (partida que no se guarda). Botones Continuar, Cargar, Nueva y Salir; Esc vuelve de las listas de ranuras.
- **Tres ranuras de guardado** (`user://saves/slot_1..3`): Cargar enseña conchas, peces y tiempo de cada una; Nueva en una ranura usada pide una segunda pulsación antes de borrarla; Continuar abre la última.
- La partida de antes de las ranuras pasa sola a la ranura 1 (`SaveController.prepare_slots`).
- **Ajustes**: «Volver al título» y «Borrar esta ranura» (triple pulsación; la ranura se borra y se vuelve al título).
- El tutorial se recuerda **por ranura** (`slot_steps` en los ajustes); una partida nueva lo empieza de cero.

### Cambiado
- Con la tienda, la enciclopedia o los ajustes abiertos la pecera **no recibe clics** y se cierra la ficha del pez (ya no se superponen).
- La rueda del ratón desplaza las listas de la tienda y la enciclopedia estando el cursor en cualquier punto del panel, no solo sobre la lista.

## [0.20.0] - 2026-11-14 · Fase 16 (balance y preparación de la 1.0)

### Cambiado
- Producción base de todas las especies ×0,352 (calibrada con un bot de economía): Arrecife ≈1 h, todas las especies ≈3 h, primer prestigio ≈8 h, segunda vuelta mucho más rápida.
- Variantes: dorada 1,7 y prismática 0,3 (normal 92) para que lo raro se vea alguna vez.

### Añadido
- `tests/support/economy_bot.gd`: bot que juega «mirando de vez en cuando».
- `tests_long/simulation/`: simulación de hitos y `report_economy.gd`; **fuera de la suite normal** por lentitud. Se ejecuta aparte con `-gdir=res://tests_long -ginclude_subdirs`.
- `export_presets.cfg` para Windows y README del jugador.

### Corregido
- Cuatro tests de integración no liberaban la escena principal.
- Test de audio de prioridad venta/compra ya no depende de frames.

## [0.19.0] - 2026-11-14 · Fase 15 (accesibilidad, idioma y tutorial)

### Añadido
- **Reducir movimiento** (Ajustes): la ondulación de peces, algas, superficie y burbujas baja a un tercio (`MotionScale`) y se apagan los parpadeos (destello del CRT, chispa del pez dorado, balanceo de huevos, brillo del título final).
- **Tamaño del texto** (pequeño 85 %, normal, grande 125 %): escala la fuente de toda la rejilla. La franja crece o encoge en altura porque su alto son filas de texto.
- **Idioma** (Ajustes): del sistema, español o inglés; al cambiarlo se recarga la escena (la partida sigue en memoria).
- **Borrar partida** con triple pulsación (pedir, confirmar, borrar): empieza una partida nueva y la guarda; la anterior queda como la última copia de seguridad. Reinicia también el tutorial.
- **Tutorial por avisos** (`Tutorial`, `TutorialHint`): cinco cuadros arriba a la derecha de la pecera que avanzan al echar comida, cobrar una perla, comprar, abrir la ficha de un pez y, por último, mostrar los atajos. Esc lo salta; se puede apagar o repetir en Ajustes. El progreso se guarda en `settings.json`, no en la partida.
- Ajustes nuevos en `settings.json`: `reduce_motion`, `text_size`, `language`, `tutorial_enabled`, `tutorial_step`.

### Cambiado
- El panel de Ajustes reparte sus filas en **dos columnas** cuando cabe, y tiene el botón de borrar partida junto a «Vender todo».

 - 2026-11-14 · Fase 14 (audio)

### Añadido
- **`AudioService`** (autoload `Audio`): crea los canales Música, Ambiente y Efectos bajo Master, escucha `EventBus` y reproduce efectos con nombres lógicos. En un mismo fotograma solo suena el de mayor prioridad (una venta no suena también como compra).
- **Todo el sonido está generado por código**: `tools/generate_audio.py` (Python + numpy/scipy) escribe los WAV de `game/assets/audio/`: 11 efectos (clic, comida, compra, venta, perla, eclosión, evento, premio de evento, logro, Gran marea, final), un ambiente de agua con burbujas y dos temas de música en bucle sin costuras. No hay muestras ni melodías de terceros, así que no hay licencias que anotar.
- **Música «lofi chiptune» original**: tema de día (72 bpm, onda de pulso, arpegios con eco, bajo de triángulo, percusión suave y crepitar de vinilo) y tema de noche (más lento, grave y sin percusión) que se funden según la franja del día. Solo comparte el ánimo de los niveles acuáticos de 16 bits; la melodía es propia.
- **Ajustes**: «Volumen» general (30 % por defecto, de 10 en 10) y «Volumen de la música»; tecla **M** silencia y reactiva todo (con aviso). Guardado en `settings.json` (`master_volume`, `music_volume`, `muted`).
- Señales nuevas `egg_hatched`, `food_dropped` y `ui_clicked` en `EventBus`.

 - 2026-11-14 · Fase 13 (prestigio y meta final)

### Añadido
- **La Gran marea (prestigio)**: reinicia conchas, peces y equipamiento a cambio de **perlas negras** = ⌊√(conchas ganadas en el ciclo ÷ 100 000)⌋ (`Prestige`, `PrestigeState`, `PrestigeDirector` en `Game.prestige`). Se conservan Enciclopedia, logros, estadísticas, especies desbloqueadas, peceras abiertas, decoración (colocada y guardada), mejoras y perlas negras (P05). Pide doble confirmación y guarda tras hacerla.
- **Cuatro mejoras permanentes** como datos (`content/prestige/*.tres`, `PrestigeUpgradeDef`, `PrestigeCatalog`): *Corriente profunda* (+10 % de producción por nivel), *Provisiones* (conchas de arranque ×3 por nivel), *Ojo de perlero* (+20 % de peso de variantes raras por nivel) y *Perlas gordas* (+25 % de valor de las perlas recogibles por nivel).
- Pestaña **Marea** en la tienda: fila de la Gran marea (perlas que daría, progreso hacia la siguiente, botón con confirmación) y una fila por mejora (nivel, efecto, coste, compra).
- **Meta final**: al completar la Enciclopedia (todas las especies con todas sus variantes) se abre una **secuencia final en ASCII** (`FinalSequence`, `FinalPanel`: olas, peces que cruzan y texto que se escribe solo), se regala el **Trofeo de la Gran marea** (decoración dorada, `DecorationDef.is_reward`, no se vende ni sale en botellas) y el juego sigue en **modo infinito**. La fila «El final» de la pestaña Marea permite volver a verla.
- Guardado **formato 9** (`prestige`), con migración desde el 8.
- Herramientas de desarrollo: **F8** completa la colección, **F9** da 5 M de conchas.

### Cambiado
- F6 adelanta el reloj **1 h** (antes 3 h). El reloj de la barra cambia de color según la hora (`ClockPalette`): cálido al amanecer, claro a mediodía, anaranjado al atardecer y azul frío de noche.
- Barra lateral: la producción por segundo va junto a las conchas, el reloj debajo y más aire entre grupos; los botones (Tienda, Enciclopedia, Logros, Ajustes) van alineados a la izquierda.
- Los símbolos del reloj pasan a caracteres permitidos por la guía de arte (`▲ ○ ▼ ●`); `☀ ☾ ◐` no están en la fuente y salían como `*`.

## [0.16.0] - 2026-11-14 · Fase 12 (día/noche y eventos aleatorios)

### Añadido
- **Día y noche**: cuatro franjas según la hora del sistema (amanecer 6–8, día 8–18, atardecer 18–21, noche 21–6) con una oscuridad que cambia poco a poco (`DayCycle`, `DayClock`, `DaylightDirector` en `Game.daylight`). La pecera se tiñe de azul oscuro de noche y de un velo cálido al amanecer y al atardecer (`DaylightView`); la barra lateral queda sin tinte. Aviso al cambiar de franja.
- **Especies diurnas y nocturnas** (`SpeciesDef.activity`): las nocturnas producen hasta +15 % de noche y −15 % de día; las diurnas, al revés; 8 nocturnas y 9 diurnas, el resto neutras (el guppy inicial es neutro). Se ve en la ficha del pez.
- **Lámpara**: además de acelerar el crecimiento, quita la penalización nocturna (nivel 5 = toda) y aclara el tinte; nunca quita el bonus. `TankBonuses.night_shield`.
- **Seis eventos aleatorios** como datos (`content/events/*.tres`, `EventDef`, `EventCatalog`): *Visitante raro* (un pez raro del bioma, con aspecto llamativo, que da conchas al pulsarlo), *Lluvia de comida* (todos los peces quedan saciados y caen copos), *Pez dorado fugaz* (conchas rápidas), *Corriente cálida* (producción ×2 durante 60 s), *Botella a la deriva* (regala un objeto de decoración) y *Plaga de algas* (la pecera se ensucia; limpiar a mano da conchas).
- `EventPlanner` (espera de 4 a 8 min con el juego abierto, pesos, elegibilidad), `EventEffects`, `EventState`, `EventDirector` (`Game.events`) con generador aleatorio propio; nuevas señales `phase_changed`, `event_started`, `event_finished`, `event_rewarded`.
- Herramientas de desarrollo: **F6** adelanta el reloj 1 h, **F7** lanza un evento; la variable de entorno `P3C3R4_HOUR` (por ejemplo `set P3C3R4_HOUR=23`) fuerza la hora al arrancar.
- **Barra lateral rediseñada**: conchas con la producción por segundo a su lado, reloj del juego debajo (☀/☾/◐ y hora) que cambia de color a lo largo del día (cálido al amanecer, claro a mediodía, anaranjado al atardecer, frío de noche; `ClockPalette`), y los botones Tienda, Enciclopedia, Logros y Ajustes alineados a la izquierda con más aire entre grupos.

### Notas
- Los eventos no se guardan ni hay progreso con el juego cerrado (D11). Ningún evento quita nada de forma permanente.
- Cambiar la hora del sistema solo mueve la franja y el ajuste de ±15 %; no avanza el tiempo de juego ni da conchas.

## [0.15.0] - 2026-11-14 · Fase 11C (pulido de movimiento y efecto CRT)

### Cambiado
- **Los peces solo nadan hacia delante.** Si el destino queda detrás, frenan, se dan la vuelta y arrancan en el otro sentido (`SwimMotion`): se acabó el nado hacia atrás. Con comida detrás se giran aunque esté muy cerca.
- **Giro «Paper Mario»**: al darse la vuelta el pez se estrecha hasta una línea (`|`) y se abre mirando al otro lado (0,45 s). Lo usan la pecera y el retrato de la Enciclopedia (`turn_scale`, `is_turning`).
- **Bichos de fondo** (caracol, cangrejo, saltarín del fango, estrella de mar): nacen y se quedan apoyados en la arena (antes se colocaban a media agua y bajaban despacio), sin ondulación ni inclinación, y avanzan a pasos con paradas.
- Burbujas: el vaivén crece al subir y se desvanecen al llegar a la superficie. Algas: balanceo más amplio con un oleaje lento añadido y más movimiento en las puntas.
- Los avisos (toasts) ya no se tapan unos a otros: esperan su turno (hasta 4).

### Añadido
- **Efecto CRT** (`CrtOverlay`, `crt.gdshader`): brillo de los caracteres, líneas de barrido, viñeta, ligero desajuste de color en los bordes y parpadeo suave. Tres niveles en Ajustes → «Efecto CRT»: Apagado, Suave (brillo + líneas) y Completo (por defecto). Se guarda en `settings.json` (`crt_level`).

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
