# Estado del proyecto

Se actualiza al final de cada sesión de trabajo. Es la fuente de verdad sobre el progreso.

**Última actualización:** 2026-11-12
**Fase actual:** Fase 1 · Motor de render ASCII y pecera viva: terminada (falta que Jorge haga el commit). Siguiente: **Fase 2 · Ventana en franja y prototipo de interfaz**.
**Versión:** `0.2.0` (pendiente de etiquetar en Git).

## Progreso por fases

| Fase | Nombre | Estado |
|---|---|---|
| 0 | Entorno y esqueleto | Hecha (falta activar el CI) |
| 1 | Motor de render ASCII y pecera viva | Hecha |
| 2 | Ventana en franja y prototipo de interfaz | Pendiente |
| 3 | Núcleo de simulación y economía | Pendiente |
| 4 | Guardado | Pendiente |
| 5 | Tienda, especies y rarezas | Pendiente |
| 6 | Cuidados: hambre, limpieza y felicidad | Pendiente |
| 7 | Cría, variantes de color y venta | Pendiente |
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

- 2026-11-12: cuestionario de decisiones respondido y plan de desarrollo redactado. Carpeta creada en el escritorio.
- 2026-11-12 (sesión 2): Fase 0, tareas 0.3, 0.4, 0.5, 0.7 (gdlintrc), 0.8 (borrador) y 0.9 escritas: `game/project.godot`, estructura de carpetas, escena principal, test de humo, `CHANGELOG.md`, `LICENSE-THIRD-PARTY.md`. gdformat y gdlint pasan sobre `src` y `tests`. Sin ejecutar en Godot todavía.
- 2026-11-12 (sesión 2, cierre): Godot 4.6 importa el proyecto; GUT 9.6.1 instalado y activado; F5 muestra "P3C3R4" con 0 errores y 0 avisos; GUT: "All tests passed" (test_smoke.gd). Commit inicial subido a GitHub (JorgeGaro-esp/p3c3r4).
- 2026-11-12 (sesión 3): Fase 1 completa. Verificado en Godot: 0 errores y 0 avisos en Salida; F5 muestra la pecera con 3 especies nadando; 40 peces a 30 FPS (update 0,11 ms, dibujo 0,86 ms); GUT: 27 tests, 30288 aserciones, todo pasa; gdformat y gdlint limpios.

## Siguiente paso concreto

Jorge: `git add .`, `git commit -m "feat: fase 1, motor de render ASCII y pecera viva"`, `git tag v0.2.0`, `git push --follow-tags`. Si aún no se hizo, mover el CI (`git mv ci.yml.propuesto .github\workflows\ci.yml`) y comprobar que sale en verde.
Claude: empezar la Fase 2 (ventana en franja). Antes hay que preguntar a Jorge P01, P02, P09 y P10.

## Bloqueos y dudas abiertas

Ninguno técnico; la Fase 0 depende de las instalaciones de Jorge. Las decisiones pendientes no bloqueantes están en `07-DECISIONES.md`, sección "Pendientes".

## Notas de la última sesión

- Fase 1 escrita en el entorno de Claude, copiada al equipo de Jorge y probada en Godot controlando la pantalla.
- La copia de archivos al equipo a veces dejó una versión anterior del archivo; se detectó comparando tamaños. Comprobar siempre tras copiar.
- Aplazado a la Fase 2: modo de bajo consumo cuando la ventana esté en segundo plano.
- Anterior (sesión 2):

- El proyecto se escribió sin poder ejecutar Godot (no hay consola en el equipo de Jorge desde la sesión). Ya verificado en la sesión 2.
- GUT se instaló desde AssetLib dentro de Godot, controlando la pantalla.
- El CI no usa acciones de terceros (regla de 02 §10): clona con git y descarga Godot 4.6-stable verificando SHA512. El CI aún no se ha ejecutado.
- `.github/` es una ubicación protegida: no se pudo escribir desde aquí.
