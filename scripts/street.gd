## Alder Street outside the houses: road, pavements, poles and wires, streetlights,
## fences, bins, the bus stop, plants, the forest edge and the far city.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Flicker := preload("res://scripts/flicker.gd")

var k: Kit
var f: Furniture
var world: Node3D


func _init(kit: Kit, root: Node3D) -> void:
	k = kit
	f = Furniture.new(kit)
	world = root


## lots: one entry per plot, {x, z (house centre), door (world x of the door), number, fence}
func build(lots: Array) -> void:
	_ground_and_road()
	_poles_and_wires()
	_streetlights()
	for lot in lots:
		_front_yard(lot)
	_street_furniture()
	_bus_stop(Vector3(36, 0, 6.2))
	_grass(lots)
	_yard_trees(lots)
	_forest()
	_tower()
	_skyline()
	_ash()
	_edges()


func _ground_and_road() -> void:
	k.box(world, Vector3(140, 0.2, 140), Vector3(0, -0.1, -10), Kit.DEAD_GRASS, {"solid": true})
	k.box(world, Vector3(110, 0.02, 7), Vector3(0, 0.01, 0), Kit.ASPHALT, {"pattern": Kit.Pattern.ASPHALT})
	for s in [-1.0, 1.0]:
		k.box(world, Vector3(110, 0.15, 0.22), Vector3(0, 0.075, s * 3.6), Kit.CONCRETE.lightened(0.05))  # kerb
		k.box(world, Vector3(110, 0.12, 1.5), Vector3(0, 0.06, s * 4.45), Kit.CONCRETE, {"pattern": Kit.Pattern.CONCRETE})
		k.box(world, Vector3(110, 0.04, 0.2), Vector3(0, 0.02, s * 3.35), Kit.ASPHALT.darkened(0.3))  # gutter
		for x in range(-50, 51, 12):
			k.box(world, Vector3(0.6, 0.03, 0.3), Vector3(x + 3, 0.025, s * 3.3), Color(0.12, 0.12, 0.12), {"pattern": Kit.Pattern.TILES})  # drain
	for x in range(-50, 51, 6):
		k.box(world, Vector3(2.2, 0.025, 0.14), Vector3(x, 0.02, 0), Color(0.68, 0.6, 0.35))
	# Cracks, patches, manholes and puddles.
	for i in 45:
		var a := Vector3(k.rng.randf_range(-50, 50), 0.023, k.rng.randf_range(-3.2, 3.2))
		var b := a + Vector3(k.rng.randf_range(-1.5, 1.5), 0, k.rng.randf_range(-0.8, 0.8))
		k.beam(world, a, b, 0.03, Color(0.12, 0.12, 0.12), {"depth": 0.005, "up": Vector3.FORWARD})
	for i in 6:
		k.box(world, Vector3(k.rng.randf_range(1, 2.5), 0.022, k.rng.randf_range(0.8, 1.5)), Vector3(k.rng.randf_range(-45, 45), 0.015, k.rng.randf_range(-2.5, 2.5)), Kit.ASPHALT.darkened(0.2))
	for x in [-28.0, 4.0, 30.0]:
		k.cyl(world, 0.35, 0.03, Vector3(x, 0.02, -1.4), Color(0.2, 0.2, 0.2), {"sides": 10, "pattern": Kit.Pattern.TILES})
	for i in 7:
		k.cyl(world, k.rng.randf_range(0.6, 1.4), 0.01, Vector3(k.rng.randf_range(-45, 45), 0.026, k.rng.randf_range(-3, 3)), Color(0.32, 0.34, 0.36), {"sides": 9, "glow": 0.15})


