extends GutTest
## Pruebas de los ajustes de audio (volúmenes y silencio).


func test_defaults_are_low_and_unmuted() -> void:
	var data: SettingsData = SettingsData.new()
	assert_eq(data.master_volume, 30)
	assert_eq(data.music_volume, 100)
	assert_false(data.muted)


func test_round_trip() -> void:
	var data: SettingsData = SettingsData.new()
	data.master_volume = 50
	data.music_volume = 20
	data.muted = true
	var back: SettingsData = SettingsData.from_json(data.to_json())
	assert_eq(back.master_volume, 50)
	assert_eq(back.music_volume, 20)
	assert_true(back.muted)


func test_invalid_values_are_fixed() -> void:
	var back: SettingsData = SettingsData.from_dict(
		{"master_volume": 900, "music_volume": "alto", "muted": 1}
	)
	assert_eq(back.master_volume, 100)
	assert_eq(back.music_volume, SettingsData.DEFAULT_MUSIC_VOLUME)
	assert_false(back.muted)
