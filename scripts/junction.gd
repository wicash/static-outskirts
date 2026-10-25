## The Hollow Junction camp, where the canal path ends: a hundred and sixty
## people living around an old railway junction, in tents and in carriages
## shunted off the line. Sam's mum is the camp nurse; Grace keeps the soup
## going; Dee Ames keeps the lights on.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Survivor := preload("res://scripts/survivor.gd")
const Trail := preload("res://scripts/trail.gd")
const Trees := preload("res://scripts/trees.gd")
const Grace := preload("res://scripts/people/grace.gd")
const Mum := preload("res://scripts/people/mum.gd")
const Dee := preload("res://scripts/people/dee.gd")

const ORIGIN := Vector3(-400, 0, -700)
const ARRIVE := ORIGIN + Vector3(0, 0.1, 19.0)
const CANAL_END := Vector3(-345, 0.1, -398.0)   # the far end of the towpath (canal.gd)

const GROUND := Color(0.33, 0.32, 0.25)
const MUD := Color(0.3, 0.26, 0.2)
const RAIL := Color(0.45, 0.4, 0.36)
const LIGHT := Color(1.0, 0.8, 0.5)

var k: Kit
var world: Node3D
var root: Node3D
var f: Furniture
var trees: Trees


func _init(kit: Kit, w: Node3D) -> void:
	k = kit
	world = w
	f = Furniture.new(kit)
	trees = Trees.new(kit, 1600)


func build() -> void:
	root = k.group(world, ORIGIN, 0)
	_ground()
	_rails()
	_carriages()
	_tents()
	_fire_and_people()
	_medical_tent()
	_power()
	_board()
	_way_back()
	_trees()


func _area(n: Node) -> Node:
	n.set_meta("area", "junction")
	return n


func _ground() -> void:
	k.box(root, Vector3(80, 0.2, 70), Vector3(0, -0.1, 0), GROUND, {"solid": true})
	k.box(root, Vector3(30, 0.02, 22), Vector3(0, 0.01, 4), MUD)  # trodden to mud round the fire
	for wall in [[Vector3(52, 10, 1), Vector3(0, 5, -22)], [Vector3(52, 10, 1), Vector3(0, 5, 24)],
			[Vector3(1, 10, 48), Vector3(-25, 5, 1)], [Vector3(1, 10, 48), Vector3(25, 5, 1)]]:
		k.blocker(root, wall[0], wall[1])
	var tuft := PrismMesh.new()
	tuft.size = Vector3(0.35, 0.45, 0.02)
	var xf: Array = []
	for i in 500:
		var p := Vector3(k.rng.randf_range(-24, 24), 0, k.rng.randf_range(-21, 23))
		if absf(p.x) < 15 and p.z > -7 and p.z < 15:
			continue
		var s := k.rng.randf_range(0.6, 1.4)
		xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).scaled(Vector3(s, s, s)), ORIGIN + p + Vector3(0, 0.2 * s, 0)))
	k.scatter(world, tuft, Color(0.38, 0.42, 0.28), xf)


func _track(a: Vector3, b: Vector3) -> void:
	var d := b - a
	var n := int(d.length() / 0.7)
	var side := d.normalized().cross(Vector3.UP)
	for i in n:
		var p := a + d * (float(i) / n)
		var sleeper := k.box(root, Vector3(2.4, 0.1, 0.25), p + Vector3(0, 0.05, 0), Kit.WOOD_DARK.darkened(0.2))
		sleeper.look_at(root.to_global(p + d + Vector3(0, 0.05, 0)), Vector3.UP)
	for s in [-0.72, 0.72]:
		k.beam(root, a + side * s + Vector3(0, 0.14, 0), b + side * s + Vector3(0, 0.14, 0), 0.08, RAIL)


