## The Hollow FM tower, at the end of the tower road north of the Ranger
## Station: a fifty-metre lattice mast with a red beacon, a concrete
## transmitter hut where Ines Varga lives and broadcasts, and a ladder up to
## a platform where you can see the whole valley.
##
## Unlike the station it is joined on: the tower road runs north out of
## Wren's clearing (through the gate in the deer fence, station.gd) and
## you walk the last fifty metres.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Houses := preload("res://scripts/houses.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Survivor := preload("res://scripts/survivor.gd")
const Ines := preload("res://scripts/ines.gd")
const Trail := preload("res://scripts/trail.gd")
const Trees := preload("res://scripts/trees.gd")

const ORIGIN := Vector3(0, 0, -490)
## The mast, from ORIGIN.
const MAST := Vector3(7, 0, -8)
## Where the ladder leaves you, up on the platform.
const PLATFORM_Y := 18.0
const PLATFORM := ORIGIN + MAST + Vector3(0, PLATFORM_Y + 0.1, 1.0)
const LADDER_FOOT := ORIGIN + MAST + Vector3(0, 0.1, 3.6)

const STEEL := Color(0.36, 0.36, 0.38)
const RED := Color(0.85, 0.2, 0.15)
const CONC := Color(0.52, 0.52, 0.5)
const PATH := Color(0.4, 0.33, 0.25)
const NIGHT_GLOW := Color(1.0, 0.8, 0.5)

var k: Kit
var world: Node3D
var root: Node3D
var houses: Houses
var f: Furniture
var trees: Trees


func _init(kit: Kit, w: Node3D) -> void:
	k = kit
	world = w
	houses = Houses.new(kit)
	f = Furniture.new(kit)
	trees = Trees.new(kit, 913)


func build() -> void:
	root = k.group(world, ORIGIN, 0)
	_ground()
	_road()
	_mast()
	_platform()
	_hut()
	_yard()
	_trees()


func _area(n: Node) -> Node:
	n.set_meta("area", "tower")
	return n


# --- Ground, walls and the road ------------------------------------------------------

func _ground() -> void:
	# Joins the station's ground at z -445 (local +45).
	k.box(root, Vector3(80, 0.2, 85), Vector3(0, -0.1, 2.5), Color(0.27, 0.29, 0.22), {"solid": true})
	k.box(root, Vector3(26, 0.02, 22), Vector3(0, 0.01, -6), Color(0.38, 0.38, 0.3))  # trampled clearing
	# The clearing is walled by forest; the road comes in from the south.
	k.blocker(root, Vector3(42, 10, 1), Vector3(0, 5, -20))
	k.blocker(root, Vector3(1, 10, 42), Vector3(-20, 5, 0))
	k.blocker(root, Vector3(1, 10, 42), Vector3(20, 5, 0))
	for s in [-1.0, 1.0]:
		k.blocker(root, Vector3(18.4, 10, 1), Vector3(s * 10.8, 5, 20))
		# The road between the station's north edge (local z 63) and here.
		k.blocker(root, Vector3(1, 10, 44), Vector3(s * 2.4, 5, 41.5))
	var tuft := PrismMesh.new()
	tuft.size = Vector3(0.35, 0.45, 0.02)
	var xf: Array = []
	for i in 500:
		var p := Vector3(k.rng.randf_range(-20, 20), 0, k.rng.randf_range(-20, 60))
		if absf(p.x) < 1.4 and p.z > -2:
			continue  # the road
		if p.z > 20 and absf(p.x) > 2.3:
			continue  # outside the road's walls
		if p.x > -9 and p.x < -1 and p.z > -10 and p.z < -3.5:
			continue  # the hut
		var s := k.rng.randf_range(0.6, 1.5)
		xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).scaled(Vector3(s, s, s)), ORIGIN + p + Vector3(0, 0.2 * s, 0)))
	k.scatter(world, tuft, Color(0.36, 0.42, 0.28), xf)


