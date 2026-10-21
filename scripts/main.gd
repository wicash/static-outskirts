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
	clock.refresh_night_things()
	_start_wind()
	_maybe_take_screenshot()


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

	_hint = _label(hud, 16)
	_hint.position = Vector2(20, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.text = "Click to look around   WASD move   Shift run   E interact   V switch view   F torch   T skip an hour   Esc free mouse"

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
	var cat: Node3D = Cat.new()
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
	clock.sleep_until_morning()
	await get_tree().create_timer(1.0).timeout
	_show_message(_morning_line(clock.day))
	var t2 := create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 2.0)
	await t2.finished
	player.frozen = false


func _morning_line(day: int) -> String:
	var lines := [
		"Morning. Biscuit is asleep on your feet, which explains the dream about sandbags.",
		"Morning. Grey light, cold floor. The kettle first, then everything else.",
		"Morning. You dreamt the radio was saying your name.",
	]
	return "Day %d. " % day + lines[(day - 2) % lines.size()]


# --- Per-frame ---------------------------------------------------------------

func _show_message(text: String) -> void:
	_message.text = text
	_message_time = 6.0
	_message.modulate.a = 1.0


func _process(delta: float) -> void:
	_fill_wind()
	_clock_label.text = clock.clock_text()
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
	}
	for key in views:
		if key in args:
			player.position = views[key][0]
			player.rotation.y = views[key][1]
			player.look(Vector2(0, views[key][2]))
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
