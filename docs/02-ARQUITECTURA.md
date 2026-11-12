# 02 · Arquitectura

## 1. Principios

1. **Separación en capas.** La lógica del juego no conoce los nodos de Godot. La presentación no contiene reglas de juego.
2. **Contenido como datos.** Añadir una especie, un logro o un equipo consiste en crear un recurso, no en escribir código.
3. **Determinismo.** La simulación recibe el tiempo y el generador de números aleatorios desde fuera, para poder probarla.
4. **Dependencias en un solo sentido:** `presentation → core → data`. Nunca al revés.
5. **Pocos singletons y con un único propósito.**
6. **Preparado para web:** sin hilos, sin rutas fuera de `user://` y `res://`, y con todo lo específico de la plataforma aislado en un servicio.

Para quien viene de Unity: una *escena* de Godot equivale a un prefab, un *nodo* a un GameObject con un único componente, un `Resource` a un ScriptableObject y un *autoload* a un singleton persistente entre escenas.

## 2. Estructura de carpetas

```
Proyecto P3C3R4/
├── README.md
├── CHANGELOG.md
├── LICENSE-THIRD-PARTY.md        Licencias de fuente, sonidos y complementos
├── .gitignore  .gitattributes  .editorconfig
├── .github/workflows/ci.yml
├── docs/
└── game/                         Raíz del proyecto de Godot
    ├── project.godot
    ├── addons/gut/               Framework de tests (versión fijada)
    ├── src/
    │   ├── core/                 Lógica pura. Sin nodos.
    │   │   ├── simulation/       Tank, Fish, reloj de simulación
    │   │   ├── economy/          Wallet, costes, producción, formato de números
    │   │   ├── care/             Hambre, limpieza, felicidad
    │   │   ├── breeding/         Cría y variantes
    │   │   ├── progression/      Desbloqueos, Pecedex, logros, prestigio
    │   │   ├── events/           Eventos aleatorios, ciclo día/noche
    │   │   └── save/             Serialización, validación, migraciones
    │   ├── data/                 Definiciones (scripts de Resource)
    │   │   ├── species_def.gd  equipment_def.gd  decoration_def.gd
    │   │   ├── biome_def.gd  achievement_def.gd  event_def.gd  variant_def.gd
    │   │   └── content_db.gd     Carga e indexa todo el contenido
    │   ├── services/             Autoloads
    │   │   ├── game.gd           Estado de la partida y bucle de simulación
    │   │   ├── event_bus.gd      Señales globales
    │   │   ├── save_service.gd   Lectura y escritura en disco
    │   │   ├── settings.gd       Ajustes del usuario
    │   │   ├── audio_service.gd
    │   │   └── platform.gd       Ventana, monitor, diferencias escritorio/web
    │   └── presentation/
    │       ├── ascii/            AsciiCanvas, AsciiSprite, paletas, fuente
    │       ├── tank/             Vista de la pecera, vistas de pez, partículas
    │       ├── ui/               Marcos, botones, paneles, barra lateral
    │       ├── fx/               Sombreador CRT, tinte día/noche
    │       └── main.tscn         Escena principal
    ├── content/                  Datos del juego (.tres) y arte
    │   ├── species/  equipment/  decorations/  biomes/
    │   ├── achievements/  events/  variants/
    │   └── sprites/              Arte ASCII en archivos de texto
    ├── assets/
    │   ├── fonts/  audio/  shaders/
    │   └── i18n/strings.csv
    └── tests/
        ├── unit/                 Tests de core
        ├── integration/          Guardado completo, simulación larga
        └── fixtures/             Partidas de ejemplo, incluidas corruptas
```

## 3. Capas

### 3.1 `core`: lógica pura

- Clases que extienden `RefCounted`, nunca `Node`.
- No usan `get_tree()`, `Input`, `Time`, `randf()` ni autoloads. Reciben por parámetro lo que necesitan: `delta`, un `RandomNumberGenerator` y un reloj.
- El estado completo de la partida es un árbol de objetos simples con raíz en `GameState`:

