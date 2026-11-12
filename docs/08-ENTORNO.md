# 08 · Preparación del entorno

Punto de partida: Windows, Visual Studio Code y una cuenta de GitHub. Faltan Godot y Git. Las versiones concretas se comprueban en el momento de instalar, porque cambian; al terminar, anotarlas en la tabla del final.

## 1. Git

1. Descargar Git para Windows desde `git-scm.com` e instalar con las opciones por defecto.
2. Configurar la identidad, en una terminal:
   ```
   git config --global user.name "Tu nombre"
   git config --global user.email "tu-correo-de-github"
   git config --global init.defaultBranch main
   git config --global core.autocrlf input
   ```
3. Opcional: instalar GitHub CLI (`gh`) para crear el repositorio desde la terminal, y ejecutar `gh auth login`.

## 2. Godot

1. Descargar desde `godotengine.org/download` la **última versión estable 4.x**, edición estándar (no la .NET: el proyecto usa GDScript).
2. Godot no tiene instalador: es un ejecutable. Colocarlo en una carpeta fija, por ejemplo `C:\Tools\Godot\`.
3. Añadir esa carpeta al `PATH` de Windows y, si se quiere, renombrar una copia a `godot.exe` para lanzarlo desde la terminal.
4. Desde el editor, en *Editor → Gestionar plantillas de exportación*, descargar las plantillas de la misma versión (hacen falta para generar el `.exe`).

## 3. Visual Studio Code

1. Instalar la extensión **godot-tools**.
2. En los ajustes de la extensión, indicar la ruta del ejecutable de Godot 4.
3. En Godot: *Editor → Configuración del editor → Editor de texto → Externo*, activar el editor externo y apuntar a VS Code, con los argumentos `{project} --goto {file}:{line}:{col}`.
4. Con Godot abierto, VS Code ofrece autocompletado, ir a definición y depuración con puntos de ruptura.

Extensiones recomendadas: EditorConfig, GitLens y Markdown All in One.

## 4. Herramientas de estilo

Requieren Python 3:

```
pip install gdtoolkit
gdformat --version
gdlint --version
```

Comprobar que la versión de gdtoolkit instalada corresponde a Godot 4. Si no admite alguna sintaxis de la versión de Godot elegida, anotarlo en `07-DECISIONES.md` y ajustar las reglas.

## 5. Tests

GUT se instala dentro del proyecto en la Fase 0, desde la biblioteca de recursos de Godot (pestaña *AssetLib*, buscar "GUT") o copiando su carpeta a `game/addons/gut/`. Usar la rama o versión que corresponda a la versión de Godot elegida.

Ejecución desde la terminal, en `game/`:

```
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

## 6. Repositorio

Con `gh`:

```
cd "%USERPROFILE%\Desktop\Proyecto P3C3R4"
git init
git add .
git commit -m "docs: plan de desarrollo inicial"
gh repo create p3c3r4 --private --source=. --push
```

Sin `gh`: crear un repositorio privado vacío en github.com y seguir las instrucciones que muestra para enlazar una carpeta existente.

## 7. Uso diario

| Acción | Cómo |
|---|---|
| Abrir el proyecto | Godot → Importar → `game/project.godot` |
| Ejecutar el juego | F5 en Godot |
| Ejecutar la escena actual | F6 |
| Ejecutar tests | Panel de GUT en Godot, o el comando de la sección 5 |
| Comprobar estilo | `gdformat --check game/src game/tests` y `gdlint game/src game/tests` |
| Formatear | `gdformat game/src game/tests` |
| Exportar | Godot → Proyecto → Exportar → Windows Desktop |

## 8. Equivalencias para quien viene de Unity y C#

| Unity / C# | Godot / GDScript |
|---|---|
| GameObject + componentes | Nodo (uno por función) en un árbol |
| Prefab | Escena (`.tscn`) |
| ScriptableObject | `Resource` (`.tres`) |
| MonoBehaviour `Start` / `Update` | `_ready()` / `_process(delta)` |
| `FixedUpdate` | `_physics_process(delta)` |
| Singleton con `DontDestroyOnLoad` | Autoload |
| Eventos de C# / UnityEvent | Señales (`signal`, `emit`, `connect`) |
| `[SerializeField]` | `@export` |
| `GetComponent<T>()` | `$Nodo`, `%NombreÚnico` o `get_node()` |
| `Instantiate(prefab)` | `escena.instantiate()` y `add_child()` |
| `Destroy(obj)` | `queue_free()` |
| Corrutinas | `await` |
| `PlayerPrefs` | Archivo en `user://` |
| Llaves y punto y coma | Sangría, como en Python |

## 9. Versiones instaladas

Rellenar en la Fase 0:

| Herramienta | Versión | Fecha |
|---|---|---|
| Godot | | |
| Plantillas de exportación | | |
| Git | | |
| Python | | |
| gdtoolkit | | |
| GUT | | |
| Extensión godot-tools | | |