func _rails() -> void:
	_track(Vector3(-24, 0, -10), Vector3(24, 0, -10))
	_track(Vector3(-20, 0, -21), Vector3(6, 0, -10.5))  # the branch line joining from the north-west
	# The signal gantry, every light dark but one, painted green by somebody.
	var g := k.group(root, Vector3(8, 0, -10), 0)
	for z in [-2.6, 2.6]:
		k.box(g, Vector3(0.3, 6.0, 0.3), Vector3(0, 3.0, z), Kit.METAL.darkened(0.2))
	k.box(g, Vector3(0.4, 0.4, 5.6), Vector3(0, 6.0, 0), Kit.METAL.darkened(0.2))
	for i in 3:
		k.box(g, Vector3(0.3, 0.9, 0.5), Vector3(0.2, 5.3, -1.6 + i * 1.6), Color(0.1, 0.1, 0.1))
		k.ball(g, Vector3(0.18, 0.18, 0.1), Vector3(0.36, 5.5, -1.6 + i * 1.6), Color(0.3, 1.0, 0.4) if i == 1 else Color(0.2, 0.2, 0.2), {"glow": 2.5 if i == 1 else 0.0})
	k.words(g, "HOLLOW JN", Vector3(0.22, 6.0, 0), Vector3(0, 90, 0), 0.008, Color(0.95, 0.95, 0.9))


func _carriages() -> void:
	# Three old carriages on the main line, homes now.
	var colours := [Color(0.55, 0.2, 0.18), Color(0.2, 0.35, 0.5), Color(0.55, 0.2, 0.18)]
	for i in 3:
		var c := k.group(root, Vector3(-17 + i * 13.0, 0, -10), 0)
		var col: Color = colours[i]
		k.box(c, Vector3(11.5, 2.4, 2.7), Vector3(0, 1.75, 0), col, {"solid": true})
		k.box(c, Vector3(11.6, 0.25, 2.8), Vector3(0, 3.05, 0), Color(0.35, 0.35, 0.35))
		k.box(c, Vector3(11.0, 0.5, 2.2), Vector3(0, 0.35, 0), Color(0.12, 0.12, 0.12))
		for j in 7:
			k.box(c, Vector3(0.9, 0.7, 0.02), Vector3(-4.5 + j * 1.5, 2.1, 1.36), Color(1.0, 0.82, 0.5) if (i + j) % 3 == 0 else Color(0.2, 0.24, 0.27), {"glow": 0.8 if (i + j) % 3 == 0 else 0.0})
		# Steps up to a door, a pot plant, someone's boots.
		k.box(c, Vector3(0.9, 0.35, 0.6), Vector3(-2.0, 0.17, 1.65), Kit.WOOD)
		k.box(c, Vector3(0.9, 0.35, 0.4), Vector3(-2.0, 0.52, 1.5), Kit.WOOD)
		k.box(c, Vector3(0.85, 1.9, 0.03), Vector3(-2.0, 1.6, 1.37), col.darkened(0.3))
		f.boots(c, Vector3(-1.2, 0, 1.7), 10, Color(0.2, 0.18, 0.15))
		f.plant(c, Vector3(-3.0, 0, 1.75), true, 0.8)
		k.words(c, ["THE PATELS' (NOT REALLY)", "DEE & CO", "SCHOOL - MON TO FRI"][i], Vector3(1.5, 2.85, 1.37), Vector3.ZERO, 0.006, Color(0.95, 0.92, 0.85))
	var school := k.thing(root, Vector3(1.0, 2.0, 0.3), Vector3(11.0, 1.6, -8.5), "Look in at the school", [
		"A carriage full of children at mismatched desks, drawing. Someone has written the date on a board, and under it: DAYS SINCE: 93. DAYS UNTIL SPRING: 51.",
		"One of the drawings on the window is the tower, with a red light and a lady inside it, and lots of little names coming out like birds.",
	])
	_area(school)