func _poles_and_wires() -> void:
	var tops: Array[Vector3] = []
	for x in range(-35, 36, 14):
		var lean := k.rng.randf_range(-5, 5)
		var pole := k.group(world, Vector3(x, 0, -5.4), 0)
		pole.rotation_degrees.z = lean * 0.4
		pole.rotation_degrees.x = -absf(lean) - 1.5  # pushed north by the blast
		k.cyl(pole, 0.14, 7.5, Vector3(0, 3.75, 0), Color(0.3, 0.24, 0.18), {"sides": 6, "solid": true})
		k.box(pole, Vector3(0.12, 0.12, 2.0), Vector3(0, 7.0, 0), Color(0.3, 0.24, 0.18))
		for z in [-0.85, 0.0, 0.85]:
			k.cyl(pole, 0.04, 0.14, Vector3(0, 7.13, z), Color(0.55, 0.65, 0.6), {"sides": 5})
		k.cyl(pole, 0.22, 0.6, Vector3(0.2, 6.2, 0), Color(0.35, 0.37, 0.38), {"sides": 7})  # transformer
		tops.append(pole.global_transform * Vector3(0, 7.2, 0) if pole.is_inside_tree() else Vector3(x, 7.2, -5.4))
	for i in tops.size() - 1:
		for z in [-0.85, 0.0, 0.85]:
			var a := tops[i] + Vector3(0, 0, z)
			var b := tops[i + 1] + Vector3(0, 0, z)
			var mid := (a + b) / 2.0 - Vector3(0, 0.5, 0)
			k.beam(world, a, mid, 0.02, Color(0.08, 0.08, 0.08))
			k.beam(world, mid, b, 0.02, Color(0.08, 0.08, 0.08))
	# One line has snapped and hangs down to the road.
	k.beam(world, tops[1] + Vector3(0, 0, 0.85), Vector3(-17, 0.05, -3.5), 0.02, Color(0.08, 0.08, 0.08))


func _streetlight(pos: Vector3, facing: float, flicker := false) -> void:
	var g := k.group(world, pos, facing)
	k.cyl(g, 0.08, 6.0, Vector3(0, 3.0, 0), Color(0.35, 0.37, 0.38), {"sides": 6, "solid": true})
	k.cyl(g, 0.14, 0.6, Vector3(0, 0.3, 0), Color(0.35, 0.37, 0.38), {"sides": 6})
	k.beam(g, Vector3(0, 5.9, 0), Vector3(0, 6.1, 1.4), 0.07, Color(0.35, 0.37, 0.38))
	k.box(g, Vector3(0.3, 0.12, 0.6), Vector3(0, 6.08, 1.5), Color(0.3, 0.32, 0.33))
	var lens := k.box(g, Vector3(0.24, 0.03, 0.5), Vector3(0, 6.01, 1.5), Color(0.75, 0.72, 0.6))
	if flicker:
		var light: OmniLight3D = Flicker.new()
		light.light_color = Color(1.0, 0.82, 0.55)
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.position = Vector3(0, 5.6, 1.5)
		light.bulb = lens
		light.on_material = k.mat(Color(1.0, 0.9, 0.6), Kit.Pattern.PLAIN, 3.0)
		light.off_material = k.mat(Color(0.75, 0.72, 0.6))
		g.add_child(light)


func _streetlights() -> void:
	for x in [-40.0, -24.0, -8.0, 24.0, 40.0]:
		_streetlight(Vector3(x, 0, 5.3), 180)
	_streetlight(Vector3(8, 0, 5.3), 180)
	# The one that still works, more or less, right by your house.
	_streetlight(Vector3(3.5, 0, -5.3), 0, true)


