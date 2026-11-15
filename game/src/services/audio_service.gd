class_name AudioService
extends Node
## Servicio de audio (autoload `Audio`): música, ambiente y efectos (Fase 14).
##
## Todo el sonido está generado por código (`tools/generate_audio.py`) y vive en
## `assets/audio/`. Los demás sistemas no piden sonidos: este servicio escucha las
## señales de [EventBus] y decide qué suena. Dentro de un mismo fotograma solo suena
## el efecto de mayor prioridad (una venta no suena además como «compra»).

const AUDIO_DIR: String = "res://assets/audio/"
const SFX_VOICES: int = 8
const SILENT_DB: float = -60.0
const FADE_SECONDS: float = 6.0
## Ajuste de cada canal respecto al general, en decibelios.
const MUSIC_BUS_DB: float = -7.0
const AMBIENT_BUS_DB: float = -20.0
const SFX_BUS_DB: float = 0.0
const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_AMBIENT: String = "Ambient"
const BUS_SFX: String = "Sfx"

## Nombre de cada efecto y su prioridad dentro del fotograma (mayor gana).
const SFX_PRIORITY: Dictionary = {
	"click": 0,
	"feed": 1,
	"buy": 2,
	"sell": 3,
	"pearl": 3,
	"hatch": 4,
	"event": 4,
	"reward": 5,
	"achievement": 6,
	"prestige": 8,
	"final": 9,
}

## Último efecto que sonó y cuántos han sonado (para las pruebas).
var last_sound: String = ""
var sound_count: int = 0

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _music_day: AudioStreamPlayer = null
var _music_night: AudioStreamPlayer = null
var _ambient: AudioStreamPlayer = null
var _night_mix: float = 0.0
var _night_target: float = 0.0
var _pending: String = ""


func _ready() -> void:
	_make_buses()
	_music_day = _make_looping("music_day", BUS_MUSIC)
	_music_night = _make_looping("music_night", BUS_MUSIC)
	_ambient = _make_looping("ambient_water", BUS_AMBIENT)
	for _index: int in range(SFX_VOICES):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = BUS_SFX
		add_child(voice)
		_voices.append(voice)
	_connect_events()
	Settings.changed.connect(_apply_volume)
	_apply_volume()
	_set_night_target(Game.daylight.phase())
	_night_mix = _night_target
	_apply_music_mix()
	for player: AudioStreamPlayer in [_music_day, _music_night, _ambient]:
		if player.stream != null:
			player.play()


func _process(delta: float) -> void:
	if not is_equal_approx(_night_mix, _night_target):
		_night_mix = move_toward(_night_mix, _night_target, delta / FADE_SECONDS)
		_apply_music_mix()
	if not _pending.is_empty():
		var name: String = _pending
		_pending = ""
		_play_now(name)


## Pide un efecto por su nombre lógico. Si en este fotograma ya se pidió otro de
## más prioridad, no suena. Los nombres desconocidos se ignoran.
func play(sfx_name: String) -> void:
	if not SFX_PRIORITY.has(sfx_name):
		return
	if _pending.is_empty() or _priority_of(sfx_name) >= _priority_of(_pending):
		_pending = sfx_name


## Alterna el silencio total y devuelve el nuevo estado.
func toggle_mute() -> bool:
	Settings.set_muted(not Settings.data.muted)
	return Settings.data.muted


## Volumen del canal [param bus_name] en dB tras aplicar ajustes (para las pruebas).
func bus_volume_db(bus_name: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


## Con cuánta fuerza suena la música nocturna (0 = día, 1 = noche).
func night_mix() -> float:
	return _night_mix


## Porcentaje (0–100) → decibelios; 0 es silencio.
static func percent_to_db(percent: int) -> float:
	if percent <= 0:
		return SILENT_DB
	return maxf(linear_to_db(float(percent) / 100.0), SILENT_DB)


func _priority_of(sfx_name: String) -> int:
	var value: int = SFX_PRIORITY[sfx_name]
	return value


func _play_now(sfx_name: String) -> void:
	var stream: AudioStream = _stream("sfx_" + sfx_name)
	if stream == null:
		return
	last_sound = sfx_name
	sound_count += 1
	for voice: AudioStreamPlayer in _voices:
		if not voice.playing:
			voice.stream = stream
			voice.play()
			return
	# Todas las voces ocupadas: se reutiliza la primera.
	_voices[0].stream = stream
	_voices[0].play()


func _stream(file_name: String) -> AudioStream:
	if _streams.has(file_name):
		var cached: AudioStream = _streams[file_name]
		return cached
	var path: String = AUDIO_DIR + file_name + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_streams[file_name] = stream
	return stream


func _make_looping(file_name: String, bus_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	var wav: AudioStreamWAV = _stream(file_name) as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
		player.stream = wav
	return player


func _make_buses() -> void:
	for spec: Array in [
		[BUS_MUSIC, MUSIC_BUS_DB], [BUS_AMBIENT, AMBIENT_BUS_DB], [BUS_SFX, SFX_BUS_DB]
	]:
		var bus_name: String = spec[0]
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, BUS_MASTER)
		var db: float = spec[1]
		AudioServer.set_bus_volume_db(index, db)


func _connect_events() -> void:
	EventBus.ui_clicked.connect(play.bind("click"))
	EventBus.food_dropped.connect(play.bind("feed"))
	EventBus.purchase_made.connect(play.bind("buy"))
	EventBus.fish_sold.connect(func(_value: float) -> void: play("sell"))
	EventBus.pearl_collected.connect(func(_value: float) -> void: play("pearl"))
	EventBus.egg_hatched.connect(func(_tank: int) -> void: play("hatch"))
	EventBus.achievement_unlocked.connect(func(_id: String) -> void: play("achievement"))
	EventBus.event_started.connect(func(_id: String, _species: String) -> void: play("event"))
	EventBus.event_rewarded.connect(
		func(_id: String, _shells: float, _decoration: String) -> void: play("reward")
	)
	EventBus.prestiged.connect(func(_pearls: int) -> void: play("prestige"))
	EventBus.final_reached.connect(play.bind("final"))
	EventBus.phase_changed.connect(func(phase: int) -> void: _set_night_target(phase))


func _set_night_target(phase: int) -> void:
	var is_night: bool = phase == DayCycle.Phase.NIGHT or phase == DayCycle.Phase.DUSK
	_night_target = 1.0 if is_night else 0.0


func _apply_volume() -> void:
	var data: SettingsData = Settings.data
	var master: int = AudioServer.get_bus_index(BUS_MASTER)
	AudioServer.set_bus_volume_db(master, percent_to_db(data.master_volume))
	AudioServer.set_bus_mute(master, data.muted)
	var music: int = AudioServer.get_bus_index(BUS_MUSIC)
	AudioServer.set_bus_volume_db(music, MUSIC_BUS_DB + percent_to_db(data.music_volume))


## Mezcla las dos pistas de música con un fundido igual de potencia.
func _apply_music_mix() -> void:
	_music_day.volume_db = percent_to_db(roundi(cos(_night_mix * PI / 2.0) * 100.0))
	_music_night.volume_db = percent_to_db(roundi(sin(_night_mix * PI / 2.0) * 100.0))
