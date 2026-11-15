# Enciclopedia 2 · propuesta (aprobada)

**Progreso:** Estanque ✅ (v0.29.0) · Arrecife ✅ (v0.30.0) · Manglar ✅ (v0.31.0) · Abisal ✅ (v0.32.0). **Enciclopedia 2 completa.**

Cada especie nueva hereda el hueco de rareza, coste, producción y desbloqueo de la que sustituye. Las especies que salen se migran en las partidas guardadas a la nueva que ocupa su hueco.

## Estanque
| Rareza | Nueva | Sustituye a |
|---|---|---|
| Común | Guppy (tamaño cría, 2-4 caracteres) | Guppy |
| Común | Carpa | Pececillo |
| Poco común | Pez de colores | Tetra neón |
| Poco común | Pez gato | Locha |
| Rara | Trucha | Caracol |
| Rara | Salmón (cabeza verde, cuerpo rojo) | Pez dorado |
| Épica | Carpa koi | Pez ángel |
| Legendaria | Siluro (grande) | Carpa koi |

## Arrecife (9 especies: el único bioma con una más)
| Rareza | Nueva | Sustituye a |
|---|---|---|
| Común (la más común) | **Krill** (diminuto, un `~` de color krill; sale en bancos) | nueva (hueco extra) |
| Común | Sardina | Pez payaso (hueco) |
| Común | Anchoa | Damisela azul |
| Poco común | Pez payaso (se mantiene) | Pez mariposa |
| Poco común | Anguila | Estrella de mar |
| Rara | Atún | Cirujano azul |
| Rara | Calamar (rediseño ASCII de くコ:彡) | Caballito de mar |
| Épica | Raya (se mantiene) | Pez globo |
| Legendaria | Tiburón (grande) | Raya |

## Manglar
| Rareza | Nueva | Sustituye a |
|---|---|---|
| Común | Renacuajo (2-4 caracteres) | Pargo |
| Común | Rana | Camarón |
| Poco común | Cangrejo (se mantiene) | Cangrejo |
| Poco común | Saltarín del fango (se mantiene) | Saltarín |
| Rara | Pez arquero (se mantiene) | Arquero |
| Rara | Barracuda (se mantiene) | Barracuda |
| Épica | Arawana | Pez gato |
| Legendaria | Cocodrilo (grande) | Pez sierra |

## Abisal
| Rareza | Nueva | Sustituye a |
|---|---|---|
| Común | Pez linterna (se mantiene) | Pez linterna |
| Común | Medusa (se mantiene) | Medusa |
| Poco común | Pez víbora (se mantiene) | Pez víbora |
| Poco común | Pez gota | Pez hacha |
| Rara | Rape (se mantiene) | Rape |
| Rara | Pez pelícano | Pez remo |
| Épica | Calamar gigante (rediseño ASCII) | Calamar |
| Legendaria | Cachalote (grande) | Calamar gigante |

> Nota: los huecos exactos (qué especie vieja pasa a cuál nueva) los fijo al implementar, siguiendo el orden de coste de cada bioma.

## Crías (nuevo)
Cada especie tendrá su propia cría (y juvenil), en vez de los sprites genéricos de hoy (`stage_fry` / `stage_juvenile`); el juego ya lo permite con `fry_sprite_path` y `juvenile_sprite_path`. Ejemplo de Jorge: cría de calamar `<:≈`. Misma regla: ojos fijos, solo serpenteo del nado.

## Animación (decidido)
- Solo `SwimMotion` + serpenteo del cuerpo; como mucho, un pequeño movimiento de cola o aletas.
- Ojos y forma del cuerpo fijos: un único fotograma de ojo por especie.
- Más variedad entre especies (carpa lenta, atún rápido, anguila serpenteando), nado menos rígido y bancos de sardinas/anchoas.

## Decisiones tomadas
- Calamares: rediseño en ASCII permitido (sin caracteres anchos japoneses).
- Partidas: migración al hueco más parecido.
- Tamaños: según el animal (grandes hasta ~6 filas × 25 columnas; guppy/renacuajo diminutos).

## Arrecife: huecos aplicados (formato de guardado 11)
Pez payaso → Pez payaso (hueco del mariposa); Damisela → Anchoa; Mariposa → Pez payaso; Estrella → Anguila; Cirujano → Atún; Caballito → Calamar; Globo → Raya; Raya → Tiburón. El Krill y la Sardina son nuevos (el pez payaso antiguo conserva su identificador). La migración es de un solo paso (`SaveMigrations.REEF_REPLACEMENTS`).

## Manglar: huecos aplicados (formato de guardado 12)
Arquero → Renacuajo; Cangrejo → Rana; Gamba → Cangrejo; Siluro → Saltarín del fango; Pargo → Pez arquero; Saltarín → Barracuda; Barracuda → Arawana; Pez sierra → Cocodrilo. Un solo paso (`SaveMigrations.MANGROVE_REPLACEMENTS`).

## Abismo: huecos aplicados (formato de guardado 13)
Pez linterna y Medusa se mantienen; Hacha → Pez víbora; Calamar vampiro → Pez gota; Pez víbora → Rape; Rape → Pez pelícano; Pez remo → Calamar gigante; Calamar gigante → Cachalote. Un solo paso (`SaveMigrations.ABYSS_REPLACEMENTS`).