func _front_yard(lot: Dictionary) -> void:
	var x: float = lot.x
	var s := -1.0 if lot.z < 0 else 1.0     # which side of the street
	var door: float = lot.get("door", x)
	var fence_z := s * 5.45
	# Path from the pavement to the porch.
	var porch_z: float = lot.z - s * 4.6
	var plen: float = absf(porch_z - fence_z)
	k.box(world, Vector3(1.0, 0.04, plen), Vector3(door, 0.02, (porch_z + fence_z) / 2.0), Kit.CONCRETE.darkened(0.1), {"pattern": Kit.Pattern.CONCRETE})
	# Picket fence with a gap for the path; some pickets missing or leaning.
	if lot.get("fence", true):
		var col: Color = lot.get("fence_color", Color(0.82, 0.8, 0.74))
		for side in [-1.0, 1.0]:
			var x0: float = door + side * 0.6
			var x1: float = x + side * 4.5
			var a := minf(x0, x1)
			var b := maxf(x0, x1)
			k.box(world, Vector3(b - a, 0.06, 0.04), Vector3((a + b) / 2.0, 0.35, fence_z), col)
			k.box(world, Vector3(b - a, 0.06, 0.04), Vector3((a + b) / 2.0, 0.75, fence_z), col)
			var px := a + 0.05
			while px < b:
				if k.rng.randf() > 0.08:
					k.box(world, Vector3(0.08, 1.0, 0.03), Vector3(px, 0.5, fence_z + s * 0.03), col.darkened(k.rng.randf() * 0.15),
						{"rot": Vector3(0, 0, k.rng.randf_range(-4, 4) if k.rng.randf() < 0.15 else 0.0)})
				px += 0.18
			k.blocker(world, Vector3(b - a, 1.0, 0.1), Vector3((a + b) / 2.0, 0.5, fence_z))
		# Gate hanging open.
		var gate := k.group(world, Vector3(door - 0.55, 0, fence_z), s * -100.0)
		for i in 6:
			k.box(gate, Vector3(0.08, 0.95, 0.03), Vector3(0.1 + i * 0.18, 0.5, 0), col)
		k.box(gate, Vector3(1.05, 0.06, 0.04), Vector3(0.52, 0.55, 0), col)
	# Mailbox with the house number.
	if lot.get("number", "") != "":
		var mb := k.group(world, Vector3(door + 1.3, 0, fence_z - s * 0.3), 0.0 if s > 0 else 180.0)
		k.box(mb, Vector3(0.08, 1.05, 0.08), Vector3(0, 0.52, 0), Kit.WOOD_DARK)
		k.box(mb, Vector3(0.24, 0.24, 0.45), Vector3(0, 1.15, 0), lot.get("mailbox", Color(0.25, 0.3, 0.38)))
		k.box(mb, Vector3(0.04, 0.18, 0.05), Vector3(0.14, 1.25, 0.1), Color(0.75, 0.2, 0.15))  # flag, still up
		k.words(mb, lot.number, Vector3(0, 1.15, -0.23), Vector3(0, 180, 0), 0.006, Color(0.9, 0.88, 0.8))
		k.words(mb, lot.number, Vector3(0, 1.15, 0.23), Vector3.ZERO, 0.006, Color(0.9, 0.88, 0.8))
	# Bushes along the front of the house.
	for i in 4:
		var bx: float = x + k.rng.randf_range(-3.8, 3.8)
		if absf(bx - door) < 1.0:
			continue
		var bz: float = lot.z - s * 4.2
		for j in 3:
			k.ball(world, Vector3.ONE * k.rng.randf_range(0.5, 0.9), Vector3(bx + j * 0.35, 0.3, bz + k.rng.randf_range(-0.2, 0.2)),
				Color(0.32, 0.36, 0.25).lerp(Color(0.42, 0.38, 0.28), k.rng.randf()), {"sides": 6})


