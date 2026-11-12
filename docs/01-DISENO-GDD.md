# 01 · Documento de diseño del juego (GDD)

Todo valor numérico de este documento es un punto de partida para el balance. Los números reales viven en los archivos de `data/` y se ajustan en la Fase 16. Lo marcado como **propuesta** espera la confirmación de Jorge (ver `07-DECISIONES.md`, sección C).

## 1. Visión

Una pecera de caracteres que vive en el borde inferior de la pantalla mientras trabajas. Pide poca atención, recompensa las visitas cortas y nunca castiga con pérdidas. La satisfacción viene de ver crecer la colección y de la belleza del arte ASCII en movimiento.

**Pilares**

1. **Compañía, no exigencia.** Nada se pierde por no mirar. Los peces descuidados se entristecen, no mueren.
2. **Todo es texto.** Peces, plantas, agua, menús y efectos se dibujan con caracteres.
3. **Coleccionar es el objetivo.** La economía existe para servir al Pecedex.
4. **Ligero.** Consumo mínimo de procesador y memoria.

**Referencias:** *Rusty's Retirement* (formato de franja, ritmo), juegos incrementales clásicos (curvas de coste), `asciiquarium` (estética).

## 2. Bucle de juego

```
 Peces producen monedas ──► Compras peces, equipo y decoración
        ▲                              │
        │                              ▼
 Cuidas (alimentar, limpiar) ◄── Más peces y mejor pecera
        │                              │
        ▼                              ▼
 Crías y vendes ──► Variantes raras ──► Pecedex ──► Nuevos biomas ──► Prestigio
```

- **Segundos:** los peces nadan, sueltan monedas, aparece comida al hacer clic.
- **Minutos:** compras, una puesta de huevos, un evento aleatorio.
- **Horas:** nuevo bioma, especie rara, logros.
- **Días:** prestigio, completar el Pecedex.

El juego solo avanza mientras está abierto (D11). Al estar pensado para permanecer abierto en la franja, no hay cálculo de ausencia.

## 3. Economía

### 3.1 Monedas

Nombre provisional: **conchas** (símbolo `¢` o `◎`; P04).

Fuentes de ingreso:

| Fuente | Descripción |
|---|---|
| Producción pasiva | Cada pez adulto genera conchas por segundo según su especie, multiplicadas por su felicidad y por las bonificaciones |
| Venta | Vender un pez da un valor según especie, etapa de crecimiento y variante |
| Recogida | A veces un pez suelta una perla visible; hacer clic en ella da un extra |
| Eventos y logros | Recompensas puntuales |

### 3.2 Fórmulas de partida

- Producción de un pez: `base_especie × felicidad × bonus_equipo × bonus_decoración × bonus_prestigio`
- Coste del enésimo pez de una especie: `coste_base × 1,15^n`
- Coste del nivel `k` de un equipo: `coste_base × 1,6^k`
- Valor de venta de un adulto: `0,5 × coste_base × multiplicador_variante`

La producción total se recalcula solo cuando algo cambia (compra, cambio de felicidad), no en cada paso.

### 3.3 Capacidad

Cada pecera admite un número máximo de peces, ampliable con equipamiento. La capacidad obliga a elegir entre conservar productores o hacer sitio para criar, y da sentido a la venta.

## 4. Peces

### 4.1 Atributos de una especie (dato)

Identificador, nombre traducible, bioma, rareza, sprites por etapa y dirección, paleta, velocidad y estilo de nado, producción base, coste base, tiempos de crecimiento y de cría, actividad diurna o nocturna.

### 4.2 Rarezas

| Rareza | Color del nombre | Cómo se obtiene |
|---|---|---|
| Común | Blanco | Tienda desde el principio |
| Poco común | Verde | Tienda tras cumplir un requisito sencillo |
| Rara | Azul | Tienda con requisito, o por evento |
| Épica | Morado | Requisitos de bioma y equipamiento |
| Legendaria | Dorado | Una por bioma; requisito especial |

El color nunca es la única señal: la rareza también se muestra con texto y con un símbolo (`·`, `+`, `*`, `#`, `@`).

### 4.3 Ciclo de vida

`Huevo → Alevín → Juvenil → Adulto`. Solo los adultos producen y crían. Los peces no envejecen ni mueren (D08).

### 4.4 Felicidad

Valor de 0 a 100 por pez, resultado de:

