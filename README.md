# Proyecto P3C3R4

Juego incremental de pecera en arte ASCII para escritorio (Windows), en forma de franja siempre visible en la parte inferior de la pantalla, al estilo de *Rusty's Retirement*. "P3C3R4" es un nombre en clave; el título definitivo está por decidir.

**Estado actual:** planificación terminada, desarrollo sin empezar. Ver `docs/ESTADO.md`.

## Resumen en una frase

Cuidas una pecera cuyos peces, plantas, decoración e interfaz están dibujados con caracteres; los peces producen monedas, los crías y vendes, desbloqueas especies, biomas y equipamiento, y el objetivo es completar el Pecedex.

## Tecnología

| Elemento | Elección |
|---|---|
| Motor | Godot 4 (última versión estable 4.x; se fija en la Fase 0) |
| Lenguaje | GDScript con tipado estático |
| Plataforma inicial | Windows 10/11 x64 |
| Plataforma futura | Navegador (HTML5); la arquitectura queda preparada |
| Editor de código | Visual Studio Code + extensión `godot-tools` |
| Pruebas | GUT 9.x |
| Estilo | `gdlint` y `gdformat` (gdtoolkit) |
| Versiones | Git + GitHub privado, con CI en GitHub Actions |

## Documentación

Leer en este orden:

| Nº | Documento | Contenido |
|---|---|---|
| 00 | [`docs/00-TRASPASO.md`](docs/00-TRASPASO.md) | Cómo continuar el proyecto en otra conversación. **Empezar aquí.** |
| 01 | [`docs/01-DISENO-GDD.md`](docs/01-DISENO-GDD.md) | Diseño del juego: mecánicas, economía, contenido |
| 02 | [`docs/02-ARQUITECTURA.md`](docs/02-ARQUITECTURA.md) | Estructura del código, capas, datos, patrones |
| 03 | [`docs/03-PLAN-DESARROLLO.md`](docs/03-PLAN-DESARROLLO.md) | Fases, entregables y criterios de aceptación |
| 04 | [`docs/04-GUIA-ESTILO-CODIGO.md`](docs/04-GUIA-ESTILO-CODIGO.md) | Convenciones de código, Git y revisión |
| 05 | [`docs/05-GUIA-ARTE-ASCII.md`](docs/05-GUIA-ARTE-ASCII.md) | Reglas del arte, paleta, fuente, formato de sprites |
| 06 | [`docs/06-SEGURIDAD-Y-GUARDADO.md`](docs/06-SEGURIDAD-Y-GUARDADO.md) | Guardado, validación, dependencias, privacidad |
| 07 | [`docs/07-DECISIONES.md`](docs/07-DECISIONES.md) | Registro de todas las decisiones tomadas y pendientes |
| 08 | [`docs/08-ENTORNO.md`](docs/08-ENTORNO.md) | Instalación de herramientas paso a paso |
| — | [`docs/ESTADO.md`](docs/ESTADO.md) | Progreso real; se actualiza al final de cada sesión |

## Estructura de la carpeta

```
Proyecto P3C3R4/
├── README.md
├── docs/                 Documentación (este plan)
└── game/                 Proyecto de Godot (se crea en la Fase 0)
```
