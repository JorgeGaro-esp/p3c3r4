# Estado del proyecto

Se actualiza al final de cada sesión de trabajo. Es la fuente de verdad sobre el progreso.

**Última actualización:** 2026-11-12
**Fase actual:** Fase 0 · Entorno y esqueleto (en curso: archivos creados, faltan instalaciones y comprobación en Godot).
**Versión:** sin versión (objetivo de la Fase 0: `0.1.0`).

## Progreso por fases

| Fase | Nombre | Estado |
|---|---|---|
| 0 | Entorno y esqueleto | En curso |
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

## Siguiente paso concreto

Jorge: 0.1 instalar Godot 4.6.x, Git y la extensión de VS Code (`08-ENTORNO.md`); 0.2 `git init` y repositorio privado en GitHub; 0.6 instalar GUT 9.6.1 desde AssetLib en `game/addons/gut/`; mover `ci.yml.propuesto` a `.github/workflows/ci.yml`. Después, abrir `game/project.godot`, pulsar F5 y ejecutar los tests; Claude cierra la fase con la versión 0.1.0.

## Bloqueos y dudas abiertas

Ninguno técnico; la Fase 0 depende de las instalaciones de Jorge. Las decisiones pendientes no bloqueantes están en `07-DECISIONES.md`, sección "Pendientes".

## Notas de la última sesión

- El proyecto se escribió sin poder ejecutar Godot (no hay consola en el equipo de Jorge desde la sesión). Si F5 o los tests dan error, copiar el mensaje.
- GUT no se pudo descargar desde la sesión (GitHub bloqueado): se instala desde AssetLib.
- El CI no usa acciones de terceros (regla de 02 §10): clona con git y descarga Godot 4.6.3 verificando SHA512. Versión de Godot del CI sin confirmar contra la descarga real.
- `.github/` es una ubicación protegida: no se pudo escribir desde aquí.