func _tents() -> void:
	var spots := [Vector3(-18, 0, 4), Vector3(-19, 0, 12), Vector3(-12, 0, 16), Vector3(16, 0, 14), Vector3(19, 0, 6),
		Vector3(19, 0, -2), Vector3(-20, 0, -3), Vector3(7, 0, 18), Vector3(-6, 0, 19)]
	var cols := [Color(0.3, 0.45, 0.3), Color(0.65, 0.35, 0.2), Color(0.3, 0.38, 0.55), Color(0.75, 0.65, 0.35), Color(0.45, 0.3, 0.4)]
	for i in spots.size():
		var p: Vector3 = spots[i]
		var turn := k.rng.randf_range(-30, 30) + (90 if absf(p.x) > 17 else 0)
		var g := k.group(root, p, turn)
		var c: Color = cols[i % cols.size()]
		k.prism(g, Vector3(2.6, 1.6, 3.2), Vector3(0, 0.8, 0), c, {"rot": Vector3(0, 0, 0)})
		k.box(g, Vector3(0.9, 1.0, 0.02), Vector3(0, 0.5, 1.61), c.darkened(0.4))  # the open flap
		k.blocker(g, Vector3(2.6, 1.6, 3.2), Vector3(0, 0.8, 0))
	# String lights from tent to tent, round the fire.
	for i in 6:
		var a := Vector3(-14 + i * 5.0, 3.0, -4.5 + (i % 2) * 1.0)
		var b := Vector3(-11 + i * 5.0, 2.6, 14.0 - (i % 2) * 1.5)
		k.beam(root, a, b, 0.01, Color(0.1, 0.1, 0.1))
		for j in 7:
			var p := a.lerp(b, (j + 0.5) / 7.0) - Vector3(0, sin((j + 0.5) / 7.0 * PI) * 0.6, 0)
			k.ball(root, Vector3(0.08, 0.1, 0.08), p, [LIGHT, Color(0.9, 0.5, 0.4), Color(0.6, 0.85, 0.6)][j % 3], {"sides": 5, "glow": 2.0})
	for x in [-14.0, -4.0, 6.0, 16.0]:
		k.box(root, Vector3(0.14, 3.1, 0.14), Vector3(x, 1.55, -4.4), Kit.WOOD_DARK)
	var lamp := OmniLight3D.new()
	lamp.light_color = LIGHT
	lamp.light_energy = 1.0
	lamp.omni_range = 16.0
	lamp.position = Vector3(0, 3.5, 5)
	lamp.add_to_group("night_only")
	root.add_child(lamp)


