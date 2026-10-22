## The Ranger Station, four kilometres up the trail from Mill Road: a clearing
## in the pines with Ranger Wren's cabin, the radio mast that talks to the
## tower, a fire that's always going, and Moss the old dog.
##
## It is built far from the street (at ORIGIN) and reached by walking the
## trail (trail.gd), which fades out and moves you here.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Houses := preload("res://scripts/houses.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Survivor := preload("res://scripts/survivor.gd")
const Wren := preload("res://scripts/wren.gd")
const Trail := preload("res://scripts/trail.gd")
const LockedDoor := preload("res://scripts/locked_door.gd")

const ORIGIN := Vector3(0, 0, -400)
## Where you arrive from the trail, and which way you face.
const ARRIVE := ORIGIN + Vector3(0, 0.1, 20.5)
## Where you come back out on Mill Road.
const TRAILHEAD := Vector3(85, 0.1, -44.2)

const LANTERN := Color(1.0, 0.78, 0.45)
const FLOOR := Color(0.28, 0.3, 0.22)
const PATH := Color(0.4, 0.33, 0.25)

var k: Kit
var world: Node3D
var root: Node3D
var houses: Houses
var f: Furniture


func _init(kit: Kit, w: Node3D) -> void:
	k = kit
	world = w
	houses = Houses.new(kit)
	f = Furniture.new(kit)


func build() -> void:
	root = k.group(world, ORIGIN, 0)
	_ground()
	_cabin()
	_fire_and_wren()
	_yard()
	_trailhead()
	_tower_road()
	_trees()
	_tower()
	_ash()


## Where the trail starts on Mill Road (called from east.gd's side of things).
static func trail_entrance(kit: Kit, parent: Node3D) -> void:
	var t: StaticBody3D = kit.thing(parent, Vector3(3.0, 2.2, 0.8), Vector3(85, 1.1, -47.6), "Follow the trail north", [], Trail)
	t.destination = ARRIVE
	t.facing = 0.0
	t.arrive_line = "An hour up the trail, between pines that are far too green. Then a clearing, woodsmoke, and lanterns strung between the trees."
	t.set_meta("area", "alder")
	kit.box(parent, Vector3(2.0, 0.03, 14), Vector3(85, 0.02, -54), PATH)
	# Wren's lanterns, leading into the trees.
	for i in 3:
		var p := Vector3(85 + (1.4 if i % 2 else -1.4), 0, -50 - i * 3.5)
		kit.box(parent, Vector3(0.1, 1.6, 0.1), p + Vector3(0, 0.8, 0), Kit.WOOD_DARK)
		kit.ball(parent, Vector3(0.18, 0.24, 0.18), p + Vector3(0, 1.7, 0), LANTERN, {"sides": 6, "glow": 1.5})
	var light := OmniLight3D.new()
	light.light_color = LANTERN
	light.light_energy = 1.0
	light.omni_range = 8.0
	light.position = Vector3(85, 2.0, -52)
	light.add_to_group("night_only")
	parent.add_child(light)


# --- The clearing ---------------------------------------------------------------------

func _ground() -> void:
	k.box(root, Vector3(90, 0.2, 90), Vector3(0, -0.1, 0), FLOOR, {"solid": true})
	k.box(root, Vector3(22, 0.02, 16), Vector3(0, 0.01, 2), Color(0.36, 0.38, 0.27))  # the clearing's grass
	# The path from the trail to the porch.
	var pts := [Vector3(0, 0, 24), Vector3(0.4, 0, 14), Vector3(1.2, 0, 6), Vector3(1.5, 0, -4.5)]
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		k.beam(root, a + Vector3(0, 0.025, 0), b + Vector3(0, 0.025, 0), 0.02, PATH, {"depth": 1.6, "up": Vector3.FORWARD})
	for wall in [[Vector3(60, 10, 1), Vector3(0, 5, -27)], [Vector3(60, 10, 1), Vector3(0, 5, 26)],
			[Vector3(1, 10, 60), Vector3(-24, 5, 0)], [Vector3(1, 10, 60), Vector3(24, 5, 0)]]:
		k.blocker(root, wall[0], wall[1])
	# Ferns and grass.
	var tuft := PrismMesh.new()
	tuft.size = Vector3(0.35, 0.45, 0.02)
	for c in [Color(0.3, 0.42, 0.25), Color(0.38, 0.45, 0.3)]:
		var xf: Array = []
		for i in 700:
			var p := Vector3(k.rng.randf_range(-24, 24), 0, k.rng.randf_range(-26, 26))
			if absf(p.x - 0.7) < 1.2 and p.z > -5:
				continue  # the path
			if absf(p.x) < 5.0 and p.z > -12.0 and p.z < -4.0:
				continue  # the cabin
			if Vector2(p.x - 4.0, p.z - 2.5).length() < 2.6:
				continue  # the fire
			var s := k.rng.randf_range(0.7, 1.7)
			xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).scaled(Vector3(s, s, s)), ORIGIN + p + Vector3(0, 0.2 * s, 0)))
		k.scatter(world, tuft, c, xf)


