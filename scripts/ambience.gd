## The world's sound, all made in code like everything else:
##
##   music   two short piano pieces (one for the day, one for night), played
##           now and then with long quiet gaps, like the music in old games.
##           They're synthesised note by note on a background thread at
##           startup, so they cost nothing while you play.
##   birds   chirps from the trees around you on dry days, more in the woods;
##           crows when it's grey or getting dark; an owl at night.
##   places  the station fire crackles and the tower's generator chugs.
##
## Rain (and the drumming on the roof when you're indoors) is in weather.gd.
extends Node

const RATE := 22050

var player: Node3D
var clock: Node
var weather: Node
var game: Node

var _music: AudioStreamPlayer
var _tracks := {}               # "day" / "night" -> AudioStreamWAV, once made
var _music_wait := 75.0         # seconds until the next piece may start
var _chirps: Array[AudioStreamWAV] = []
var _caws: Array[AudioStreamWAV] = []
var _owl: AudioStreamWAV
var _bird_wait := 3.0
var _rng := RandomNumberGenerator.new()
var _task := -1


func _ready() -> void:
	_rng.randomize()
	_music = AudioStreamPlayer.new()
	_music.volume_db = -13.0
	add_child(_music)
	for i in 5:
		_chirps.append(_make_chirp(i))
	for i in 2:
		_caws.append(_make_caw(i))
	_owl = _make_owl()
	_place_loop(_make_crackle(), Vector3(4, 0.6, -397.5), -6.0, 3.0)    # the station fire
	_place_loop(_make_generator(), Vector3(-0.8, 0.6, -494.2), -10.0, 2.5)  # the tower generator
	_task = WorkerThreadPool.add_task(_compose_all)


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


# --- Music ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if player == null:
		return
	_update_music(delta)
	_update_birds(delta)


func _night() -> bool:
	return clock != null and (clock.hour >= 20.0 or clock.hour < 6.0)


func _update_music(delta: float) -> void:
	if _music.playing:
		# Make room for the radio, the tape and the broadcast.
		var quiet: bool = game != null and game.music_should_hush()
		_music.volume_db = move_toward(_music.volume_db, -40.0 if quiet else -13.0, delta * 10.0)
		return
	_music_wait -= delta
	if _music_wait > 0.0:
		return
	var which := "night" if _night() else "day"
	if not _tracks.has(which) or (game and game.music_should_hush()):
		_music_wait = 10.0
		return
	_music.stream = _tracks[which]
	_music.volume_db = -13.0
	_music.play()
	_music_wait = _rng.randf_range(180.0, 300.0)


## Plays the day piece straight away (the title screen).
func play_title_music() -> void:
	if _tracks.has("day"):
		_music.stream = _tracks["day"]
		_music.play()
		_music_wait = 240.0
	else:
		_music_wait = 2.0


## Note lists: [start beat, midi note, length in beats, loudness].
func _compose_all() -> void:
	var day := _day_notes()
	var night := _night_notes()
	var a := _render(day[0], day[1], false)
	var b := _render(night[0], night[1], true)
	if is_instance_valid(self):
		call_deferred("_tracks_ready", a, b)


func _tracks_ready(day: PackedByteArray, night: PackedByteArray) -> void:
	_tracks["day"] = _wav(day)
	_tracks["night"] = _wav(night)


## "Outskirts": A minor, slow, a left-hand arpeggio and a plain tune on top.
static func _day_notes() -> Array:
	var notes: Array = []
	var chords := [[45, 52, 57, 60], [41, 48, 53, 57], [48, 55, 60, 64], [43, 50, 55, 59],
		[45, 52, 57, 60], [41, 48, 53, 57], [48, 55, 60, 64], [40, 47, 52, 56]]
	var tune := [
		[[0, 76, 2], [2, 72, 1], [3, 74, 1]],
		[[0, 72, 2], [2, 69, 2]],
		[[0, 67, 1], [1, 72, 1], [2, 76, 2]],
		[[0, 74, 3], [3, 71, 1]],
		[[0, 72, 1.5], [1.5, 71, 0.5], [2, 69, 2]],
		[[0, 69, 1], [1, 72, 1], [2, 77, 2]],
		[[0, 76, 2], [2, 74, 1], [3, 72, 1]],
		[[0, 71, 2], [2, 68, 2]],
	]
	for rep in 2:
		for bar in 8:
			var t0 := (rep * 8 + bar) * 4.0
			var c: Array = chords[bar]
			for i in 4:
				notes.append([t0 + i, c[[0, 1, 3, 2][i]], 2.5, 0.32])
			if rep == 1 and bar == 7:
				break
			for n in tune[bar]:
				var up := 12 if rep == 1 and bar in [2, 3, 6] else 0
				notes.append([t0 + n[0], n[1] + up, n[2] + 0.5, 0.42])
	# The ending: A minor, held.
	var end := 15 * 4.0
	for m in [33, 45, 52, 57, 60, 64, 69]:
		notes.append([end + (0.0 if m < 50 else 0.15 * (m - 50) / 5.0), m, 6.0, 0.3])
	return [notes, 72.0]


