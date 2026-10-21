## Builds Alder Street: your house, the neighbours' houses, the street, the cars,
## Biscuit the cat, and the radio. Everything is built from code-made blocks
## (see kit.gd) so it's easy to change while we find the feel.
extends Node

const SCREEN := preload("res://shaders/screen.gdshader")
const Player := preload("res://scripts/player.gd")
const Cat := preload("res://scripts/cat.gd")
const Kit := preload("res://scripts/kit.gd")
const Cars := preload("res://scripts/cars.gd")
const Houses := preload("res://scripts/houses.gd")
const Street := preload("res://scripts/street.gd")
const Survivor := preload("res://scripts/survivor.gd")
const DayNight := preload("res://scripts/daynight.gd")
const RadioDial := preload("res://scripts/radio_dial.gd")
const Aftermath := preload("res://scripts/aftermath.gd")
const Geiger := preload("res://scripts/geiger.gd")
const Items := preload("res://scripts/items.gd")
const Paper := preload("res://scripts/paper.gd")
const Weather := preload("res://scripts/weather.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const Title := preload("res://scripts/title.gd")

## How many screen pixels make up one game pixel. Bigger = chunkier.
const PIXEL_SIZE := 2

var world: Node3D
var player: CharacterBody3D
var kit: Kit

var _prompt: Label
var _message: Label
var _message_time := 0.0
var _hint: Label
var _clock_label: Label
var _dial: Control
var _fade: ColorRect
var clock: Node
var _radio: Node = null  # the radio being tuned, if any
var _geiger: Node3D = null
var cat: Node3D
var weather: Node
var _comfort_label: Label
var _title: Control

# What Sam carries and what she has written down.
var inventory := {}            # item id -> count
var journal_entries: Array = []  # [day, text]
var _paper: Control
var _paper_mode := ""          # "", "journal" or "backpack"
var _journal_hint: Label

# Tom's tape, when it's playing.
const TAPE_LINES := [
	"*click* ...is it on? It's on. Hi. This is Tom Bell. I'm eight and a half.",
	"If you find this, we went to the bus. Dad says we're going to Aunt Ruth's, where there's a farm.",
	"Ada says the radio said it was a drill, but it wasn't a drill. There were three suns.",
	"We were in the shelter for four days. At night there's a lady on the radio. She reads out names.",
	"Mum turns it off when she does. But I heard her say Okafor. And I think she said Hale.",
	"Please feed the cat at number six. His name is Biscuit. He likes his ears done. Bye. *click*",
]
var _tape_audio: AudioStreamGeneratorPlayback
var _tape_line := -1
var _tape_time := 0.0
var _tape_phase := 0.0
var _tape_lp := 0.0
var _tape_st := 0.0


func _ready() -> void:
	add_to_group("game")
	_setup_input()
	_setup_view()
	_setup_hud()
	kit = Kit.new()
	_build_environment()
	_build_alder_street()
	_build_cars()
	_spawn_player(Vector3(0.6, 0.1, -10.5), PI)
	_spawn_cat(Vector3(1.5, 0, -6.8))
	weather = Weather.new()
	weather.clock = clock
	weather.player = player
	add_child(weather)
	weather.set_day(clock.day)
	clock.refresh_night_things()
	_start_wind()
	var args := OS.get_cmdline_user_args()
	if "--selftest" in args:
		_selftest()
	elif "--loadtest" in args:
		_loadtest()
	elif Array(args).any(func(a): return a.begins_with("--shot=")):
		_maybe_take_screenshot()
	else:
		_show_title()


# --- Setup -------------------------------------------------------------------

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"run": [KEY_SHIFT],
		"interact": [KEY_E],
		"toggle_view": [KEY_V],
		"torch": [KEY_F],
		"skip_hour": [KEY_T],
		"geiger": [KEY_G],
		"backpack": [KEY_TAB],
		"journal": [KEY_J],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _setup_view() -> void:
	# Render the 3D world at a low resolution and scale it up with hard pixels.
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.stretch_shrink = PIXEL_SIZE
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SCREEN
	container.material = mat
	add_child(container)

	var viewport := SubViewport.new()
	viewport.audio_listener_enable_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	container.add_child(viewport)

	world = Node3D.new()
	world.name = "World"
	viewport.add_child(world)


func _setup_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	_prompt = _label(hud, 20)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60

	_message = _label(hud, 22)
	_message.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_message.offset_top = -240
	_message.offset_bottom = -140
	_message.offset_left = 200
	_message.offset_right = -200
	_message.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_hint = _label(hud, 14)
	_hint.position = Vector2(20, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.text = "Click to look   WASD move   Shift run   E use   V view   F torch   Tab backpack   J journal   T skip hour"

	_journal_hint = _label(hud, 16)
	_journal_hint.position = Vector2(20, 44)
	_journal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_journal_hint.modulate.a = 0.0

	_comfort_label = _label(hud, 16)
	_comfort_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_comfort_label.offset_left = -260
	_comfort_label.offset_right = -20
	_comfort_label.offset_top = 42
	_comfort_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_paper = Paper.new()
	hud.add_child(_paper)

	_clock_label = _label(hud, 18)
	_clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock_label.offset_left = -220
	_clock_label.offset_right = -20
	_clock_label.offset_top = 16
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_dial = RadioDial.new()
	_dial.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_dial.offset_left = -300
	_dial.offset_right = 300
	_dial.offset_top = -95
	_dial.offset_bottom = -15
	_dial.visible = false
	hud.add_child(_dial)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_fade)

	var dot := _label(hud, 16)
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dot.text = "·"


func _label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.93, 0.9, 0.82))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Kit.FOG
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.58)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.7)
	sun.light_energy = 0.7
	sun.rotation_degrees = Vector3(-35, 40, 0)
	world.add_child(sun)

	clock = DayNight.new()
	clock.env = env
	clock.sun = sun
	add_child(clock)


