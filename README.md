# P3C3R4 · pecera ASCII incremental

Una pecera de letras que vive en una franja en la parte baja de tu escritorio. Dale de comer, compra peces, cría, decora y desbloquea biomas.

## Cómo se juega
- Clic en la pecera: soltar comida; clic en perlas: recogerlas.
- Tienda con pestañas: peces, equipo, decoración, biomas, Pecedex, logros, estadísticas.
- **M** silencia, **Esc** salta el tutorial. Ajustes: volumen, idioma, tamaño de texto, reducir movimiento, borrar partida.
- Al abrir el juego aparece el título: **Continuar**, **Cargar** o **Nueva**. Hay tres ranuras de guardado; desde Ajustes puedes volver al título o borrar la ranura abierta.
- La pecera es el doble de ancha que la ventana: **arrastra con el botón derecho** para mover la cámara.
- Con la tienda o los ajustes abiertos la pecera no responde; la rueda del ratón desplaza las listas.
- La partida se guarda sola. El juego avanza también mientras está cerrado (producción offline).

## Ejecutar
Abre `P3C3R4.exe`. No necesita instalación.

## Desarrollo
Godot 4.6, GDScript tipado. Tests: GUT (`-gdir=res://tests -ginclude_subdirs`). Simulación de economía (lenta): `-gdir=res://tests_long`. Docs en `docs/`.
