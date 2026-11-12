# 00 · Traspaso: cómo continuar el proyecto

Este documento va dirigido a Claude en una conversación nueva, sin memoria de la conversación de planificación. Contiene todo lo necesario para retomar el trabajo.

## Mensaje para iniciar la siguiente conversación

Jorge puede pegar esto tal cual:

> Continúa el desarrollo del Proyecto P3C3R4. La carpeta está en mi escritorio (`C:\Users\h95jo\Desktop\Proyecto P3C3R4`). Lee `docs/00-TRASPASO.md` y `docs/ESTADO.md`, y sigue con la siguiente fase pendiente de `docs/03-PLAN-DESARROLLO.md`.

## Contexto mínimo

- **Qué es:** juego incremental de pecera en arte ASCII, en una franja inferior siempre visible del escritorio de Windows.
- **Para quién:** proyecto personal de Jorge. No se publica por ahora; itch.io y Steam quedan como posibilidad futura.
- **Con qué:** Godot 4 + GDScript tipado. Windows primero; navegador más adelante.
- **Perfil de Jorge:** programa en Java, JavaScript, C, C++ y C#; ha usado Unity, nunca Godot. Usa Visual Studio Code. Quiere entender y poder modificar el código, así que cada fase incluye una explicación de lo hecho y de los conceptos de Godot nuevos, comparándolos con Unity o C# cuando ayude.
- **Instalado al planificar:** solo tiene cuenta de GitHub. Godot y Git hay que instalarlos (ver `08-ENTORNO.md`).

## Orden de lectura

1. `docs/ESTADO.md`: qué está hecho y qué toca.
2. `docs/03-PLAN-DESARROLLO.md`: la fase que toca, con entregables y criterios de aceptación.
3. `docs/02-ARQUITECTURA.md` y `docs/04-GUIA-ESTILO-CODIGO.md` antes de escribir código.
4. `docs/01-DISENO-GDD.md` y `docs/05-GUIA-ARTE-ASCII.md` cuando la fase toque mecánicas o arte.
5. `docs/06-SEGURIDAD-Y-GUARDADO.md` en cualquier fase que toque archivos, guardado o dependencias.
6. `docs/07-DECISIONES.md` ante cualquier duda de "¿esto se decidió?".

## Reglas de trabajo

1. **Una fase cada vez, en orden.** No adelantar sistemas de fases posteriores salvo que la arquitectura lo exija.
2. **Cada fase termina con algo ejecutable** y con sus criterios de aceptación cumplidos y comprobados.
3. **La lógica vive en `core/` sin depender de nodos.** Si una regla de juego necesita un nodo para probarse, está mal ubicada.
4. **El contenido es dato, no código.** Especies, precios, logros y eventos van en recursos de `data/`, nunca escritos dentro de scripts.
5. **Tests junto al código.** Toda lógica nueva de `core/` lleva tests GUT en la misma fase.
6. **Decisiones de Jorge.** Las de diseño, jugabilidad y arte son suyas. Preguntar con preguntas interactivas de opciones, no con cuestionarios largos de texto. Las técnicas menores se toman y se anotan en `07-DECISIONES.md`.
7. **No inventar hechos sobre el entorno.** Comprobar versiones de Godot, GUT y gdtoolkit en el momento de instalarlas, porque cambian.
8. **Al cerrar la sesión:** actualizar `docs/ESTADO.md`, añadir decisiones nuevas a `07-DECISIONES.md`, hacer commit y explicar a Jorge qué se hizo y cómo probarlo.
9. **Nada destructivo sin confirmación:** no borrar archivos de Jorge, no forzar `git push`, no reescribir historial.

## Cómo se trabaja en el equipo de Jorge

Con la app de escritorio de Claude abierta, Claude puede leer y escribir en la carpeta del proyecto. Compilar y ejecutar el juego requiere Godot en el equipo de Jorge: o bien Claude lo lanza mediante una consola en ese equipo si la sesión la ofrece, o bien Jorge pulsa F5 en Godot y cuenta lo que ve. Los tests y el análisis de estilo también se ejecutan en CI, así que cada subida a GitHub da una segunda comprobación.

## Riesgos conocidos que conviene tener presentes

| Riesgo | Mitigación prevista |
|---|---|
| La primera versión jugable es "completa" (decisión de Jorge), así que tarda en llegar | El plan mantiene hitos internos ejecutables en cada fase, aunque la versión 1.0 no salga hasta el final |
| La franja tiene poca altura para tienda, Pecedex y decoración | Prototipo de interfaz en la Fase 2 antes de construir menús; ver GDD §10 |
| La fuente debe cubrir caracteres de caja y bloques | Verificar cobertura de la fuente en la Fase 1; ver guía de arte |
| Dibujar miles de caracteres por fotograma | Presupuesto de rendimiento y medición desde la Fase 1 |
| Balance de economía incremental | Todos los números en datos y un simulador de economía en tests |
| Versión web futura | Sin hilos, sin rutas fuera de `user://`, servicios de plataforma aislados |