## "Lanterns": a music-box lullaby, high and slow, for after dark.
static func _night_notes() -> Array:
	var notes: Array = []
	var arps := [[69, 72, 76, 79], [65, 69, 72, 76], [72, 76, 79, 84], [67, 71, 74, 79]]
	var tune := [[0, 88, 3], [0, 84, 3], [0, 86, 2, 2, 88, 1], [0, 83, 3]]
	for rep in 3:
		for bar in 4:
			var t0 := (rep * 4 + bar) * 4.0
			var a: Array = arps[bar]
			for i in 8:
				notes.append([t0 + i * 0.5, a[[0, 1, 2, 3, 2, 1, 2, 1][i]], 1.5, 0.22])
			if rep > 0:
				var tl: Array = tune[bar]
				notes.append([t0 + tl[0], tl[1], tl[2], 0.3])
				if tl.size() > 3:
					notes.append([t0 + tl[3], tl[4], tl[5], 0.3])
	notes.append([48.0, 69, 6.0, 0.3])
	notes.append([48.0, 57, 6.0, 0.25])
	return [notes, 58.0]


## Synthesises a note list. Piano: a few decaying harmonics. Music box: a
## brighter, quicker ping with a slightly out-of-tune overtone.
static func _render(notes: Array, bpm: float, box: bool) -> PackedByteArray:
	var beat := 60.0 / bpm
	var last := 0.0
	for n in notes:
		last = maxf(last, (n[0] + n[2]) * beat)
	var total := int((last + 2.5) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for n in notes:
		var start := int(n[0] * beat * RATE)
		var hz := 440.0 * pow(2.0, (n[1] - 69) / 12.0)
		var amp: float = n[3]
		var length := minf(n[2] * beat + 1.2, 4.0)
		var count := mini(int(length * RATE), total - start)
		var parts := [[1.0, 1.0, 1.6], [2.0, 0.45, 2.6], [3.0, 0.2, 3.6], [4.0, 0.1, 5.0]]
		if box:
			parts = [[1.0, 1.0, 2.4], [2.76, 0.25, 6.0], [5.4, 0.08, 9.0]]
		var release_at: float = n[2] * beat
		for p in parts:
			var w: float = TAU * hz * p[0] / RATE
			var a: float = amp * p[1]
			var decay := exp(-p[2] / RATE)
			# A rotating phasor instead of sin() per sample: much faster.
			var c := cos(w)
			var s := sin(w)
			var x := 0.0
			var y := 1.0
			var env := 1.0
			for i in count:
				var t := float(i) / RATE
				var attack := minf(t * 200.0, 1.0)
				var rel := 1.0 if t < release_at else maxf(0.0, 1.0 - (t - release_at) * 1.5)
				buf[start + i] += x * a * env * attack * rel
				var nx := x * c + y * s
				y = y * c - x * s
				x = nx
				env *= decay
	var out := PackedByteArray()
	out.resize(total * 2)
	for i in total:
		out.encode_s16(i * 2, int(clampf(buf[i] * (1.0 if box else 0.55), -1.0, 1.0) * 30000.0))
	return out


# --- Birds and the like ------------------------------------------------------------------

func _update_birds(delta: float) -> void:
	_bird_wait -= delta
	if _bird_wait > 0.0:
		return
	var woods := player.global_position.z < -300.0  # the station and the tower
	_bird_wait = _rng.randf_range(2.0, 6.0) if woods else _rng.randf_range(4.0, 11.0)
	if weather and weather.kind == "rain":
		return
	if weather and weather._indoors:
		if _rng.randf() < 0.6:
			return  # you hear less from inside
	var h: float = clock.hour if clock else 12.0
	var stream: AudioStreamWAV = null
	if h >= 21.5 or h < 5.0:
		if woods or _rng.randf() < 0.3:
			if _rng.randf() < 0.35:
				stream = _owl
	elif (h >= 17.5 and h < 20.0) or (weather and weather.kind in ["grey", "ash"] and _rng.randf() < 0.3):
		stream = _caws[_rng.randi() % _caws.size()] if _rng.randf() < 0.6 else _chirps[_rng.randi() % _chirps.size()]
	elif h >= 5.5 and h < 20.0:
		stream = _chirps[_rng.randi() % _chirps.size()]
	if stream == null:
		return
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(8.0, 22.0)
	var p := player.global_position + Vector3(cos(a) * r, _rng.randf_range(4.0, 9.0), sin(a) * r)
	var s := AudioStreamPlayer3D.new()
	s.stream = stream
	s.unit_size = 9.0
	s.volume_db = -8.0 if stream in _chirps else -4.0
	s.pitch_scale = _rng.randf_range(0.92, 1.08)
	s.position = p
	add_child(s)
	s.play()
	s.finished.connect(s.queue_free)


func _place_loop(stream: AudioStreamWAV, pos: Vector3, db: float, unit: float) -> void:
	var s := AudioStreamPlayer3D.new()
	s.stream = stream
	s.volume_db = db
	s.unit_size = unit
	s.max_distance = 30.0
	s.position = pos
	add_child(s)
	s.play()


## A little songbird phrase: quick upward and downward sweeps.
func _make_chirp(seed: int) -> AudioStreamWAV:
	var r := RandomNumberGenerator.new()
	r.seed = 100 + seed
	var notes := r.randi_range(2, 5)
	var data := PackedFloat32Array()
	var phase := 0.0
	for n in notes:
		var dur := r.randf_range(0.05, 0.14)
		var f0 := r.randf_range(2600.0, 4200.0)
		var f1 := f0 * r.randf_range(0.7, 1.4)
		var count := int(dur * RATE)
		for i in count:
			var t := float(i) / count
			var f := lerpf(f0, f1, t) + sin(t * 40.0) * 120.0
			phase += TAU * f / RATE
			data.append(sin(phase) * sin(t * PI) * 0.5)
		for i in int(r.randf_range(0.03, 0.09) * RATE):
			data.append(0.0)
	return _wav(_bytes(data))


## A crow: a few harsh, falling "caws" (a buzzy tone with noise in it).
func _make_caw(seed: int) -> AudioStreamWAV:
	var r := RandomNumberGenerator.new()
	r.seed = 200 + seed
	var data := PackedFloat32Array()
	var phase := 0.0
	var lp := 0.0
	for n in r.randi_range(2, 3):
		var count := int(r.randf_range(0.28, 0.4) * RATE)
		for i in count:
			var t := float(i) / count
			var f := lerpf(560.0, 380.0, t)
			phase += f / RATE
			var saw := fmod(phase, 1.0) * 2.0 - 1.0
			lp = lerpf(lp, saw + r.randf_range(-0.6, 0.6), 0.35)
			data.append(lp * minf(t * 12.0, 1.0) * (1.0 - t) * 0.6)
		for i in int(r.randf_range(0.18, 0.3) * RATE):
			data.append(0.0)
	return _wav(_bytes(data))


## A tawny owl: "hoo... hoo-hoo-hoooo".
func _make_owl() -> AudioStreamWAV:
	var data := PackedFloat32Array()
	var phase := 0.0
	for part in [[0.5, 0.0], [0.6, 0.0], [0.25, 0.15], [0.25, 0.05], [0.9, 0.0]]:
		var count := int(part[0] * RATE)
		for i in count:
			var t := float(i) / count
			var f := 400.0 - t * 40.0 + sin(t * 30.0) * 6.0
			phase += TAU * f / RATE
			data.append(sin(phase) * sin(t * PI) * 0.45)
		for i in int((0.35 if part[1] == 0.0 else part[1]) * RATE):
			data.append(0.0)
	return _wav(_bytes(data))


## Fire: soft roar with pops and crackles. Loops.
func _make_crackle() -> AudioStreamWAV:
	var r := RandomNumberGenerator.new()
	r.seed = 9
	var data := PackedFloat32Array()
	var lp := 0.0
	var pop := 0.0
	for i in RATE * 4:
		lp = lerpf(lp, r.randf_range(-1.0, 1.0), 0.05)
		if r.randf() < 0.0009:
			pop = r.randf_range(0.4, 0.9)
		pop *= 0.93
		data.append(lp * 0.35 + pop * r.randf_range(-1.0, 1.0))
	var w := _wav(_bytes(data))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = data.size()
	return w


## The generator: a low chug with a rattle.
func _make_generator() -> AudioStreamWAV:
	var data := PackedFloat32Array()
	var r := RandomNumberGenerator.new()
	r.seed = 3
	for i in RATE * 2:
		var t := float(i) / RATE
		var chug := pow(absf(sin(t * TAU * 12.5)), 6.0)  # 25 strokes a second
		var tone := sin(t * TAU * 50.0) * 0.4 + sin(t * TAU * 100.0) * 0.2
		data.append((tone * (0.5 + chug) + r.randf_range(-0.15, 0.15) * chug) * 0.5)
	var w := _wav(_bytes(data))
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = data.size()
	return w


static func _bytes(data: PackedFloat32Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(data.size() * 2)
	for i in data.size():
		out.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 30000.0))
	return out


static func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w
