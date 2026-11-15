# Catálogo de peces · P3C3R4

Documento para decidir cambios sobre los peces. Generado a partir de `content/species/*.tres` y `assets/i18n/strings.csv` (versión 0.29.0). Al final de cada ficha hay un hueco **Cambios** para anotar qué tocar.

**33 especies** en 4 biomas.

## Resumen

| Bioma | Pez | Rareza | Actividad | Coste | Conchas/s | Crece (s) | Cría (s) | Desbloqueo |
|---|---|---|---|---|---|---|---|---|
| Estanque | Guppy | · Común | Neutra | 10 | 0.02464 | 60 | 90 | Desde el principio |
| Estanque | Carpa | · Común | Diurna | 25 | 0.0528 | 80 | 110 | Desde el principio |
| Estanque | Pez de colores | + Poco común | Diurna | 60 | 0.1232 | 100 | 140 | Ganar 100 conchas en total |
| Estanque | Pez gato | + Poco común | Nocturna | 150 | 0.2816 | 130 | 180 | Colocar 1 decoración con etiqueta «cave» |
| Estanque | Trucha | * Rara | Neutra | 400 | 0.704 | 160 | 220 | Ganar 500 conchas en total |
| Estanque | Salmón | * Rara | Diurna | 1200 | 1.936 | 200 | 300 | Tener 3 × Pez de colores |
| Estanque | Carpa koi | # Épica | Diurna | 4000 | 5.984 | 260 | 420 | Tener 15 peces en total |
| Estanque | Siluro | @ Legendaria | Nocturna | 15000 | 21.12 | 400 | 600 | Tener 3 × Salmón |
| Arrecife | Krill | · Común | Diurna | 600 | 0.915 | 50 | 75 | Desde el principio |
| Arrecife | Sardina | · Común | Diurna | 1500 | 2.288 | 90 | 130 | Desde el principio |
| Arrecife | Anchoa | · Común | Diurna | 2500 | 3.696 | 100 | 140 | Desde el principio |
| Arrecife | Pez payaso | + Poco común | Diurna | 6000 | 8.448 | 140 | 200 | Tener 3 × Sardina |
| Arrecife | Anguila | + Poco común | Diurna | 9000 | 12.32 | 180 | 240 | Colocar 1 decoración con etiqueta «coral» |
| Arrecife | Atún | * Rara | Diurna | 20000 | 27.46 | 220 | 320 | Tener 3 × Anchoa |
| Arrecife | Calamar | * Rara | Nocturna | 32000 | 42.24 | 260 | 380 | Colocar 1 decoración con etiqueta «anemone» |
| Arrecife | Manta raya | # Épica | Diurna | 70000 | 91.52 | 300 | 440 | Tener 3 × Atún |
| Arrecife | Tiburón | @ Legendaria | Nocturna | 220000 | 281.6 | 500 | 700 | Ganar 1.000.000 conchas en total |
| Manglar | Renacuajo | · Común | Neutra | 12000 | 18.3 | 300 | 450 | Desde el principio |
| Manglar | Rana | · Común | Nocturna | 20000 | 29.57 | 330 | 480 | Desde el principio |
| Manglar | Cangrejo de río | + Poco común | Nocturna | 48000 | 66.88 | 380 | 540 | Tener 3 × Rana |
| Manglar | Saltarín del fango | + Poco común | Nocturna | 72000 | 98.56 | 420 | 600 | Colocar 1 decoración con etiqueta «mud» |
| Manglar | Pez arquero | * Rara | Neutra | 160000 | 218.2 | 480 | 680 | Tener 3 × Cangrejo de río |
| Manglar | Barracuda | * Rara | Neutra | 260000 | 337.9 | 540 | 760 | Colocar 1 decoración con etiqueta «root» |
| Manglar | Arawana | # Épica | Nocturna | 560000 | 732.2 | 620 | 860 | Tener 3 × Pez arquero |
| Manglar | Cocodrilo | @ Legendaria | Neutra | 1.8e+06 | 2253 | 800 | 1100 | Ganar 20.000.000 conchas en total |
| Abismo | Pez linterna | · Común | Neutra | 100000 | 147.8 | 500 | 700 | Desde el principio |
| Abismo | Medusa abisal | · Común | Neutra | 160000 | 235.8 | 540 | 740 | Desde el principio |
| Abismo | Pez víbora | + Poco común | Neutra | 380000 | 528 | 600 | 820 | Tener 3 × Pez linterna |
| Abismo | Pez gota | + Poco común | Neutra | 580000 | 792 | 660 | 900 | Colocar 1 decoración con etiqueta «bones» |
| Abismo | Rape abisal | * Rara | Neutra | 1.3e+06 | 1760 | 740 | 1000 | Tener 3 × Medusa abisal |
| Abismo | Pez pelícano | * Rara | Neutra | 2.1e+06 | 2710 | 820 | 1100 | Colocar 1 decoración con etiqueta «lure» |
| Abismo | Calamar gigante | # Épica | Neutra | 4.5e+06 | 5843 | 920 | 1250 | Tener 3 × Pez víbora |
| Abismo | Cachalote | @ Legendaria | Neutra | 1.4e+07 | 17950 | 1200 | 1600 | Ganar 300.000.000 conchas en total |