# --- Places ------------------------------------------------------------------

func _build_alder_street() -> void:
	var houses := Houses.new(kit)
	# North side (your side of the street), west to east.
	houses.empty_lot(world, Vector3(-16, 0, -12))
	houses.your_house(world, Vector3(0, 0, -12))
	houses.okafor_house(world, Vector3(16, 0, -12))
	houses.patel_house(world, Vector3(32, 0, -12))
	# South side.
	houses.bell_house(world, Vector3(-30, 0, 12))
	houses.burnt_house(world, Vector3(-15, 0, 12))
	houses.boarded_house(world, Vector3(16, 0, 12))

	# Door x positions in world space (south-side houses are turned around).
	Street.new(kit, world).build([
		{"x": -16.0, "z": -12.0, "door": -16.0, "number": "2", "fence": false},
		{"x": 0.0, "z": -12.0, "door": 0.6, "number": "4", "mailbox": Color(0.3, 0.42, 0.38)},
		{"x": 16.0, "z": -12.0, "door": 16.0, "number": "6", "mailbox": Color(0.55, 0.15, 0.15)},
		{"x": 32.0, "z": -12.0, "door": 31.5, "number": "8"},
		{"x": -30.0, "z": 12.0, "door": -30.3, "number": "3", "mailbox": Color(0.2, 0.35, 0.55)},
		{"x": -15.0, "z": 12.0, "door": -15.0, "number": "5", "fence_color": Color(0.2, 0.18, 0.16)},
		{"x": 16.0, "z": 12.0, "door": 16.0, "number": "7"},
	])
	Aftermath.new(kit, world).build()


