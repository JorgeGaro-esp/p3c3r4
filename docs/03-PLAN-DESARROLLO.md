# 03 · Plan de desarrollo

## Cómo leer este plan

- Las fases van en orden y cada una deja el juego ejecutable.
- **Tamaño** es una estimación relativa del esfuerzo: S (una sesión), M (dos o tres), L (cuatro o más). No son fechas.
- Una fase está terminada cuando se cumple la **definición de hecho** común y sus **criterios de aceptación** propios.
- Jorge decidió que la primera versión jugable sea la completa (D21). Por eso la versión `1.0.0` llega al final de la Fase 16, pero cada fase produce una versión interna `0.x.0` que se puede abrir y probar.

## Definición de hecho (común a todas las fases)

1. El juego arranca sin errores ni avisos en la consola de Godot.
2. `gdformat --check` y `gdlint` pasan.
3. Los tests GUT pasan en local y en CI.
4. La lógica nueva de `core/` tiene tests.
5. Los textos visibles nuevos están en `strings.csv` en español e inglés.
6. `CHANGELOG.md` y `docs/ESTADO.md` actualizados; decisiones nuevas en `07-DECISIONES.md`.
7. Commit con etiqueta de versión `v0.x.0` subido a GitHub.
8. Jorge ha recibido una explicación de lo hecho, de los conceptos de Godot nuevos y de cómo probarlo.

## Resumen

| Fase | Nombre | Tamaño | Versión | Depende de |
|---|---|---|---|---|
| 0 | Entorno y esqueleto | S | 0.1.0 | — |
| 1 | Motor de render ASCII y pecera viva | M | 0.2.0 | 0 |
| 2 | Ventana en franja y prototipo de interfaz | M | 0.3.0 | 1 |
| 3 | Núcleo de simulación y economía | M | 0.4.0 | 1 |
| 4 | Guardado | M | 0.5.0 | 3 |
| 5 | Tienda, especies y rarezas | L | 0.6.0 | 2, 4 |
| 6 | Cuidados: hambre, limpieza y felicidad | M | 0.7.0 | 5 |
| 7 | Cría, variantes de color y venta | M | 0.8.0 | 6 |
| 8 | Equipamiento mejorable | M | 0.9.0 | 6 |
| 9 | Decoración colocable | M | 0.10.0 | 5 |
| 10 | Biomas y varias peceras | L | 0.11.0 | 7, 8, 9 |
| 11 | Pecedex y logros | M | 0.12.0 | 10 |
| 12 | Día/noche y eventos aleatorios | M | 0.13.0 | 10 |
| 13 | Prestigio y meta final | M | 0.14.0 | 11 |
| 14 | Audio | S | 0.15.0 | 5 |
| 15 | Efecto CRT, accesibilidad e inglés | M | 0.16.0 | 13 |
| 16 | Balance, pruebas y versión 1.0 | L | 1.0.0 | todas |
| 17 | (Futuro) Versión web y publicación | — | 1.1.0 | 16 |

---

## Fase 0 · Entorno y esqueleto

**Objetivo:** proyecto vacío que arranca, con todas las herramientas de calidad funcionando.

**Tareas**

- 0.1 Instalar Godot, Git y la extensión de VS Code (`08-ENTORNO.md`). Anotar la versión exacta de Godot en T01.
- 0.2 Crear el repositorio Git en la carpeta y el repositorio privado en GitHub.
- 0.3 Crear el proyecto de Godot en `game/` con renderizador Compatibility, tipado estricto y avisos como errores.
- 0.4 Crear la estructura de carpetas de `02-ARQUITECTURA.md`.
- 0.5 Añadir `.gitignore`, `.gitattributes`, `.editorconfig`, `CHANGELOG.md`, `LICENSE-THIRD-PARTY.md`.
- 0.6 Instalar GUT en `addons/` y escribir un test trivial.
- 0.7 Instalar gdtoolkit y configurar `gdlintrc`. Comprobar que es compatible con la versión de Godot elegida.
- 0.8 Escribir `ci.yml`: estilo + tests.
- 0.9 Escena principal que muestra "P3C3R4" con la fuente por defecto.

**Criterios de aceptación**

- F5 en Godot abre una ventana con el texto.
- La CI aparece en verde en GitHub.
- Jorge sabe abrir el proyecto, ejecutar el juego, ejecutar los tests y hacer un commit.

