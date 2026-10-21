## The radio in your house. Press E to sit down and tune it: the dial runs from
## 87.5 to 108 MHz, static fades as you get close to a station, and holding a
## station for a moment lets you make out what it says.
##
## Stations:
##   91.3  the tower. Only after dark. A woman's voice; each time you find it
##         you hear the next fragment (the `lines` set in houses.gd).
##   96.4  a music box tape on a loop (the number on the Bells' walkie-talkie).
##   104.1 the emergency service, still looping its "it's a drill" message.
extends "res://scripts/interactable.gd"

signal heard(text: String)

const MIN_FREQ := 87.5
const MAX_FREQ := 108.0
const RATE := 22050.0
const LOCK_TIME := 1.2

const STATIONS := {
	"tower": 91.3,
	"music": 96.4,
	"emergency": 104.1,
}

const EMERGENCY_LINES := [
	"\"...this is the Alder Hollow Civil Emergency Service. This is a scheduled drill. There is no cause for alarm. Please remain where you are...\"",
	"The same message, on a loop. Ninety-one days of \"no cause for alarm\".",
	"\"...this is a scheduled drill...\" You turn it down a little.",
]
const MUSIC_LINES := [
	"A music box tape, playing on a loop. The kind you'd leave on for a child who can't sleep.",
	"The music box again. It's oddly nice to have on.",
]
const MUSIC_NOTES := [0, 4, 7, 12, 7, 4, 9, 7, 0, 4, 7, 11, 12, 11, 7, 4]

var freq := 99.0
var on := false
var tuning := false

var _audio: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _noise := 0.0
var _voice_lp := 0.0
var _t := 0.0
var _st := 0.0  # audio sample clock
var _phase := 0.0
var _phase2 := 0.0
var _note_phase := 0.0
var _lock := 0.0
var _locked_on := ""
var _heard := {"tower": 0, "music": 0, "emergency": 0}
var _strength := {"tower": 0.0, "music": 0.0, "emergency": 0.0}


func _ready() -> void:
	add_to_group("radio")
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.2
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = gen
	_audio.unit_size = 3.0
	_audio.volume_db = -10.0
	add_child(_audio)


func interact() -> String:
	power_on()
	get_tree().call_group("game", "start_tuning", self)
	return ""


func power_on() -> void:
	if on:
		return
	on = true
	prompt = "Tune the radio"
	_audio.play()
	_playback = _audio.get_stream_playback() as AudioStreamGeneratorPlayback


## Which stations you've heard, for saving.
func heard_counts() -> Dictionary:
	return _heard.duplicate()


func restore_heard(d: Dictionary) -> void:
	for id in d:
		_heard[id] = int(d[id])


## How clearly the strongest station is coming through, 0..1.
func strength() -> float:
	var best := 0.0
	for id in _strength:
		best = maxf(best, _strength[id])
	return best


## Moves the dial by `mhz` (negative = left).
func turn(mhz: float) -> void:
	freq = clampf(freq + mhz, MIN_FREQ, MAX_FREQ)


func _is_night() -> bool:
	var clock := get_tree().get_first_node_in_group("clock")
	return clock != null and clock.is_night()


func _process(delta: float) -> void:
	if not on:
		return
	_t += delta
	var best := ""
	var best_strength := 0.0
	for id in STATIONS:
		var s := clampf(1.0 - absf(freq - STATIONS[id]) / 0.6, 0.0, 1.0)
		s *= s
		if id == "tower" and not _is_night():
			s *= 0.15  # just a faint hum during the day
		_strength[id] = s
		if s > best_strength:
			best_strength = s
			best = id
	_update_lock(best, best_strength, delta)
	_fill_audio(best_strength)


func _update_lock(best: String, strength: float, delta: float) -> void:
	var near := absf(freq - STATIONS.get(best, -10.0)) < 0.2
	if not tuning or not near:
		_lock = 0.0
		if not near:
			_locked_on = ""
		return
	if _locked_on == best:
		return
	_lock += delta
	if _lock < LOCK_TIME:
		return
	_locked_on = best
	heard.emit(_station_text(best, strength))


const JOURNAL := {
	"tower": "91.3 at night: a woman's voice, very far away. I think she's at the tower.",
	"music": "96.4 is a music box tape on a loop. The number from the Bells' walkie-talkie. It's oddly nice.",
	"emergency": "104.1 still plays the emergency message. \"This is a scheduled drill.\" It wasn't.",
}


func _station_text(id: String, strength: float) -> String:
	var n: int = _heard[id]
	_heard[id] = n + 1
	if n == 0 and (id != "tower" or strength >= 0.5):
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.write_journal(JOURNAL[id])
	match id:
		"tower":
			if strength < 0.5:
				_heard[id] = n
				return "91.3... just a hum under the static. Maybe it carries better after dark."
			if lines.is_empty():
				return ""
			return lines[mini(n, lines.size() - 1)]
		"music":
			return MUSIC_LINES[mini(n, MUSIC_LINES.size() - 1)]
		"emergency":
			return EMERGENCY_LINES[mini(n, EMERGENCY_LINES.size() - 1)]
	return ""


## Mixes static with whichever stations are in range.
func _fill_audio(best_strength: float) -> void:
	if _playback == null:
		return
	var noise_level := 0.55 * (1.0 - best_strength * 0.85)
	var tower: float = _strength["tower"]
	var music: float = _strength["music"]
	var emergency: float = _strength["emergency"]
	for i in _playback.get_frames_available():
		var dt := 1.0 / RATE
		_st += dt
		var time := _st
		_noise = lerpf(_noise, randf_range(-1.0, 1.0), 0.4)
		var v := _noise * noise_level
		# Voices: a buzzy, filtered "mumble" with syllable-like bursts.
		if tower > 0.01 or emergency > 0.01:
			var pitch := 150.0 + sin(time * 2.3) * 18.0
			_phase = fmod(_phase + pitch * dt, 1.0)
			var buzz := _phase * 2.0 - 1.0
			_voice_lp = lerpf(_voice_lp, buzz, 0.12)
			var syllable := maxf(0.0, sin(time * 11.0) * sin(time * 2.7 + 1.0))
			var voice := _voice_lp * syllable
			v += voice * tower * 0.7
			# Emergency: the two-tone alert, then the announcer.
			var cycle := fmod(time, 9.0)
			if cycle < 2.0:
				_phase2 = fmod(_phase2 + 853.0 * dt, 1.0)
				v += (sin(_phase2 * TAU) + sin(_phase2 * TAU * 960.0 / 853.0)) * 0.12 * emergency
			else:
				v += voice * emergency * 0.6
		# Music box: plucked notes with a quick decay.
		if music > 0.01:
			var beat := time / 0.38
			var note: int = MUSIC_NOTES[int(beat) % MUSIC_NOTES.size()]
			var hz := 523.25 * pow(2.0, note / 12.0)
			_note_phase = fmod(_note_phase + hz * dt, 1.0)
			var env := exp(-fmod(beat, 1.0) * 4.0)
			v += sin(_note_phase * TAU) * env * 0.3 * music
		_playback.push_frame(Vector2(v, v))