func _fire_and_people() -> void:
	var c := Vector3(0, 0, 5)
	for i in 11:
		var a := i * TAU / 11.0
		k.ball(root, Vector3(0.4, 0.25, 0.35), c + Vector3(cos(a) * 1.0, 0.1, sin(a) * 1.0), Color(0.45, 0.43, 0.4), {"sides": 5})
	k.prism(root, Vector3(0.7, 1.0, 0.7), c + Vector3(0, 0.5, 0), Color(1.0, 0.55, 0.15), {"glow": 2.5})
	k.prism(root, Vector3(0.45, 0.7, 0.45), c + Vector3(0.15, 0.4, 0.1), Color(1.0, 0.82, 0.3), {"glow": 3.0, "rot": Vector3(0, 45, 0)})
	k.blocker(root, Vector3(2.0, 1, 2.0), c + Vector3(0, 0.5, 0))
	# The soup pot on a tripod.
	for i in 3:
		var a := i * TAU / 3.0
		k.beam(root, c + Vector3(cos(a) * 1.2, 0, sin(a) * 1.2), c + Vector3(0, 1.8, 0), 0.05, Kit.WOOD_DARK)
	k.cyl(root, 0.35, 0.4, c + Vector3(0, 1.1, 0), Color(0.18, 0.18, 0.2), {"sides": 9})
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.6, 0.3)
	fire.light_energy = 2.4
	fire.omni_range = 11.0
	fire.position = c + Vector3(0, 1.2, 0)
	root.add_child(fire)
	var t := fire.create_tween().set_loops()
	t.tween_property(fire, "light_energy", 2.8, 0.23)
	t.tween_property(fire, "light_energy", 2.0, 0.31)
	# Log benches in a ring.
	for i in 5:
		var a := i * TAU / 5.0 + 0.3
		var p := c + Vector3(cos(a) * 3.2, 0, sin(a) * 3.2)
		var g := k.group(root, p, -rad_to_deg(a) + 90)
		k.cyl(g, 0.22, 2.0, Vector3(0, 0.22, 0), Color(0.35, 0.26, 0.18), {"rot": Vector3(0, 0, 90), "sides": 7, "solid": true})
	# Grace, with the ladle.
	var grace: StaticBody3D = Grace.new()
	grace.place = "junction"
	_person(grace, c + Vector3(1.6, 0, -1.2), 230, {
		"coat": Color(0.3, 0.38, 0.28), "tights": Color(0.25, 0.22, 0.2), "boots": Color(0.25, 0.18, 0.12),
		"skin": Color(0.45, 0.3, 0.22), "hair": Color(0.12, 0.1, 0.1), "hat": Color(0.85, 0.55, 0.2),
		"scarf": Color(0.8, 0.5, 0.2), "mitten": Color(0.85, 0.55, 0.2), "iris": Color(0.2, 0.12, 0.08),
		"iris_low": Color(0.45, 0.3, 0.2), "hat_style": "beanie", "braids": false, "backpack": false,
	})
	# Campers round the fire: just a word each.
	var campers := [
		[c + Vector3(-3.0, 0, 1.0), 120, "Say hello to the old man", ["\"Evening.\" He's whittling a spoon. There's a basket of spoons by his feet. \"Everybody needs a spoon.\""], Color(0.45, 0.4, 0.35), Color(0.75, 0.75, 0.75)],
		[c + Vector3(2.6, 0, 2.4), 210, "Say hello to the girl with the dog", ["\"This is Pickle. He's a good boy. He found us in the woods.\" Pickle is asleep and agrees."], Color(0.7, 0.25, 0.3), Color(0.3, 0.2, 0.12)],
		[c + Vector3(-1.2, 0, 3.4), 170, "Say hello to the man with the guitar", ["He's tuning a guitar with four strings. \"Requests?\" He plays something you half remember from the radio, before."], Color(0.25, 0.3, 0.4), Color(0.2, 0.15, 0.1)],
		[c + Vector3(3.4, 0, -1.4), 260, "Say hello to the woman knitting", ["Grace's sister, it has to be: same laugh. \"You're Sam! Hold your foot out.\" She measures it against a sock. \"Thursday.\""], Color(0.55, 0.45, 0.2), Color(0.12, 0.1, 0.1)],
	]
	for cm in campers:
		var t2 := k.thing(root, Vector3(0.6, 1.7, 0.6), cm[0] + Vector3(0, 0.85, 0), cm[2], cm[3])
		_area(t2)
		var body: Node3D = Survivor.new()
		body.position = Vector3(0, -0.85, 0)
		body.rotation_degrees.y = cm[1]
		t2.add_child(body)
		body.build(k, {"coat": cm[4], "hair": cm[5], "hat_style": "none", "braids": false, "backpack": false,
			"skin": [Color(0.9, 0.75, 0.62), Color(0.55, 0.38, 0.28), Color(0.8, 0.62, 0.5)][k.rng.randi() % 3],
			"scarf": cm[4].lightened(0.3), "mitten": cm[4].darkened(0.2), "tights": Color(0.2, 0.2, 0.25)})
	# Pickle the dog.
	var dog := k.group(root, c + Vector3(3.2, 0, 3.0), 60)
	k.ball(dog, Vector3(0.45, 0.25, 0.3), Vector3(0, 0.12, 0), Color(0.75, 0.6, 0.4), {"sides": 6})
	k.ball(dog, Vector3(0.2, 0.18, 0.2), Vector3(0.28, 0.12, 0.08), Color(0.75, 0.6, 0.4), {"sides": 6})