func _cabin() -> void:
	var h := houses.shell(root, Vector3(0, 0, -8), {
		"w": 7.0, "d": 5.0, "h": 2.6, "walls": Color(0.45, 0.32, 0.22), "pattern": Kit.Pattern.PLANKS,
		"inside": Color(0.62, 0.48, 0.33), "floor": Kit.WOOD, "roof": Color(0.25, 0.3, 0.22),
		"door_x": 1.5, "door": "open", "door_color": Color(0.3, 0.4, 0.28), "number": "", "chimney": true,
		"windows": [["front", -1.6, "ok", Kit.FABRIC_RED], ["left", 0.0, "ok", null], ["right", 0.5, "ok", Kit.FABRIC_RED]],
	})
	k.box(h, Vector3(2.6, 0.4, 0.06), Vector3(-1.4, 2.95, 2.62), Color(0.3, 0.4, 0.28))
	k.words(h, "RANGER STATION 4", Vector3(-1.4, 2.95, 2.66), Vector3.ZERO, 0.007, Color(0.92, 0.88, 0.7))
	# The radio desk: Wren's link to the tower.
	f.table(h, Vector3(-1.6, 0, -1.9), 0, Vector2(1.8, 0.7), Kit.WOOD_DARK)
	f.chair(h, Vector3(-1.6, 0, -1.2), 180, Kit.WOOD)
	k.box(h, Vector3(0.9, 0.35, 0.4), Vector3(-1.9, 0.95, -2.0), Color(0.25, 0.27, 0.25))
	for i in 4:
		k.cyl(h, 0.04, 0.02, Vector3(-2.2 + i * 0.18, 0.95, -1.79), Color(0.85, 0.8, 0.6), {"rot": Vector3(90, 0, 0), "sides": 8, "glow": 0.6})
	k.box(h, Vector3(0.3, 0.06, 0.02), Vector3(-1.8, 1.07, -1.79), Color(0.95, 0.7, 0.3), {"glow": 1.2})
	k.cyl(h, 0.03, 0.25, Vector3(-1.1, 0.9, -2.0), Kit.METAL, {"sides": 5})  # microphone
	k.ball(h, Vector3(0.08, 0.1, 0.08), Vector3(-1.1, 1.05, -2.0), Color(0.15, 0.15, 0.15), {"sides": 6})
	k.ring(h, 0.07, 0.1, Vector3(-0.9, 0.79, -1.7), Color(0.15, 0.15, 0.15), Vector3(90, 0, 0))  # headphones
	var log := k.thing(h, Vector3(1.8, 0.5, 0.7), Vector3(-1.6, 0.95, -1.9), "Look at the radio desk", [
		"A proper radio set, much bigger than yours. A logbook lies open: call times to the tower, twice a night, every night since day four.",
		"The last entry is today's: \"Ines - 214 names tonight. +2 from the junction. Sam H. still on the list. Still no idea who sent it.\"",
	])
	log.journal = "Wren's radio log: she sends Ines the names of everyone who checks in alive. 214 of them. My name is on it and Wren didn't send it."
	log.set_meta("area", "station")
	# The wall map.
	var map := k.thing(h, Vector3(1.6, 1.0, 0.1), Vector3(1.4, 1.55, -2.38), "Look at Wren's map", [
		"A huge map of Alder Hollow, pinned all over. Green pins for her caches, blue for camps, a red pin on the tower.",
		"A blue pin labelled HOLLOW JUNCTION CAMP - 160. Another, east: \"The 6:40 lot. 11. Went to junction.\"",
		"Over the tower, in Wren's writing: \"Ines. Don't push. She'll open the gate when she's ready.\"",
	])
	map.set_meta("area", "station")
	k.box(map, Vector3(1.6, 1.0, 0.02), Vector3.ZERO, Color(0.86, 0.82, 0.66))
	k.box(map, Vector3(0.9, 0.5, 0.022), Vector3(-0.2, 0.2, 0.0), Color(0.42, 0.52, 0.36))
	for i in 12:
		var c: Color = [Color(0.3, 0.6, 0.3), Color(0.25, 0.4, 0.75), Color(0.8, 0.15, 0.1)][i % 3]
		k.ball(map, Vector3(0.035, 0.035, 0.035), Vector3(k.rng.randf_range(-0.7, 0.7), k.rng.randf_range(-0.45, 0.45), 0.03), c, {"sides": 5})
	# Bed, stove, shelves.
	f.bed(h, Vector3(2.85, 0, 0.1), 0, 0.85, Kit.FABRIC_GREEN)
	f.stove(h, Vector3(-3.0, 0, 0.9), 90)
	f.kettle(h, Vector3(-2.95, 0.9, 0.9))
	k.box(h, Vector3(0.3, 0.04, 1.6), Vector3(-3.3, 1.5, -0.6), Kit.WOOD)
	for i in 6:
		k.cyl(h, 0.06, 0.16, Vector3(-3.3, 1.6, -1.2 + i * 0.22), [Color(0.7, 0.3, 0.2), Color(0.85, 0.75, 0.4), Color(0.4, 0.55, 0.3)][i % 3], {"sides": 6})
	_search(h, Vector3(0.4, 0.5, 1.7), Vector3(-3.3, 1.6, -0.6), "Look at the jars",
		"Jam, pickled beans, dried mushrooms, all labelled W. One jar is labelled FOR SAM. It's full of tea.", ["tea"], "station")
	f.rug(h, Vector3(0.2, 0, 0.3), 0, Vector2(2.0, 1.4), Color(0.55, 0.35, 0.25))
	var light := OmniLight3D.new()
	light.light_color = LANTERN
	light.light_energy = 1.3
	light.omni_range = 6.0
	light.position = Vector3(0, 2.1, 0)
	h.add_child(light)
	k.ball(h, Vector3(0.2, 0.25, 0.2), Vector3(0, 2.35, 0), LANTERN, {"sides": 6, "glow": 1.5})
	# The mast beside the cabin.
	var mast := k.group(root, Vector3(5.5, 0, -10.5), 0)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			k.beam(mast, Vector3(s * 0.5, 0, t * 0.5), Vector3(s * 0.1, 14, t * 0.1), 0.06, Kit.METAL)
	for y in range(2, 14, 2):
		var w := 0.5 - y / 14.0 * 0.4
		k.box(mast, Vector3(w * 2, 0.04, 0.04), Vector3(0, y, w), Kit.METAL)
		k.box(mast, Vector3(w * 2, 0.04, 0.04), Vector3(0, y, -w), Kit.METAL)
	k.ball(mast, Vector3(0.25, 0.25, 0.25), Vector3(0, 14.2, 0), Color(1.0, 0.85, 0.5), {"glow": 2.5})
	k.beam(root, Vector3(5.5, 8, -10.5), Vector3(-2.0, 2.9, -8.0), 0.015, Color(0.1, 0.1, 0.1))  # the cable