## Variantes de color (iguales para todas las especies)

| Variante | Peso | Multiplicador de venta |
|---|---|---|
| Albina | 4 | ×3 |
| Dorada | 1.7 | ×15 |
| Melánica | 2 | ×5 |
| Normal | 92 | ×1 |
| Prismática | 0.3 | ×50 |

## Bioma: Estanque

_Agua dulce y tranquila entre juncos. Donde empieza todo._

### Guppy (pond_guppy)

Pequeño y nervioso. Cualquier estanque empieza con uno.

```
<(°>
```

- **Rareza:** · Común · **Actividad:** Neutra
- **Coste:** 10 conchas · **Producción:** 0.02464/s
- **Crecimiento:** 60 s · **Cría:** 90 s · **Eclosión:** 20 s
- **Nado:** Dardo · velocidad 7 · onda 0.2 × 1.6 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Carpa (pond_carp)

Grande y tranquila; remueve el fondo buscando algo que comer.

```
><(###°)>
```

- **Rareza:** · Común · **Actividad:** Diurna
- **Coste:** 25 conchas · **Producción:** 0.0528/s
- **Crecimiento:** 80 s · **Cría:** 110 s · **Eclosión:** 25 s
- **Nado:** Planeo · velocidad 4 · onda 0.15 × 1 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Pez de colores (pond_goldfish)

Aletas de seda y una memoria mejor de lo que dicen.

```
   ,~. 
≈≈(o°)>
```

- **Rareza:** + Poco común · **Actividad:** Diurna
- **Coste:** 60 conchas · **Producción:** 0.1232/s
- **Crecimiento:** 100 s · **Cría:** 140 s · **Eclosión:** 30 s
- **Nado:** Planeo · velocidad 3.5 · onda 0.25 × 1.3 Hz
- **Desbloqueo:** Ganar 100 conchas en total
- **Cambios:** 


### Pez gato (pond_catfish)

Husmea el fondo con sus bigotes cuando cae la noche.

```
><(__°)>
     ~~~
```

- **Rareza:** + Poco común · **Actividad:** Nocturna
- **Coste:** 150 conchas · **Producción:** 0.2816/s
- **Crecimiento:** 130 s · **Cría:** 180 s · **Eclosión:** 35 s
- **Nado:** Planeo · velocidad 3 · onda 0.3 × 1.2 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «cave»
- **Cambios:** 


### Trucha (pond_trout)

Rápida y moteada; solo le gusta el agua fresca y limpia.