func _build_cars() -> void:
	var cars := Cars.new(kit)

	# The family estate car that never left. Packed to the roof.
	cars.build(world, "estate", Vector3(30, 0, -2.3), 186, {
		"color": Color(0.33, 0.48, 0.5), "interior": Color(0.55, 0.48, 0.38), "plate": "AH 51 KR",
		"writing": "WAIT FOR US", "dirt": 0.3, "rust": 0.2,
		"prompt": "Look inside the car",
		"lines": [
			"The car is packed to the roof: suitcases, a birdcage, a child's car seat with a yellow raincoat folded on it.",
			"The keys are still in the ignition. The battery is dead.",
			"A road map on the passenger seat. Someone drew the route to the coast in red pen.",
		],
		"cargo": [
			["suitcase", Vector3(-1.5, 0.63, -0.4), 0.0, Color(0.25, 0.3, 0.45)],
			["suitcase", Vector3(-1.5, 0.63, 0.35), 0.0, Color(0.5, 0.2, 0.18)],
			["suitcase", Vector3(-1.55, 0.86, 0.0), 6.0, Color(0.3, 0.35, 0.3)],
			["bag", Vector3(-1.3, 0.86, 0.5), 20.0, Color(0.35, 0.42, 0.28)],
			["box", Vector3(-1.95, 0.63, 0.0), 90.0, Color.WHITE],
			["box", Vector3(-1.95, 0.93, 0.1), 80.0, Color.WHITE],
			["blanket", Vector3(-1.4, 1.08, -0.2), 10.0, Color(0.55, 0.22, 0.2)],
			["child_seat", Vector3(-0.6, 0.73, 0.45), 0.0, Color(0.6, 0.25, 0.25)],
			["raincoat", Vector3(-0.52, 0.85, 0.45), 0.0, Color.WHITE],
			["birdcage", Vector3(-0.62, 0.73, -0.42), 0.0, Color.WHITE],
			["teddy", Vector3(-0.6, 0.73, 0.02), 15.0, Color.WHITE],
			["map", Vector3(0.3, 0.69, 0.4), 12.0, Color.WHITE],
			["mug", Vector3(0.55, 0.55, 0.0), 0.0, Color(0.8, 0.8, 0.75)],
			["photo", Vector3(1.05, 1.06, 0.3), 20.0, Color(0.4, 0.5, 0.6)],
		],
	})

	# A saloon that hit the power pole on the night of the strikes.
	cars.build(world, "sedan", Vector3(-19.15, 0, -3.86), 140, {
		"color": Color(0.5, 0.18, 0.15), "interior": Color(0.25, 0.25, 0.27), "plate": "KD 07 LMN",
		"crashed": true, "driver_door_open": true, "rust": 0.3, "dirt": 0.6,
		"prompt": "Look at the crashed car",
		"lines": [
			"It hit the pole hard. The airbag is out, grey with dust. The driver's door hangs open.",
			"A hospital parking permit on the dashboard. Whoever it was was heading to the city.",
		],
		"cargo": [
			["airbag", Vector3(0.42, 0.95, -0.4), 0.0, Color.WHITE],
			["tissues", Vector3(-1.2, 0.86, 0.3), 30.0, Color(0.4, 0.55, 0.7)],
			["bag", Vector3(0.1, 0.68, 0.4), 50.0, Color(0.2, 0.2, 0.22)],
		],
	})

	# The bakery van. Someone has been sleeping in the back.
	var van := cars.build(world, "van", Vector3(22, 0, 2.3), 180, {
		"color": Color(0.78, 0.76, 0.7), "interior": Color(0.3, 0.3, 0.32), "plate": "AB 88 KRE",
		"side_door_open": true, "rust": 0.4, "dirt": 0.4,
		"prompt": "Look inside the van",
		"lines": [
			"ALDER BAKERY. The back is full of flour sacks and boxes of jars.",
			"Someone has been sleeping in here: a blanket, a candle stub, and a tin of peaches, unopened.",
		],
		"cargo": [
			["box", Vector3(-1.8, 0.4, -0.5), 0.0, Color.WHITE],
			["box", Vector3(-1.8, 0.7, -0.5), 10.0, Color.WHITE],
			["box", Vector3(-1.4, 0.4, -0.55), 5.0, Color.WHITE],
			["blanket", Vector3(-1.0, 0.4, 0.2), 80.0, Color(0.35, 0.42, 0.3)],
			["jerrycan", Vector3(-2.2, 0.4, 0.6), 90.0, Color.WHITE],
			["bottle", Vector3(-0.8, 0.4, -0.5), 0.0, Color.WHITE],
		],
	})
	for s in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = "ALDER BAKERY"
		label.pixel_size = 0.008
		label.font_size = 32
		label.outline_size = 0
		label.modulate = Color(0.55, 0.3, 0.18)
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		label.position = Vector3(-0.9, 1.55, s * 0.99)
		label.rotation_degrees.y = 0.0 if s > 0 else 180.0
		van.add_child(label)

	# A little hatchback that was already old before everything happened.
	cars.build(world, "hatchback", Vector3(-25, 0, 2.3), -5, {
		"color": Color(0.7, 0.58, 0.25), "interior": Color(0.4, 0.33, 0.28), "plate": "LT 63 BVX",
		"flat": true, "rust": 0.9, "dirt": 0.95,
		"prompt": "Look at the old hatchback",
		"lines": [
			"Rusted through. The tyres are flat and the windows are grey with ash.",
			"A parking ticket under the wiper, dated the day before the strikes.",
		],
		"cargo": [
			["box", Vector3(-1.4, 0.63, 0.2), 30.0, Color.WHITE],
			["bottle", Vector3(0.1, 0.68, 0.4), 0.0, Color.WHITE],
		],
	})

	# A pickup someone tried to move a whole bedroom with.
	cars.build(world, "pickup", Vector3(-38, 0, -2.3), 5, {
		"color": Color(0.32, 0.4, 0.55), "interior": Color(0.3, 0.27, 0.24), "plate": "RV 12 TOB",
		"rust": 0.5, "dirt": 0.5,
		"prompt": "Look at the pickup",
		"lines": [
			"Someone tried to bring a whole bedroom: a mattress, a chair, boxes of clothes.",
			"Out of fuel. The jerrycan in the cab is empty too.",
		],
		"cargo": [
			["mattress", Vector3(-1.65, 0.73, 0.0), 0.0, Color.WHITE],
			["chair", Vector3(-1.4, 0.91, 0.25), 30.0, Color.WHITE],
			["box", Vector3(-2.1, 0.91, -0.45), 10.0, Color.WHITE],
			["jerrycan", Vector3(0.3, 0.68, 0.4), 0.0, Color.WHITE],
		],
	})