func _road() -> void:
	k.box(root, Vector3(2.2, 0.03, 66), Vector3(0, 0.02, 31), PATH)
	# Old reflector posts, every ten metres, alternating sides.
	for i in 6:
		var p := Vector3(-1.6 if i % 2 else 1.6, 0, 58 - i * 10.0)
		k.box(root, Vector3(0.1, 1.0, 0.1), p + Vector3(0, 0.5, 0), Color(0.85, 0.85, 0.8))
		k.box(root, Vector3(0.11, 0.12, 0.02), p + Vector3(0, 0.85, 0.06), RED, {"glow": 0.8})
	var sign := k.group(root, Vector3(-1.9, 0, 18), 0)
	k.box(sign, Vector3(0.1, 2.0, 0.1), Vector3(0, 1.0, 0), Kit.METAL)
	k.box(sign, Vector3(1.4, 0.7, 0.04), Vector3(0, 1.75, 0.06), Color(0.85, 0.83, 0.76))
	k.words(sign, "HOLLOW FM\n91.3\nNO UNAUTHORISED ACCESS", Vector3(0, 1.75, 0.085), Vector3.ZERO, 0.004, Color(0.6, 0.15, 0.12))
	k.words(sign, "(except Sam)", Vector3(0.2, 1.47, 0.085), Vector3(0, 0, 4), 0.003, Color(0.15, 0.25, 0.5))
	var look := k.thing(root, Vector3(1.4, 0.8, 0.3), Vector3(-1.9, 1.75, 18.1), "Read the sign", [
		"HOLLOW FM 91.3. NO UNAUTHORISED ACCESS. Under it, fresh, in blue biro: (except Sam).",
	])
	look.journal = "The sign on the tower road says NO UNAUTHORISED ACCESS. Someone's added \"(except Sam)\" in biro."
	_area(look)


# --- The mast ------------------------------------------------------------------------

func _mast() -> void:
	var g := k.group(root, MAST, 0)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			k.beam(g, Vector3(s * 2.5, 0, t * 2.5), Vector3(s * 0.3, 48, t * 0.3), 0.25, STEEL, {"fog_end": 160.0})
			k.box(g, Vector3(0.9, 0.5, 0.9), Vector3(s * 2.5, 0.25, t * 2.5), CONC, {"solid": true})  # footings
	for y in range(4, 48, 4):
		var w := 2.5 - y / 48.0 * 2.2
		var c: Color = RED if (y / 4) % 3 == 0 else STEEL  # red and white bands, faded
		for side in [-1.0, 1.0]:
			k.box(g, Vector3(w * 2, 0.15, 0.15), Vector3(0, y, side * w), c, {"fog_end": 160.0})
			k.box(g, Vector3(0.15, 0.15, w * 2), Vector3(side * w, y, 0), c, {"fog_end": 160.0})
		# Cross bracing on the faces, every other bay.
		if (y / 4) % 2 == 0:
			var w2 := 2.5 - (y + 4) / 48.0 * 2.2
			k.beam(g, Vector3(-w, y, w), Vector3(w2, y + 4, w2), 0.07, STEEL, {"fog_end": 160.0})
			k.beam(g, Vector3(w, y, -w), Vector3(-w2, y + 4, -w2), 0.07, STEEL, {"fog_end": 160.0})
	# Dishes and dipoles near the top.
	k.cyl(g, 0.7, 0.15, Vector3(0.9, 38, 0.9), Color(0.8, 0.8, 0.78), {"rot": Vector3(90, 45, 0), "sides": 10, "fog_end": 160.0})
	for y in [42.0, 44.5]:
		k.box(g, Vector3(3.2, 0.08, 0.08), Vector3(0, y, 0), STEEL, {"fog_end": 160.0})
	# The beacon.
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(1, 0.15, 0.1)
	var beacon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.9
	sm.height = 1.8
	beacon.mesh = sm
	beacon.material_override = red
	beacon.position = Vector3(0, 48.8, 0)
	g.add_child(beacon)
	var blink := g.create_tween().set_loops()
	blink.tween_callback(func(): beacon.visible = true)
	blink.tween_interval(0.25)
	blink.tween_callback(func(): beacon.visible = false)
	blink.tween_interval(1.8)
	# The ladder up the south face, as far as the platform.
	var top_z := 2.5 - PLATFORM_Y / 48.0 * 2.2 + 0.15
	for s in [-0.25, 0.25]:
		k.beam(g, Vector3(s, 0, 2.7), Vector3(s, PLATFORM_Y + 1.0, top_z), 0.05, Kit.METAL)
	for i in int(PLATFORM_Y / 0.4):
		var y := i * 0.4 + 0.3
		var z := lerpf(2.7, top_z, y / (PLATFORM_Y + 1.0))
		k.box(g, Vector3(0.5, 0.03, 0.03), Vector3(0, y, z), Kit.METAL)
	# A cage round the bottom of the ladder, padlock long since cut.
	k.box(g, Vector3(0.9, 0.03, 0.03), Vector3(0, 2.2, 3.2), Kit.METAL)
	var climb: StaticBody3D = k.thing(root, Vector3(1.2, 2.0, 0.6), MAST + Vector3(0, 1.0, 3.0), "Climb the ladder", [], Trail)
	climb.destination = PLATFORM
	climb.facing = 0.0
	climb.hours = 0.25
	climb.arrive_line = "Eighteen metres of cold rungs. You don't look down until the platform, and then you can't stop looking."
	_area(climb)