func _search(parent: Node, size: Vector3, pos: Vector3, prompt: String, found: String, loot: Array, area: String) -> StaticBody3D:
	var t := k.search(parent, size, pos, prompt, found, loot)
	t.set_meta("area", area)
	return t


func _fire_and_wren() -> void:
	var c := Vector3(4, 0, 2.5)
	for i in 9:
		var a := i * TAU / 9.0
		k.ball(root, Vector3(0.35, 0.22, 0.3), c + Vector3(cos(a) * 0.75, 0.1, sin(a) * 0.75), Color(0.45, 0.43, 0.4), {"sides": 5})
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		k.beam(root, c + Vector3(cos(a) * 0.5, 0.05, sin(a) * 0.5), c + Vector3(0, 0.45, 0), 0.1, Color(0.3, 0.22, 0.15))
	k.prism(root, Vector3(0.45, 0.7, 0.45), c + Vector3(0, 0.4, 0), Color(1.0, 0.55, 0.15), {"glow": 2.5})
	k.prism(root, Vector3(0.3, 0.5, 0.3), c + Vector3(0.12, 0.3, 0.1), Color(1.0, 0.8, 0.3), {"glow": 3.0, "rot": Vector3(0, 45, 0)})
	k.blocker(root, Vector3(1.4, 1, 1.4), c + Vector3(0, 0.5, 0))
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.6, 0.3)
	fire.light_energy = 2.0
	fire.omni_range = 9.0
	fire.position = c + Vector3(0, 1.0, 0)
	root.add_child(fire)
	var t := fire.create_tween().set_loops()
	t.tween_property(fire, "light_energy", 2.4, 0.23)
	t.tween_property(fire, "light_energy", 1.7, 0.31)
	t.tween_property(fire, "light_energy", 2.1, 0.17)
	# A kettle on a hook over the fire.
	for s in [-1.0, 1.0]:
		k.beam(root, c + Vector3(s * 0.8, 0, 0), c + Vector3(s * 0.6, 1.3, 0), 0.05, Kit.METAL)
	k.box(root, Vector3(1.3, 0.04, 0.04), c + Vector3(0, 1.3, 0), Kit.METAL)
	k.cyl(root, 0.14, 0.18, c + Vector3(0, 1.0, 0), Color(0.2, 0.2, 0.22), {"sides": 7})
	# Log benches.
	for p: Vector3 in [c + Vector3(-1.9, 0, 0.2), c + Vector3(0.3, 0, 2.0)]:
		var turn := 90.0 if p.z < c.z + 1.0 else 0.0
		var g := k.group(root, p, turn)
		k.cyl(g, 0.22, 1.6, Vector3(0, 0.22, 0), Color(0.35, 0.26, 0.18), {"rot": Vector3(0, 0, 90), "sides": 7, "solid": true})
	var sit := k.thing(root, Vector3(1.6, 0.6, 0.6), c + Vector3(0.3, 0.3, 2.0), "Sit by the fire", [
		"You sit on the log and hold your hands out to the fire. For a while, nobody says anything, and that's nice.",
		"The fire pops. Moss sighs in his sleep. You could stay here a long time.",
	])
	sit.journal = "Sat by Wren's fire. First time in ninety-one days I've been warm and not alone at the same time."
	sit.set_meta("area", "station")

	# Ranger Wren herself, by the fire, watching the trail.
	var wren: StaticBody3D = Wren.new()
	wren.position = c + Vector3(1.4, 0.85, 0.9)
	wren.rotation_degrees.y = 125
	k.add_shape(wren, Vector3(0.6, 1.7, 0.6))
	root.add_child(wren)
	var body: Node3D = Survivor.new()
	body.position = Vector3(0, -0.85, 0)
	body.scale = Vector3.ONE * 1.12
	wren.add_child(body)
	body.build(k, {
		"coat": Color(0.3, 0.38, 0.26), "tights": Color(0.3, 0.27, 0.22), "boots": Color(0.32, 0.22, 0.15),
		"skin": Color(0.78, 0.6, 0.46), "hair": Color(0.72, 0.7, 0.68), "hat": Color(0.55, 0.45, 0.3),
		"scarf": Color(0.75, 0.6, 0.25), "mitten": Color(0.3, 0.27, 0.22), "iris": Color(0.15, 0.25, 0.2),
		"iris_low": Color(0.4, 0.62, 0.45), "hat_style": "brim", "backpack": false,
	})
	wren.body = body
	k.box(body, Vector3(0.1, 0.07, 0.02), Vector3(0.1, 1.15, -0.14), Color(0.85, 0.7, 0.3))  # badge

	# Moss, the station dog, asleep by the fire.
	var dog := k.group(root, c + Vector3(-0.9, 0, 1.3), 30)
	var fur := Color(0.25, 0.2, 0.17)
	k.ball(dog, Vector3(0.55, 0.3, 0.38), Vector3(0, 0.15, 0), fur, {"sides": 7})
	k.ball(dog, Vector3(0.3, 0.17, 0.32), Vector3(0.05, 0.16, 0.05), Color(0.9, 0.88, 0.82), {"sides": 6})
	k.ball(dog, Vector3(0.22, 0.2, 0.22), Vector3(0.32, 0.14, 0.12), fur, {"sides": 6})
	k.ball(dog, Vector3(0.12, 0.08, 0.1), Vector3(0.45, 0.11, 0.14), Color(0.9, 0.88, 0.82), {"sides": 5})
	for s in [-1.0, 1.0]:
		k.box(dog, Vector3(0.08, 0.03, 0.1), Vector3(0.3, 0.22, 0.12 + s * 0.08), fur.darkened(0.2), {"rot": Vector3(s * 30, 0, 0)})
	k.beam(dog, Vector3(-0.25, 0.1, 0), Vector3(-0.3, 0.05, 0.3), 0.07, fur)
	var pat := k.thing(root, Vector3(0.8, 0.5, 0.6), c + Vector3(-0.9, 0.25, 1.3), "Pat the dog", [
		"An old collie, grey round the nose. His tail thumps twice without him opening his eyes.",
		"He rolls over so you can do his tummy. Professional.",
		"Moss. That's what the tag says. He snores.",
	])
	pat.set_meta("area", "station")


