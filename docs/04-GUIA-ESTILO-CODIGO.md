# 04 · Guía de estilo de código y de trabajo

Base: la guía de estilo oficial de GDScript. Aquí se recoge lo esencial y lo propio del proyecto. `gdformat` y `gdlint` hacen cumplir la mayor parte de forma automática.

## 1. Idioma

- **Código** (nombres de archivos, clases, funciones, variables, señales, identificadores de contenido): inglés.
- **Comentarios, documentación y mensajes de commit:** español.
- **Textos del juego:** nunca en el código; siempre claves de traducción.

## 2. Nombres

| Elemento | Convención | Ejemplo |
|---|---|---|
| Archivos y carpetas | `snake_case` | `fish_view.gd` |
| Clases (`class_name`) | `PascalCase` | `SpeciesDef` |
| Funciones y variables | `snake_case` | `coins_per_second` |
| Constantes | `MAYÚSCULAS_CON_GUION` | `MAX_FISH_PER_TANK` |
| Enumerados | `PascalCase` y valores en mayúsculas | `Rarity.EPIC` |
| Señales | `snake_case` en pasado | `fish_hatched` |
| Privado | prefijo `_` | `_accumulator` |
| Booleanos | `is_`, `has_`, `can_` | `is_adult` |
| Identificadores de contenido | `bioma_nombre` en minúsculas | `pond_guppy` |
| Claves de texto | mayúsculas con prefijo de tipo | `SPECIES_POND_GUPPY` |

## 3. Tipado

Tipado estático en todo:

```gdscript
var hunger: float = 0.0
var fish: Array[Fish] = []

func production_per_second(happiness: float) -> float:
    return base_production * happiness
```

- Activar en el proyecto los avisos de tipado ausente o inseguro y tratarlos como errores.
- Evitar `Variant` y los diccionarios sin tipo salvo en la frontera de serialización.
- Preferir clases con campos a diccionarios con claves de texto.

## 4. Orden dentro de un script

1. `class_name` y `extends`
2. Comentario de documentación (`##`)
3. Señales
4. Enumerados y constantes
5. Variables `@export`
6. Variables públicas y luego privadas
7. `@onready`
8. Funciones virtuales de Godot (`_ready`, `_process`…)
9. Funciones públicas
10. Funciones privadas

## 5. Reglas de diseño

- Una clase, una responsabilidad. Si un script pasa de unas 300 líneas, revisar si hay que dividirlo.
- Funciones cortas; si no caben en una pantalla, extraer.
- Sin números mágicos: constantes con nombre o datos en `content/`.
- `core/` no usa `Node`, autoloads, `Input`, `Time` ni funciones aleatorias globales.
- La interfaz no modifica el estado; llama a órdenes de `Game`.
- Nada de `get_node` con rutas largas ni `get_parent()` encadenados. Usar señales, `@export` o nombres únicos de escena (`%Nombre`).
- No dejar `print` de depuración; usar un registro con niveles.
- Fallar pronto y con mensaje claro: `assert` para errores de programación, validación con resultado para datos externos.
- Comentar el porqué, no el qué.

## 6. Documentación en el código

Cada clase y función pública lleva un comentario `##`, que Godot muestra en su ayuda integrada:

```gdscript
## Calcula el multiplicador de producción a partir de la felicidad.
## [param happiness] va de 0 a 100. Devuelve un valor entre 0.25 y 1.25.
static func happiness_multiplier(happiness: float) -> float:
```

## 7. Escenas y recursos

- Una escena por elemento reutilizable, con su script al lado y el mismo nombre.
- Nodo raíz con nombre en `PascalCase` igual que la escena.
- Los recursos de contenido se guardan en formato de texto (`.tres`), no binario, para que Git muestre los cambios.

## 8. Tests

- Archivo `test_<unidad>.gd` en `tests/unit/`, reflejando la ruta de `src/`.
- Nombre de test que describe el comportamiento: `test_sad_fish_produces_quarter`.
- Patrón preparar, actuar, comprobar. Un concepto por test.
- Semilla fija en todo lo aleatorio; reloj falso en todo lo que dependa del tiempo.
- Un error corregido deja un test que lo habría detectado.

## 9. Git

- **Ramas:** `main` siempre funciona. El trabajo va en ramas cortas `feat/…`, `fix/…`, `docs/…` que se fusionan con petición de fusión cuando la CI pasa.
- **Commits convencionales**, en español:

```
feat(breeding): añade variantes de color al eclosionar
fix(save): evita partida vacía si falla la escritura
docs: actualiza estado tras la fase 4
test(economy): cubre el coste del pez número 100
refactor(ascii): extrae el espejado de sprites
chore(ci): fija la versión de Godot
```

- Commits pequeños y con un solo propósito.
- **Versiones:** versionado semántico. Etiqueta `vX.Y.Z` al cerrar cada fase.
- **`CHANGELOG.md`** con el formato de *Keep a Changelog*: Añadido, Cambiado, Corregido, Eliminado.
- Nunca subir secretos, partidas personales ni la carpeta `.godot/`.

## 10. Revisión antes de fusionar

- [ ] Cumple la arquitectura de capas.
- [ ] Sin textos visibles en el código.
- [ ] Sin números de balance en el código.
- [ ] Tests nuevos y CI en verde.
- [ ] Sin avisos en la consola de Godot.
- [ ] Documentación y `ESTADO.md` al día.
- [ ] Si toca guardado: versión de formato y migración revisadas.