func _platform() -> void:
	var g := k.group(root, MAST + Vector3(0, PLATFORM_Y, 0), 0)
	k.box(g, Vector3(4.6, 0.15, 4.6), Vector3(0, -0.075, 0), Color(0.3, 0.3, 0.32), {"pattern": Kit.Pattern.TILES, "solid": true})
	for side in [-1.0, 1.0]:
		for x in [-2.25, 0.0, 2.25]:
			k.box(g, Vector3(0.06, 1.05, 0.06), Vector3(x, 0.52, side * 2.25), Kit.METAL)
			k.box(g, Vector3(0.06, 1.05, 0.06), Vector3(side * 2.25, 0.52, x), Kit.METAL)
		for y in [0.5, 1.05]:
			k.box(g, Vector3(4.6, 0.05, 0.05), Vector3(0, y, side * 2.25), Kit.METAL)
			k.box(g, Vector3(0.05, 0.05, 4.6), Vector3(side * 2.25, y, 0), Kit.METAL)
		k.blocker(g, Vector3(4.6, 1.2, 0.2), Vector3(0, 0.6, side * 2.3))
		k.blocker(g, Vector3(0.2, 1.2, 4.6), Vector3(side * 2.3, 0.6, 0))
	var down: StaticBody3D = k.thing(g, Vector3(0.8, 0.8, 0.4), Vector3(0, 0.5, 2.0), "Climb down", [], Trail)
	down.destination = LADDER_FOOT
	down.facing = PI
	down.hours = 0.25
	down.arrive_line = "Back on the ground. Your hands smell of rust and your knees have opinions."
	_area(down)
	var view := k.thing(g, Vector3(4.0, 1.0, 0.3), Vector3(0, 1.0, -2.1), "Look out over the valley", [
		"North: forest, forever. Somewhere past it, the junction camp, where Wren's blue pins are. A thread of smoke. More than one.",
		"South, the lanterns at the station, and past them the dark where Alder Street is. You think you can see Wren's lanterns behind your house. You probably can't. You look anyway.",
		"Further south, the city. Grey on grey. Nothing moves. You look north again.",
	])
	view.journal = "Climbed the tower. North of the forest there's smoke from the junction camp. More than one fire. People."
	_area(view)
	# Smoke from the junction camp, far to the north.
	for i in 3:
		var smoke := CPUParticles3D.new()
		smoke.amount = 24
		smoke.lifetime = 14.0
		smoke.preprocess = 14.0
		smoke.position = Vector3(-30 + i * 22, 2, -150 - i * 12)
		smoke.direction = Vector3(0.2, 1, 0)
		smoke.spread = 8.0
		smoke.initial_velocity_min = 1.0
		smoke.initial_velocity_max = 1.6
		smoke.gravity = Vector3(0.15, 0, 0)
		smoke.scale_amount_min = 2.0
		smoke.scale_amount_max = 4.0
		var q := QuadMesh.new()
		q.size = Vector2(1.0, 1.0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.7, 0.7, 0.72, 0.25)
		q.material = m
		smoke.mesh = q
		g.add_child(smoke)


