extends Node

const SEA_SOURCE: AudioStream = preload("res://assets/audio/ambience/sea_felix_blume_500171.ogg")
const RAIN_SOURCE: AudioStream = preload("res://assets/audio/ambience/rain_window_yostpeter_523405.ogg")
const DOOR_SOURCE: AudioStream = preload("res://assets/audio/sfx/old_door_ittaisha_819384.ogg")
const KEY_SOURCE: AudioStream = preload("res://assets/audio/sfx/key_lock_solar01_662888.ogg")
const PAPER_SOURCE: AudioStream = preload("res://assets/audio/sfx/paper_benjaminnelan_353125.ogg")

var sea_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player := 0


func _ready() -> void:
	sea_player = _create_player("SeaAmbience", &"Ambience")
	rain_player = _create_player("RainAmbience", &"Ambience")
	sea_player.stream = _make_looping_stream(SEA_SOURCE)
	rain_player.stream = _make_looping_stream(RAIN_SOURCE)
	for index in range(3):
		sfx_players.append(_create_player("SFX%d" % index, &"SFX"))
	_start_ambience_if_needed()


func set_location(location_id: String) -> void:
	_start_ambience_if_needed()
	match location_id:
		"title":
			sea_player.volume_db = -28.0
			rain_player.volume_db = -23.0
		"lobby":
			sea_player.volume_db = -25.0
			rain_player.volume_db = -15.0
		"room_307":
			sea_player.volume_db = -29.0
			rain_player.volume_db = -13.0
		"laundry":
			sea_player.volume_db = -34.0
			rain_player.volume_db = -22.0
		"finale":
			sea_player.volume_db = -24.0
			rain_player.volume_db = -16.0
		"ending":
			sea_player.volume_db = -30.0
			rain_player.volume_db = -27.0
		_:
			sea_player.volume_db = -30.0
			rain_player.volume_db = -24.0


func play_old_door() -> void:
	_play_sfx(DOOR_SOURCE, -12.0)


func play_key_lock() -> void:
	_play_sfx(KEY_SOURCE, -10.0)


func play_paper() -> void:
	_play_sfx(PAPER_SOURCE, -9.0)


func _create_player(player_name: String, bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


func _make_looping_stream(source: AudioStream) -> AudioStream:
	var stream := source.duplicate()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


func _start_ambience_if_needed() -> void:
	if not sea_player.playing:
		sea_player.play()
	if not rain_player.playing:
		rain_player.play()


func _play_sfx(stream: AudioStream, volume_db: float) -> void:
	if sfx_players.is_empty():
		return
	var player := sfx_players[next_sfx_player]
	next_sfx_player = (next_sfx_player + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()