```
GameState
├── wallet: Wallet                 conchas, perlas negras, totales históricos
├── tanks: Array[Tank]
│   └── Tank
│       ├── biome_id
│       ├── fish: Array[Fish]      especie, variante, etapa, hambre, felicidad
│       ├── eggs: Array[Egg]
│       ├── equipment: Dictionary  id → nivel
│       ├── decorations: Array[PlacedDecoration]
│       └── cleanliness
├── pokedex: Pokedex               entradas descubiertas
├── achievements: Dictionary
├── prestige: PrestigeState
├── stats: Stats
└── rng_seed, sim_time
```

- La simulación avanza con `Simulation.step(state, dt, rng, clock)`, que llama por orden a sistemas pequeños: cuidados, crecimiento, cría, producción, eventos, logros.
- Los sistemas comunican lo ocurrido devolviendo una lista de **eventos de dominio** (`FishHatched`, `VariantDiscovered`, `AchievementUnlocked`), que la capa de servicios reenvía como señales. Así `core` no depende del bus.

### 3.2 `data`: definiciones de contenido

- Cada tipo de contenido es un script que extiende `Resource` con campos `@export` tipados. Los datos concretos son archivos `.tres` en `content/`, editables desde el inspector de Godot.
- `ContentDB` los carga al arrancar, los indexa por identificador y **valida**: identificadores únicos, referencias que existen, valores en rango, sprites presentes. Un fallo de validación detiene el arranque en desarrollo y hace fallar la CI.
- Los identificadores son cadenas estables en minúsculas (`pond_guppy`). No se renombran nunca tras publicarse, porque las partidas guardadas los referencian.

### 3.3 `services`: autoloads

| Autoload | Responsabilidad | No hace |
|---|---|---|
| `Game` | Posee el `GameState`, ejecuta el paso fijo, ofrece las órdenes del jugador (`buy_fish`, `feed`, `sell_fish`…) | Dibujar |
| `EventBus` | Declara las señales globales | Guardar estado |
| `SaveService` | Leer, escribir, copiar y migrar partidas | Decidir cuándo guardar más allá del temporizador |
| `Settings` | Ajustes del usuario en un archivo aparte | Estado de la partida |
| `AudioService` | Reproducir por nombre lógico, gestionar canales | Lógica de juego |
| `Platform` | Posición de la franja, monitor, siempre visible, hora del sistema, diferencias con web | — |

Las acciones del jugador entran siempre por órdenes de `Game`, que valida (¿hay conchas?, ¿hay capacidad?) y devuelve un resultado. La interfaz nunca modifica el estado directamente.

### 3.4 `presentation`: nodos

- **`AsciiCanvas`:** un único `Node2D` que en `_draw()` pinta todos los caracteres de la pecera con `draw_string`/`draw_char` y la fuente monoespaciada. Cada elemento visible es un objeto ligero con posición en píxeles, sprite y paleta. No hay un nodo por pez ni por carácter (T06).
- **Vistas:** `FishView`, `BubbleView`, `PlantView`… guardan solo estado visual (fase de ondulación, giro suavizado) y leen del modelo. Se crean y destruyen al recibir señales.
- **Interfaz:** nodos `Control` propios con marcos de caja dibujados con la misma fuente. Se usa el sistema de foco de Godot para el teclado.
- **Efectos:** el CRT es un sombreador de pantalla completa sobre un `CanvasLayer`; el tinte día/noche es un `CanvasModulate` o un parámetro de la paleta.

## 4. Bucle y tiempo

- **Simulación a paso fijo:** 10 pasos por segundo (T05). `Game._process(delta)` acumula tiempo y ejecuta tantos pasos como correspondan, con un máximo por fotograma para evitar la espiral tras una pausa larga.
- **Dibujado:** hasta 30 FPS (T07), con interpolación visual propia de cada vista. `OS.low_processor_usage_mode` activado.
- **Peceras no visibles:** mismos sistemas de economía y cría, sin vistas.
- **Pausa:** cuando la ventana se oculta o el equipo se suspende, la simulación se detiene; al volver no se "recupera" el tiempo (D11).