func _spawn_player(pos: Vector3, yaw: float) -> void:
	player = Player.new()
	player.position = pos
	player.rotation.y = yaw
	world.add_child(player)
	var body: Node3D = Survivor.new()
	body.build(kit)
	player.set_body(body)
	player.focus_changed.connect(func(p: String): _prompt.text = ("[E] " + p) if p != "" else "")
	player.message.connect(_show_message)


func _spawn_cat(pos: Vector3) -> void:
	cat = Cat.new()
	cat.position = pos
	cat.home = pos
	cat.player = player
	world.add_child(cat)
	cat.build(kit)


## Soft wind: filtered noise that swells and fades in gusts.
var _wind: AudioStreamGeneratorPlayback
var _wind_lp := 0.0
var _wind_t := 0.0


func _start_wind() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.3
	var audio := AudioStreamPlayer.new()
	audio.stream = gen
	audio.volume_db = -20.0
	add_child(audio)
	audio.play()
	_wind = audio.get_stream_playback() as AudioStreamGeneratorPlayback


func _fill_wind() -> void:
	if _wind == null:
		return
	for i in _wind.get_frames_available():
		_wind_t += 1.0 / 22050.0
		var gust := 0.35 + 0.35 * sin(_wind_t * 0.4) + 0.2 * sin(_wind_t * 1.3 + 1.0)
		_wind_lp = lerpf(_wind_lp, randf_range(-1.0, 1.0), 0.03 + gust * 0.04)
		var v := _wind_lp * gust * 2.5
		_wind.push_frame(Vector2(v, v * 0.9))


# --- Radio, sleep -----------------------------------------------------------

## Called by the radio when you press E on it.
func start_tuning(radio: Node) -> void:
	_radio = radio
	_radio.tuning = true
	if not _radio.heard.is_connected(_show_message):
		_radio.heard.connect(_show_message)
	player.frozen = true
	_dial.visible = true
	_prompt.offset_top = -135
	_prompt.offset_bottom = -105
	_prompt.text = "[A/D or scroll] turn the dial   [Shift] fine tune   [E] stop"


func stop_tuning() -> void:
	_radio.tuning = false
	_radio = null
	_dial.visible = false
	_prompt.text = ""
	_prompt.offset_top = -90
	_prompt.offset_bottom = -60
	# Wait a moment so the same E press doesn't start tuning again.
	await get_tree().create_timer(0.2).timeout
	player.frozen = false


## Called when you pick up the Geiger counter in your kitchen.
func pick_up_geiger() -> void:
	_geiger = Geiger.new()
	player.add_child(_geiger)


