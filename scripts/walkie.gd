## The Bells' walkie-talkie. Hold R to listen: it beeps faster the closer you
## are to a Ranger cache you haven't found yet.
extends Node3D

const RATE := 22050.0

var listening := false
var strength := 0.0   # 0..1, for the HUD
var _playback: AudioStreamGeneratorPlayback
var _phase := 0.0
var _beep := 0.0       # time until next beep
var _beep_len := 0     # samples left in the current beep


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.15
	var audio := AudioStreamPlayer.new()
	audio.stream = gen
	audio.volume_db = -14.0
	add_child(audio)
	audio.play()
	_playback = audio.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	var nearest := 1e9
	for c in get_tree().get_nodes_in_group("cache"):
		if not c.found():
			nearest = minf(nearest, global_position.distance_to(c.global_position))
	strength = clampf(1.0 - (nearest - 1.5) / 40.0, 0.0, 1.0)
	if listening and nearest < 1e8:
		_beep -= delta
		if _beep <= 0.0:
			_beep = lerpf(1.6, 0.08, strength)
			_beep_len = 900
	if _playback == null:
		return
	for i in _playback.get_frames_available():
		var v := 0.0
		if listening:
			v = randf_range(-1.0, 1.0) * 0.04  # open-channel hiss
			if _beep_len > 0:
				_phase = fmod(_phase + lerpf(600.0, 1400.0, strength) / RATE, 1.0)
				v += (1.0 if _phase < 0.5 else -1.0) * 0.18
				_beep_len -= 1
		_playback.push_frame(Vector2(v, v))
