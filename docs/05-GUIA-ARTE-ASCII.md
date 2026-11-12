# 05 · Guía de arte ASCII

## 1. Principios

1. **Todo lo visible es un carácter** de la fuente del juego. No hay imágenes, salvo el icono de la aplicación.
2. **La forma identifica, el color acompaña.** Cada especie debe reconocerse en un solo color.
3. **Movimiento fluido.** Los caracteres se desplazan por píxel, no por celda (D14).
4. **Menos es más.** Un pez de siete caracteres bien elegido vale más que uno grande y confuso.
5. **Fondo negro.** Los colores se eligen para destacar sobre negro (D16).

## 2. Fuente

- Monoespaciada, con licencia libre que permita incluirla en el juego (por ejemplo, SIL OFL), incluida en `assets/fonts/` junto a su licencia.
- Elegida en la Fase 1 (P08, T17): DejaVu Sans Mono 2.37 (licencia libre tipo Bitstream Vera), en `assets/fonts/`. Es la única candidata evaluada que cubre todos los caracteres de la sección 3.
- Debe cubrir todos los caracteres de la sección 3. Un test recorre los sprites y falla si algún carácter no existe en la fuente.
- Sin ligaduras.

## 3. Juego de caracteres permitido

| Grupo | Caracteres |
|---|---|
| ASCII imprimible | del espacio a `~` |
| Latín para textos | `áéíóúüñÁÉÍÓÚÜÑ¿¡` |
| Signos sueltos | `° º · • ¢ ¥ § ¤ « » × ÷ ±` |
| Marcos de caja | `─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼ ═ ║ ╔ ╗ ╚ ╝` |
| Bloques y tramas | `░ ▒ ▓ █ ▀ ▄ ▌ ▐` |
| Formas | `◎ ○ ● ◦ ◆ ◇ ▲ ▼ ◄ ► ≡ ≈ ∞` |

Cualquier carácter nuevo se añade primero a esta tabla y se comprueba en la fuente. Sin emojis.

## 4. Sprites

### 4.1 Tamaños

| Tipo | Tamaño máximo | Uso |
|---|---|---|
| Diminuto | 3 × 1 | Alevines, peces de banco: `><>` |
| Pequeño | 8 × 1 | Especies comunes: `><(((°>` |
| Mediano | 12 × 3 | Poco comunes y raras |
| Grande | 20 × 5 | Épicas y legendarias |
| Decoración | 16 × 6 | Objetos del fondo |

La altura de la franja limita la pecera a unas pocas líneas, así que los sprites grandes deben ser escasos.

### 4.2 Ejemplos

```
Pequeño (1 línea)        Mediano (3 líneas)        Medusa (3 líneas)

  ><(((°>                    /\                       ,---.
                           ><  °>                    (     )
                             \/                       )|(|(
```

### 4.3 Reglas

- Todo sprite se dibuja **mirando a la derecha**. La versión izquierda se genera sola con la tabla de espejado.
- Tabla de espejado: `( ↔ )`, `< ↔ >`, `/ ↔ \`, `[ ↔ ]`, `{ ↔ }`, `┌ ↔ ┐`, `└ ↔ ┘`, `├ ↔ ┤`, `◄ ↔ ►`, `« ↔ »`. Los demás caracteres no cambian. Si un sprite queda mal espejado, puede traer su versión izquierda a mano.
- El espacio es transparente. Para un hueco opaco dentro de un sprite se usa el marcador definido en el formato.
- El ojo es el punto de anclaje para comer y para las burbujas.
- Etapas de crecimiento: alevín diminuto genérico por familia, juvenil reducido, adulto completo.

### 4.4 Formato de archivo

Un archivo de texto UTF-8 por sprite en `content/sprites/`, con capas separadas:

```
# pond_angelfish · adulto
[frame]
  /\
><  °>
  \/
[colors]
  bb
tt  eb
  bb
