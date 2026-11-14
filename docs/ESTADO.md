# Estado del proyecto

Se actualiza al final de cada sesión de trabajo. Es la fuente de verdad sobre el progreso.

**Última actualización:** 2026-11-14
**Fase actual:** Fase 13 · Prestigio y meta final: código y 649 tests hechos (Fases 7–13 sin commit aún). Pendiente de Jorge: probar la pestaña Marea (F9 da conchas, F8 completa la colección para ver el final), además del tinte (F6) y los eventos (F7) de la Fase 12. Siguiente: **Fase 14 · Audio**. Al terminar la Fase 16: pasada de estilo con el HTML de referencia (P11).
**Versión:** `0.17.0` (pendiente de commit; `0.8.0` a `0.16.0` tampoco tienen etiqueta aún). Etiquetas hasta `v0.7.0`.

## Progreso por fases

| Fase | Nombre | Estado |
|---|---|---|
| 0 | Entorno y esqueleto | Hecha |
| 1 | Motor de render ASCII y pecera viva | Hecha |
| 2 | Ventana en franja y prototipo de interfaz | Hecha en código; pendiente de prueba manual de Jorge y de P02 |
| 3 | Núcleo de simulación y economía | Hecha en código; pendiente de prueba manual de Jorge |
| 4 | Guardado | Hecha; guardar y recargar conchas probado por Jorge |
| 5 | Tienda, especies y rarezas | Hecha en código; pendiente de prueba manual de Jorge |
| 6 | Cuidados: hambre, limpieza y felicidad | Hecha en código; pendiente de prueba manual de Jorge |
| 7 | Cría, variantes de color y venta | Hecha en código; pendiente de prueba manual de Jorge |
| 8 | Equipamiento mejorable | Hecha en código; pendiente de prueba manual de Jorge |
| 9 | Decoración colocable | Hecha en código; pendiente de prueba manual de Jorge |
| 10 | Biomas y varias peceras | hecha (Estanque, Arrecife, Manglar, Abismo) |
| 11 | Enciclopedia y logros | hecha (11A estadísticas y Enciclopedia; 11B 60 logros con bonus de producción) |
| 12 | Día/noche y eventos aleatorios | Hecha en código; pendiente de prueba manual de Jorge |
| 13 | Prestigio y meta final | Hecha en código; pendiente de prueba manual de Jorge |
| 14 | Audio | Pendiente |
| 15 | Efecto CRT, accesibilidad e inglés | Pendiente |
| 16 | Balance, pruebas y versión 1.0 | Pendiente |
| 17 | (Futuro) Versión web y publicación | Sin planificar en detalle |

## Hecho hasta ahora

- 2026-11-14 (sesión 11): Fase 13: Gran marea con perlas negras (raíz cuadrada), reinicio selectivo (P05), cuatro mejoras permanentes como datos, pestaña «Marea» en la tienda con doble confirmación, final al completar la Enciclopedia (secuencia ASCII, Trofeo de la Gran marea, modo infinito), guardado formato 9, F8/F9 de prueba; reloj de la barra con color por hora y F6 a +1 h; símbolos del reloj válidos. 649 tests.
- 2026-11-14 (sesión 11): Fase 12: reloj inyectable y cuatro franjas con transición suave, tinte de la pecera, especies diurnas/nocturnas (±15 %, la lámpara compensa), planificador y seis eventos como datos (visitante raro, lluvia de comida, pez dorado, corriente cálida, botella, plaga de algas), F6/F7 y `P3C3R4_HOUR` para probar. 612 tests (también a distintas horas simuladas).
- 2026-11-13 (sesión 8): Fase 10A: `BiomeDef` y `BiomeCatalog`, pecera activa y `BiomeDirector`, pestañas de pecera, pestaña «Biomas» en la tienda, visuales por bioma (superficie, arena, plantas, fondo y partículas), Arrecife con 8 especies y 4 decoraciones, peceras ocultas con la misma simulación (test de igualdad), guardado formato 6. 453 tests.
- 2026-11-13 (sesión 8): Fase 10B: Manglar y Abismo (16 especies, 8 decoraciones, 2 biomas con aspecto propio), 6 etiquetas nuevas, tests de la cadena de desbloqueo. 455 tests.
- 2026-11-14 (sesión 10): Fase 11C: nado solo hacia delante, giro de canto, bichos de fondo en la arena, entorno más vivo, efecto CRT en 3 niveles, cola de avisos. 527 tests.
- 2026-11-13 (sesión 9): Fase 11B: 60 logros como datos, bonus de producción con tope (+50 %), guardado formato 8, pestañas «Logros» y «Estadísticas» en la tienda (tecla L), aviso al desbloquear. 516 tests.
- 2026-11-13 (sesión 8): Fase 11A: `GameStats` guardadas (formato 7), `Encyclopedia` con progreso por bioma, pestaña «Enciclopedia» en la tienda (tecla E, botón lateral, «???» y silueta para lo no descubierto, retrato animado). 484 tests.
- 2026-11-13 (sesión 7): Fase 9: 20 objetos de decoración con arte, tienda con pestaña de decoración, modo decorar (`D`), bonificaciones con tope, la lota pide una cueva, guardado formato 5. 405 tests.
- 2026-11-13 (sesión 6): botón «Vender todos los peces» en Ajustes (T68) y Fase 8: siete equipos con 5 niveles, pestaña «Equipo» en la tienda, dibujo animado en la pecera, imán de perlas, `TankBonuses`, guardado formato 4. Con filtro 5 y comedero 3 una pecera de 40 peces se mantiene sola (test). 368 tests.
- 2026-11-13 (sesión 5): arreglo de las manchas del cristal (T56) y limpieza visible en el panel (T57). Fase 7: etapas de vida, huevos y eclosión, 5 variantes con paletas (prismática animada), venta desde la ficha con confirmación y venta de sobrantes, aviso de variante nueva y registro de combinaciones descubiertas (base del Enciclopedia). Guardado formato 3. 337 tests.