---

## Fase 1 · Motor de render ASCII y pecera viva

**Objetivo:** recuperar la pecera del prototipo anterior (versión canvas y WinForms) dentro de la arquitectura nueva.

**Tareas**

- 1.1 Elegir y añadir la fuente monoespaciada; verificar cobertura de caracteres (P08).
- 1.2 `AsciiCanvas`: dibujo de caracteres con posición en píxeles, color por carácter y escalado según el tamaño de la ventana.
- 1.3 Formato de archivo de sprite y su cargador (`05-GUIA-ARTE-ASCII.md`), con espejado automático.
- 1.4 Portar el nado del prototipo: impulsos, ondulación del cuerpo, giro suave, inclinación.
- 1.5 Algas que se mecen, burbujas, superficie con olas, arena.
- 1.6 Indicador de depuración con FPS y tiempos.
- 1.7 Tests del cargador de sprites y del espejado.

**Criterios de aceptación**

- Pecera con al menos 3 especies de prueba (una multilínea) nadando con fluidez.
- 40 peces a 30 FPS dentro del presupuesto de rendimiento.
- Añadir un pez de prueba no requiere tocar código de dibujo.

---

## Fase 2 · Ventana en franja y prototipo de interfaz

**Objetivo:** el juego vive en el borde inferior de la pantalla y queda decidido cómo caben los menús.

**Tareas**

- 2.1 `Platform`: ventana sin bordes, siempre visible, anclada al área útil del monitor por encima de la barra de tareas.
- 2.2 Reacción a cambios de resolución, escala de Windows y monitor.
- 2.3 Ajustes básicos persistentes: altura, monitor, siempre visible, límite de FPS (P01, P10).
- 2.4 Componentes de interfaz ASCII: marco, botón, lista, barra de progreso, pestañas, aviso.
- 2.5 Navegación con ratón y teclado.
- 2.6 **Prototipo de las dos formas de abrir paneles** (P02) con una tienda de mentira; Jorge elige.
- 2.7 Salida limpia: icono o tecla para minimizar y cerrar.

**Criterios de aceptación**

- La franja se coloca bien a 100 %, 125 % y 150 % de escala de Windows.
- No roba el foco de otras aplicaciones al arrancar ni tapa la barra de tareas.
- P01, P02, P09 y P10 quedan decididas y anotadas.

---

## Fase 3 · Núcleo de simulación y economía

**Objetivo:** el modelo de juego existe y produce monedas, sin interfaz todavía.

**Tareas**

- 3.1 `GameState`, `Tank`, `Fish`, `Wallet`.
- 3.2 Bucle de paso fijo en `Game` con reloj y generador aleatorio inyectados.
- 3.3 `SpeciesDef` y `ContentDB` con validación.
- 3.4 Producción pasiva y fórmulas de coste.
- 3.5 Formato de números grandes (`12,4K`, `3,1M`) según idioma.
- 3.6 Conectar modelo y vistas mediante `EventBus`.
- 3.7 Contador de conchas y producción por segundo en la barra lateral.
- 3.8 Tests de economía y de determinismo: misma semilla, mismo resultado.

**Criterios de aceptación**

- Los peces de la pecera corresponden al modelo y las conchas suben.
- Mil pasos de simulación con la misma semilla dan un estado idéntico.

---

## Fase 4 · Guardado

**Objetivo:** cerrar y abrir el juego conserva la partida de forma segura.

**Tareas**

- 4.1 `to_dict`/`from_dict` en todas las clases de estado.
- 4.2 `SaveService`: escritura atómica, copias rotativas, suma de comprobación.
- 4.3 Validación de esquema y de rangos al cargar; recuperación desde copia.
- 4.4 Sistema de migraciones por versión, con una migración de ejemplo.
- 4.5 Autoguardado cada 60 s, al cerrar y tras compras importantes.
- 4.6 Tests con partidas válidas, truncadas, manipuladas y de versión antigua.

**Criterios de aceptación**

- Matar el proceso durante el guardado no deja la partida inservible.
- Un archivo corrupto no bloquea el arranque: se recupera la copia y se avisa.
- Cumple `06-SEGURIDAD-Y-GUARDADO.md`.

---

## Fase 5 · Tienda, especies y rarezas

