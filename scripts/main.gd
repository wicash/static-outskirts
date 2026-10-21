## Builds the first test area: one street on the city outskirts, your house,
## two neighbours' houses, a stray cat, and the radio.
## Everything is placeholder blocks so it's easy to change while we find the feel.
extends Node

const PS1 := preload("res://shaders/ps1.gdshader")
const SCREEN := preload("res://shaders/screen.gdshader")
const Player := preload("res://scripts/player.gd")
const Interactable := preload("res://scripts/interactable.gd")
const Radio := preload("res://scripts/radio.gd")
const Cat := preload("res://scripts/cat.gd")

## How many screen pixels make up one game pixel. Bigger = chunkier.
const PIXEL_SIZE := 3
const FOG := Color(0.55, 0.52, 0.47)

var world: Node3D
var player: CharacterBody3D
var grain: NoiseTexture2D
var _materials := {}

var _prompt: Label
var _message: Label
var _message_time := 0.0
var _hint: Label


func _ready() -> void:
	_setup_input()
	_setup_view()
	_setup_hud()
	_make_grain()
	_build_environment()
	_build_street()
	_build_your_house(Vector3(0, 0, -12))
	_build_neighbour_house(Vector3(-16, 0, -12))
	_build_burnt_house(Vector3(-15, 0, 12))
	_build_calendar_house(Vector3(16, 0, 12))
	_build_forest_edge()
	_build_skyline()
	_build_ash()
	_spawn_player(Vector3(0, 0.1, -11), PI)
	_spawn_cat(Vector3(1.5, 0, -6.5))
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
	_message.offset_top = -200
	_message.offset_bottom = -110
	_message.offset_left = 200
	_message.offset_right = -200
	_message.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_hint = _label(hud, 16)
	_hint.position = Vector2(20, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.text = "Click to look around   WASD move   Shift run   E interact   V switch view   Esc free mouse"

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


func _make_grain() -> void:
	grain = NoiseTexture2D.new()
	grain.width = 64
	grain.height = 64
	grain.seamless = true
	var noise := FastNoiseLite.new()
	noise.frequency = 0.2
	noise.fractal_octaves = 3
	grain.noise = noise


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = FOG
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


# --- Building blocks ---------------------------------------------------------

func mat(color: Color, glow := 0.0) -> ShaderMaterial:
	var key := "%s/%s" % [color.to_html(), glow]
	if _materials.has(key):
		return _materials[key]
	var m := ShaderMaterial.new()
	m.shader = PS1
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("fog_color", FOG)
	m.set_shader_parameter("emission", glow)
	_materials[key] = m
	return m


## A coloured block. Solid ones get collision.
func box(parent: Node, size: Vector3, pos: Vector3, color: Color, solid := true, rot_y := 0.0) -> Node3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	# Extra vertices on big surfaces so the per-vertex fog and lighting stay smooth.
	bm.subdivide_width = int(size.x / 2.0)
	bm.subdivide_height = int(size.y / 2.0)
	bm.subdivide_depth = int(size.z / 2.0)
	mesh.mesh = bm
	mesh.material_override = mat(color)
	if not solid:
		mesh.position = pos
		mesh.rotation.y = rot_y
		parent.add_child(mesh)
		return mesh
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	_add_shape(body, size)
	body.add_child(mesh)
	parent.add_child(body)
	return body


func _add_shape(body: Node, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)


## A block you can press E on.
func thing(parent: Node, size: Vector3, pos: Vector3, color: Color, prompt: String, lines: Array, script: Script = Interactable) -> StaticBody3D:
	var body: StaticBody3D = script.new()
	body.position = pos
	body.prompt = prompt
	body.lines = PackedStringArray(lines)
	_add_shape(body, size)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat(color)
	body.add_child(mesh)
	parent.add_child(body)
	return body


## A simple house shell with a door in the front (local +Z) side.
func house(pos: Vector3, facing_road: bool, walls: Color, roof: Color, w := 7.0, d := 6.0, h := 2.8, with_roof := true) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = 0.0 if facing_road == (pos.z < 0) else PI
	world.add_child(root)
	var t := 0.2
	var door := 1.2
	var seg := (w - door) / 2.0
	box(root, Vector3(w, h, t), Vector3(0, h / 2, -d / 2), walls)
	box(root, Vector3(t, h, d), Vector3(-w / 2, h / 2, 0), walls)
	box(root, Vector3(t, h, d), Vector3(w / 2, h / 2, 0), walls)
	box(root, Vector3(seg, h, t), Vector3(-w / 2 + seg / 2, h / 2, d / 2), walls)
	box(root, Vector3(seg, h, t), Vector3(w / 2 - seg / 2, h / 2, d / 2), walls)
	box(root, Vector3(door, h - 2.1, t), Vector3(0, 2.1 + (h - 2.1) / 2, d / 2), walls)
	box(root, Vector3(w, 0.02, d), Vector3(0, 0.01, 0), walls.darkened(0.45), false)
	# Windows (dark glass on the outside).
	for x in [-w / 2 + seg / 2, w / 2 - seg / 2]:
		box(root, Vector3(1.1, 0.8, 0.05), Vector3(x, 1.5, d / 2 + 0.12), Color(0.12, 0.14, 0.16), false)
	if with_roof:
		box(root, Vector3(w, 0.1, d), Vector3(0, h, 0), walls.darkened(0.3), false)
		var rm := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(w + 0.6, 1.5, d + 0.6)
		rm.mesh = prism
		rm.material_override = mat(roof)
		rm.position = Vector3(0, h + 0.75, 0)
		root.add_child(rm)
	return root


# --- Places ------------------------------------------------------------------

func _build_street() -> void:
	box(world, Vector3(140, 0.2, 140), Vector3(0, -0.1, -10), Color(0.4, 0.4, 0.33))  # dead grass
	box(world, Vector3(110, 0.02, 7), Vector3(0, 0.01, 0), Color(0.24, 0.24, 0.25), false)  # road
	for z in [-4.2, 4.2]:
		box(world, Vector3(110, 0.12, 1.4), Vector3(0, 0.06, z), Color(0.5, 0.49, 0.46), false)
	for x in range(-50, 51, 6):
		box(world, Vector3(2, 0.03, 0.15), Vector3(x, 0.02, 0), Color(0.62, 0.58, 0.4), false)

	# Leaning power poles with sagging lines.
	for x in range(-35, 36, 14):
		var pole := box(world, Vector3(0.25, 7, 0.25), Vector3(x, 3.5, -5.4), Color(0.3, 0.25, 0.2))
		pole.rotation.z = deg_to_rad(randf_range(-6, 6))
		box(world, Vector3(1.8, 0.15, 0.15), Vector3(x, 6.6, -5.4), Color(0.3, 0.25, 0.2), false)

	# The packed car that never left.
	var car := Node3D.new()
	car.position = Vector3(6, 0, 1.6)
	car.rotation.y = deg_to_rad(8)
	world.add_child(car)
	thing(car, Vector3(4.2, 0.9, 1.8), Vector3(0, 0.65, 0), Color(0.45, 0.5, 0.55), "Look inside the car", [
		"The car is packed: suitcases, a birdcage, a child's raincoat. The keys are still in the ignition.",
		"The battery is dead. Someone wrote WAIT FOR US in the dust on the back window.",
	])
	box(car, Vector3(2.2, 0.7, 1.6), Vector3(-0.2, 1.4, 0), Color(0.18, 0.2, 0.22), false)
	for cx in [-1.4, 1.4]:
		for cz in [-0.9, 0.9]:
			box(car, Vector3(0.6, 0.6, 0.25), Vector3(cx, 0.3, cz), Color(0.08, 0.08, 0.08), false)

	# Invisible walls at the edge of the test area.
	for wall in [[Vector3(100, 10, 1), Vector3(0, 5, -48)], [Vector3(100, 10, 1), Vector3(0, 5, 28)],
			[Vector3(1, 10, 80), Vector3(-45, 5, -10)], [Vector3(1, 10, 80), Vector3(45, 5, -10)]]:
		var body := StaticBody3D.new()
		body.position = wall[1]
		_add_shape(body, wall[0])
		world.add_child(body)


func _build_your_house(pos: Vector3) -> void:
	var h := house(pos, true, Color(0.72, 0.64, 0.52), Color(0.42, 0.24, 0.2))
	# Warm lamp: the one cozy light on the street.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.7, 0.4)
	lamp.light_energy = 1.6
	lamp.omni_range = 7.0
	lamp.position = Vector3(1.5, 2.2, -1)
	h.add_child(lamp)
	var bulb := MeshInstance3D.new()
	bulb.mesh = SphereMesh.new()
	bulb.scale = Vector3.ONE * 0.3
	bulb.material_override = mat(Color(1, 0.8, 0.5), 2.0)
	bulb.position = Vector3(1.5, 2.55, -1)
	h.add_child(bulb)

	box(h, Vector3(2.6, 0.04, 1.8), Vector3(0, 0.03, 0.5), Color(0.55, 0.22, 0.2), false)  # rug
	thing(h, Vector3(1.4, 0.5, 2.1), Vector3(-2.5, 0.25, -1.6), Color(0.6, 0.62, 0.7), "Lie down", [
		"Not yet. There's still some light out.",
	])
	box(h, Vector3(1.4, 0.75, 0.8), Vector3(2.3, 0.375, -2.4), Color(0.45, 0.32, 0.22))  # table
	thing(h, Vector3(0.6, 0.35, 0.3), Vector3(2.3, 0.93, -2.4), Color(0.25, 0.2, 0.16), "Switch on the radio", [
		"...kssh... this is... broadcasting on... if anyone can hear this...",
		"...the evacuation buses never came to Alder Street. We waited by the overpass until dark...",
		"...ninety-one days. The lights in the woods are still on. Who is keeping them on?...",
		"...follow the tower past the treeline. Someone is still reading the names...",
		"Only static now. The signal felt stronger when the dial pointed north, toward the trees.",
	], Radio)
	thing(h, Vector3(0.7, 0.12, 0.5), Vector3(2.4, 0.06, 1.8), Color(0.4, 0.45, 0.35), "Look at the old blanket", [
		"A folded blanket by the door. Something small has been sleeping on it.",
	])


func _build_neighbour_house(pos: Vector3) -> void:
	var h := house(pos, true, Color(0.55, 0.6, 0.62), Color(0.3, 0.3, 0.33))
	box(h, Vector3(1.6, 0.75, 0.9), Vector3(1.8, 0.375, -1.8), Color(0.5, 0.42, 0.33))
	thing(h, Vector3(0.3, 0.02, 0.22), Vector3(1.8, 0.76, -1.8), Color(0.9, 0.88, 0.8), "Read the note", [
		"\"Gone to my sister's in the city. Back Sunday. Feed Biscuit!\"",
		"The note is from March. The cat bowl by the door is empty.",
	])
	thing(h, Vector3(0.3, 0.1, 0.3), Vector3(-0.3, 0.05, 2.4), Color(0.7, 0.3, 0.3), "Look at the bowl", [
		"A cat bowl with BISCUIT painted on it.",
	])


func _build_burnt_house(pos: Vector3) -> void:
	var h := house(pos, true, Color(0.16, 0.15, 0.14), Color(0.1, 0.1, 0.1), 7.0, 6.0, 2.8, false)
	box(h, Vector3(4, 0.15, 3), Vector3(-1, 2.2, -1), Color(0.12, 0.11, 0.1), false).rotation.z = 0.5
	thing(h, Vector3(0.6, 0.6, 0.6), Vector3(1.2, 0.3, -1.4), Color(0.3, 0.28, 0.25), "Look at the scorched box", [
		"Photographs, curled from the heat. The faces have all burned away except one: a dog, smiling.",
	])


func _build_calendar_house(pos: Vector3) -> void:
	var h := house(pos, true, Color(0.66, 0.6, 0.48), Color(0.25, 0.3, 0.26))
	thing(h, Vector3(0.6, 0.8, 0.05), Vector3(-1.5, 1.6, -2.88), Color(0.9, 0.9, 0.85), "Read the calendar", [
		"The calendar is still on March. Someone circled the 14th and wrote \"drill?\" next to it.",
	])
	thing(h, Vector3(0.5, 0.4, 0.05), Vector3(1.4, 1.4, -2.88), Color(0.85, 0.82, 0.5), "Look at the drawing", [
		"A child's drawing of the street. There are three suns in the sky.",
	])
	box(h, Vector3(1.0, 0.5, 2.0), Vector3(2.6, 0.25, 1.4), Color(0.45, 0.5, 0.6))


func _build_forest_edge() -> void:
	# The treeline to the north. Dead, grey, and a bit wrong.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 140:
		var p := Vector3(rng.randf_range(-60, 60), 0, rng.randf_range(-46, -95))
		var tall := rng.randf_range(6, 12)
		box(world, Vector3(0.35, tall, 0.35), p + Vector3(0, tall / 2, 0), Color(0.22, 0.2, 0.18), false)
		var crown := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = rng.randf_range(1.2, 2.2)
		cone.height = tall * 0.7
		cone.radial_segments = 5
		cone.rings = 1
		crown.mesh = cone
		crown.material_override = mat(Color(0.25, 0.3, 0.24).lerp(Color(0.35, 0.33, 0.3), rng.randf()))
		crown.position = p + Vector3(0, tall * 0.75, 0)
		world.add_child(crown)

	# The radio tower, with a red light that is somehow still blinking.
	var tower := box(world, Vector3(0.5, 30, 0.5), Vector3(22, 15, -92), Color(0.3, 0.3, 0.3), false)
	var beacon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	beacon.mesh = sm
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(1, 0.15, 0.1)
	red.disable_fog = true
	beacon.material_override = red
	beacon.position = Vector3(0, 15.5, 0)
	tower.add_child(beacon)
	var blink := create_tween().set_loops()
	blink.tween_callback(func(): beacon.visible = true)
	blink.tween_interval(0.25)
	blink.tween_callback(func(): beacon.visible = false)
	blink.tween_interval(1.8)


func _build_skyline() -> void:
	# The city you never reach, mostly lost in the haze.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 24:
		var w := rng.randf_range(5, 12)
		var tall := rng.randf_range(10, 40)
		var b: MeshInstance3D = box(world, Vector3(w, tall, w), Vector3(-80 + i * 7 + rng.randf_range(-2, 2), tall / 2, rng.randf_range(80, 100)), Color(0.3, 0.3, 0.32), false)
		# Let the far city show through the haze as faint shapes.
		var far: ShaderMaterial = mat(Color(0.3, 0.3, 0.32)).duplicate()
		far.set_shader_parameter("fog_end", 125.0)
		b.material_override = far
		if rng.randf() < 0.3:
			b.rotation.z = rng.randf_range(-0.25, 0.25)  # some of them are leaning


func _build_ash() -> void:
	var ash := CPUParticles3D.new()
	ash.amount = 400
	ash.lifetime = 18.0
	ash.preprocess = 18.0
	ash.position = Vector3(0, 9, 0)
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(45, 0.5, 4)
	ash.direction = Vector3(1, 0, 0)
	ash.initial_velocity_min = 0.1
	ash.initial_velocity_max = 0.4
	ash.gravity = Vector3(0.1, -0.5, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(0.85, 0.83, 0.8)
	q.material = m
	ash.mesh = q
	world.add_child(ash)


func _spawn_player(pos: Vector3, yaw: float) -> void:
	player = Player.new()
	player.position = pos
	player.rotation.y = yaw
	world.add_child(player)
	# Placeholder body for third person: coat, head, backpack.
	var look := Node3D.new()
	box(look, Vector3(0.5, 0.9, 0.3), Vector3(0, 1.0, 0), Color(0.35, 0.38, 0.3), false)
	box(look, Vector3(0.45, 0.6, 0.25), Vector3(0, 0.3, 0), Color(0.2, 0.2, 0.24), false)
	box(look, Vector3(0.3, 0.3, 0.3), Vector3(0, 1.62, 0), Color(0.8, 0.66, 0.55), false)
	box(look, Vector3(0.4, 0.5, 0.2), Vector3(0, 1.05, 0.25), Color(0.45, 0.3, 0.2), false)
	player.set_body(look)
	player.focus_changed.connect(func(p: String): _prompt.text = ("[E] " + p) if p != "" else "")
	player.message.connect(_show_message)


func _spawn_cat(pos: Vector3) -> void:
	var cat: Node3D = Cat.new()
	cat.position = pos
	cat.home = pos
	cat.player = player
	world.add_child(cat)
	var fur := Color(0.85, 0.55, 0.3)
	var pet := thing(cat, Vector3(0.25, 0.25, 0.55), Vector3(0, 0.25, 0), fur, "Pet the cat", [
		"The cat flinches and backs away. Maybe next time.",
		"The cat sniffs your hand, then lets you touch its ears.",
		"The cat purrs. It seems to have decided you're alright.",
		"The cat headbutts your knee. Its collar tag says BISCUIT.",
		"Biscuit purrs.",
	])
	pet.used.connect(cat.on_petted)
	box(cat, Vector3(0.18, 0.18, 0.18), Vector3(0, 0.42, 0.3), fur, false)
	for x in [-0.06, 0.06]:
		box(cat, Vector3(0.05, 0.07, 0.03), Vector3(x, 0.54, 0.3), fur.darkened(0.2), false)
	var tail := box(cat, Vector3(0.05, 0.05, 0.35), Vector3(0, 0.38, -0.38), fur.darkened(0.2), false)
	tail.rotation.x = 0.7
	for x in [-0.08, 0.08]:
		for z in [-0.18, 0.18]:
			box(cat, Vector3(0.06, 0.14, 0.06), Vector3(x, 0.07, z), fur.darkened(0.1), false)


# --- Per-frame ---------------------------------------------------------------

func _show_message(text: String) -> void:
	_message.text = text
	_message_time = 6.0
	_message.modulate.a = 1.0


func _process(delta: float) -> void:
	if _message_time > 0.0:
		_message_time -= delta
		_message.modulate.a = clampf(_message_time, 0.0, 1.0)
	if _hint.modulate.a > 0.0 and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_hint.modulate.a -= delta * 0.08


func _unhandled_input(event: InputEvent) -> void:
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
	if "--outside" in args:
		player.position = Vector3(-4, 0.1, 3)
		player.rotation.y = deg_to_rad(-150)
	if "--north" in args:
		player.position = Vector3(3, 0.1, 6)
		player.rotation.y = 0.0
	if "--inside" in args:
		player.rotation.y = -0.6
	if "--third" in args:
		player.toggle_view()
	for i in 30:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