func _bin(pos: Vector3, turn: float, color: Color, tipped := false, melted := false) -> void:
	var g := k.group(world, pos, turn)
	var body := k.group(g)
	if melted:
		# The plastic sagged in the heat and set again, slumped toward the city.
		body.scale = Vector3(1.1, 0.72, 1.0)
		body.rotation_degrees = Vector3(-6, 0, 9)
		for i in 4:
			k.cyl(g, 0.04, k.rng.randf_range(0.15, 0.4), Vector3(-0.25 + i * 0.16, 0.6, -0.36), color.darkened(0.1), {"sides": 4})  # drips
		k.box(g, Vector3(0.66, 0.05, 0.4), Vector3(0, 0.62, -0.5), color.darkened(0.15), {"rot": Vector3(-60, 0, 0)})  # drooping lid
		k.ball(g, Vector3(0.9, 0.06, 0.8), Vector3(0, 0.03, -0.05), color.darkened(0.25))  # puddle of plastic
	k.box(body, Vector3(0.6, 1.0, 0.7), Vector3(0, 0.55, 0), color)
	k.box(body, Vector3(0.64, 0.06, 0.74), Vector3(0, 1.08, 0.0), color.darkened(0.15))
	for s in [-0.25, 0.25]:
		k.cyl(body, 0.1, 0.06, Vector3(s, 0.1, -0.33), Color(0.08, 0.08, 0.08), {"rot": Vector3(0, 0, 90), "sides": 8})
	if tipped:
		body.rotation_degrees.x = 90
		body.position = Vector3(0, 0.3, -0.5)
		for i in 3:
			k.ball(g, Vector3(0.5, 0.35, 0.45), Vector3(k.rng.randf_range(-0.6, 0.6), 0.17, 0.6 + i * 0.4), Color(0.1, 0.1, 0.11), {"sides": 6})
	else:
		k.blocker(g, Vector3(0.6, 1.1, 0.7), Vector3(0, 0.55, 0))


func _street_furniture() -> void:
	_bin(Vector3(-2.3, 0, -5.0), 180, Color(0.2, 0.35, 0.25))
	_bin(Vector3(14.0, 0, -5.0), 170, Color(0.3, 0.3, 0.32), false, true)
	_bin(Vector3(13.2, 0, -5.0), 185, Color(0.2, 0.35, 0.25), true)
	_bin(Vector3(-28.0, 0, 5.0), 0, Color(0.3, 0.3, 0.32))
	_bin(Vector3(18.5, 0, 5.0), 10, Color(0.45, 0.3, 0.2), true)
	# Fire hydrants.
	for p in [Vector3(10, 0, 5.0), Vector3(-26, 0, -5.0)]:
		k.cyl(world, 0.13, 0.6, p + Vector3(0, 0.3, 0), Color(0.7, 0.18, 0.12), {"sides": 7})
		k.cyl(world, 0.15, 0.12, p + Vector3(0, 0.65, 0), Color(0.7, 0.18, 0.12), {"top": 0.06, "sides": 7})
		k.cyl(world, 0.05, 0.38, p + Vector3(0, 0.42, 0), Color(0.75, 0.2, 0.15), {"rot": Vector3(90, 0, 0), "sides": 5})
	# Street sign at the west end.
	var sign := k.group(world, Vector3(-43, 0, -5.0), 0)
	k.cyl(sign, 0.04, 2.8, Vector3(0, 1.4, 0), Kit.METAL, {"sides": 5})
	k.box(sign, Vector3(1.0, 0.22, 0.03), Vector3(0, 2.7, 0), Color(0.15, 0.32, 0.22))
	k.words(sign, "ALDER ST", Vector3(0, 2.7, 0.02), Vector3.ZERO, 0.006, Color(0.9, 0.9, 0.85))
	k.words(sign, "ALDER ST", Vector3(0, 2.7, -0.02), Vector3(0, 180, 0), 0.006, Color(0.9, 0.9, 0.85))
	# A stop sign at the east end, bent by something.
	var stop := k.group(world, Vector3(43, 0, 5.0), -90)
	stop.rotation_degrees.z = 12
	k.cyl(stop, 0.04, 2.3, Vector3(0, 1.15, 0), Kit.METAL, {"sides": 5})
	k.cyl(stop, 0.38, 0.03, Vector3(0, 2.5, 0), Color(0.7, 0.12, 0.1), {"rot": Vector3(90, 0, 0), "sides": 8})
	k.words(stop, "STOP", Vector3(0, 2.5, 0.02), Vector3.ZERO, 0.007, Color(0.95, 0.95, 0.95))
	# A noticeboard covered in missing-person posters.
	var board := k.thing(world, Vector3(1.4, 1.2, 0.3), Vector3(-6, 1.6, 5.1), "Read the posters", [
		"MISSING posters, dozens of them, layered on top of each other. Faces, phone numbers that won't ring.",
		"Patience Okafor, last seen at St. Brigid's shelter. A dog called Pip. The Bell children, Ada and Tom.",
		"Near the bottom, half hidden: a hospital staff photo. It takes you a moment to recognise yourself.",
	])
	board.rotation_degrees.y = 180
	board.journal = "There's a staff photo of me on the missing posters board. Someone was looking for me. Or for my body."
	for s in [-0.65, 0.65]:
		k.box(board, Vector3(0.08, 2.2, 0.08), Vector3(s, -0.5, 0), Kit.WOOD_DARK)
	k.box(board, Vector3(1.4, 1.0, 0.05), Vector3(0, 0.1, 0), Color(0.55, 0.42, 0.3))
	for i in 9:
		k.box(board, Vector3(0.28, 0.36, 0.01), Vector3(-0.5 + (i % 4) * 0.33 + k.rng.randf_range(-0.04, 0.04), 0.3 - (i / 4) * 0.33, 0.03 + i * 0.001),
			Kit.PAPER.darkened(k.rng.randf() * 0.2), {"rot": Vector3(0, 0, k.rng.randf_range(-8, 8))})