# --- The transmitter hut, where Ines lives ---------------------------------------------

func _hut() -> void:
	var h := houses.shell(root, Vector3(-5, 0, -7), {
		"w": 6.0, "d": 4.5, "h": 2.6, "walls": CONC, "pattern": Kit.Pattern.CONCRETE,
		"inside": Color(0.66, 0.68, 0.62), "floor": Color(0.42, 0.4, 0.36), "roof": Color(0.3, 0.3, 0.3),
		"door_x": 1.6, "door": "open", "door_color": Color(0.35, 0.42, 0.45), "number": "",
		"windows": [["front", -1.2, "ok", Kit.FABRIC_RED], ["right", 0.6, "ok", null]],
	})
	# ON AIR over the door, lit when she's broadcasting (after dark).
	k.box(h, Vector3(0.8, 0.28, 0.08), Vector3(1.6, 2.45, 2.32), Color(0.15, 0.1, 0.1))
	var on_air := k.box(h, Vector3(0.7, 0.2, 0.02), Vector3(1.6, 2.45, 2.37), Color(1.0, 0.25, 0.2), {"glow": 2.5})
	on_air.add_to_group("night_only")
	k.words(h, "ON AIR", Vector3(1.6, 2.45, 2.39), Vector3.ZERO, 0.005, Color(1.0, 0.95, 0.9))
	k.words(h, "HOLLOW FM - TRANSMITTER 2", Vector3(-0.8, 2.3, 2.33), Vector3.ZERO, 0.004, Color(0.2, 0.2, 0.2))

	# The broadcast desk along the back wall.
	f.table(h, Vector3(0.9, 0, -1.65), 0, Vector2(2.4, 0.8), Color(0.35, 0.33, 0.32))
	f.chair(h, Vector3(0.9, 0, -0.9), 180, Color(0.25, 0.25, 0.28))
	k.box(h, Vector3(1.2, 0.12, 0.45), Vector3(0.6, 0.83, -1.7), Color(0.2, 0.2, 0.22))  # mixing desk
	for i in 8:
		k.box(h, Vector3(0.03, 0.03, 0.12), Vector3(0.1 + i * 0.14, 0.9, -1.65 + (i % 3) * 0.03), Color(0.9, 0.9, 0.85))
	k.box(h, Vector3(0.5, 0.05, 0.02), Vector3(0.6, 0.9, -1.48), Color(0.4, 1.0, 0.4), {"glow": 1.5})  # level meter
	k.cyl(h, 0.02, 0.35, Vector3(1.45, 0.95, -1.6), Kit.METAL, {"rot": Vector3(-20, 0, 0), "sides": 5})  # mic arm
	k.cyl(h, 0.06, 0.18, Vector3(1.45, 1.15, -1.5), Color(0.15, 0.15, 0.17), {"rot": Vector3(70, 0, 0), "sides": 8})  # microphone
	k.ring(h, 0.08, 0.1, Vector3(1.45, 1.15, -1.36), Color(0.15, 0.15, 0.15), Vector3(90, 0, 0))  # pop filter
	# Stacks of Wren's lists, a mug, a lamp.
	for i in 4:
		k.box(h, Vector3(0.21, 0.02 + i * 0.01, 0.3), Vector3(1.85, 0.79 + i * 0.012, -1.75), Kit.PAPER.darkened(i * 0.05), {"rot": Vector3(0, i * 7, 0)})
	k.cyl(h, 0.045, 0.1, Vector3(0.05, 0.83, -1.4), Color(0.75, 0.3, 0.25), {"sides": 7})
	f.lamp(h, Vector3(-0.2, 0.78, -1.85), true)
	var desk := k.thing(h, Vector3(2.4, 0.6, 0.8), Vector3(0.9, 0.95, -1.65), "Look at the broadcast desk", [
		"The microphone has a sock over it, knitted, red. A list in Wren's handwriting is clipped to the stand: tonight's names, two hundred and fourteen.",
		"Taped to the desk, a note to herself in capitals: SLOWLY. EVERY ONE. THEY'RE LISTENING FOR ONE.",
	])
	_area(desk)
	# The transmitter racks.
	for i in 2:
		var rx := 2.55
		var rz := -1.65 + i * 0.7
		k.box(h, Vector3(0.65, 1.9, 0.6), Vector3(rx, 0.95, rz), Color(0.3, 0.32, 0.34))
		for j in 5:
			k.box(h, Vector3(0.02, 0.12, 0.45), Vector3(rx - 0.33, 0.5 + j * 0.28, rz), Color(0.2, 0.22, 0.24))
			k.box(h, Vector3(0.02, 0.03, 0.05), Vector3(rx - 0.34, 0.5 + j * 0.28, rz - 0.15 + (j % 2) * 0.2), [Color(1.0, 0.6, 0.2), Color(0.4, 1.0, 0.4), Color(1.0, 0.3, 0.2)][j % 3], {"glow": 1.8})
	k.blocker(h, Vector3(0.7, 1.9, 1.4), Vector3(2.55, 0.95, -1.3))

	# The wall of names: the left half of the back wall, and round the corner.
	var wall := k.thing(h, Vector3(2.6, 1.6, 0.2), Vector3(-1.6, 1.4, -2.1), "Read the wall of names", [
		"Hundreds of slips of paper, pinned edge to edge, each one a name and a place. ALIVE on every one. Coloured pins where people have found each other.",
		"You find Grace Okafor, with a pin. The Patels. The Bells. And near the bottom, on its own: HALE, SAM - 4 ALDER ST. Two empty pins beside it.",
	])
	wall.journal = "Ines's wall of names: everyone who's checked in alive, with a pin when somebody finds somebody. My slip has two empty pins beside it."
	_area(wall)
	var rng := RandomNumberGenerator.new()
	rng.seed = 214
	for i in 96:
		var x := -2.75 + (i % 16) * 0.16 + rng.randf_range(-0.02, 0.02)
		var y := 0.75 + (i / 16) * 0.22 + rng.randf_range(-0.03, 0.03)
		k.box(h, Vector3(0.13, 0.08, 0.005), Vector3(x, y, -2.1), Kit.PAPER.darkened(rng.randf() * 0.25), {"rot": Vector3(0, 0, rng.randf_range(-6, 6))})
		if rng.randf() < 0.25:
			k.ball(h, Vector3(0.02, 0.02, 0.02), Vector3(x + 0.05, y + 0.03, -2.09), [RED, Color(0.3, 0.5, 0.85), Color(0.95, 0.8, 0.2)][i % 3], {"sides": 4})
	k.box(h, Vector3(0.2, 0.1, 0.005), Vector3(-1.6, 0.62, -2.095), Color(0.98, 0.95, 0.85))  # Sam's slip
	for s in [-1.0, 1.0]:
		k.ball(h, Vector3(0.025, 0.025, 0.025), Vector3(-1.6 + s * 0.15, 0.62, -2.085), Color(0.95, 0.8, 0.2), {"sides": 4})

	# Where she sleeps: a camp bed, a record player, a crate of records.
	f.bed(h, Vector3(-2.35, 0, 0.6), 90, 0.75, Color(0.45, 0.25, 0.3))
	f.crate(h, Vector3(-0.9, 0, 1.5), 15, 0.45)
	k.box(h, Vector3(0.4, 0.12, 0.35), Vector3(-0.9, 0.51, 1.5), Color(0.55, 0.38, 0.25))  # record player
	k.cyl(h, 0.14, 0.01, Vector3(-0.92, 0.58, 1.5), Color(0.08, 0.08, 0.08), {"sides": 10})
	var records := _search(h, Vector3(0.5, 0.5, 0.5), Vector3(-0.3, 0.25, 1.55), "Look through the records",
		"Jazz, mostly, and a lot of Kate Bush. One sleeve has a note in it: \"For Ines, who plays the good stuff at 3am. From the night bus drivers.\" Under the crate, a box of batteries she's labelled SPARES - TAKE.", ["batteries", "batteries"])
	f.crate(h, Vector3(-0.3, 0, 1.55), -10, 0.45)
	for i in 6:
		k.box(h, Vector3(0.02, 0.3, 0.3), Vector3(-0.45 + i * 0.05, 0.6, 1.55), [Color(0.7, 0.3, 0.3), Color(0.25, 0.3, 0.5), Color(0.85, 0.75, 0.4)][i % 3], {"rot": Vector3(0, 0, -6)})
	records.set_meta("area", "tower")
	# A camping stove, a kettle, tins.
	k.box(h, Vector3(0.5, 0.7, 0.4), Vector3(-2.65, 0.35, -1.6), Color(0.45, 0.42, 0.38))
	f.kettle(h, Vector3(-2.65, 0.72, -1.6))
	var tins := _search(h, Vector3(0.5, 0.5, 0.5), Vector3(-2.65, 0.95, -1.0), "Look at her shelf",
		"Tins, all the same: soup. Ninety days of soup. A postcard of the sea propped against them. On the back: \"One day. - I.\"", ["soup"])
	k.box(h, Vector3(0.3, 0.03, 0.9), Vector3(-2.8, 1.3, -1.0), Kit.WOOD)
	for i in 5:
		k.cyl(h, 0.06, 0.12, Vector3(-2.8, 1.38, -1.35 + i * 0.17), Color(0.75, 0.3, 0.2), {"sides": 6})
	tins.set_meta("area", "tower")
	# Lights: a warm lamp and the transmitter glow.
	var light := OmniLight3D.new()
	light.light_color = Kit.WARM_LIGHT
	light.light_energy = 1.2
	light.omni_range = 5.5
	light.position = Vector3(0, 2.1, -0.3)
	h.add_child(light)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.45, 0.35)
	glow.light_energy = 0.6
	glow.omni_range = 3.0
	glow.position = Vector3(2.0, 1.3, -1.0)
	h.add_child(glow)

	# Ines herself, at the desk, turned towards the door.
	var ines: StaticBody3D = Ines.new()
	ines.position = Vector3(0.4, 0.85, -0.7)
	ines.rotation_degrees.y = 200
	k.add_shape(ines, Vector3(0.6, 1.7, 0.6))
	h.add_child(ines)
	var body: Node3D = Survivor.new()
	body.position = Vector3(0, -0.85, 0)
	body.scale = Vector3.ONE * 1.1
	ines.add_child(body)
	body.build(k, {
		"coat": Color(0.48, 0.18, 0.22), "tights": Color(0.18, 0.18, 0.2), "boots": Color(0.18, 0.15, 0.13),
		"skin": Color(0.88, 0.72, 0.6), "hair": Color(0.1, 0.09, 0.1), "scarf": Color(0.85, 0.8, 0.7),
		"mitten": Color(0.88, 0.72, 0.6), "iris": Color(0.25, 0.18, 0.12), "iris_low": Color(0.55, 0.4, 0.28),
		"hat_style": "none", "braids": false, "backpack": false, "headphones": true, "glasses": true,
	})
	ines.body = body


