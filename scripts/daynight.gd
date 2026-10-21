## The clock: one in-game hour passes every SECONDS_PER_HOUR real seconds.
## Drives the sun, sky, ambient light and fog through the day, using global
## shader values (world_fog, fog_scale) shared by every PS1 material.
extends Node

const SECONDS_PER_HOUR := 60.0

## [hour, fog/sky colour, sun colour, sun energy, ambient colour, ambient energy, fog distance scale]
const KEYS := [
	[0.0, Color(0.05, 0.06, 0.09), Color(0.55, 0.62, 0.85), 0.12, Color(0.3, 0.34, 0.5), 0.32, 0.42],
	[5.0, Color(0.06, 0.07, 0.1), Color(0.55, 0.62, 0.85), 0.12, Color(0.3, 0.34, 0.5), 0.32, 0.42],
	[6.5, Color(0.42, 0.36, 0.38), Color(1.0, 0.7, 0.6), 0.35, Color(0.55, 0.5, 0.55), 0.42, 0.6],
	[9.0, Color(0.55, 0.53, 0.49), Color(1.0, 0.88, 0.74), 0.72, Color(0.62, 0.6, 0.58), 0.55, 1.0],
	[16.0, Color(0.56, 0.52, 0.46), Color(1.0, 0.85, 0.68), 0.7, Color(0.62, 0.6, 0.57), 0.55, 1.0],
	[18.0, Color(0.55, 0.42, 0.33), Color(1.0, 0.62, 0.38), 0.55, Color(0.6, 0.5, 0.45), 0.48, 0.85],
	[19.5, Color(0.22, 0.18, 0.22), Color(0.8, 0.45, 0.4), 0.18, Color(0.4, 0.36, 0.45), 0.38, 0.6],
	[21.0, Color(0.06, 0.07, 0.1), Color(0.55, 0.62, 0.85), 0.12, Color(0.3, 0.34, 0.5), 0.32, 0.42],
	[24.0, Color(0.05, 0.06, 0.09), Color(0.55, 0.62, 0.85), 0.12, Color(0.3, 0.34, 0.5), 0.32, 0.42],
]

var day := 1
var hour := 15.0
var running := true
var env: Environment
var sun: DirectionalLight3D
var _was_night := -1


func _ready() -> void:
	add_to_group("clock")
	apply()


func _process(delta: float) -> void:
	if not running:
		return
	hour += delta / SECONDS_PER_HOUR
	if hour >= 24.0:
		hour -= 24.0
		day += 1
	apply()


## After dark: the tower voice can be heard.
func is_night() -> bool:
	return hour >= 20.5 or hour < 5.0


## Late enough to go to bed.
func is_evening() -> bool:
	return hour >= 19.0 or hour < 5.0


func clock_text() -> String:
	return "Day %d   %02d:%02d" % [day, int(hour), int(fmod(hour, 1.0) * 60.0)]


## Skip ahead to 7 in the morning.
func sleep_until_morning() -> void:
	if hour >= 7.0:
		day += 1
	hour = 7.0
	apply()


func skip(hours: float) -> void:
	hour += hours
	while hour >= 24.0:
		hour -= 24.0
		day += 1
	apply()


## Shows things in the "night_only" group after dusk (moths, glowing flowers).
func refresh_night_things() -> void:
	_was_night = -1
	apply()


func apply() -> void:
	var dark := 1 if (hour >= 19.6 or hour < 5.6) else 0
	if dark != _was_night and is_inside_tree():
		_was_night = dark
		get_tree().call_group("night_only", "set_visible", dark == 1)
	var a: Array = KEYS[0]
	var b: Array = KEYS[1]
	for i in KEYS.size() - 1:
		if hour >= KEYS[i][0] and hour <= KEYS[i + 1][0]:
			a = KEYS[i]
			b = KEYS[i + 1]
			break
	var t := smoothstep(0.0, 1.0, (hour - a[0]) / maxf(b[0] - a[0], 0.001))
	var fog: Color = (a[1] as Color).lerp(b[1], t)
	RenderingServer.global_shader_parameter_set("world_fog", fog)
	RenderingServer.global_shader_parameter_set("fog_scale", lerpf(a[6], b[6], t))
	if env:
		env.background_color = fog
		env.ambient_light_color = (a[4] as Color).lerp(b[4], t)
		env.ambient_light_energy = lerpf(a[5], b[5], t)
	if sun:
		sun.light_color = (a[2] as Color).lerp(b[2], t)
		sun.light_energy = lerpf(a[3], b[3], t)
		# The sun crosses from east to west; at night the same light is a low moon.
		var day_t := clampf((hour - 6.0) / 13.0, 0.0, 1.0)
		var up := sin(day_t * PI)
		if hour < 5.5 or hour > 20.0:
			sun.rotation_degrees = Vector3(-40, -30, 0)
		else:
			sun.rotation_degrees = Vector3(-8.0 - up * 50.0, lerpf(100.0, -100.0, day_t), 0)