func _bus_stop(pos: Vector3) -> void:
	var g := k.group(world, pos, 180)
	var steel := Color(0.3, 0.38, 0.35)
	for x in [-1.6, 1.6]:
		for z in [-0.6, 0.5]:
			k.box(g, Vector3(0.08, 2.4, 0.08), Vector3(x, 1.2, z), steel)
	k.box(g, Vector3(3.5, 0.08, 1.5), Vector3(0, 2.44, 0), steel.darkened(0.2))
	k.pane(g, Vector3(3.2, 1.7, 0.02), Vector3(0, 1.3, -0.6), Vector3.ZERO, 0.6)
	k.pane(g, Vector3(0.02, 1.7, 1.0), Vector3(-1.6, 1.3, -0.05), Vector3.ZERO, 0.6)
	k.box(g, Vector3(2.4, 0.06, 0.4), Vector3(0, 0.5, -0.35), Kit.WOOD)
	for x in [-1.0, 1.0]:
		k.box(g, Vector3(0.06, 0.5, 0.35), Vector3(x, 0.25, -0.35), steel)
	var sign := k.thing(g, Vector3(0.6, 0.8, 0.1), Vector3(1.6, 1.6, 0.6), "Read the timetable", [
		"EVACUATION PICKUP POINT. Buses every 30 minutes. One bag per person. Pets cannot be accommodated.",
		"Someone has crossed out \"every 30 minutes\" and written \"NEVER CAME\" in marker.",
	])
	k.box(sign, Vector3(0.6, 0.8, 0.03), Vector3.ZERO, Color(0.85, 0.85, 0.8))
	k.box(sign, Vector3(0.6, 0.14, 0.035), Vector3(0, 0.3, 0), Color(0.75, 0.2, 0.15))
	k.cyl(g, 0.05, 2.6, Vector3(1.6, 1.3, 0.6), Kit.METAL, {"sides": 5})
	# Suitcases left in a neat row, as if their owners just stepped away.
	var cols := [Color(0.3, 0.35, 0.5), Color(0.5, 0.2, 0.18), Color(0.25, 0.25, 0.25), Color(0.6, 0.5, 0.3), Color(0.35, 0.45, 0.35)]
	for i in 5:
		var c := k.group(g, Vector3(-1.2 + i * 0.6, 0, 0.9), k.rng.randf_range(-6, 6))
		k.box(c, Vector3(0.45, 0.6, 0.22), Vector3(0, 0.3, 0), cols[i])
		k.box(c, Vector3(0.14, 0.04, 0.04), Vector3(0, 0.64, 0), Color(0.1, 0.1, 0.1))