- 2026-11-12: cuestionario de decisiones respondido y plan de desarrollo redactado. Carpeta creada en el escritorio.
- 2026-11-12 (sesión 2): Fase 0, tareas 0.3, 0.4, 0.5, 0.7 (gdlintrc), 0.8 (borrador) y 0.9 escritas: `game/project.godot`, estructura de carpetas, escena principal, test de humo, `CHANGELOG.md`, `LICENSE-THIRD-PARTY.md`. gdformat y gdlint pasan sobre `src` y `tests`. Sin ejecutar en Godot todavía.
- 2026-11-12 (sesión 2, cierre): Godot 4.6 importa el proyecto; GUT 9.6.1 instalado y activado; F5 muestra "P3C3R4" con 0 errores y 0 avisos; GUT: "All tests passed" (test_smoke.gd). Commit inicial subido a GitHub (JorgeGaro-esp/p3c3r4).
- 2026-11-12 (sesión 3): Fase 1 completa. Verificado en Godot: 0 errores y 0 avisos en Salida; F5 muestra la pecera con 3 especies nadando; 40 peces a 30 FPS (update 0,11 ms, dibujo 0,86 ms); GUT: 27 tests, 30288 aserciones, todo pasa; gdformat y gdlint limpios.

- 2026-11-13 (sesión 4): Fase 2 escrita y probada en un Godot 4.6 de Linux (headless): 138 tests, 32151 aserciones, gdformat y gdlint limpios. Incluye la matemática de la franja a 100/125/150 % y varios monitores (tests unitarios), ajustes, widgets, paneles y tests de integración con clics y teclado sobre la escena completa.

- 2026-11-13 (sesión 4, prueba en el equipo): proyecto abierto en Godot 4.6; F5 sin errores ni avisos propios; pecera y barra lateral visibles; Ajustes se abre y se cierra pulsando de nuevo el botón. GUT en el editor: 137 de 138 pasan; falla `test_clicking_the_open_panel_button_again_closes_it` solo dentro del editor (con ventana real) aunque a mano funciona y en headless pasa. Pendiente de investigar. No se pudo probar la franja sin incrustar (el editor la ejecuta incrustada: "Embedded window can't be moved/resized"); falta que Jorge la ejecute como ventana real.