## Called by your bed in the evening: fade out, sleep, wake up at 7.
func sleep() -> void:
	player.frozen = true
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 1.5)
	await t.finished
	var cozy := comfort()
	clock.sleep_until_morning()
	weather.set_day(clock.day)
	write_journal("Slept. Woke up on day %d. %s" % [clock.day, weather.label()])
	SaveGame.save(self)
	await get_tree().create_timer(1.0).timeout
	_show_message(_morning_line(clock.day, cozy) + "  (Saved)")
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 2.0)
	await t2.finished
	player.frozen = false


func _morning_line(day: int, cozy: int) -> String:
	var night := "Cold night. The house still feels borrowed."
	if cozy >= 5:
		night = "A warm night. Biscuit snoring on your feet. You slept like you used to."
	elif cozy >= 3:
		night = "You slept better. The candles burnt down to stubs, and you didn't dream."
	elif cozy >= 1:
		night = "You woke twice, listening. Nothing. Just the house settling."
	return "Day %d. %s %s" % [day, night, weather.morning_line()]


# --- Home comfort ----------------------------------------------------------------

## How cozy your house is right now: lit candles, Biscuit living in,
## tea today, and music on the radio.
func comfort() -> int:
	var c := 0
	for spot in get_tree().get_nodes_in_group("candle_spot"):
		if spot.lit:
			c += 1
	if cat and cat.moved_in:
		c += 1
	var kettle := get_tree().get_first_node_in_group("kettle")
	if kettle and kettle.tea_day == clock.day:
		c += 1
	var radio := get_tree().get_first_node_in_group("radio")
	if radio and radio.on and absf(radio.freq - 96.4) < 0.3:
		c += 1
	return c


func _comfort_text() -> String:
	var c := comfort()
	var words := ["chilly", "chilly", "a bit better", "getting there", "cozy", "cozy", "home"]
	var dots := mini(5, ceili(c * 5.0 / 8.0))
	return "Home  " + "●".repeat(dots) + "○".repeat(5 - dots) + "  " + words[mini(c, 6)]


func _in_your_house() -> bool:
	var p := player.global_position
	return absf(p.x) < 4.0 and p.z < -8.5 and p.z > -15.5


# --- Title -------------------------------------------------------------------------

func _show_title() -> void:
	_title = Title.new()
	_hint.visible = false
	_clock_label.visible = false
	_comfort_label.visible = false
	player.frozen = true
	clock.running = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_paper.get_parent().add_child(_title)
	_title.chosen.connect(_on_title)


func _on_title(choice: String) -> void:
	if choice == "quit":
		get_tree().quit()
		return
	if choice == "continue":
		SaveGame.load_into(self)
		weather.set_day(clock.day)
		clock.refresh_night_things()
	_title.queue_free()
	_title = null
	_hint.visible = true
	_clock_label.visible = true
	_comfort_label.visible = true
	player.frozen = false
	clock.running = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if choice == "continue":
		_show_message("Day %d. %s" % [clock.day, weather.morning_line()])
	else:
		_show_message("Day 1. Home, finally. The house is cold and Biscuit's bowl is empty. Grace next door would know where the food is.")


# --- Per-frame ---------------------------------------------------------------

# --- Backpack and journal -----------------------------------------------------

func has_item(id: String) -> bool:
	return inventory.get(id, 0) > 0


func take_item(id: String) -> void:
	inventory[id] = maxi(inventory.get(id, 0) - 1, 0)
	if inventory[id] == 0:
		inventory.erase(id)


## Adds items and returns a short line saying what went into the backpack.
func add_items(ids: Array) -> String:
	var counts := {}
	for id in ids:
		inventory[id] = inventory.get(id, 0) + 1
		counts[id] = counts.get(id, 0) + 1
	var parts: Array[String] = []
	for id in counts:
		parts.append(("%d x %s" % [counts[id], Items.name_of(id)]) if counts[id] > 1 else Items.name_of(id))
	return "(Into your backpack: %s)" % ", ".join(parts)


## Sam writes a line in her journal (once per day for each line).
func write_journal(text: String) -> void:
	for e in journal_entries:
		if e[0] == clock.day and e[1] == text:
			return
	journal_entries.append([clock.day, text])
	_journal_hint.text = "Journal updated  (J)"
	_journal_hint.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(3.0)
	t.tween_property(_journal_hint, "modulate:a", 0.0, 1.5)