func _search(parent: Node, size: Vector3, pos: Vector3, prompt: String, found: String, loot: Array) -> StaticBody3D:
	var t := k.search(parent, size, pos, prompt, found, loot)
	_area(t)
	return t


# --- Outside ----------------------------------------------------------------------------

func _yard() -> void:
	# The generator and its fuel, with a cable to the mast.
	var gen := k.group(root, Vector3(-0.8, 0, -4.2), 10)
	k.box(gen, Vector3(1.1, 0.7, 0.7), Vector3(0, 0.35, 0), Color(0.75, 0.6, 0.15), {"solid": true})
	k.box(gen, Vector3(1.15, 0.08, 0.75), Vector3(0, 0.74, 0), Color(0.2, 0.2, 0.2))
	k.cyl(gen, 0.05, 0.3, Vector3(0.4, 0.9, 0.2), Color(0.2, 0.2, 0.2), {"sides": 6})
	for i in 3:
		k.box(root, Vector3(0.35, 0.45, 0.2), Vector3(0.6 + i * 0.4, 0.22, -3.6), Color(0.65, 0.15, 0.12), {"rot": Vector3(0, i * 12, 0)})
	k.beam(root, Vector3(-0.3, 0.05, -4.2), MAST + Vector3(-2.3, 0.1, 1.5), 0.03, Color(0.1, 0.1, 0.1))
	var gen_look := k.thing(root, Vector3(1.2, 0.8, 0.8), Vector3(-0.8, 0.4, -4.2), "Look at the generator", [
		"An old yellow generator, chugging away. A rota taped to it: DIESEL - WREN BRINGS TUESDAYS. Today's not a Tuesday. It's never been clearer what day it isn't.",
	])
	_area(gen_look)
	# A bench by the door, two mugs, tomato plants in paint tins.
	var bench := k.group(root, Vector3(-2.2, 0, -3.6), 0)
	k.box(bench, Vector3(1.4, 0.06, 0.4), Vector3(0, 0.45, 0), Kit.WOOD)
	for x in [-0.6, 0.6]:
		k.box(bench, Vector3(0.08, 0.45, 0.35), Vector3(x, 0.22, 0), Kit.WOOD_DARK)
	for i in 4:
		k.cyl(root, 0.15, 0.25, Vector3(-8.6, 0.12, -4.0 + i * 0.4), [Color(0.3, 0.45, 0.6), Color(0.85, 0.85, 0.8)][i % 2], {"sides": 7})
		k.ball(root, Vector3(0.3, 0.4, 0.3), Vector3(-8.6, 0.45, -4.0 + i * 0.4), Kit.PLANT, {"sides": 5})
	var bench_sit := k.thing(root, Vector3(1.4, 0.5, 0.5), Vector3(-2.2, 0.4, -3.6), "Sit on the bench", [
		"You sit. The generator chugs. The beacon blinks red on the pines, over and over, the way it has every night for ninety-one days.",
	])
	_area(bench_sit)
	# A satellite dish on the roof, and the hut's own little aerial.
	k.cyl(root, 0.5, 0.08, Vector3(-6.5, 3.0, -8.0), Color(0.8, 0.8, 0.78), {"rot": Vector3(60, 0, 0), "sides": 10})
	k.box(root, Vector3(0.05, 1.6, 0.05), Vector3(-3.0, 3.4, -8.2), Kit.METAL)
	# Night: the hut's window spills light on the grass.
	var spill := OmniLight3D.new()
	spill.light_color = NIGHT_GLOW
	spill.light_energy = 0.8
	spill.omni_range = 6.0
	spill.position = Vector3(-5.5, 1.6, -3.6)
	spill.add_to_group("night_only")
	root.add_child(spill)


func _trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var placed := 0
	while placed < 110:
		var p := Vector3(rng.randf_range(-38, 38), 0, rng.randf_range(-38, 44))
		var r := Vector2(p.x, p.z + 4).length()
		if r < 17.0 or absf(p.x) < 4.0:
			continue
		placed += 1
		trees.pine(root, p, rng.randf_range(9, 18), {"solid": false})
	# A few dead ones nearest the mast, and a birch by the hut.
	trees.pine(root, Vector3(15, 0, -15), 12.0, {"style": "snag"})
	trees.pine(root, Vector3(-16, 0, 8), 10.0, {"style": "snag"})
	trees.birch(root, Vector3(-11, 0, -2), 6.5)