func _person(npc: StaticBody3D, pos: Vector3, turn: float, look: Dictionary) -> void:
	npc.position = pos + Vector3(0, 0.85, 0)
	npc.rotation_degrees.y = turn
	k.add_shape(npc, Vector3(0.6, 1.7, 0.6))
	root.add_child(npc)
	_area(npc)
	var body: Node3D = Survivor.new()
	body.position = Vector3(0, -0.85, 0)
	body.scale = Vector3.ONE * 1.1
	npc.add_child(body)
	body.build(k, look)
	npc.body = body


func _medical_tent() -> void:
	var g := k.group(root, Vector3(-12, 0, -1), 0)
	k.box(g, Vector3(5.0, 2.2, 4.0), Vector3(0, 1.1, 0), Color(0.88, 0.88, 0.85), {"solid": true})
	k.prism(g, Vector3(5.2, 1.0, 4.2), Vector3(0, 2.7, 0), Color(0.85, 0.85, 0.82), {"rot": Vector3(0, 90, 0)})
	for r in [Vector3(1.0, 0.25, 0.02), Vector3(0.25, 1.0, 0.02)]:
		k.box(g, r, Vector3(0, 1.4, 2.01), Color(0.8, 0.15, 0.15))
	k.box(g, Vector3(1.2, 1.9, 0.02), Vector3(1.4, 0.95, 2.01), Color(0.6, 0.6, 0.58))  # the door flap
	# Outside: a basin on a crate, a bench where people wait.
	f.crate(g, Vector3(-1.6, 0, 2.6), 0, 0.5)
	k.cyl(g, 0.25, 0.1, Vector3(-1.6, 0.55, 2.6), Color(0.85, 0.85, 0.88), {"sides": 9})
	k.box(g, Vector3(2.0, 0.08, 0.4), Vector3(3.6, 0.45, 2.9), Kit.WOOD)
	k.words(g, "CLINIC - WAIT HERE - H.", Vector3(0, 2.0, 2.02), Vector3.ZERO, 0.005, Color(0.25, 0.25, 0.3))
	var mum: StaticBody3D = Mum.new()
	_person(mum, Vector3(-11.0, 0, 2.3), 170, {
		"coat": Color(0.82, 0.84, 0.88), "tights": Color(0.22, 0.24, 0.32), "boots": Color(0.2, 0.2, 0.22),
		"skin": Color(0.95, 0.8, 0.68), "hair": Color(0.42, 0.3, 0.22), "scarf": Color(0.93, 0.72, 0.2),
		"mitten": Color(0.95, 0.8, 0.68), "iris": Color(0.25, 0.3, 0.2), "iris_low": Color(0.5, 0.6, 0.4),
		"hat_style": "none", "braids": false, "backpack": false,
	})
	# A grey streak in her hair that wasn't there in March.
	k.box(mum.body, Vector3(0.05, 0.03, 0.2), Vector3(0.06, 1.66, 0.0), Color(0.75, 0.75, 0.75))