func _open_journal() -> void:
	var text := ""
	var day := -1
	if journal_entries.is_empty():
		text = "[i]Nothing written yet. Go and look around.[/i]"
	for e in journal_entries:
		if e[0] != day:
			day = e[0]
			text += ("\n" if text != "" else "") + "[b]Day %d[/b]\n" % day
		text += "-  " + e[1] + "\n"
	_paper.open("Sam's journal", text, "J or Esc to close", true)
	_paper_mode = "journal"
	_paper_opened()


func _open_backpack() -> void:
	var text := ""
	var ids := inventory.keys()
	ids.sort()
	if ids.is_empty():
		text = "[i]Empty, apart from crumbs. Search cupboards, drawers and cars.[/i]"
	for id in ids:
		var n: int = inventory[id]
		text += "[b]%s[/b]%s   [i]%s[/i]\n" % [Items.name_of(id), "  x%d" % n if n > 1 else "", Items.describe(id)]
	_paper.open("Backpack", text, "Tab or Esc to close")
	if has_item("tape") and has_item("walkman"):
		_paper.add_button("Play Tom's tape on the Walkman", func(): _close_paper(); _play_tape())
	elif has_item("tape"):
		_paper.add_button("Play the tape (you need something to play it on)", func(): pass)
	if has_item("collar"):
		_paper.add_button("Put the collar on Biscuit", _give_collar)
	for food in ["peaches", "biscuits", "soup"]:
		if has_item(food):
			_paper.add_button("Eat the %s" % Items.name_of(food).to_lower(), _eat.bind(food))
	_paper_mode = "backpack"
	_paper_opened()


func _paper_opened() -> void:
	player.frozen = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _close_paper() -> void:
	_paper.close()
	_paper_mode = ""
	player.frozen = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _give_collar() -> void:
	var close := cat and cat.global_position.distance_to(player.global_position) < 3.0
	if not close or cat.trust < 2:
		_close_paper()
		_show_message("Biscuit needs to be close by, and to trust you a bit more first.")
		return
	take_item("collar")
	cat.wear_collar()
	_close_paper()
	_show_message("You buckle the red collar on. Biscuit shakes his head, then sits down as if nothing happened.")
	write_journal("Biscuit has his collar back. If Grace comes home, he'll be wearing it.")


func _eat(food: String) -> void:
	take_item(food)
	_close_paper()
	var lines := {
		"peaches": "You eat the peaches straight from the tin, slowly. Today is a good day.",
		"biscuits": "Custard creams, slightly soft. You eat three and save the rest for later. You eat the rest.",
		"soup": "Cold tomato soup from the tin. You've had worse. You've had better. You feel warmer anyway.",
	}
	_show_message(lines[food])
	write_journal("Ate the %s." % Items.name_of(food).to_lower())


# --- Tom's tape ----------------------------------------------------------------

func _play_tape() -> void:
	if _tape_audio == null:
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = 22050.0
		gen.buffer_length = 0.2
		var audio := AudioStreamPlayer.new()
		audio.stream = gen
		audio.volume_db = -12.0
		add_child(audio)
		audio.play()
		_tape_audio = audio.get_stream_playback() as AudioStreamGeneratorPlayback
	_tape_line = 0
	_tape_time = 0.0
	_show_message(TAPE_LINES[0])


func _update_tape(delta: float) -> void:
	if _tape_audio == null:
		return
	var playing := _tape_line >= 0
	if playing:
		_tape_time += delta
		if _tape_time > 5.5:
			_tape_time = 0.0
			_tape_line += 1
			if _tape_line >= TAPE_LINES.size():
				_tape_line = -1
				write_journal("Tom Bell's tape. He heard the lady on the radio read out names. He thinks she said Hale. That's my name.")
			else:
				_show_message(TAPE_LINES[_tape_line])
	# Tape hiss and a small, high, mumbling voice.
	for i in _tape_audio.get_frames_available():
		var v := 0.0
		if playing:
			_tape_st += 1.0 / 22050.0
			var pitch := 270.0 + sin(_tape_st * 3.1) * 30.0
			_tape_phase = fmod(_tape_phase + pitch / 22050.0, 1.0)
			_tape_lp = lerpf(_tape_lp, _tape_phase * 2.0 - 1.0, 0.15)
			var syllable := maxf(0.0, sin(_tape_st * 13.0) * sin(_tape_st * 3.3 + 0.5))
			var pause := 1.0 if _tape_time < 4.6 else 0.0
			v = _tape_lp * syllable * 0.5 * pause + randf_range(-1.0, 1.0) * 0.03
		_tape_audio.push_frame(Vector2(v, v))


