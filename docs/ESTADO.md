# Estado del proyecto

Se actualiza al final de cada sesión de trabajo. Es la fuente de verdad sobre el progreso.

**Última actualización:** 2026-11-12
**Fase actual:** Fase 0 · Entorno y esqueleto: terminada salvo el CI (ver abajo). Siguiente: **Fase 1 · Motor de render ASCII y pecera viva**.
**Versión:** `0.1.0` (pendiente de etiquetar en Git).

## Progreso por fases

| Fase | Nombre | Estado |
|---|---|---|
| 0 | Entorno y esqueleto | Hecha (falta activar el CI) |
| 1 | Motor de render ASCII y pecera viva | Pendiente |
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

## Siguiente paso concreto

Jorge: en la terminal, `git add .`, `git commit -m "feat: GUT instalado, fase 0 completa"`, `git tag v0.1.0`, `git push --follow-tags`. Después mover el CI: `mkdir .github\workflows`, `git mv ci.yml.propuesto .github\workflows\ci.yml`, commit y push, y comprobar que el CI sale en verde en GitHub (el CI no se ha podido probar todavía).
Claude: empezar la Fase 1, tarea 1.1 (fuente monoespaciada y cobertura de caracteres).

## Bloqueos y dudas abiertas

Ninguno técnico; la Fase 0 depende de las instalaciones de Jorge. Las decisiones pendientes no bloqueantes están en `07-DECISIONES.md`, sección "Pendientes".

## Notas de la última sesión

- El proyecto se escribió sin poder ejecutar Godot (no hay consola en el equipo de Jorge desde la sesión). Ya verificado en la sesión 2.
- GUT se instaló desde AssetLib dentro de Godot, controlando la pantalla.
- El CI no usa acciones de terceros (regla de 02 §10): clona con git y descarga Godot 4.6-stable verificando SHA512. El CI aún no se ha ejecutado.
- `.github/` es una ubicación protegida: no se pudo escribir desde aquí.