**Objetivo:** primer bucle jugable: ganar, comprar, ganar más.

**Tareas**

- 5.1 Panel de tienda con la solución elegida en la Fase 2.
- 5.2 Órdenes `buy_fish` con validación de conchas y capacidad.
- 5.3 Rarezas y condiciones de desbloqueo declarativas.
- 5.4 Las 8 especies del primer bioma, con arte definitivo (P03).
- 5.5 Ficha de pez al hacer clic sobre él.
- 5.6 Tests de desbloqueos y de compra.

**Criterios de aceptación**

- Se puede jugar 20 minutos comprando peces con una curva de costes razonable.
- Cada especie es reconocible y cumple la guía de arte.

---

## Fase 6 · Cuidados: hambre, limpieza y felicidad

**Tareas**

- 6.1 Hambre, limpieza y cálculo de felicidad.
- 6.2 Alimentar con clic: copos que caen y peces que acuden.
- 6.3 Manchas de alga en el cristal y limpieza arrastrando.
- 6.4 Perlas recogibles.
- 6.5 Efecto visual de la felicidad: velocidad y saturación.
- 6.6 Tests de los límites del multiplicador (×0,25 a ×1,25).

**Criterios de aceptación**

- Sin cuidar la pecera, la producción baja pero nunca llega a cero ni se pierde nada.
- El estado de ánimo se distingue a simple vista.

---

## Fase 7 · Cría, variantes de color y venta

**Tareas**

- 7.1 Etapas de crecimiento con sprites por etapa.
- 7.2 Puesta, huevo y eclosión.
- 7.3 `VariantDef` y sorteo de variante con semilla.
- 7.4 Paletas de variante, incluida la prismática animada.
- 7.5 Venta desde la ficha del pez; venta múltiple.
- 7.6 Aviso de variante nueva.
- 7.7 Tests estadísticos de probabilidades con muchas muestras.

**Criterios de aceptación**

- Una pareja cría solo si hay capacidad y felicidad suficiente.
- La frecuencia de variantes observada en tests coincide con la configurada.

---

## Fase 8 · Equipamiento mejorable

**Tareas**

- 8.1 `EquipmentDef` con niveles y tipos de efecto.
- 8.2 Los siete equipos del GDD §7 con su sprite y animación.
- 8.3 Pestaña de equipo en la tienda.
- 8.4 Automatizaciones: comedero, filtro, imán.
- 8.5 Tests de acumulación de bonificaciones.

**Criterios de aceptación**

- Con comedero y filtro al nivel adecuado, la pecera se mantiene sola.

---

## Fase 9 · Decoración colocable

**Tareas**

- 9.1 `DecorationDef`, inventario y `PlacedDecoration`.
- 9.2 Modo decorar: rejilla, vista previa, colocar, mover, guardar.
- 9.3 Capas de profundidad: fondo, peces, primer plano.
- 9.4 Bonificaciones y requisitos de especie ligados a decoración.
- 9.5 Unos 20 objetos de arte.
- 9.6 Tests de colocación, solapes y límites.

**Criterios de aceptación**

- Colocar y mover objetos es cómodo dentro de la franja.
- La decoración se guarda y se restaura en su sitio.

---

## Fase 10 · Biomas y varias peceras

**Tareas**

- 10.1 `BiomeDef`: fondo, paleta, superficie, suelo, partículas.
- 10.2 Pestañas de pecera y desbloqueo de biomas.
- 10.3 Simulación simplificada de peceras no visibles.
- 10.4 Arte y datos de los biomas 2, 3 y 4: 24 especies más.
- 10.5 Equipo y decoración específicos de bioma.
- 10.6 Tests: la producción de una pecera oculta coincide con la de una visible.

**Criterios de aceptación**

- Cuatro biomas con identidad visual clara.
- Cambiar de pecera es instantáneo y el rendimiento se mantiene.

---

## Fase 11 · Pecedex y logros

**Tareas**

- 11.1 Modelo `Pokedex` y registro de descubrimientos.
- 11.2 Panel de Pecedex con fichas, siluetas y progreso por bioma.
- 11.3 `AchievementDef` con condiciones declarativas sobre estadísticas.
- 11.4 Entre 40 y 60 logros y sus recompensas.
- 11.5 Panel de logros y de estadísticas.

**Criterios de aceptación**

