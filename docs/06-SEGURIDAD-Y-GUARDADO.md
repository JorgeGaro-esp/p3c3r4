# 06 · Seguridad, guardado y privacidad

El juego es local, sin red y de un solo jugador, así que la superficie de ataque es pequeña. Los riesgos reales son tres: perder o corromper la partida, ejecutar algo indeseado al cargar un archivo manipulado, y arrastrar dependencias o licencias problemáticas.

## 1. Modelo de amenazas

| Amenaza | Ejemplo | Medida |
|---|---|---|
| Corrupción de la partida | Corte de luz durante el guardado | Escritura atómica y copias de seguridad |
| Archivo de guardado manipulado | Una partida descargada de internet | Solo JSON, validación estricta, sin carga de recursos ni scripts |
| Valores imposibles | Conchas negativas, `NaN`, un millón de peces | Validación de rangos y límites |
| Incompatibilidad entre versiones | Partida de la 0.6 abierta en la 1.0 | Versión de formato y migraciones |
| Dependencias comprometidas | Complemento o acción de CI alterados | Versiones fijadas e incluidas en el repositorio |
| Fuga de datos personales | Rutas o nombre de usuario en registros | No registrar datos del sistema; sin telemetría |
| Licencias | Fuente o sonido sin permiso de uso | Registro de licencias obligatorio |

Hacer trampas editando la partida no se considera una amenaza: es un juego de un jugador sin clasificaciones. La suma de comprobación sirve para detectar corrupción, no para impedir trampas.

## 2. Formato de guardado

- **Ubicación:** `user://saves/` (en Windows, dentro de `%APPDATA%\Godot\app_userdata\<nombre>` o la carpeta propia que se configure). Nunca fuera de `user://`.
- **Formato:** JSON en UTF-8.
- **Archivos:** `save.json`, `save.bak1.json`, `save.bak2.json`, `save.bak3.json` y, aparte, `settings.json`.

```json
{
  "format_version": 1,
  "game_version": "0.5.0",
  "saved_at_unix": 1794500000,
  "checksum": "sha256 del campo data serializado de forma canónica",
  "data": {
    "wallet": { "coins": 12400.0, "pearls": 0, "lifetime_coins": 58000.0 },
    "tanks": [
      {
        "biome_id": "pond",
        "cleanliness": 82.5,
        "fish": [
          { "species_id": "pond_guppy", "variant_id": "normal", "stage": 3, "hunger": 40.0 }
        ],
        "eggs": [],
        "equipment": { "filter": 2 },
        "decorations": [ { "def_id": "rock_small", "x": 12, "y": 0, "layer": 0 } ]
      }
    ],
    "pokedex": { "pond_guppy": ["normal"] },
    "achievements": {},
    "prestige": { "count": 0, "upgrades": {} },
    "stats": {},
    "rng_state": 0,
    "sim_time": 3600.0
  }
}
```

## 3. Reglas obligatorias al cargar

1. **Solo `JSON.parse_string`.** Prohibido para datos del usuario: `str_to_var`, `bytes_to_var` con objetos, `FileAccess.get_var(true)`, `ResourceLoader.load` y `load()` sobre rutas de `user://`. Un recurso `.tres` o `.res` puede llevar un script incrustado que se ejecuta al cargarlo.
2. **Tamaño máximo** del archivo antes de leerlo (por ejemplo, 5 MB).
3. **Validación de esquema:** tipo de cada campo, campos obligatorios, campos desconocidos ignorados.
4. **Validación de rangos:** números finitos (ni `NaN` ni infinito), no negativos donde corresponda, recortados a sus límites; longitud máxima de cada lista.
5. **Validación de referencias:** todo `species_id`, `variant_id`, `def_id` o `biome_id` debe existir en `ContentDB`. Los desconocidos se descartan y se anota en el registro.
6. **Nunca usar una cadena del archivo como ruta, nombre de clase, nombre de método o expresión.**
7. **Ante un fallo:** probar las copias en orden. Si ninguna sirve, conservar los archivos dañados con otro nombre, empezar partida nueva y avisar al jugador. Jamás sobrescribir en silencio una partida que no se pudo leer.

