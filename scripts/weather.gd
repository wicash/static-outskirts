## Each day has its own weather: grey, rain, heavy ash or (rarely) clear.
## Rain falls around the player and drums on the roof when you're indoors.
extends Node

const KINDS := {
	"grey": {"name": "Grey", "tint": Color(0.5, 0.5, 0.5), "tint_amount": 0.0, "fog": 1.0, "light": 1.0, "ash": 600,
		"morning": "Grey again. The sky hasn't been blue since March."},
	"rain": {"name": "Rain", "tint": Color(0.42, 0.46, 0.5), "tint_amount": 0.55, "fog": 0.7, "light": 0.6, "ash": 150,
		"morning": "Rain on the roof. Grey rain, but rain. A day for tea and staying in."},
	"ash": {"name": "Ash fall", "tint": Color(0.55, 0.52, 0.5), "tint_amount": 0.7, "fog": 0.55, "light": 0.7, "ash": 3000,
		"morning": "Ash is coming down like snow that doesn't melt. Better keep the windows shut."},
	"clear": {"name": "Clearer", "tint": Color(0.6, 0.58, 0.5), "tint_amount": 0.2, "fog": 1.5, "light": 1.25, "ash": 80,
		"morning": "The haze has thinned. You can almost see the city. You decide not to look for long."},
}
## The first days are fixed, after that it's random (but the same for each day).
const FIXED := ["grey", "rain", "ash"]

var kind := "grey"
var clock: Node
var player: Node3D

var _rain: CPUParticles3D
var _playback: AudioStreamGeneratorPlayback
var _drop := 0.0
var _audio: AudioStreamPlayer
var _lp := 0.0
var _indoors := false
var _check := 0.0


func _ready() -> void:
	add_to_group("weather")
	_rain = CPUParticles3D.new()
	_rain.amount = 1400
	_rain.lifetime = 1.2
	_rain.local_coords = false
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(14, 0.5, 14)
	_rain.direction = Vector3(0.1, -1, 0)
	_rain.spread = 3.0
	_rain.gravity = Vector3(0, -9, 0)
	_rain.initial_velocity_min = 10.0
	_rain.initial_velocity_max = 13.0
	var q := QuadMesh.new()
	q.size = Vector2(0.015, 0.35)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.78, 0.8, 0.35)
	q.material = m
	_rain.mesh = q
	_rain.emitting = false
	add_child(_rain)

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.25
	_audio = AudioStreamPlayer.new()
	_audio.stream = gen
	_audio.volume_db = -60.0
	add_child(_audio)
	_audio.play()
	_playback = _audio.get_stream_playback() as AudioStreamGeneratorPlayback


static func kind_for_day(day: int) -> String:
	if day <= FIXED.size():
		return FIXED[day - 1]
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919
	var roll := rng.randf()
	return "rain" if roll < 0.3 else ("ash" if roll < 0.45 else ("clear" if roll < 0.6 else "grey"))


func set_day(day: int) -> void:
	set_kind(kind_for_day(day))


func set_kind(k: String) -> void:
	kind = k
	var w: Dictionary = KINDS[k]
	clock.fog_tint = w.tint
	clock.fog_tint_amount = w.tint_amount
	clock.fog_mult = w.fog
	clock.light_mult = w.light
	for ash in get_tree().get_nodes_in_group("ash"):
		ash.amount = w.ash
	_rain.emitting = k == "rain"
	# Distant smoke fades out when the weather closes in.
	for smoke in get_tree().get_nodes_in_group("smoke"):
		smoke.color = Color(1, 1, 1, clampf(w.fog, 0.15, 1.0) if w.fog < 1.0 else 1.0)
		if w.fog < 0.8:
			smoke.color.a = 0.15
	clock.apply()


func label() -> String:
	return KINDS[kind].name


func morning_line() -> String:
	return KINDS[kind].morning


func _process(delta: float) -> void:
	if player:
		_rain.global_position = player.global_position + Vector3(0, 9, 0)
		_check -= delta
		if _check <= 0.0:
			_check = 0.3
			_indoors = _under_roof()
	var rain := kind == "rain"
	_rain.visible = rain and not _indoors
	var target := -60.0 if not rain else (-17.0 if _indoors else -12.0)
	_audio.volume_db = move_toward(_audio.volume_db, target, delta * 30.0)
	_fill(rain)


func _under_roof() -> bool:
	var space := player.get_world_3d().direct_space_state
	var from := player.global_position + Vector3(0, 1.6, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, 6, 0))
	q.exclude = [player.get_rid()]
	return not space.intersect_ray(q).is_empty()


## Rain hiss; indoors it's muffled into a soft drumming.
func _fill(rain: bool) -> void:
	if _playback == null:
		return
	var smooth := 0.08 if _indoors else 0.6
	for i in _playback.get_frames_available():
		var v := 0.0
		if rain:
			_lp = lerpf(_lp, randf_range(-1.0, 1.0), smooth)
			v = _lp * (1.6 if _indoors else 0.5)
			# Single drops: a soft patter on the roof indoors, splashes outside.
			if randf() < (0.004 if _indoors else 0.0015):
				_drop = randf_range(0.2, 0.6)
			_drop *= 0.86 if _indoors else 0.7
			v += _drop * randf_range(-1.0, 1.0) * (0.5 if _indoors else 1.0)
		_playback.push_frame(Vector2(v, v))