func _in_house(p: Vector3, lots: Array) -> bool:
	for lot in lots:
		if absf(p.x - lot.x) < 4.6 and absf(p.z - lot.z) < 4.6:
			return true
	return false


func _grass(lots: Array) -> void:
	var tuft := PrismMesh.new()
	tuft.size = Vector3(0.3, 0.38, 0.02)
	var colors := [Color(0.45, 0.43, 0.3), Color(0.38, 0.4, 0.28), Color(0.52, 0.48, 0.34)]
	for c in colors:
		var xf: Array = []
		var tries := 0
		while xf.size() < 1400 and tries < 6000:
			tries += 1
			var p := Vector3(k.rng.randf_range(-45, 45), 0, k.rng.randf_range(-47, 27))
			if absf(p.z) < 5.3 or _in_house(p, lots):
				continue
			var s := k.rng.randf_range(0.7, 1.6)
			var t := Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).scaled(Vector3(s, s, s)), p + Vector3(0, 0.17 * s, 0))
			xf.append(t)
		k.scatter(world, tuft, c, xf)
	# Leaves and litter on the road and pavements.
	var leaf := BoxMesh.new()
	leaf.size = Vector3(0.12, 0.01, 0.08)
	var lx: Array = []
	for i in 600:
		var p := Vector3(k.rng.randf_range(-50, 50), 0.13 if k.rng.randf() < 0.5 else 0.03, k.rng.randf_range(-5.2, 5.2))
		lx.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU), p))
	k.scatter(world, leaf, Color(0.45, 0.32, 0.2), lx)


func _dead_tree(pos: Vector3, tall: float, color := Color(0.3, 0.25, 0.2)) -> void:
	# Every tree leans a little north, away from the city.
	var lean := k.group(world, pos, 0)
	lean.rotation_degrees.x = -k.rng.randf_range(4, 12)
	var g := k.group(lean, Vector3.ZERO, k.rng.randf() * 360)
	k.cyl(g, 0.16 * tall / 5.0, tall * 0.6, Vector3(0, tall * 0.3, 0), color, {"top": 0.1 * tall / 5.0, "sides": 6, "solid": true})
	for i in 5:
		var a := i * TAU / 5.0 + k.rng.randf()
		var start := Vector3(0, tall * k.rng.randf_range(0.4, 0.6), 0)
		var tip := start + Vector3(cos(a), k.rng.randf_range(0.6, 1.2), sin(a)) * tall * 0.3
		k.beam(g, start, tip, 0.07 * tall / 5.0, color)
		for j in 2:
			var twig := tip + Vector3(k.rng.randf_range(-0.6, 0.6), k.rng.randf_range(0.2, 0.6), k.rng.randf_range(-0.6, 0.6))
			k.beam(g, tip, twig, 0.035, color)
			if k.rng.randf() < 0.4:
				k.ball(g, Vector3(0.4, 0.3, 0.4), twig, Color(0.45, 0.35, 0.22), {"sides": 5})  # last brown leaves


func _yard_trees(lots: Array) -> void:
	for lot in lots:
		var s := -1.0 if lot.z < 0 else 1.0
		_dead_tree(Vector3(lot.x + k.rng.randf_range(-3, 3), 0, lot.z + s * 6.5), k.rng.randf_range(4, 6))
		if k.rng.randf() < 0.6:
			_dead_tree(Vector3(lot.x + k.rng.randf_range(-3.5, 3.5), 0, lot.z - s * 5.2), k.rng.randf_range(3, 4.5))