- **Hambre:** baja con el tiempo; se recupera al comer.
- **Limpieza de la pecera:** el agua se ensucia según el número de peces; se limpia a mano o con filtro.
- **Comodidad:** decoración y equipo adecuados a la especie.

La felicidad se traduce en un multiplicador de producción entre **×0,25** (muy triste) y **×1,25** (radiante). Un pez triste nada más despacio y pierde saturación de color, de modo que el estado se lee de un vistazo sin abrir menús.

## 5. Tareas ligeras

| Tarea | Acción | Efecto | Automatización |
|---|---|---|---|
| Alimentar | Clic en el agua: caen copos | Sube el hambre saciada de quien los come | Comedero automático |
| Limpiar | Arrastrar sobre las manchas de alga del cristal | Sube la limpieza | Filtro |
| Recoger perlas | Clic en la perla | Conchas extra | Imán de perlas (equipo avanzado) |
| Atender eventos | Clic en el visitante o en el objeto | Recompensa | No automatizable |

Ninguna tarea es obligatoria: sin ellas el juego progresa más despacio, nunca retrocede.

## 6. Cría y variantes de color

- Dos adultos de la misma especie con felicidad alta ponen un huevo cada cierto tiempo, si hay capacidad libre.
- La cría es de la misma especie que sus padres. No hay herencia genética (D09).
- Cada huevo tiene una probabilidad de salir con una **variante de color** (D27):

| Variante | Probabilidad de partida | Multiplicador de venta |
|---|---|---|
| Normal | 93 % | ×1 |
| Albina | 4 % | ×3 |
| Melánica (oscura) | 2 % | ×5 |
| Dorada | 0,9 % | ×15 |
| Prismática (colores cambiantes) | 0,1 % | ×50 |

- Las variantes solo cambian la paleta, no la forma, lo que mantiene el coste de arte bajo.
- Cada combinación de especie y variante es una entrada del Pecedex.
- Ciertos equipos o decoraciones aumentan la probabilidad de variantes.

## 7. Equipamiento

Mejoras por pecera, con niveles. **Propuesta inicial:**

| Equipo | Efecto por nivel |
|---|---|
| Filtro | La suciedad se acumula más despacio; a nivel alto, limpia solo |
| Comedero | Alimenta automáticamente cada cierto tiempo |
| Calentador | Sube la comodidad de especies tropicales; necesario para algunas |
| Lámpara | Acelera el crecimiento; atenúa la penalización nocturna |
| Aireador | Aumenta la capacidad de peces |
| Incubadora | Acorta la eclosión y sube la probabilidad de variantes |
| Imán de perlas | Recoge perlas automáticamente |

Cada equipo se dibuja en la pecera con su sprite ASCII y una pequeña animación (burbujas del aireador, luz de la lámpara).

## 8. Decoración

- Objetos ASCII que el jugador coloca en el fondo o en el suelo: plantas, rocas, troncos, cofres, ruinas, conchas.
- Se colocan con el ratón sobre una rejilla de celdas; se pueden mover y guardar en inventario.
- Cada objeto da una pequeña bonificación (comodidad, producción de un tipo de pez) y algunos desbloquean especies ("requiere una cueva").
- Límite de objetos por pecera para proteger el rendimiento y la legibilidad.

## 9. Biomas y varias peceras

Cada bioma es una pecera independiente con sus especies, fondo, paleta y decoración. El jugador cambia de pecera con una pestaña; las que no se ven siguen simulándose de forma simplificada (sin animación).

**Propuesta de biomas (P03):**

| Nº | Bioma | Ambiente | Ejemplos de especies |
|---|---|---|---|
| 1 | Estanque | Agua dulce, verde, juncos | Carpa, guppy, tetra, pez ángel, caracol |
| 2 | Arrecife | Coral, colores vivos | Pez payaso, cirujano, caballito de mar, estrella |
| 3 | Manglar | Raíces, agua turbia | Pez arquero, saltarín del fango, cangrejo |
| 4 | Abismo | Negro, bioluminiscencia | Rape abisal, medusa, calamar, pez hacha |

Objetivo de contenido para la versión 1.0: 4 biomas × 8 especies = **32 especies**, cada una con 5 variantes = **160 entradas** de Pecedex. Es una cifra ajustable antes de la Fase 10.

## 10. Interfaz en la franja

La ventana es una franja horizontal pegada al borde inferior de la pantalla, por encima de la barra de tareas, siempre visible.