- Cada especie y variante obtenida queda registrada, también de forma retroactiva al cargar una partida.

---

## Fase 12 · Día/noche y eventos aleatorios

**Tareas**

- 12.1 Reloj inyectable y cuatro franjas horarias con transición suave.
- 12.2 Tinte de la pecera y comportamiento diurno/nocturno.
- 12.3 Planificador de eventos con pesos y tiempos de espera.
- 12.4 Los seis eventos del GDD §12.
- 12.5 Tests con reloj falso y semilla fija.

**Criterios de aceptación**

- Cambiar la hora del sistema cambia el ambiente sin romper nada ni dar ventajas explotables.

---

## Fase 13 · Prestigio y meta final

**Tareas**

- 13.1 Cálculo de perlas negras y reinicio selectivo (P05).
- 13.2 Tienda de mejoras permanentes.
- 13.3 Detección de Pecedex completo y secuencia final en ASCII.
- 13.4 Modo infinito posterior.
- 13.5 Tests: tras el prestigio se conserva exactamente lo acordado.

**Criterios de aceptación**

- Un segundo ciclo es claramente más rápido que el primero.
- El final se puede alcanzar y el juego continúa después.

---

## Fase 14 · Audio

**Tareas**

- 14.1 Canales Master, Música, Ambiente y Efectos.
- 14.2 `AudioService` con nombres lógicos.
- 14.3 Ambiente acuático, efectos y una o dos pistas chiptune (P06), con licencias anotadas.
- 14.4 Controles de volumen y silencio rápido.

**Criterios de aceptación**

- El sonido no molesta tras una hora de fondo; todo se puede silenciar.

---

## Fase 15 · Efecto CRT, accesibilidad e inglés

**Tareas**

- 15.1 Sombreador CRT: líneas de barrido, brillo, ligera curvatura; tres niveles.
- 15.2 Opciones de accesibilidad del GDD §15.
- 15.3 Revisión completa de la traducción al inglés y de textos que no caben.
- 15.4 Pantalla de ajustes completa.
- 15.5 Tutorial breve integrado en los primeros minutos.

**Criterios de aceptación**

- Con CRT desactivado y movimiento reducido el juego sigue siendo legible y agradable.
- Ningún texto se corta en ninguno de los dos idiomas.

---

## Fase 16 · Balance, pruebas y versión 1.0

**Tareas**

- 16.1 Simulador de economía en tests: tiempos hasta cada hito.
- 16.2 Ajuste de costes, producciones y probabilidades.
- 16.3 Sesiones de prueba reales de Jorge y corrección de errores.
- 16.4 Revisión de rendimiento frente al presupuesto.
- 16.5 Revisión de seguridad con la lista del doc 06.
- 16.6 Exportación *release* de Windows y prueba en un equipo limpio.
- 16.7 Documentación final para el jugador (controles) y actualización del README.

**Criterios de aceptación**

- Tiempos objetivo (ajustables): segundo bioma hacia la primera hora, primer prestigio entre 8 y 12 horas, Pecedex completo entre 40 y 60 horas.
- Ningún error conocido que bloquee o corrompa la partida.
- Etiqueta `v1.0.0`.

---

## Fase 17 · (Futuro) Versión web y publicación

Sin detallar hasta que Jorge lo decida. Incluiría: exportación HTML5, adaptación de `Platform` a un lienzo apaisado, exportar e importar partidas, página en itch.io, y, para Steam, página de tienda, firma de código e integración con sus servicios.

---

## Riesgos y respuesta

| Riesgo | Probabilidad | Impacto | Respuesta |
|---|---|---|---|
| Los menús no caben en la franja | Alta | Alto | Prototipo en Fase 2 antes de construir paneles |
| Volumen de arte (32 especies con etapas) | Media | Medio | Variantes por paleta, etapas por escala cuando sea posible, arte por bioma repartido |
| Economía desequilibrada | Alta | Medio | Datos externos y simulador automático |
| Rendimiento del dibujado de texto | Media | Alto | Medición desde Fase 1; caché de sprites si hace falta |
| Cambios de versión de Godot o de complementos | Media | Bajo | Versiones fijadas; actualizar solo entre fases |
| Alcance creciente | Alta | Alto | Lista "fuera de alcance" del GDD; ideas nuevas van a una lista para después de la 1.0 |