func _yard() -> void:
	# Lantern posts along the path, and string lights over the fire.
	for i in 5:
		var p := Vector3(1.8 if i % 2 else -1.0, 0, 17 - i * 4.0)
		k.box(root, Vector3(0.1, 1.7, 0.1), p + Vector3(0, 0.85, 0), Kit.WOOD_DARK)
		k.box(root, Vector3(0.35, 0.05, 0.05), p + Vector3(0.15, 1.65, 0), Kit.WOOD_DARK)
		k.ball(root, Vector3(0.18, 0.24, 0.18), p + Vector3(0.3, 1.5, 0), LANTERN, {"sides": 6, "glow": 1.5})
	for i in 2:
		var light := OmniLight3D.new()
		light.light_color = LANTERN
		light.light_energy = 0.9
		light.omni_range = 7.0
		light.position = Vector3(0.4, 1.8, 17 - i * 9)
		light.add_to_group("night_only")
		root.add_child(light)
	var a := Vector3(-1.5, 2.9, -5.6)
	var b := Vector3(8.5, 3.2, 4.5)
	var mid := (a + b) / 2.0 - Vector3(0, 0.6, 0)
	k.box(root, Vector3(0.15, 3.3, 0.15), b - Vector3(0, 1.65, 0) + Vector3(0, 0.1, 0), Kit.WOOD_DARK)
	for seg in [[a, mid], [mid, b]]:
		k.beam(root, seg[0], seg[1], 0.012, Color(0.1, 0.1, 0.1))
		for j in 6:
			var p: Vector3 = (seg[0] as Vector3).lerp(seg[1], (j + 0.5) / 6.0)
			k.ball(root, Vector3(0.07, 0.09, 0.07), p - Vector3(0, 0.06, 0), [LANTERN, Color(0.9, 0.5, 0.4), Color(0.6, 0.85, 0.6)][j % 3], {"sides": 5, "glow": 2.0})
	# Woodpile, solar panel, rain barrel, washing line, a vegetable patch.
	for i in 12:
		k.cyl(root, 0.13, 1.6, Vector3(-4.3, 0.13 + (i / 4) * 0.25, -11.0 + (i % 4) * 0.27 + (i / 4) * 0.13), Color(0.5, 0.38, 0.25), {"rot": Vector3(0, 90, 90), "sides": 6})
	k.blocker(root, Vector3(1.8, 0.8, 1.3), Vector3(-4.3, 0.4, -10.4))
	var panel := k.group(root, Vector3(-7, 0, -6), 20)
	for x in [-0.8, 0.8]:
		k.box(panel, Vector3(0.08, 1.0, 0.08), Vector3(x, 0.5, 0.3), Kit.METAL)
		k.box(panel, Vector3(0.08, 1.5, 0.08), Vector3(x, 0.75, -0.3), Kit.METAL)
	k.box(panel, Vector3(2.0, 0.05, 1.2), Vector3(0, 1.25, 0), Color(0.15, 0.2, 0.35), {"rot": Vector3(-25, 0, 0), "pattern": Kit.Pattern.TILES, "solid": true})
	k.cyl(root, 0.4, 1.0, Vector3(3.9, 0.5, -5.8), Color(0.25, 0.32, 0.4), {"sides": 8, "solid": true})
	for z in [-1.0, 4.0]:
		k.box(root, Vector3(0.08, 1.9, 0.08), Vector3(-8.5, 0.95, z), Kit.WOOD)
	k.box(root, Vector3(0.01, 0.01, 5.0), Vector3(-8.5, 1.85, 1.5), Color(0.8, 0.8, 0.8))
	for i in 4:
		k.box(root, Vector3(0.02, [0.6, 0.5, 0.7, 0.4][i], 0.45), Vector3(-8.5, 1.55 - i * 0.03, -0.2 + i * 1.1), [Kit.FABRIC_RED, Color(0.3, 0.38, 0.26), CREAM_C, Kit.FABRIC_BLUE][i])
	k.box(root, Vector3(3.0, 0.25, 2.0), Vector3(-6.5, 0.12, 9), Color(0.3, 0.24, 0.18), {"solid": true})
	for i in 8:
		k.ball(root, Vector3(0.4, 0.3, 0.4), Vector3(-7.6 + (i % 4) * 0.75, 0.4, 8.5 + (i / 4) * 0.9), Kit.PLANT.lightened(0.1), {"sides": 6})
	# The check-in board.
	var board := k.thing(root, Vector3(0.3, 1.2, 1.6), Vector3(-3.4, 1.4, 10), "Read the check-in board", [
		"CHECK IN HERE. Dozens of cards: a name, where they came from, the day. ALIVE written on every one, by different hands.",
		"Patel, family of four, day 9. D. Ames and ten others from the 6:40, day 3. G. Okafor, by radio from the junction, day 12.",
		"At the bottom, a card in handwriting you don't know: SAM HALE - 4 ALDER ST - ALIVE. No day. You never checked in.",
	])
	board.journal = "There's a card on Wren's check-in board: SAM HALE - 4 ALDER ST - ALIVE. I never wrote it. The Patels are alive. So is Grace Okafor."
	board.set_meta("area", "station")
	k.box(board, Vector3(0.05, 1.0, 1.5), Vector3.ZERO, Color(0.5, 0.38, 0.26))
	for i in 15:
		k.box(board, Vector3(0.02, 0.15, 0.22), Vector3(0.04, 0.35 - (i / 5) * 0.3, -0.55 + (i % 5) * 0.27), Kit.PAPER.darkened(k.rng.randf() * 0.2), {"rot": Vector3(k.rng.randf_range(-8, 8), 0, 0)})
	for z in [-0.7, 0.7]:
		k.box(root, Vector3(0.1, 2.0, 0.1), Vector3(-3.45, 1.0, 10 + z), Kit.WOOD_DARK)
	k.words(board, "CHECK IN HERE", Vector3(0.04, 0.6, 0), Vector3(0, 90, 0), 0.006, Color(0.95, 0.9, 0.75))