```
><(:°)>
```

- **Rareza:** * Rara · **Actividad:** Neutra
- **Coste:** 400 conchas · **Producción:** 0.704/s
- **Crecimiento:** 160 s · **Cría:** 220 s · **Eclosión:** 40 s
- **Nado:** Dardo · velocidad 8 · onda 0.18 × 2 Hz
- **Desbloqueo:** Ganar 500 conchas en total
- **Cambios:** 


### Salmón (pond_salmon)

Cabeza verde y cuerpo rojo; siempre nada contra la corriente.

```
   ___  
><(≈≈°)>
```

- **Rareza:** * Rara · **Actividad:** Diurna
- **Coste:** 1200 conchas · **Producción:** 1.936/s
- **Crecimiento:** 200 s · **Cría:** 300 s · **Eclosión:** 50 s
- **Nado:** Planeo · velocidad 6 · onda 0.2 × 1.6 Hz
- **Desbloqueo:** Tener 3 × Pez de colores
- **Cambios:** 


### Carpa koi (pond_koi)

La joya del estanque. Dicen que trae buena suerte.

```
><(###°)>
```

- **Rareza:** # Épica · **Actividad:** Diurna
- **Coste:** 4000 conchas · **Producción:** 5.984/s
- **Crecimiento:** 260 s · **Cría:** 420 s · **Eclosión:** 60 s
- **Nado:** Planeo · velocidad 3.5 · onda 0.15 × 0.9 Hz
- **Desbloqueo:** Tener 15 peces en total
- **Cambios:** 


### Siluro (pond_wels)

El gigante del estanque. Nadie sabe cuántos años tiene.

```
~~=(_____°)>
        ≈≈≈≈
```

- **Rareza:** @ Legendaria · **Actividad:** Nocturna
- **Coste:** 15000 conchas · **Producción:** 21.12/s
- **Crecimiento:** 400 s · **Cría:** 600 s · **Eclosión:** 80 s
- **Nado:** Planeo · velocidad 2.5 · onda 0.35 × 0.7 Hz
- **Desbloqueo:** Tener 3 × Salmón
- **Cambios:** 


## Bioma: Arrecife

_Coral y colores vivos. Peces tropicales que piden más cuidados._

### Krill (reef_krill)

Diminuto y rosado; nunca va solo, siempre en nube.

```
~°
```

- **Rareza:** · Común · **Actividad:** Diurna
- **Coste:** 600 conchas · **Producción:** 0.915/s
- **Crecimiento:** 50 s · **Cría:** 75 s · **Eclosión:** 18 s
- **Nado:** Deriva · velocidad 2.6 · onda 0.1 × 1.6 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Sardina (reef_sardine)

Plateada y rápida; se mueve con el banco como un solo cuerpo.

```
><(((°>
```

- **Rareza:** · Común · **Actividad:** Diurna
- **Coste:** 1500 conchas · **Producción:** 2.288/s
- **Crecimiento:** 90 s · **Cría:** 130 s · **Eclosión:** 25 s
- **Nado:** Dardo · velocidad 7 · onda 0.2 × 1.8 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Anchoa (reef_anchovy)

Delgada y nerviosa; da vueltas en bancos enormes.

```
~°>
```

- **Rareza:** · Común · **Actividad:** Diurna
- **Coste:** 2500 conchas · **Producción:** 3.696/s
- **Crecimiento:** 100 s · **Cría:** 140 s · **Eclosión:** 28 s
- **Nado:** Dardo · velocidad 7.5 · onda 0.2 × 1.9 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Pez payaso (reef_clownfish)

Naranja con franjas blancas. Se esconde entre los tentáculos.

```
><(|_°|>
```

- **Rareza:** + Poco común · **Actividad:** Diurna
- **Coste:** 6000 conchas · **Producción:** 8.448/s
- **Crecimiento:** 140 s · **Cría:** 200 s · **Eclosión:** 35 s
- **Nado:** Planeo · velocidad 4.5 · onda 0.15 × 1.3 Hz
- **Desbloqueo:** Tener 3 × Sardina
- **Cambios:** 


