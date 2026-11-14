extends GutTest
## Pruebas del tutorial (datos puros) y de los ajustes de accesibilidad.


func test_each_step_is_completed_by_its_action() -> void:
	assert_true(Tutorial.completes(0, Tutorial.Action.FEED))
	assert_false(Tutorial.completes(0, Tutorial.Action.BUY))
	assert_true(Tutorial.completes(2, Tutorial.Action.BUY))
	assert_true(Tutorial.completes(4, Tutorial.Action.SHORTCUTS))


func test_finished_tutorial_completes_nothing() -> void:
	assert_false(Tutorial.is_active_step(Tutorial.DONE))
	assert_false(Tutorial.completes(Tutorial.DONE, Tutorial.Action.FEED))


func test_done_matches_step_count() -> void:
	assert_eq(Tutorial.DONE, Tutorial.STEPS.size())


func test_every_step_has_text_in_both_languages() -> void:
	for step: int in range(Tutorial.DONE):
		var key: String = Tutorial.text_key(step)
		assert_ne(TranslationServer.translate(key), key, key)


func test_settings_defaults_and_validation() -> void:
	var data: SettingsData = SettingsData.new()
	assert_false(data.reduce_motion)
	assert_eq(data.text_size, 1)
	assert_eq(data.language, SettingsData.Language.AUTO)
	assert_true(data.tutorial_enabled)
	var back: SettingsData = SettingsData.from_dict(
		{"text_size": 9, "language": -3, "tutorial_step": 99, "reduce_motion": "si"}
	)
	assert_eq(back.text_size, 2)
	assert_eq(back.language, SettingsData.Language.AUTO)
	assert_eq(back.tutorial_step, Tutorial.DONE)
	assert_false(back.reduce_motion)


func test_settings_round_trip() -> void:
	var data: SettingsData = SettingsData.new()
	data.reduce_motion = true
	data.text_size = 0
	data.language = SettingsData.Language.ENGLISH
	data.tutorial_enabled = false
	data.tutorial_step = 3
	var back: SettingsData = SettingsData.from_json(data.to_json())
	assert_true(back.reduce_motion)
	assert_eq(back.text_size, 0)
	assert_eq(back.language, SettingsData.Language.ENGLISH)
	assert_false(back.tutorial_enabled)
	assert_eq(back.tutorial_step, 3)