func _forest() -> void:
	# A darker forest floor, then pines: greener and denser than they should be.
	k.box(world, Vector3(140, 0.02, 60), Vector3(0, 0.01, -78), Color(0.26, 0.3, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 170:
		var p := Vector3(rng.randf_range(-62, 62), 0, rng.randf_range(-47, -100))
		var tall := rng.randf_range(7, 14)
		if rng.randf() < 0.15:
			_dead_tree(p, tall * 0.6, Color(0.25, 0.22, 0.2))
			continue
		k.cyl(world, 0.22, tall * 0.5, p + Vector3(0, tall * 0.25, 0), Color(0.25, 0.2, 0.16), {"sides": 5})
		var green := Color(0.2, 0.3, 0.22).lerp(Color(0.28, 0.34, 0.26), rng.randf())
		for tier in 3:
			var r := (2.2 - tier * 0.55) * tall / 10.0
			var y := tall * (0.35 + tier * 0.2)
			k.cyl(world, r, tall * 0.35, p + Vector3(0, y + tall * 0.15, 0), green.lightened(tier * 0.05), {"top": 0.0, "sides": 6})
	for i in 12:
		var p := Vector3(rng.randf_range(-40, 40), 0.25, rng.randf_range(-48, -60))
		k.beam(world, p, p + Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-1, 1)), 0.4, Color(0.28, 0.24, 0.2))  # fallen logs
	# A string of lanterns between two trees at the forest edge, unlit. For now.
	for i in 8:
		var p := Vector3(-8 + i * 0.9, 2.6 - sin(i / 7.0 * PI) * 0.4, -49)
		k.ball(world, Vector3(0.12, 0.16, 0.12), p, Color(0.75, 0.6, 0.35), {"sides": 5})
	k.beam(world, Vector3(-8.5, 2.7, -49), Vector3(-1.2, 2.7, -49), 0.01, Color(0.1, 0.1, 0.1))


func _tower() -> void:
	# The radio tower, with a red light that is somehow still blinking.
	var g := k.group(world, Vector3(22, 0, -92), 0)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			k.beam(g, Vector3(s * 1.5, 0, t * 1.5), Vector3(s * 0.2, 30, t * 0.2), 0.15, Color(0.35, 0.35, 0.36))
	for y in range(3, 30, 3):
		var w := 1.5 - y / 30.0 * 1.3
		k.box(g, Vector3(w * 2, 0.08, 0.08), Vector3(0, y, w), Color(0.35, 0.35, 0.36))
		k.box(g, Vector3(w * 2, 0.08, 0.08), Vector3(0, y, -w), Color(0.35, 0.35, 0.36))
	var red := StandardMaterial3D.new()
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.albedo_color = Color(1, 0.15, 0.1)
	var beacon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	beacon.mesh = sm
	beacon.material_override = red
	beacon.position = Vector3(0, 30.5, 0)
	g.add_child(beacon)
	var blink := g.create_tween().set_loops()
	blink.tween_callback(func(): beacon.visible = true)
	blink.tween_interval(0.25)
	blink.tween_callback(func(): beacon.visible = false)
	blink.tween_interval(1.8)


func _skyline() -> void:
	# The city you never reach, mostly lost in the haze.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 24:
		var w := rng.randf_range(5, 12)
		var tall := rng.randf_range(10, 40)
		var b := k.box(world, Vector3(w, tall, w), Vector3(-80 + i * 7 + rng.randf_range(-2, 2), tall / 2.0, rng.randf_range(80, 100)), Color(0.3, 0.3, 0.32), {"fog_end": 125.0})
		if rng.randf() < 0.3:
			b.rotation.z = rng.randf_range(-0.25, 0.25)  # some of them are leaning


func _ash() -> void:
	var ash := CPUParticles3D.new()
	ash.add_to_group("ash")
	ash.amount = 600
	ash.lifetime = 18.0
	ash.preprocess = 18.0
	ash.position = Vector3(0, 9, -6)
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(45, 0.5, 14)
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


func _edges() -> void:
	# Invisible walls at the edge of the test area.
	for wall in [[Vector3(100, 10, 1), Vector3(0, 5, -48)], [Vector3(100, 10, 1), Vector3(0, 5, 28)],
			[Vector3(1, 10, 80), Vector3(-45, 5, -10)], [Vector3(1, 10, 80), Vector3(45, 5, -10)]]:
		k.blocker(world, wall[0], wall[1])