### Anguila (reef_eel)

Larga y serpenteante; vive escondida entre el coral.

```
  ,-.  ,-.   
~'  `-'  `-°>
```

- **Rareza:** + Poco común · **Actividad:** Diurna
- **Coste:** 9000 conchas · **Producción:** 12.32/s
- **Crecimiento:** 180 s · **Cría:** 240 s · **Eclosión:** 45 s
- **Nado:** Planeo · velocidad 3 · onda 0.35 × 1.1 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «coral»
- **Cambios:** 


### Atún (reef_tuna)

Un torpedo azul que no se detiene nunca.

```
    ,^,  
><=(≡≡°)>
```

- **Rareza:** * Rara · **Actividad:** Diurna
- **Coste:** 20000 conchas · **Producción:** 27.46/s
- **Crecimiento:** 220 s · **Cría:** 320 s · **Eclosión:** 55 s
- **Nado:** Dardo · velocidad 9 · onda 0.1 × 1.2 Hz
- **Desbloqueo:** Tener 3 × Anchoa
- **Cambios:** 


### Calamar (reef_squid)

Aletas atrás y tentáculos delante; pasa como una flecha.

```
<(::°)≈≈≈
```

- **Rareza:** * Rara · **Actividad:** Nocturna
- **Coste:** 32000 conchas · **Producción:** 42.24/s
- **Crecimiento:** 260 s · **Cría:** 380 s · **Eclosión:** 65 s
- **Nado:** Deriva · velocidad 3 · onda 0.25 × 0.9 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «anemone»
- **Cambios:** 


### Manta raya (reef_ray)

Planea como si volara sobre el arrecife.

```
   ,-. 
~~◄__°►
```

- **Rareza:** # Épica · **Actividad:** Diurna
- **Coste:** 70000 conchas · **Producción:** 91.52/s
- **Crecimiento:** 300 s · **Cría:** 440 s · **Eclosión:** 70 s
- **Nado:** Planeo · velocidad 3.5 · onda 0.3 × 0.7 Hz
- **Desbloqueo:** Tener 3 × Atún
- **Cambios:** 


### Tiburón (reef_shark)

El rey del arrecife. Todo el mundo se aparta.

```
      ▲   
