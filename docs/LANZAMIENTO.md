# Lista para lanzar la 1.0

Estado (2026-11-15): 683 de 683 tests unitarios pasan en Godot 4.6. Falta la prueba a mano y la exportación.

## 1. Prueba a mano (unos 30 minutos, con F5 y la franja como ventana real)

Arranque y ventana
- [ ] La franja aparece pegada al borde inferior, sin cubrir la barra de tareas, y no roba el foco.
- [ ] Fondo transparente donde corresponde; siempre encima; se puede cambiar de monitor.
- [ ] Título: Nueva partida, Continuar, ranuras 1 a 3, borrar ranura.

Pecera y peces
- [ ] Los peces de los 4 biomas se ven bien (sin recortes, ojo `°` visible).
- [ ] Sardinas, anchoas y krill se apartan del cursor; koi, carpas y payasos se acercan.
- [ ] Un clic en el agua suelta comida y asusta a los huidizos cercanos.
- [ ] De noche los diurnos se hunden y se paran; de día los nocturnos.
- [ ] Rana a saltos, cangrejo de río a pie, medusa a la deriva.

Ficha, tienda y cuidados
- [ ] Ficha de un pez: textos dentro del marco; Apodo ► recorre nombres; ◆ Favorito bloquea la venta y los sobrantes.
- [ ] Comprar, vender, sobrantes, comida, limpiar manchas, perlas.
- [ ] Cría: huevo, alevín, juvenil, adulto; variantes raras.
- [ ] Equipo y decoración (colocar, mover, guardar).
- [ ] Enciclopedia, Logros, Ajustes (idioma ES/EN, CRT, efecto binario, FPS).

Persistencia y economía
- [ ] Cerrar y abrir: la partida se conserva (apodos y favoritos incluidos).
- [ ] Prestigio funciona y conserva la colección.
- [ ] Dejarlo 20 minutos sin tocar: no sube el consumo de CPU/RAM de forma rara.

## 2. Exportar el .exe

1. Godot: Editor → Administrar plantillas de exportación → descargar las de 4.6 (una vez).
2. Proyecto → Exportar… → preset «Windows Desktop» (ya está en `export_presets.cfg`).
3. Dejar desmarcado «Exportar con depuración» y pulsar Exportar proyecto.
4. Sale `build/P3C3R4.exe` (con el PCK incrustado).

## 3. Probar el .exe
- [ ] Abre con doble clic fuera del editor; la franja se coloca bien.
- [ ] Ajustes → arrancar con Windows: activar, reiniciar sesión, comprobar y desactivar.
- [ ] Guardar, cerrar, abrir: sigue la partida.
- [ ] Probarlo en otro PC (o cuenta de Windows) si es posible.

## 4. Cierre
- [ ] `project.godot` a 1.0.0 y entrada `[1.0.0]` en `CHANGELOG.md`.
- [ ] Commit y etiqueta `v1.0.0`.
- [ ] Las ideas de las fases 21 a 25 pasan a ser la 1.1.
