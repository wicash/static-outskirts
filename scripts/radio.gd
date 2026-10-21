## The radio in your house. Switching it on plays static and the next
## fragment of the mystery broadcast.
extends "res://scripts/interactable.gd"

var _audio: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _on := false
var _noise := 0.0
var _phase := 0.0
var _t := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.2
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = gen
	_audio.unit_size = 3.0
	_audio.volume_db = -14.0
	add_child(_audio)


func interact() -> String:
	_on = true
	prompt = "Turn the dial"
	if not _audio.playing:
		_audio.play()
		_playback = _audio.get_stream_playback() as AudioStreamGeneratorPlayback
	return super.interact()


func _process(delta: float) -> void:
	if not _on or _playback == null:
		return
	_t += delta
	# A faint carrier tone that drifts in and out of the static.
	var tone_level := 0.12 * (0.5 + 0.5 * sin(_t * 0.7))
	for i in _playback.get_frames_available():
		_noise = lerpf(_noise, randf_range(-1.0, 1.0), 0.35)
		_phase = fmod(_phase + 440.0 / 22050.0, 1.0)
		var v := _noise * 0.5 + sin(_phase * TAU) * tone_level
		_playback.push_frame(Vector2(v, v))