Jorge: borrar `game/src/presentation/tank/swimmer_def.gd` y su `.uid` (ya no se usan; no los borró Claude). Después abrir el proyecto en Godot (se generarán los `.uid` nuevos), F5, y comprobar: franja sobre la barra de tareas sin cubrirla, sin robar el foco, `[_]`/`[X]`, barra lateral (Tienda, Ajustes), cambios en Ajustes. Probar 125/150 % de escala y un segundo monitor si es posible. Elegir P02 (paneles que sustituyen la pecera, o ventana que crece hacia arriba). Luego `git add .`, commit y `git tag v0.3.0`.
Jorge: borrar `game/content/species/test_*.tres` y `game/content/sprites/test_*.txt` (6 archivos y sus `.uid`; si no, aparecerían como especies extra). Probar: comprar peces en la tienda, ver desbloqueos, clic en un pez para su ficha (Esc la cierra) y cerrar/abrir para comprobar que se conserva la partida (las especies de prueba antiguas pasan a las del estanque). Elegir P02.
Jorge (Fase 6): clic en el agua para echar comida; arrastrar sobre las manchas verdes para limpiar (aparecen con el tiempo); clic en las perlas `○` que caen. Para ver el efecto sin esperar: bajar `hunger` con el depurador no existe aún; esperar unos minutos basta.
Jorge (Fase 8): reimportar traducciones (`--headless --import`), ganar conchas, abrir Tienda → pestaña «Equipo» (flechas ←/→), comprar el filtro y el comedero y ver cómo aparecen en la pecera.
Jorge (Fase 9): reimportar traducciones; Tienda → pestaña «Decoración» (←/→), comprar una cueva, botón [D]ecorar o tecla D, clic para colocar, clic derecho para guardar, rueda para cambiar de objeto; comprobar que la lota aparece en la tienda.
Jorge (Fase 10A): reimportar traducciones; ganar 6000 ¢ (o F4 para peces de prueba), Tienda → pestaña «Biomas» (flechas ←/→), comprar el Arrecife; aparecen las pestañas «Estanque | Arrecife» sobre el agua (también teclas 1 y 2).
Jorge (Fase 11A): reimportar traducciones; pulsar E o el botón «Enciclopedia»: lista de las 32 especies con «???» para las no vistas y variantes marcadas `[x]`.
Jorge (Fase 11B): reimportar traducciones; pulsar L: lista de 60 logros con `[ ]`/`[x]`; ver el aviso «¡Logro: …!» al conseguir uno (p. ej. comprar el primer pez) y el bonus en «Estadísticas».
Jorge (Fase 11C): reimportar; mirar cómo giran los peces (se aplanan y se abren), que caracol/cangrejo/estrella van pegados a la arena, y probar Ajustes → «Efecto CRT» (Apagado/Suave/Completo).
Jorge (Fase 12): reimportar; pulsar F3 para ver la ayuda de depuración; F6 adelanta el reloj 1 h (ver amanecer, atardecer y noche, y el aviso); F7 lanza un evento; probar el pez dorado (clic), el visitante (clic), la botella (clic), la lluvia de comida, la corriente cálida y la plaga de algas (limpiar las manchas).
Jorge (Fase 13): reimportar; en cmd con `Godot --path .`: pulsa F3 (ayuda), F9 (+5 M de conchas), abre Tienda → pestaña «Marea», pulsa «Reiniciar» dos veces y compra mejoras con las perlas negras; F8 completa la colección y lanza el final (Esc o clic para salir); el Trofeo aparece en Decoración (modo D).
Claude: Fase 14 (audio).

## Bloqueos y dudas abiertas

Ninguno técnico; la Fase 0 depende de las instalaciones de Jorge. Las decisiones pendientes no bloqueantes están en `07-DECISIONES.md`, sección "Pendientes".

## Notas de la última sesión

- Fase 2: no se pudo cambiar la escala de Windows desde aquí (es un ajuste del sistema); 125/150 % está cubierto por tests de cálculo, no por prueba en pantalla.
- El arranque con Windows no se ha probado en vivo para no tocar el registro de Jorge; probar con una versión exportada.
- Corregido: la nota antigua sobre el commit pendiente de la Fase 1 estaba obsoleta (ya hecho, con v0.1.0 y v0.2.0).
- Bajo consumo al minimizar: hecho (T29).

### Sesión 3 (anterior)


- Fase 1 escrita en el entorno de Claude, copiada al equipo de Jorge y probada en Godot controlando la pantalla.
- La copia de archivos al equipo a veces dejó una versión anterior del archivo; se detectó comparando tamaños. Comprobar siempre tras copiar.
- Anterior (sesión 2):

- El proyecto se escribió sin poder ejecutar Godot (no hay consola en el equipo de Jorge desde la sesión). Ya verificado en la sesión 2.
- GUT se instaló desde AssetLib dentro de Godot, controlando la pantalla.
- El CI no usa acciones de terceros (regla de 02 §10): clona con git y descarga Godot 4.6-stable verificando SHA512. El CI aún no se ha ejecutado.
- `.github/` es una ubicación protegida: no se pudo escribir desde aquí.
