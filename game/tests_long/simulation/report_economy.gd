extends GutTest
## Informe de economía (no forma parte de la batería normal: el nombre no empieza
## por `test_`). Juega con el bot mixto y escribe los hitos en la consola.
##
## Uso, desde la carpeta `game`:
##   set SIM_HOURS=40
##   set SIM_PRESTIGE=1e10
##   Godot --headless -s addons/gut/gut_cmdln.gd \
##     -gtest=res://tests_long/simulation/report_economy.gd -gexit
## `SIM_PRESTIGE` (opcional) hace la Gran marea cada vez que el ciclo gana esas conchas.


func test_report() -> void:
	var hours: float = OS.get_environment("SIM_HOURS").to_float()
	var prestige_at: float = OS.get_environment("SIM_PRESTIGE").to_float()
	var bot: EconomyBot = EconomyBot.new()
	var result: Dictionary[String, float] = bot.run(maxf(hours, 1.0), prestige_at)
	print("RESUMEN ", bot.summary())
	for key: String in result:
		print("HITO %-24s %.2f h" % [key, result[key] / 3600.0])
	assert_true(true)
