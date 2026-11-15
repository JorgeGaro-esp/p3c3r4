# Comportamiento de los peces

Generado desde `content/species/*.tres`. Se ajusta con los campos `style`, `speed`, `school_pull`, `depth_min/depth_max`, `rest_chance` y `rest_seconds` de cada especie.

- **Banco**: 0 nada solo, 1 siempre con los de su especie.
- **Profundidad**: 0 superficie, 1 fondo.
- **Parada**: probabilidad de quedarse quieto al llegar a un destino y segundos medios.

| Bioma | Pez | Nado | Velocidad | Banco | Profundidad | Parada | Actividad |
|---|---|---|---|---|---|---|---|
| pond | Carpa | Suave | 3.5 | 0 | 0.25–1 | 30 % · 3 s | Diurna |
| pond | Pez gato | Suave | 2 | 0 | 0.6–1 | 60 % · 4 s | Nocturna |
| pond | Pez de colores | Suave | 3.2 | 0.25 | 0.05–0.8 | 20 % · 2.5 s | Diurna |
| pond | Guppy | A impulsos | 7 | 0.3 | 0–0.7 | 10 % · 2 s | Neutra |
| pond | Carpa koi | Suave | 3 | 0.3 | 0.05–0.7 | 15 % · 3 s | Diurna |
| pond | Salmón | Suave | 6.5 | 0.5 | 0–0.8 | 0 % · 2 s | Diurna |
| pond | Trucha | A impulsos | 8 | 0 | 0.2–0.8 | 25 % · 2 s | Neutra |
| pond | Siluro | Suave | 2 | 0 | 0.65–1 | 75 % · 6 s | Nocturna |
| reef | Anchoa | A impulsos | 7.5 | 0.95 | 0–0.5 | 0 % · 2 s | Diurna |
| reef | Pez payaso | Suave | 3 | 0.35 | 0.6–1 | 50 % · 2.5 s | Diurna |
| reef | Anguila | Suave | 2.5 | 0 | 0.7–1 | 50 % · 4 s | Diurna |
| reef | Krill | Flotando | 2.6 | 0.9 | 0–0.6 | 0 % · 2 s | Diurna |
| reef | Manta raya | Suave | 3 | 0 | 0.65–1 | 40 % · 4 s | Diurna |
| reef | Sardina | A impulsos | 7 | 0.9 | 0.1–0.8 | 0 % · 2 s | Diurna |
| reef | Tiburón | Suave | 4.5 | 0 | 0.15–0.8 | 0 % · 2 s | Nocturna |
| reef | Calamar | A impulsos | 4.5 | 0.4 | 0.2–0.8 | 30 % · 2 s | Nocturna |
| reef | Atún | Suave | 8.5 | 0.6 | 0.1–0.7 | 0 % · 2 s | Diurna |
| mangrove | Arawana | Suave | 4 | 0 | 0–0.3 | 20 % · 2 s | Nocturna |
| mangrove | Pez arquero | Suave | 4 | 0 | 0–0.3 | 50 % · 3 s | Neutra |
| mangrove | Barracuda | A impulsos | 10 | 0.2 | 0.3–0.8 | 50 % · 3 s | Neutra |
| mangrove | Cangrejo de río | Pegado al fondo | 1.4 | 0 | 0–1 | 50 % · 3 s | Nocturna |
| mangrove | Cocodrilo | Suave | 2.5 | 0 | 0–0.25 | 75 % · 8 s | Neutra |
| mangrove | Rana | A saltos | 3 | 0 | 0–1 | 0 % · 2.5 s | Nocturna |
| mangrove | Saltarín del fango | Pegado al fondo | 2.2 | 0 | 0–1 | 40 % · 2 s | Nocturna |
| mangrove | Renacuajo | A impulsos | 3.5 | 0.8 | 0–0.5 | 20 % · 1.5 s | Neutra |
| abyss | Rape abisal | Suave | 2 | 0 | 0.5–1 | 80 % · 8 s | Neutra |
| abyss | Pez gota | Flotando | 0.8 | 0 | 0.8–1 | 80 % · 8 s | Neutra |
| abyss | Calamar gigante | Suave | 2.5 | 0 | 0.3–0.9 | 30 % · 3 s | Neutra |
| abyss | Medusa abisal | Flotando | 1.4 | 0 | 0.1–0.9 | 20 % · 3 s | Neutra |
| abyss | Pez linterna | A impulsos | 7 | 0.9 | 0.2–0.9 | 0 % · 2 s | Neutra |
| abyss | Pez pelícano | Suave | 3 | 0 | 0.3–0.9 | 30 % · 3 s | Neutra |
| abyss | Cachalote | Suave | 3 | 0 | 0.2–0.8 | 0 % · 2 s | Neutra |
| abyss | Pez víbora | A impulsos | 6 | 0 | 0.4–1 | 50 % · 3 s | Neutra |
