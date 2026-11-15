extends GutTest
## Tiempos hasta cada hito con el bot «mixto» (Fase 16.1). Son objetivos de diseño
## (docs/03-PLAN-DESARROLLO.md, Fase 16): si el balance cambia, estas franjas avisan.
##
## El bot es determinista, así que los tiempos salen siempre iguales; las franjas
## dejan margen para ajustes pequeños de costes y producciones.

const HOUR: float = 3600.0


func test_milestones_follow_the_design_targets() -> void:
	var bot: EconomyBot = EconomyBot.new()
	# Se juega lo justo para ver los hitos del primer ciclo y el segundo.
	var m: Dictionary[String, float] = bot.run(13.0, 1.0e10)
	assert_true(m.has("tank_reef"), "abre el Arrecife")
	assert_between(m["tank_reef"] / HOUR, 0.5, 1.5, "segundo bioma hacia la primera hora")
	assert_true(m.has("all_species_unlocked"), "desbloquea todas las especies")
	assert_lt(m["all_species_unlocked"] / HOUR, 4.0, "todas las especies en pocas horas")
	assert_true(m.has("prestige_ready"), "llega a la primera Gran marea")
	assert_between(m["prestige_ready"] / HOUR, 7.0, 12.0, "primer prestigio entre 7 y 12 h")
	assert_true(m.has("r2_prestige_ready"), "llega a la segunda Gran marea")
	assert_lt(
		m["r2_prestige_ready"],
		m["prestige_ready"] * 0.7,
		"el segundo ciclo es claramente más rápido"
	)