func _show_message(text: String) -> void:
	_message.text = text
	_message_time = 6.0
	_message.modulate.a = 1.0


func _process(delta: float) -> void:
	_fill_wind()
	_update_tape(delta)
	_clock_label.text = clock.clock_text() + ("   " + weather.label() if weather else "")
	_comfort_label.text = _comfort_text() if _in_your_house() else ""
	if _radio:
		var speed := 0.5 if Input.is_action_pressed("run") else 2.5
		_radio.turn(Input.get_axis("move_left", "move_right") * speed * delta)
		_dial.freq = _radio.freq
		_dial.signal_strength = _radio.strength()
	if _message_time > 0.0:
		_message_time -= delta
		_message.modulate.a = clampf(_message_time, 0.0, 1.0)
	if _hint.modulate.a > 0.0 and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_hint.modulate.a -= delta * 0.08


func _unhandled_input(event: InputEvent) -> void:
	if _title:
		return
	if _paper_mode != "":
		if event.is_action_pressed("ui_cancel") or (event.is_action_pressed("journal") and _paper_mode == "journal") \
				or (event.is_action_pressed("backpack") and _paper_mode == "backpack"):
			_close_paper()
			get_viewport().set_input_as_handled()
		return
	if _radio == null and not player.frozen:
		if event.is_action_pressed("journal"):
			_open_journal()
			return
		if event.is_action_pressed("backpack"):
			_open_backpack()
			return
	if _radio:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_radio.turn(0.1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_radio.turn(-0.1)
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			stop_tuning()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("geiger") and _geiger:
		_show_message(_geiger.reading())
	if event.is_action_pressed("skip_hour") and _radio == null:
		clock.skip(1.0)
		_show_message("You let an hour slip by. " + clock.clock_text().split("   ")[1])
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		player.look(event.relative)


## Dev helper: presses E on a few things in order and prints what happens.
func _selftest() -> void:
	await get_tree().process_frame
	var by_prompt := {}
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.has_method("interact") and "prompt" in n:
			by_prompt[n.prompt] = n
		stack.append_array(n.get_children())
	for p in ["Fill Biscuit's bowl", "Take the cat food", "Search the cupboards", "Search the kitchen cupboards", "Dig up the tin", "Search the desk", "Pick up the collar", "Read the note"]:
		if by_prompt.has(p):
			print(p, " -> ", by_prompt[p].interact())
		else:
			print("MISSING: ", p)
	print("inventory: ", inventory)
	print("bowl -> ", by_prompt["Fill Biscuit's bowl"].interact())
	for i in 900:
		await get_tree().process_frame
	print("cat at ", cat.global_position, " trust ", cat.trust)
	_open_backpack()
	_close_paper()
	_play_tape()
	print("journal: ", journal_entries)
	for spot in get_tree().get_nodes_in_group("candle_spot"):
		print("candle -> ", spot.interact())
	print("comfort ", comfort(), " ", _comfort_text())
	SaveGame.save(self)
	print("saved")
	get_tree().quit()


func _loadtest() -> void:
	await get_tree().process_frame
	print("load -> ", SaveGame.load_into(self))
	print("day ", clock.day, " inventory ", inventory)
	print("cat trust ", cat.trust, " inside ", cat.moved_in, " comfort ", comfort())
	print("journal lines ", journal_entries.size(), " geiger ", _geiger != null)
	get_tree().quit()


## Dev helper: `godot -- --shot=out.png [--outside] [--third]` saves a screenshot and quits.
func _maybe_take_screenshot() -> void:
	var path := ""
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--shot="):
			path = a.trim_prefix("--shot=")
	if path == "":
		return
	var views := {
		"--outside": [Vector3(-4, 0.1, 3), deg_to_rad(-150), 0.0],
		"--north": [Vector3(3, 0.1, 6), 0.0, 0.0],
		"--home": [Vector3(-0.2, 0.1, -9.4), 0.9, 25.0],
		"--kitchen": [Vector3(1.0, 0.1, -10.5), 0.0, 40.0],
		"--bedroom": [Vector3(-2.2, 0.1, -10.8), 0.3, 40.0],
		"--yourhouse": [Vector3(4, 0.1, -1), 0.35, -10.0],
		"--okafor": [Vector3(15.0, 0.1, -9.6), 0.5, 30.0],
		"--bells": [Vector3(-29.6, 0.1, 10.2), -1.86, 25.0],
		"--burnt": [Vector3(-12, 0.1, 5.5), 2.6, -10.0],
		"--street": [Vector3(-36, 0.1, 6), -1.75, -10.0],
		"--lot": [Vector3(-12, 0.1, -6), 1.0, 0.0],
		"--busstop": [Vector3(30, 0.1, 3), -1.9, 0.0],
		"--car": [Vector3(26.5, 0.1, 0.5), -0.6, 40.0],
		"--crash": [Vector3(-15.5, 0.1, -0.8), 0.83, 40.0],
		"--van": [Vector3(19.5, 0.1, 6.0), -0.75, 40.0],
		"--cat": [Vector3(1.5, 0.1, -4.6), 0.0, 120.0],
		"--road": [Vector3(-6, 0.1, -1.0), -1.4, -12.0],
		"--flash": [Vector3(-16, 0.1, -10.5), 0.0, 5.0],
		"--decon": [Vector3(40.5, 0.1, -3.5), 0.15, -5.0],
		"--help": [Vector3(-12.5, 3.0, 5.0), -0.3, 220.0],
		"--memorial": [Vector3(-14, 0.1, 2.5), PI + 0.3, -20.0],
		"--wires": [Vector3(0, 0.1, -1.0), 0.6, 35.0],
		"--shelter": [Vector3(-29, 0.1, 16.5), PI + 0.2, -15.0],
		"--bowl": [Vector3(1.2, 0.1, -10.8), 2.6, 60.0],
	}
	for key in views:
		if key in args:
			player.position = views[key][0]
			player.rotation.y = views[key][1]
			player.look(Vector2(0, views[key][2]))
	if "--rain" in args:
		weather.set_kind("rain")
	if "--ashfall" in args:
		weather.set_kind("ash")
	if "--title" in args:
		_show_title()
	if "--candles" in args:
		for spot in get_tree().get_nodes_in_group("candle_spot"):
			spot.light()
	if "--dusk" in args:
		clock.hour = 18.6
	if "--night" in args:
		clock.hour = 22.5
	clock.running = false
	clock.refresh_night_things()
	if "--torch" in args:
		player.torch.visible = true
	if "--tuning" in args:
		var radio := get_tree().get_first_node_in_group("radio")
		radio.interact()
		radio.freq = 104.1
	if "--journal" in args or "--backpack" in args:
		add_items(["cat_food", "cat_food", "cat_food", "cat_food", "cat_food", "candle", "candle", "matches", "tea", "peaches", "tape", "walkman", "collar"])
		write_journal("Grace from No. 6 went to her sister's in the city in March. \"Back Sunday.\" She asked someone to feed Biscuit. I suppose that's me now.")
		write_journal("Found Biscuit's food in Grace's cupboard. Six tins. I'll ration them.")
		write_journal("Fed Biscuit.")
		write_journal("There's a shadow on the wall at the empty lot. A person and a bicycle. I keep thinking about which way they were going.")
		clock.day = 2
		write_journal("Slept. Woke up on day 2.")
		write_journal("104.1 still plays the emergency message. \"This is a scheduled drill.\" It wasn't.")
		write_journal("Tom Bell's tape. He heard the lady on the radio read out names. He thinks she said Hale. That's my name.")
		if "--journal" in args:
			_open_journal()
		else:
			_open_backpack()
	if "--third" in args or "--face" in args:
		player.toggle_view()
	if "--face" in args:
		# Turn Sam around to face the camera, for character close-ups.
		player.body.rotation.y = PI
		player.arm.spring_length = 2.0 if not "--close" in args else 0.9
		player.camera.h_offset = 0.0
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