><==(~~°)>
```

- **Rareza:** @ Legendaria · **Actividad:** Nocturna
- **Coste:** 220000 conchas · **Producción:** 281.6/s
- **Crecimiento:** 500 s · **Cría:** 700 s · **Eclosión:** 90 s
- **Nado:** Planeo · velocidad 4.5 · onda 0.15 × 0.7 Hz
- **Desbloqueo:** Ganar 1.000.000 conchas en total
- **Cambios:** 


## Bioma: Manglar

_Raíces enredadas y agua turbia. Criaturas que viven entre el barro._

### Renacuajo (mangrove_tadpole)

Diminuto y todo cola; nada en nubes entre las raíces.

```
~~(°
```

- **Rareza:** · Común · **Actividad:** Neutra
- **Coste:** 12000 conchas · **Producción:** 18.3/s
- **Crecimiento:** 300 s · **Cría:** 450 s · **Eclosión:** 70 s
- **Nado:** Dardo · velocidad 3.5 · onda 0.2 × 2 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Rana (mangrove_frog)

Salta entre las raíces y canta cuando cae la tarde.

```
  (°)>
_/(_)\
```

- **Rareza:** · Común · **Actividad:** Nocturna
- **Coste:** 20000 conchas · **Producción:** 29.57/s
- **Crecimiento:** 330 s · **Cría:** 480 s · **Eclosión:** 75 s
- **Nado:** Deriva · velocidad 2.5 · onda 0.1 × 0.8 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Cangrejo de río (mangrove_crab)

Camina por el fondo blandiendo sus pinzas.

```
~=(::°)>>
  /|/|   
```

- **Rareza:** + Poco común · **Actividad:** Nocturna
- **Coste:** 48000 conchas · **Producción:** 66.88/s
- **Crecimiento:** 380 s · **Cría:** 540 s · **Eclosión:** 80 s
- **Nado:** Arrastre · velocidad 1.4 · onda 0.05 × 0.7 Hz
- **Desbloqueo:** Tener 3 × Rana
- **Cambios:** 


### Saltarín del fango (mangrove_mudskipper)

Sale del agua y se arrastra sobre el barro.

```
     (°) 
~-=(===)>
    /\   
```

- **Rareza:** + Poco común · **Actividad:** Nocturna
- **Coste:** 72000 conchas · **Producción:** 98.56/s
- **Crecimiento:** 420 s · **Cría:** 600 s · **Eclosión:** 85 s
- **Nado:** Arrastre · velocidad 2 · onda 0.1 × 0.9 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «mud»
- **Cambios:** 


### Pez arquero (mangrove_archer)

Escupe chorros de agua para derribar insectos.

```
><(||°)>··
```

- **Rareza:** * Rara · **Actividad:** Neutra
- **Coste:** 160000 conchas · **Producción:** 218.2/s
- **Crecimiento:** 480 s · **Cría:** 680 s · **Eclosión:** 90 s
- **Nado:** Planeo · velocidad 6 · onda 0.2 × 1.4 Hz
- **Desbloqueo:** Tener 3 × Cangrejo de río
- **Cambios:** 


### Barracuda (mangrove_barracuda)

Rápida y dentuda. Patrulla el borde del manglar.

```
><=(===°)>
```

- **Rareza:** * Rara · **Actividad:** Neutra
- **Coste:** 260000 conchas · **Producción:** 337.9/s
- **Crecimiento:** 540 s · **Cría:** 760 s · **Eclosión:** 95 s
- **Nado:** Dardo · velocidad 9 · onda 0.15 × 1.8 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «root»
- **Cambios:** 


### Arawana (mangrove_arawana)

Escamas de plata y bigotes; salta fuera del agua a por su presa.

```
   _____   
><(_____°)≈
```

- **Rareza:** # Épica · **Actividad:** Nocturna
- **Coste:** 560000 conchas · **Producción:** 732.2/s
- **Crecimiento:** 620 s · **Cría:** 860 s · **Eclosión:** 100 s
- **Nado:** Planeo · velocidad 4 · onda 0.2 × 1 Hz
- **Desbloqueo:** Tener 3 × Pez arquero
- **Cambios:** 


### Cocodrilo (mangrove_crocodile)

El rey del manglar. Espera inmóvil, como un tronco.

```
   ^^^^   
~=(~~~~°)=
```

- **Rareza:** @ Legendaria · **Actividad:** Neutra
- **Coste:** 1.8e+06 conchas · **Producción:** 2253/s
- **Crecimiento:** 800 s · **Cría:** 1100 s · **Eclosión:** 120 s
- **Nado:** Planeo · velocidad 3 · onda 0.2 × 0.6 Hz
- **Desbloqueo:** Ganar 20.000.000 conchas en total
- **Cambios:** 


## Bioma: Abismo

_Oscuridad total salpicada de luz propia. Los peces más raros del océano._

### Pez linterna (abyss_lantern)

Miles de puntitos de luz en el flanco.

```
><(ooo°)>
```

- **Rareza:** · Común · **Actividad:** Neutra
- **Coste:** 100000 conchas · **Producción:** 147.8/s
- **Crecimiento:** 500 s · **Cría:** 700 s · **Eclosión:** 80 s
- **Nado:** Dardo · velocidad 7 · onda 0.2 × 1.6 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Medusa abisal (abyss_jellyfish)

Flota sin rumbo, translúcida y morada.

```
 ___ 
(_°_)
|:|:|
```

- **Rareza:** · Común · **Actividad:** Neutra
- **Coste:** 160000 conchas · **Producción:** 235.8/s
- **Crecimiento:** 540 s · **Cría:** 740 s · **Eclosión:** 85 s
- **Nado:** Deriva · velocidad 1.6 · onda 0.3 × 0.8 Hz
- **Desbloqueo:** Desde el principio
- **Cambios:** 


### Pez víbora (abyss_viperfish)

Colmillos tan largos que no le caben en la boca.

```
><(oo°)E
```

- **Rareza:** + Poco común · **Actividad:** Neutra
- **Coste:** 380000 conchas · **Producción:** 528/s
- **Crecimiento:** 600 s · **Cría:** 820 s · **Eclosión:** 90 s
- **Nado:** Dardo · velocidad 6 · onda 0.2 × 1.3 Hz
- **Desbloqueo:** Tener 3 × Pez linterna
- **Cambios:** 


### Pez gota (abyss_blobfish)

Blando y con cara de pena; la presión lo mantiene entero.

```
  ,~~~,  
~(___°_)v
```

- **Rareza:** + Poco común · **Actividad:** Neutra
- **Coste:** 580000 conchas · **Producción:** 792/s
- **Crecimiento:** 660 s · **Cría:** 900 s · **Eclosión:** 95 s
- **Nado:** Deriva · velocidad 1.2 · onda 0.1 × 0.7 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «bones»
- **Cambios:** 


### Rape abisal (abyss_anglerfish)

Un farol en la frente atrae a sus presas.

```
    ,o  
><(VV°)>
```

- **Rareza:** * Rara · **Actividad:** Neutra
- **Coste:** 1.3e+06 conchas · **Producción:** 1760/s
- **Crecimiento:** 740 s · **Cría:** 1000 s · **Eclosión:** 100 s
- **Nado:** Planeo · velocidad 2.5 · onda 0.15 × 0.9 Hz
- **Desbloqueo:** Tener 3 × Medusa abisal
- **Cambios:** 


### Pez pelícano (abyss_pelican)

Casi todo boca y cola; traga lo que encuentre.

```
~-~-~(°  )>
```

- **Rareza:** * Rara · **Actividad:** Neutra
- **Coste:** 2.1e+06 conchas · **Producción:** 2710/s
- **Crecimiento:** 820 s · **Cría:** 1100 s · **Eclosión:** 105 s
- **Nado:** Planeo · velocidad 3 · onda 0.35 × 1 Hz
- **Desbloqueo:** Colocar 1 decoración con etiqueta «lure»
- **Cambios:** 


### Calamar gigante (abyss_giant_squid)

Ojos como platos. Casi nadie lo ha visto vivo.

```
<(::::°)≈≈≈≈
```

- **Rareza:** # Épica · **Actividad:** Neutra
- **Coste:** 4.5e+06 conchas · **Producción:** 5843/s
- **Crecimiento:** 920 s · **Cría:** 1250 s · **Eclosión:** 110 s
- **Nado:** Deriva · velocidad 2 · onda 0.3 × 0.6 Hz
- **Desbloqueo:** Tener 3 × Pez víbora
- **Cambios:** 


### Cachalote (abyss_sperm_whale)

Baja a oscuras a cazar calamares gigantes.

```
    ,-----. 
><=(~~~°   )
```

- **Rareza:** @ Legendaria · **Actividad:** Neutra
- **Coste:** 1.4e+07 conchas · **Producción:** 17950/s
- **Crecimiento:** 1200 s · **Cría:** 1600 s · **Eclosión:** 130 s
- **Nado:** Planeo · velocidad 3 · onda 0.15 × 0.5 Hz
- **Desbloqueo:** Ganar 300.000.000 conchas en total
- **Cambios:** 