```
┌─ Estanque ─┬─ Arrecife ─┬─ ··· ─────────────────────────────────────────┬──────────────┐
│~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~│ ◎ 12,4K      │
│      ><(((°>          o                    <°)))><                       │ +38,2/s      │
│  )        o      ><>                 ><>                 (               │ [T]ienda     │
│ (   ¥        ___                                      )   )   ▓▓         │ [P]ecedex    │
│.:.:.:.:.:.:./___\.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.▓▓▓▓.:.:.:│ [D]ecorar ≡  │
└──────────────────────────────────────────────────────────────────────────┴──────────────┘
```

- **Zona de pecera:** ocupa casi todo el ancho.
- **Barra lateral:** conchas, producción por segundo, accesos a menús y un botón de ajustes.
- **Paneles:** tienda, Pecedex, logros y ajustes necesitan más altura que la franja. Hay dos soluciones posibles y se decide con un prototipo en la Fase 2 (P02):
  - a) el panel sustituye temporalmente a la zona de pecera, con desplazamiento horizontal;
  - b) la ventana crece hacia arriba mientras el panel está abierto.
- **Controles:** todo accesible con ratón y con teclado (tecla entre corchetes).
- **Avisos:** mensajes breves que aparecen en la barra lateral ("¡Nueva variante!").

## 11. Pecedex y logros

- **Pecedex:** una ficha por especie con su sprite animado, descripción, rareza, bioma y las cinco variantes como casillas. Lo no descubierto se muestra como silueta de `?`.
- **Logros:** hitos con recompensa (conchas, decoración exclusiva, bonificación permanente pequeña). Entre 40 y 60 para la versión 1.0.
- **Estadísticas:** tiempo de juego, conchas totales, peces criados, variantes obtenidas.

## 12. Día, noche y eventos

- **Día/noche:** la hora del sistema define cuatro franjas (amanecer, día, atardecer, noche) que tiñen el agua y la superficie. Las especies nocturnas producen más de noche y las diurnas duermen. El efecto es suave para no castigar a quien solo juega en un horario; la lámpara lo compensa.
- **Eventos aleatorios**, cada pocos minutos:

| Evento | Qué ocurre |
|---|---|
| Visitante raro | Un pez no comprable cruza la pecera; clic para una recompensa o una entrada especial del Pecedex |
| Lluvia de comida | Todos los peces se sacian |
| Pez dorado fugaz | Clic rápido para un extra de conchas |
| Corriente cálida | Producción ×2 durante un rato |
| Botella a la deriva | Trae un objeto de decoración |
| Plaga de algas | La suciedad sube; limpiar da una recompensa |

Ningún evento causa pérdidas permanentes.

## 13. Prestigio y meta final

- **Prestigio ("Gran marea", nombre provisional):** reinicia conchas, peces y equipamiento a cambio de **perlas negras**, calculadas a partir de las conchas ganadas en la partida. Con ellas se compran mejoras permanentes. **Propuesta (P05):** se conservan Pecedex, logros, decoración desbloqueada y biomas descubiertos.
- **Meta final:** completar el Pecedex (D13). Al conseguirlo se muestra una secuencia final en ASCII y se desbloquea una recompensa cosmética. Después el juego sigue en modo infinito (D12) con prestigio ilimitado.

## 14. Arte y sonido

Las reglas están en `05-GUIA-ARTE-ASCII.md`. En resumen: caracteres con color por especie sobre negro, movimiento fluido por píxel, sprites de una y varias líneas, interfaz con marcos de caja y efecto CRT desactivable.

**Audio (D19):** burbujeo de fondo, efectos discretos (compra, perla, eclosión, logro) y música chiptune tranquila en bucle. Volúmenes independientes para música, ambiente y efectos, y silencio total con una tecla. El juego arranca con volumen bajo porque convive con otras aplicaciones.

## 15. Ajustes y accesibilidad

- Volúmenes por canal y silencio.
- Efecto CRT: activado, reducido o desactivado.
- Reducir movimiento: menos ondulación y sin parpadeos.
- Tamaño del texto de la interfaz.
- Idioma: español o inglés.
- Altura y monitor de la franja (P01, P10).
- Siempre visible: sí o no.
- Límite de fotogramas: 15, 30 o 60.
- Borrar partida, con doble confirmación.

## 16. Fuera de alcance en la versión 1.0

Progreso con el juego cerrado, genética heredada, multijugador, tablas de clasificación, compras dentro del juego, versión móvil, guardado en la nube, modo de ventana normal o transparente.