## 4. Reglas obligatorias al guardar

1. Serializar a memoria y comprobar que el resultado se puede volver a leer.
2. Escribir en `save.tmp`, cerrar el archivo y comprobar el resultado.
3. Rotar copias: `bak2 → bak3`, `bak1 → bak2`, `save → bak1`.
4. Renombrar `save.tmp` a `save.json`.
5. Si cualquier paso falla, dejar intacto el guardado anterior y avisar.

**Cuándo:** cada 60 segundos, al cerrar, al recibir la notificación de cierre de ventana, tras un prestigio y tras descubrir una variante. Nunca más de una vez cada pocos segundos.

## 5. Versiones y migraciones

- `format_version` es un entero que sube en cada cambio incompatible del formato.
- Cada salto tiene una función pura `migrate_N_to_N+1(dict) -> dict`, con su test y una partida de ejemplo en `tests/fixtures/`.
- Al cargar se aplican en cadena hasta la versión actual.
- Una partida con versión **superior** a la que el juego conoce no se carga ni se sobrescribe: se avisa de que hay que actualizar el juego.
- Los identificadores de contenido no se renombran. Si hay que retirar uno, se añade una tabla de equivalencias en una migración.

## 6. Ajustes

`settings.json` sigue las mismas reglas de validación. Un archivo de ajustes inválido se sustituye por los valores por defecto sin afectar a la partida.

## 7. Código y dependencias

- Sin `OS.execute`, `OS.shell_open` con datos externos, `Expression` ni carga dinámica de scripts.
- Sin acceso a red. Si algún día se añade (versión web, nube), se revisa este documento antes.
- Complementos incluidos en `addons/` con la versión anotada en `LICENSE-THIRD-PARTY.md`. Se actualizan a propósito y entre fases, leyendo antes sus notas de versión.
- En la CI, las acciones de terceros se fijan por identificador de commit y el flujo declara permisos mínimos (`contents: read`).
- Activar en GitHub las alertas de dependencias para las acciones y el escaneo de secretos.
- El repositorio no contiene contraseñas, claves ni partidas personales. `.gitignore` cubre `.godot/`, exportaciones y archivos de usuario.

## 8. Privacidad

- El juego no recoge, envía ni comparte ningún dato.
- Lee la hora del sistema solo para el ciclo de día y noche.
- Los registros no incluyen el nombre de usuario ni rutas absolutas: usar rutas `user://` y `res://`.

## 9. Distribución

- Exportar siempre en perfil *release*, sin consola de depuración ni depurador remoto.
- Un ejecutable sin firma provoca el aviso de SmartScreen en otros equipos. Para uso propio es aceptable; para repartirlo, valorar un certificado de firma de código.
- Cifrar el paquete de recursos no aporta seguridad real en un juego local y no se hará.

## 10. Licencias

Todo recurso de terceros (fuente, sonido, música, complemento, sombreador) se anota en `LICENSE-THIRD-PARTY.md` con: nombre, autor, origen, licencia y si exige atribución. No entra en el repositorio nada cuya licencia no esté clara. Preferencia: CC0, OFL, MIT.

## 11. Lista de comprobación de seguridad (Fases 4 y 16)

- [ ] Ninguna función prohibida de la sección 3 aparece en el código (búsqueda automática en CI).
- [ ] Tests de carga con archivo vacío, truncado, enorme, con tipos erróneos, con `NaN`, con identificadores inexistentes y con versión futura.
- [ ] Interrumpir el proceso durante el guardado no pierde la partida.
- [ ] Sin llamadas de red en el proyecto.
- [ ] Registro de licencias completo.
- [ ] Exportación *release* sin herramientas de depuración.
- [ ] Sin datos personales en registros ni en el repositorio.