const CREAM_C := Color(0.88, 0.85, 0.76)


func _trailhead() -> void:
	var sign := k.group(root, Vector3(1.6, 0, 23.5), 0)
	k.box(sign, Vector3(0.12, 2.0, 0.12), Vector3(0, 1.0, 0), Kit.WOOD)
	k.box(sign, Vector3(1.3, 0.3, 0.05), Vector3(0.4, 1.7, 0), Kit.WOOD_LIGHT, {"rot": Vector3(0, 0, -6)})
	k.words(sign, "ALDER HOLLOW 4 KM", Vector3(0.4, 1.7, -0.03), Vector3(0, 180, -6), 0.005, Color(0.2, 0.15, 0.1))
	var t: StaticBody3D = k.thing(root, Vector3(3.0, 2.2, 0.8), Vector3(0, 1.1, 24.5), "Walk back down the trail", [], Trail)
	t.destination = TRAILHEAD
	t.facing = PI
	t.arrive_line = "Back down the trail to Mill Road. The lanterns behind you get smaller and then they're gone."
	t.set_meta("area", "station")


func _tower_road() -> void:
	# The track north to the tower, gated. Wren keeps the key.
	k.box(root, Vector3(2.4, 0.03, 10), Vector3(0, 0.02, -21), PATH)
	for x in [-1.6, 1.6]:
		k.box(root, Vector3(0.2, 1.4, 0.2), Vector3(x, 0.7, -16), Kit.WOOD_DARK)
	var lock: StaticBody3D = k.thing(root, Vector3(3.0, 1.3, 0.3), Vector3(0, 0.65, -16), "Try the tower road gate", [
		"A gate across the track north. A sign: TOWER ROAD - NO ENTRY. Under it, chalk: \"Not yet. - W\"",
		"Padlocked. Wren's padlock. The tower's red light blinks above the trees.",
	], LockedDoor)
	lock.lock_name = "The tower road gate"
	lock.tool_hint = "Wren keeps the key"
	lock.needs = "tower_key"
	lock.needs_line = "Padlocked. Wren's padlock. The tower's red light blinks above the trees."
	lock.open_line = "The padlock clicks open. The tower road runs north into the dark."
	lock.set_meta("area", "station")
	for y in [0.3, 0.7, 1.1]:
		k.box(lock, Vector3(3.0, 0.1, 0.06), Vector3(0, y - 0.65, 0), Color(0.85, 0.85, 0.8))
	k.box(lock, Vector3(0.9, 0.5, 0.04), Vector3(0, 0.1, 0.05), Color(0.75, 0.15, 0.1))
	k.words(lock, "NO ENTRY", Vector3(0, 0.1, 0.075), Vector3.ZERO, 0.006, Color(0.95, 0.95, 0.9))


