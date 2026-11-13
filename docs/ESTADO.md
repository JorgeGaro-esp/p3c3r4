# Estado del proyecto

Se actualiza al final de cada sesión de trabajo. Es la fuente de verdad sobre el progreso.

**Última actualización:** 2026-11-13
**Fase actual:** Fase 7 · Cría, variantes y venta: código y 337 tests hechos. Pendiente de Jorge: probarla en la ventana real (ver abajo). Siguiente: **Fase 8 · Equipamiento**. Al terminar la Fase 16: pasada de estilo con el HTML de referencia (P11).
**Versión:** `0.8.0` (pendiente de commit y etiqueta `v0.8.0`). Etiquetas hasta `v0.7.0`.

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
| 8 | Equipamiento mejorable | Pendiente |
| 9 | Decoración colocable | Pendiente |
| 10 | Biomas y varias peceras | Pendiente |
| 11 | Pecedex y logros | Pendiente |
| 12 | Día/noche y eventos aleatorios | Pendiente |
| 13 | Prestigio y meta final | Pendiente |
| 14 | Audio | Pendiente |
| 15 | Efecto CRT, accesibilidad e inglés | Pendiente |
| 16 | Balance, pruebas y versión 1.0 | Pendiente |
| 17 | (Futuro) Versión web y publicación | Sin planificar en detalle |

## Hecho hasta ahora

- 2026-11-13 (sesión 5): arreglo de las manchas del cristal (T56) y limpieza visible en el panel (T57). Fase 7: etapas de vida, huevos y eclosión, 5 variantes con paletas (prismática animada), venta desde la ficha con confirmación y venta de sobrantes, aviso de variante nueva y registro de combinaciones descubiertas (base del Pecedex). Guardado formato 3. 337 tests.

- 2026-11-12: cuestionario de decisiones respondido y plan de desarrollo redactado. Carpeta creada en el escritorio.
- 2026-11-12 (sesión 2): Fase 0, tareas 0.3, 0.4, 0.5, 0.7 (gdlintrc), 0.8 (borrador) y 0.9 escritas: `game/project.godot`, estructura de carpetas, escena principal, test de humo, `CHANGELOG.md`, `LICENSE-THIRD-PARTY.md`. gdformat y gdlint pasan sobre `src` y `tests`. Sin ejecutar en Godot todavía.
- 2026-11-12 (sesión 2, cierre): Godot 4.6 importa el proyecto; GUT 9.6.1 instalado y activado; F5 muestra "P3C3R4" con 0 errores y 0 avisos; GUT: "All tests passed" (test_smoke.gd). Commit inicial subido a GitHub (JorgeGaro-esp/p3c3r4).
- 2026-11-12 (sesión 3): Fase 1 completa. Verificado en Godot: 0 errores y 0 avisos en Salida; F5 muestra la pecera con 3 especies nadando; 40 peces a 30 FPS (update 0,11 ms, dibujo 0,86 ms); GUT: 27 tests, 30288 aserciones, todo pasa; gdformat y gdlint limpios.

- 2026-11-13 (sesión 4): Fase 2 escrita y probada en un Godot 4.6 de Linux (headless): 138 tests, 32151 aserciones, gdformat y gdlint limpios. Incluye la matemática de la franja a 100/125/150 % y varios monitores (tests unitarios), ajustes, widgets, paneles y tests de integración con clics y teclado sobre la escena completa.

- 2026-11-13 (sesión 4, prueba en el equipo): proyecto abierto en Godot 4.6; F5 sin errores ni avisos propios; pecera y barra lateral visibles; Ajustes se abre y se cierra pulsando de nuevo el botón. GUT en el editor: 137 de 138 pasan; falla `test_clicking_the_open_panel_button_again_closes_it` solo dentro del editor (con ventana real) aunque a mano funciona y en headless pasa. Pendiente de investigar. No se pudo probar la franja sin incrustar (el editor la ejecuta incrustada: "Embedded window can't be moved/resized"); falta que Jorge la ejecute como ventana real.


Jorge: borrar `game/src/presentation/tank/swimmer_def.gd` y su `.uid` (ya no se usan; no los borró Claude). Después abrir el proyecto en Godot (se generarán los `.uid` nuevos), F5, y comprobar: franja sobre la barra de tareas sin cubrirla, sin robar el foco, `[_]`/`[X]`, barra lateral (Tienda, Ajustes), cambios en Ajustes. Probar 125/150 % de escala y un segundo monitor si es posible. Elegir P02 (paneles que sustituyen la pecera, o ventana que crece hacia arriba). Luego `git add .`, commit y `git tag v0.3.0`.
Jorge: borrar `game/content/species/test_*.tres` y `game/content/sprites/test_*.txt` (6 archivos y sus `.uid`; si no, aparecerían como especies extra). Probar: comprar peces en la tienda, ver desbloqueos, clic en un pez para su ficha (Esc la cierra) y cerrar/abrir para comprobar que se conserva la partida (las especies de prueba antiguas pasan a las del estanque). Elegir P02.
Jorge (Fase 6): clic en el agua para echar comida; arrastrar sobre las manchas verdes para limpiar (aparecen con el tiempo); clic en las perlas `○` que caen. Para ver el efecto sin esperar: bajar `hunger` con el depurador no existe aún; esperar unos minutos basta.
Claude: Fase 7 (cría, variantes de color y venta).

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
