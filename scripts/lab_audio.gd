class_name LabAudio
extends Node

const MUSIC = preload("res://assets/audio/space-flight.ogg")
const EFFECTS = {
	"click": preload("res://assets/audio/click.ogg"),
	"goal": preload("res://assets/audio/goal.ogg"),
	"notice": preload("res://assets/audio/notice.ogg"),
	"place": preload("res://assets/audio/place.ogg")
}
var music_volume = 0.3
var effects_volume = 0.45
var silent = false
var started = false
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index = 0
var last_click = -1000

func _ready() -> void:
	add_to_group("lab_audio")
	music = AudioStreamPlayer.new()
	music.stream = MUSIC.duplicate()
	music.stream.loop = true
	add_child(music)
	for i in range(4):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	apply_levels()

func _input(event: InputEvent) -> void:
	# Browsers unlock audio on the first user gesture. The track then spans menus.
	if event is InputEventMouseButton and event.pressed or event is InputEventKey and event.pressed:
		start_music()

func start_music() -> void:
	if silent or started: return
	started = true
	music.play()

func apply_levels() -> void:
	music_volume = clampf(music_volume, 0.0, 1.0)
	effects_volume = clampf(effects_volume, 0.0, 1.0)
	if is_instance_valid(music): music.volume_db = linear_to_db(maxf(0.00001, music_volume))
	for voice in voices: voice.volume_db = linear_to_db(maxf(0.00001, effects_volume))

func play_effect(kind: String) -> void:
	if silent or not EFFECTS.has(kind): return
	start_music()
	if effects_volume == 0: return
	if kind == "click":
		var now = Time.get_ticks_msec()
		if now - last_click < 65: return
		last_click = now
	var voice = voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = EFFECTS[kind]
	voice.play()