## 5. Comunicación

- **Hacia abajo, llamadas; hacia arriba, señales.** La interfaz llama a `Game.buy_fish(...)`; `Game` emite `EventBus.fish_added`.
- Las señales del bus llevan datos tipados y nombres en pasado (`coins_changed`, `variant_discovered`).
- Nada de `get_node("../../X")` entre ramas lejanas del árbol.

## 6. Guardado

Detalle en `06-SEGURIDAD-Y-GUARDADO.md`. Resumen: cada clase de `core` tiene `to_dict()` y `static from_dict()`; `SaveService` escribe JSON con número de versión, de forma atómica y con copias de seguridad, y aplica migraciones encadenadas al cargar partidas antiguas.

## 7. Localización

- Todas las cadenas visibles pasan por `tr("CLAVE")`. Las claves van en `assets/i18n/strings.csv` con columnas `keys,es,en`.
- Los datos guardan claves, no textos (`name_key = "SPECIES_POND_GUPPY"`).
- Un test comprueba que cada clave usada existe en los dos idiomas.
- El arte ASCII no contiene texto traducible.

## 8. Rendimiento

| Métrica | Presupuesto |
|---|---|
| Procesador en reposo, pecera con 40 peces | < 3 % de un núcleo |
| Memoria | < 200 MB |
| Fotogramas | 30 estables |
| Tamaño del ejecutable | < 100 MB |
| Arranque hasta pecera visible | < 3 s |

Medidas: un único lienzo, sin asignaciones de memoria por fotograma en el camino caliente, sprites precalculados por dirección, límites de entidades por pecera y un indicador de depuración (F3) con tiempos de simulación y dibujado.

## 9. Pruebas

- **Unitarias (GUT):** todos los sistemas de `core`: costes, producción, felicidad, cría con semilla fija, desbloqueos, prestigio, serialización de ida y vuelta, migraciones.
- **De integración:** simular horas de juego en segundos con una "política de jugador" simple, comprobando que no hay valores negativos ni infinitos y que el progreso cae dentro de los márgenes de balance.
- **De contenido:** `ContentDB` valida todo el contenido; claves de traducción completas; cada sprite respeta la guía de arte.
- **Manuales:** lista de comprobación por fase en `03-PLAN-DESARROLLO.md`.

## 10. Integración continua

`ci.yml` en cada subida y en cada petición de fusión:

1. `gdformat --check` y `gdlint` sobre `game/src` y `game/tests`.
2. Importar el proyecto con Godot en modo sin interfaz.
3. Ejecutar GUT y publicar el resultado.
4. En la rama principal: exportar el ejecutable de Windows y guardarlo como artefacto.

Las acciones de terceros se fijan por identificador de commit, no por etiqueta.

## 11. Compilación y distribución

- Plantillas de exportación de Godot para Windows x64, perfil *release*, sin símbolos de depuración.
- Versión en `project.godot` y visible en ajustes.
- El ejecutable sin firmar provoca un aviso de Windows SmartScreen. Para uso propio no importa; para distribuirlo habrá que valorar la firma de código.
- **Web (futuro):** exportación HTML5 con el mismo proyecto. `Platform` sustituye la franja por un lienzo apaisado y el guardado usa el almacenamiento del navegador que Godot asigna a `user://`.

## 12. Extender el juego

| Quiero añadir… | Pasos |
|---|---|
| Una especie | Sprite en `content/sprites/`, recurso `SpeciesDef` en `content/species/`, claves de texto. Sin código |
| Una variante | Recurso `VariantDef` con su paleta y probabilidad |
| Un equipo | Recurso `EquipmentDef`; si el efecto es de un tipo nuevo, añadir ese tipo en `core/care` o `core/economy` |
| Un logro | Recurso `AchievementDef` con condición declarativa (`stat >= valor`) |
| Un evento | Recurso `EventDef`; si necesita comportamiento nuevo, una clase en `core/events` |
| Un bioma | Recurso `BiomeDef`, fondo, paleta y sus especies |
| Un idioma | Una columna nueva en `strings.csv` |
