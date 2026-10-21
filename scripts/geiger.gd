## Sam's Geiger counter. Once picked up it clicks quietly all the time, and
## faster near hot spots (Marker3Ds in the "hotspot" group with a "strength").
## G shows a reading.
extends Node3D

const RATE := 22050.0

var _playback: AudioStreamGeneratorPlayback
var _rate := 0.5      # clicks per second
var _click := 0       # samples left in the current click


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.15
	var audio := AudioStreamPlayer.new()
	audio.stream = gen
	audio.volume_db = -16.0
	add_child(audio)
	audio.play()
	_playback = audio.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	_rate = 0.5
	for h in get_tree().get_nodes_in_group("hotspot"):
		var d := global_position.distance_to(h.global_position)
		_rate += float(h.get_meta("strength", 1.0)) * 25.0 / (1.0 + d * d / 6.0)
	if _playback == null:
		return
	var chance := _rate / RATE
	for i in _playback.get_frames_available():
		if _click <= 0 and randf() < chance:
			_click = 70
		var v := 0.0
		if _click > 0:
			v = randf_range(-1.0, 1.0) * (_click / 70.0)
			_click -= 1
		_playback.push_frame(Vector2(v, v))


## A short line for the HUD when you check the counter.
func reading() -> String:
	var usv := _rate * 0.06
	var note := "Background. Fine."
	if usv > 2.0:
		note = "Don't stay here long."
	elif usv > 0.6:
		note = "Higher than it should be."
	elif usv > 0.15:
		note = "A little high. Probably fine."
	return "The counter reads %.2f µSv/h. %s" % [usv, note]
