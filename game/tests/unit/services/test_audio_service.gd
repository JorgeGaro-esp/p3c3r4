extends GutTest
## Pruebas del servicio de audio (autoload `Audio`).

var _saved: SettingsData = null


func before_each() -> void:
	_saved = Settings.data
	Settings.data = SettingsData.new()
	Audio.last_sound = ""
	Audio.sound_count = 0


func after_each() -> void:
	Settings.data = _saved
	Settings.changed.emit()


func test_percent_to_db() -> void:
	assert_eq(AudioService.percent_to_db(0), AudioService.SILENT_DB)
	assert_eq(AudioService.percent_to_db(100), 0.0)
	assert_lt(AudioService.percent_to_db(30), AudioService.percent_to_db(60))


func test_buses_exist() -> void:
	for bus_name: String in [
		AudioService.BUS_MUSIC, AudioService.BUS_AMBIENT, AudioService.BUS_SFX
	]:
		assert_gte(AudioServer.get_bus_index(bus_name), 0, bus_name)


func test_master_volume_follows_settings() -> void:
	Settings.set_master_volume(50)
	assert_almost_eq(Audio.bus_volume_db(AudioService.BUS_MASTER), linear_to_db(0.5), 0.01)


func test_mute_toggle() -> void:
	var master: int = AudioServer.get_bus_index(AudioService.BUS_MASTER)
	assert_true(Audio.toggle_mute())
	assert_true(AudioServer.is_bus_mute(master))
	assert_false(Audio.toggle_mute())
	assert_false(AudioServer.is_bus_mute(master))


func test_sell_wins_over_buy_in_the_same_frame() -> void:
	EventBus.fish_sold.emit(10.0)
	EventBus.purchase_made.emit()
	Audio._process(0.0)
	assert_eq(Audio.last_sound, "sell")
	assert_eq(Audio.sound_count, 1)


func test_click_alone_plays_click() -> void:
	EventBus.ui_clicked.emit()
	await wait_process_frames(2)
	assert_eq(Audio.last_sound, "click")


func test_unknown_sound_is_ignored() -> void:
	Audio.play("no_existe")
	await wait_process_frames(2)
	assert_eq(Audio.sound_count, 0)


func test_every_named_sound_has_a_file() -> void:
	for sfx_name: String in AudioService.SFX_PRIORITY:
		var path: String = AudioService.AUDIO_DIR + "sfx_%s.wav" % sfx_name
		assert_true(ResourceLoader.exists(path), path)


func test_night_phase_fades_to_night_music() -> void:
	EventBus.phase_changed.emit(DayCycle.Phase.NIGHT)
	await wait_seconds(0.3)
	assert_gt(Audio.night_mix(), 0.0)
	EventBus.phase_changed.emit(DayCycle.Phase.DAY)