func _power() -> void:
	# Dee's wind turbine, off a farm, and a bank of car batteries.
	var g := k.group(root, Vector3(15, 0, 6), 0)
	k.cyl(g, 0.12, 8.0, Vector3(0, 4.0, 0), Color(0.85, 0.85, 0.85), {"sides": 7})
	k.box(g, Vector3(0.4, 0.4, 0.9), Vector3(0, 8.1, 0), Color(0.85, 0.85, 0.85))
	var hub := k.group(g, Vector3(0, 8.1, -0.5), 0)
	for i in 3:
		var blade := k.group(hub, Vector3.ZERO, 0)
		blade.rotation.z = i * TAU / 3.0
		k.box(blade, Vector3(0.25, 2.4, 0.05), Vector3(0, 1.2, 0), Color(0.9, 0.9, 0.9))
	var spin := hub.create_tween().set_loops()
	spin.tween_property(hub, "rotation:z", TAU, 4.0).from(0.0)
	for i in 6:
		k.box(g, Vector3(0.5, 0.35, 0.3), Vector3(-1.4 + (i % 3) * 0.55, 0.18 + (i / 3) * 0.36, 1.0), Color(0.15, 0.15, 0.17))
	k.blocker(g, Vector3(1.8, 0.8, 0.6), Vector3(-0.85, 0.4, 1.0))
	var dee: StaticBody3D = Dee.new()
	_person(dee, Vector3(13.4, 0, 8.2), 210, {
		"coat": Color(0.15, 0.18, 0.28), "tights": Color(0.2, 0.2, 0.22), "boots": Color(0.15, 0.12, 0.1),
		"skin": Color(0.4, 0.27, 0.2), "hair": Color(0.1, 0.1, 0.1), "hat": Color(0.15, 0.18, 0.28),
		"scarf": Color(0.7, 0.6, 0.2), "mitten": Color(0.15, 0.12, 0.1), "iris": Color(0.15, 0.1, 0.08),
		"iris_low": Color(0.4, 0.28, 0.2), "hat_style": "brim", "braids": false, "backpack": false,
	})
	dee.body.scale = Vector3.ONE * 1.3


func _board() -> void:
	var board := k.thing(root, Vector3(2.4, 1.4, 0.2), Vector3(4.5, 1.5, -4.0), "Read the noticeboard", [
		"THE LIVING, it says at the top, in paint. A hundred and sixty names. Next to some, a pin and a second name: FOUND.",
		"Rotas: water, wood, soup, night watch. A notice: RADIO TO STATION 4 - 9PM & 2AM - ASK DEE. And a child's drawing of a cat, labelled BISCUIT (GRACE'S), LOST.",
		"Someone's crossed out LOST and written FOUND (SAM'S) underneath, in Grace's writing.",
	])
	board.journal = "The camp's noticeboard is headed THE LIVING. Grace has already changed Biscuit's poster from LOST to FOUND (SAM'S)."
	_area(board)
	k.box(board, Vector3(2.4, 1.3, 0.06), Vector3.ZERO, Color(0.45, 0.33, 0.22))
	for i in 18:
		k.box(board, Vector3(0.28, 0.2, 0.01), Vector3(-1.0 + (i % 6) * 0.4, 0.4 - (i / 6) * 0.35, 0.04), Kit.PAPER.darkened(k.rng.randf() * 0.2), {"rot": Vector3(0, 0, k.rng.randf_range(-6, 6))})
	k.words(board, "THE LIVING", Vector3(0, 0.55, 0.05), Vector3.ZERO, 0.007, Color(0.6, 0.15, 0.1))
	for x in [-1.1, 1.1]:
		k.box(root, Vector3(0.12, 2.2, 0.12), Vector3(4.5 + x, 1.1, -4.1), Kit.WOOD_DARK)


func _way_back() -> void:
	var t: StaticBody3D = k.thing(root, Vector3(3.0, 2.2, 0.8), Vector3(0, 1.1, 23.2), "Walk back along the canal", [], Trail)
	t.destination = CANAL_END
	t.facing = PI / 2.0
	t.hours = 2.0
	t.arrive_line = "Back down the cutting to the canal, and Grace's fire under the bridge, cold now."
	_area(t)
	k.box(root, Vector3(2.2, 0.03, 8), Vector3(0, 0.02, 19), MUD)


func _trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 160
	var placed := 0
	while placed < 90:
		var p := Vector3(rng.randf_range(-40, 40), 0, rng.randf_range(-35, 35))
		if absf(p.x) < 26 and p.z > -23 and p.z < 25:
			continue
		placed += 1
		if rng.randf() < 0.25:
			trees.birch(root, p, rng.randf_range(5, 8))
		else:
			trees.pine(root, p, rng.randf_range(9, 16), {"solid": false})