func _trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var placed := 0
	while placed < 130:
		var p := Vector3(rng.randf_range(-44, 44), 0, rng.randf_range(-44, 44))
		var r := Vector2(p.x, p.z - 2).length()
		if r < 14.0 or (absf(p.x) < 3.0 and absf(p.z) > 14):
			continue
		placed += 1
		var tall := rng.randf_range(8, 16)
		k.cyl(root, 0.24, tall * 0.5, p + Vector3(0, tall * 0.25, 0), Color(0.25, 0.2, 0.16), {"sides": 5, "solid": r < 30})
		var green := Color(0.2, 0.32, 0.22).lerp(Color(0.28, 0.36, 0.26), rng.randf())
		for tier in 3:
			var rad := (2.2 - tier * 0.55) * tall / 10.0
			var y := tall * (0.35 + tier * 0.2)
			k.cyl(root, rad, tall * 0.35, p + Vector3(0, y + tall * 0.15, 0), green.lightened(tier * 0.05), {"top": 0.0, "sides": 6})


func _tower() -> void:
	# Much closer from up here.
	var g := k.group(root, Vector3(14, 0, -90), 0)
	var col := Color(0.32, 0.32, 0.34)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			k.beam(g, Vector3(s * 2.5, 0, t * 2.5), Vector3(s * 0.3, 48, t * 0.3), 0.25, col, {"fog_end": 140.0})
	for y in range(4, 48, 4):
		var w := 2.5 - y / 48.0 * 2.2
		k.box(g, Vector3(w * 2, 0.15, 0.15), Vector3(0, y, w), col, {"fog_end": 140.0})
		k.box(g, Vector3(w * 2, 0.15, 0.15), Vector3(0, y, -w), col, {"fog_end": 140.0})
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


func _ash() -> void:
	var ash := CPUParticles3D.new()
	ash.add_to_group("ash")
	ash.amount = 200
	ash.lifetime = 18.0
	ash.preprocess = 18.0
	ash.position = Vector3(0, 9, 0)
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(20, 0.5, 20)
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
	root.add_child(ash)