[anchor]
eye=4,1
```

- `[frame]`: los caracteres. Puede haber varios fotogramas.
- `[colors]`: misma forma; cada letra es una entrada de la paleta de la especie (`b` cuerpo, `t` cola, `e` ojo, `f` aleta, `d` detalle).
- `[anchor]`: puntos con nombre.

Reglas definitivas (Fase 1):

- La cabecera `# id · etapa` es opcional; si falta, el id es el nombre del archivo.
- Cada `[frame]` es un fotograma. Las líneas más cortas se rellenan con espacios hasta el ancho del fotograma más ancho; el alto se rellena igual.
- `[colors]` es opcional y va justo después de su `[frame]`, con el mismo número de líneas. Un espacio significa "sin color propio" (color de cuerpo por defecto). Un fotograma sin `[colors]` hereda el del anterior.
- `[anchor]`: una línea `nombre=x,y` por punto, con coordenadas desde la esquina superior izquierda, dentro del sprite.
- Todos los sprites se dibujan **mirando a la derecha**. El juego genera la versión mirando a la izquierda invirtiendo cada línea y cambiando las parejas `( )`, `< >`, `/ \`, `[ ]`, `{ }`, `┌ ┐`, `└ ┘`, `├ ┤`, `◄ ►`, `« »`. Los anclajes y colores se reflejan solos.
- El carácter `¤` marca una celda opaca (tapa lo que haya detrás en negro).
- Un archivo con cualquier error (carácter no permitido, anclaje fuera, líneas de color que no cuadran) se rechaza con un mensaje y no se dibuja.

## 5. Color

### 5.1 Paleta general

| Uso | Color |
|---|---|
| Fondo | Negro `#000000` |
| Texto de interfaz | Gris claro `#C8C8C8` |
| Texto atenuado | Gris `#6E6E6E` |
| Resaltado y selección | Ámbar `#FFC857` |
| Agua, superficie | Azul `#3FA7FF` |
| Burbujas | Azul claro `#9AD8FF` |
| Algas | Verdes `#2ECC71` y `#1E8E4E` |
| Arena | Ocre `#C2A66B` |
| Monedas | Dorado `#FFD700` |
| Aviso | Rojo suave `#FF6B6B` |

### 5.2 Paletas de especie

Cada especie define de tres a cinco colores con nombre de papel (cuerpo, cola, ojo, aleta, detalle). Cada bioma tiene una gama dominante para que se distinga de un vistazo: verdes y ocres en el estanque, colores saturados en el arrecife, marrones y verdes apagados en el manglar, azules y cian luminosos sobre negro en el abismo.

### 5.3 Variantes

Las variantes sustituyen la paleta, no la forma:

| Variante | Regla |
|---|---|
| Albina | Blancos y rosas muy claros; ojo rojo |
| Melánica | Grises oscuros con un único detalle de color |
| Dorada | Gama de dorados con brillo que recorre el cuerpo |
| Prismática | El tono de cada carácter rota con el tiempo |

### 5.4 Accesibilidad del color

- Ninguna información depende solo del color: la rareza lleva símbolo y texto; la felicidad se ve también en la velocidad.
- Contraste alto contra negro en todo el texto de la interfaz.

## 6. Animación

- **Nado:** onda que recorre el cuerpo de la cabeza a la cola, con más amplitud en la cola; avance a impulsos; giro progresivo; ligera inclinación al subir o bajar. Parámetros por especie: velocidad, amplitud, frecuencia y estilo (`dart`, `glide`, `drift`, `crawl`).
- **Fotogramas alternos:** la boca o las aletas pueden alternar entre dos fotogramas (`°` y `o`).
- **Entorno:** algas que se mecen con desfase, burbujas con vaivén, superficie `~^~^` que se desplaza, partículas del bioma.
- **Estado:** un pez triste nada lento y desaturado; uno dormido queda quieto con una `z` que sube.
- **Reducir movimiento:** amplitudes a la mitad y sin parpadeos.

## 7. Interfaz

- Marcos sencillos `┌─┐` para paneles normales y dobles `╔═╗` para el panel activo o avisos importantes.
- Atajos entre corchetes: `[T]ienda`.
- Barras de progreso con bloques: `[▓▓▓▓░░░░]`.
- Elemento con foco: color ámbar y marcadores `►` `◄`.
- Elemento desactivado: gris atenuado.
- Texto alineado a la rejilla de la fuente; la interfaz no usa posicionamiento por píxel.

## 8. Efecto CRT

Sombreador de pantalla completa con líneas de barrido, brillo suave alrededor de los caracteres, viñeta y curvatura ligera. Tres niveles: completo, reducido (solo brillo) y desactivado. No debe comprometer la legibilidad del texto pequeño.

## 9. Lista de comprobación de un sprite nuevo

- [ ] Solo usa caracteres de la tabla de la sección 3.
- [ ] Respeta el tamaño máximo de su tipo.
- [ ] Mira a la derecha y se espeja bien.
- [ ] Se reconoce en un solo color.
- [ ] Tiene capa de color y punto de ojo.
- [ ] Se distingue de las demás especies de su bioma.
- [ ] Pasa el test de contenido.
