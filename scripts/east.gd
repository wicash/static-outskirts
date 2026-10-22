## Mill Road: the road east past the stop sign. The Savoy garage, the Mill
## Road allotments, and the 6:40 train, stopped on the level crossing since
## the morning of the strikes.
##
## It is built around a chain of tools:
##   crowbar (crashed van)  -> garage back room -> bolt cutters
##   bolt cutters           -> allotment sheds, the crossing gate (the train)
##   the train's guard van  -> long-wire antenna -> Ranger Station on 99.1
## and two collections that glint so you spot them from afar:
##   6 Ranger caches (the walkie-talkie beeps faster near them)
##   8 lost things (they end up on the board in your house)
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Houses := preload("res://scripts/houses.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Cars := preload("res://scripts/cars.gd")
const LockedDoor := preload("res://scripts/locked_door.gd")
const Harvest := preload("res://scripts/harvest.gd")
const Collectible := preload("res://scripts/collectible.gd")
const Trees := preload("res://scripts/trees.gd")

const RAIL_X := 100.0
const LIVERY := Color(0.24, 0.3, 0.42)
const CREAM := Color(0.82, 0.78, 0.66)
const ROOF := Color(0.36, 0.36, 0.37)
const RANGER := Color(0.25, 0.36, 0.22)

const CROWBAR_HINT := "Needs something to lever it open"
const CUTTER_HINT := "Needs something to cut the chain"

var k: Kit
var world: Node3D
var houses: Houses
var f: Furniture
var trees: Trees


func _init(kit: Kit, root: Node3D) -> void:
	k = kit
	world = root
	houses = Houses.new(kit)
	f = Furniture.new(kit)
	trees = Trees.new(kit, 202)


func build() -> void:
	_ground_and_road()
	_signs()
	_garage()
	_allotments()
	_railway()
	_train()
	_signal_box()
	_forest_edge()
	_grass()
	_ash()
	_bus_ticket()


# --- Helpers ------------------------------------------------------------------------

## Tags a searchable place with its area, for the map.
func _area(t: Node, area: String) -> Node:
	t.set_meta("area", area)
	return t


func _search(parent: Node, size: Vector3, pos: Vector3, prompt: String, found: String, loot: Array, area: String, journal := "") -> StaticBody3D:
	var t := k.search(parent, size, pos, prompt, found, loot, journal)
	_area(t, area)
	return t


## A glinting find: a lost thing ("memory") or a Ranger cache ("cache").
func _find(parent: Node, pos: Vector3, kind: String, title: String, prompt: String, lines: Array, gives := [], journal := "") -> StaticBody3D:
	var c: StaticBody3D = Collectible.new()
	c.kind = kind
	c.title = title
	c.prompt = prompt
	c.lines = PackedStringArray(lines)
	c.gives = gives
	c.journal = journal
	c.position = pos
	k.add_shape(c, Vector3(0.45, 0.35, 0.45), Vector3(0, 0.12, 0))
	parent.add_child(c)
	return c


## A green Ranger ammo tin with a painted R.
func _cache(parent: Node, pos: Vector3, title: String, note: String, gives: Array, turn := 0.0) -> StaticBody3D:
	var c := _find(parent, pos, "cache", title, "Open the Ranger cache", [note, "Empty now. You leave the lid open so the next person knows."], gives)
	var g := k.group(c, Vector3.ZERO, turn)
	k.box(g, Vector3(0.38, 0.2, 0.2), Vector3(0, 0.1, 0), RANGER)
	k.box(g, Vector3(0.4, 0.04, 0.22), Vector3(0, 0.21, 0), RANGER.darkened(0.2))
	k.box(g, Vector3(0.12, 0.03, 0.03), Vector3(0, 0.25, 0), Kit.METAL)  # handle
	k.words(g, "R", Vector3(0, 0.1, 0.102), Vector3.ZERO, 0.004, Color(0.9, 0.85, 0.6))
	return c


## A lock you open with a tool. `size`/`pos` are the part that blocks the way.
func _lock(parent: Node, size: Vector3, pos: Vector3, prompt: String, name: String, needs: String, lines: Array, open_line: String, journal := "") -> StaticBody3D:
	var l: StaticBody3D = k.thing(parent, size, pos, prompt, lines, LockedDoor)
	l.lock_name = name
	l.needs = needs
	l.tool_hint = CROWBAR_HINT if needs == "crowbar" else CUTTER_HINT
	l.needs_line = lines[-1] if not lines.is_empty() else "It won't open."
	l.open_line = open_line
	l.journal = journal
	return l


func _padlock(parent: Node, pos: Vector3) -> Node3D:
	var g := k.group(parent, pos, 0)
	k.box(g, Vector3(0.09, 0.08, 0.04), Vector3.ZERO, Color(0.7, 0.6, 0.3))
	k.ring(g, 0.025, 0.035, Vector3(0, 0.055, 0), Kit.METAL, Vector3(90, 0, 0))
	return g


func _post_and_wire(a: Vector3, b: Vector3, height := 1.3, color := Kit.WOOD_DARK) -> void:
	var n := maxi(1, int(a.distance_to(b) / 2.5))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		k.box(world, Vector3(0.1, height, 0.1), p + Vector3(0, height / 2.0, 0), color)
	for y in [height * 0.45, height * 0.9]:
		k.beam(world, a + Vector3(0, y, 0), b + Vector3(0, y, 0), 0.02, Kit.METAL.darkened(0.3))
	var mid := (a + b) / 2.0
	var d := b - a
	k.blocker(world, Vector3(d.length(), 2.5, 0.2), mid + Vector3(0, 1.25, 0), -rad_to_deg(atan2(d.z, d.x)))


# --- Ground, road ---------------------------------------------------------------------

func _ground_and_road() -> void:
	# The street ground ends at x 70; this carries on to the railway and beyond.
	k.box(world, Vector3(45, 0.2, 80), Vector3(92.5, -0.1, -10), Kit.DEAD_GRASS, {"solid": true})
	var x0 := 55.0
	var x1 := 108.0
	var cx := (x0 + x1) / 2.0
	var L := x1 - x0
	k.box(world, Vector3(L, 0.02, 7), Vector3(cx, 0.01, 0), Kit.ASPHALT, {"pattern": Kit.Pattern.ASPHALT})
	for s in [-1.0, 1.0]:
		k.box(world, Vector3(L, 0.15, 0.22), Vector3(cx, 0.075, s * 3.6), Kit.CONCRETE.lightened(0.05))
		k.box(world, Vector3(L, 0.12, 1.5), Vector3(cx, 0.06, s * 4.45), Kit.CONCRETE, {"pattern": Kit.Pattern.CONCRETE})
		k.box(world, Vector3(L, 0.04, 0.2), Vector3(cx, 0.02, s * 3.35), Kit.ASPHALT.darkened(0.3))
	for x in range(56, 96, 6):
		k.box(world, Vector3(2.2, 0.025, 0.14), Vector3(x, 0.02, 0), Color(0.68, 0.6, 0.35))
	for i in 25:
		var a := Vector3(k.rng.randf_range(x0, x1), 0.023, k.rng.randf_range(-3.2, 3.2))
		var b := a + Vector3(k.rng.randf_range(-1.5, 1.5), 0, k.rng.randf_range(-0.8, 0.8))
		k.beam(world, a, b, 0.03, Color(0.12, 0.12, 0.12), {"depth": 0.005, "up": Vector3.FORWARD})
	# "STOP" painted before the crossing, and a road block past it.
	k.words(world, "SLOW", Vector3(90, 0.03, 1.8), Vector3(-90, 90, 0), 0.02, Color(0.85, 0.82, 0.7))
	var block := k.group(world, Vector3(106.5, 0, 0), 90)
	for x in [-2.4, 0.0, 2.4]:
		k.box(block, Vector3(2.2, 0.25, 0.08), Vector3(x, 0.9, 0), Color(0.85, 0.85, 0.82))
		for s in [-0.9, 0.9]:
			k.box(block, Vector3(0.08, 0.95, 0.4), Vector3(x + s, 0.47, 0), Color(0.5, 0.5, 0.5))
	k.words(block, "ROAD CLOSED", Vector3(0, 0.9, 0.05), Vector3.ZERO, 0.008, Color(0.75, 0.15, 0.1))
	k.blocker(world, Vector3(1, 3, 10), Vector3(106.5, 1.5, 0))
	# Telegraph poles carrying on along the north side.
	var tops: Array[Vector3] = []
	for x in [49.0, 63.0, 77.0, 91.0]:
		var lean := k.rng.randf_range(-4, 4)
		var pole := k.group(world, Vector3(x, 0, -5.4), 0)
		pole.rotation_degrees = Vector3(-absf(lean) - 1.5, 0, lean * 0.4)
		k.cyl(pole, 0.14, 7.5, Vector3(0, 3.75, 0), Color(0.3, 0.24, 0.18), {"sides": 6, "solid": true})
		k.box(pole, Vector3(0.12, 0.12, 2.0), Vector3(0, 7.0, 0), Color(0.3, 0.24, 0.18))
		tops.append(Vector3(x, 7.15, -5.4) + Vector3(0, 0, -0.25))
	for i in tops.size() - 1:
		for z in [-0.85, 0.0, 0.85]:
			var a := tops[i] + Vector3(0, 0, z)
			var b := tops[i + 1] + Vector3(0, 0, z)
			var mid := (a + b) / 2.0 - Vector3(0, 0.5, 0)
			k.beam(world, a, mid, 0.02, Color(0.08, 0.08, 0.08))
			k.beam(world, mid, b, 0.02, Color(0.08, 0.08, 0.08))


func _signs() -> void:
	var sign := k.group(world, Vector3(50, 0, 5.0), 0)
	k.cyl(sign, 0.04, 2.8, Vector3(0, 1.4, 0), Kit.METAL, {"sides": 5})
	k.box(sign, Vector3(1.1, 0.22, 0.03), Vector3(0, 2.7, 0), Color(0.15, 0.32, 0.22))
	for r in [0.0, 180.0]:
		k.words(sign, "MILL RD", Vector3(0, 2.7, 0.02 if r == 0.0 else -0.02), Vector3(0, r, 0), 0.006, Color(0.9, 0.9, 0.85))
	# A hand-painted board for the garage.
	var board := k.thing(world, Vector3(1.6, 1.0, 0.3), Vector3(53, 1.2, -5.6), "Read the sign", [
		"SAVOY GARAGE. FUEL - SWEETS - BAIT. \"If we're shut, knock. If we don't answer, we're fishing.\"",
		"Underneath, in fresh paint: NO FUEL. NO ONE. SORRY. - R",
	])
	k.box(board, Vector3(1.6, 0.9, 0.05), Vector3.ZERO, Color(0.75, 0.3, 0.2))
	k.words(board, "SAVOY", Vector3(0, 0.2, 0.03), Vector3.ZERO, 0.014, Color(0.95, 0.9, 0.75))
	k.words(board, "FUEL  SWEETS  BAIT", Vector3(0, -0.15, 0.03), Vector3.ZERO, 0.006, Color(0.95, 0.9, 0.75))
	for x in [-0.6, 0.6]:
		k.box(world, Vector3(0.08, 1.2, 0.08), Vector3(53 + x, 0.6, -5.6), Kit.WOOD_DARK)


# --- The Savoy garage --------------------------------------------------------------------

func _garage() -> void:
	# Forecourt and canopy.
	k.box(world, Vector3(20, 0.04, 11), Vector3(68, 0.02, -10.8), Kit.CONCRETE.darkened(0.1), {"pattern": Kit.Pattern.CONCRETE})
	var red := Color(0.7, 0.2, 0.15)
	for x in [63.5, 72.5]:
		for z in [-8.0, -14.0]:
			k.box(world, Vector3(0.3, 4.6, 0.3), Vector3(x, 2.3, z), Color(0.85, 0.85, 0.82), {"solid": true})
	k.box(world, Vector3(11, 0.5, 8), Vector3(68, 4.85, -11), Color(0.85, 0.85, 0.82))
	for s in [-1.0, 1.0]:
		k.box(world, Vector3(11.1, 0.35, 0.05), Vector3(68, 4.8, -11 + s * 4.02), red)
	k.words(world, "SAVOY", Vector3(68, 4.8, -6.95), Vector3.ZERO, 0.03, Color(0.95, 0.92, 0.8))
	# One canopy light still hanging by its wire.
	k.beam(world, Vector3(70, 4.6, -10), Vector3(70.3, 3.6, -10.2), 0.015, Color(0.1, 0.1, 0.1))
	k.box(world, Vector3(0.6, 0.08, 0.3), Vector3(70.3, 3.55, -10.2), Color(0.8, 0.8, 0.75), {"rot": Vector3(0, 0, 30)})
	# Pumps.
	for x in [66.0, 70.0]:
		k.box(world, Vector3(2.4, 0.2, 1.0), Vector3(x, 0.1, -11), Kit.CONCRETE)
		var p := k.group(world, Vector3(x, 0.2, -11), 0)
		k.box(p, Vector3(0.8, 1.6, 0.5), Vector3(0, 0.8, 0), red, {"solid": true})
		k.box(p, Vector3(0.6, 0.35, 0.02), Vector3(0, 1.25, 0.26), Color(0.15, 0.15, 0.15))
		k.words(p, "0.00", Vector3(0, 1.25, 0.275), Vector3.ZERO, 0.005, Color(0.8, 0.85, 0.5))
		k.box(p, Vector3(0.82, 0.25, 0.52), Vector3(0, 1.72, 0), Color(0.9, 0.88, 0.8))
		k.beam(p, Vector3(0.42, 1.0, 0), Vector3(0.6, 0.15, 0.4), 0.04, Color(0.1, 0.1, 0.1))
	var pump := k.thing(world, Vector3(0.9, 1.8, 0.6), Vector3(66, 1.1, -11), "Try the pump", [
		"You squeeze the nozzle. A sigh of air and a smell of petrol, a long way down.",
		"Dry. The counter still says 0.00, like it's sorry.",
	])
	_area(pump, "savoy")
	_ice_chest(Vector3(72.8, 0, -16.4))
	_crashed_van()
	_shop()


func _ice_chest(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	k.box(g, Vector3(1.4, 1.0, 0.7), Vector3(0, 0.5, 0), Color(0.85, 0.87, 0.9), {"solid": true})
	k.words(g, "ICE", Vector3(0, 0.6, 0.36), Vector3.ZERO, 0.012, Color(0.2, 0.4, 0.7))
	_search(world, Vector3(1.4, 0.4, 0.7), pos + Vector3(0, 1.0, 0), "Open the ice chest",
		"No ice for months. Just water at the bottom, and two sealed bottles floating in it.", ["water", "water"], "savoy")


func _crashed_van() -> void:
	var cars := Cars.new(k)
	var van := cars.build(world, "van", Vector3(58.6, 0, -13.2), 72, {
		"color": Color(0.85, 0.62, 0.2), "interior": Color(0.3, 0.3, 0.32), "plate": "MR 19 PKT",
		"crashed": true, "side_door_open": true, "rust": 0.3, "dirt": 0.5,
		"prompt": "Search the delivery van",
		"lines": [
			"A parcel van, nose-first into the verge. The back is a mess of split boxes. In one, still in its packaging: a crowbar.",
			"Parcels for people on Alder Street. One is addressed to you. It's the kettle descaler you ordered. You leave it.",
		],
		"gives": ["crowbar"],
		"journal": "Found a crowbar in the crashed parcel van at the Savoy. Things that were shut are about to be less shut.",
		"cargo": [
			["box", Vector3(-1.8, 0.4, -0.5), 0.0, Color.WHITE],
			["box", Vector3(-1.6, 0.7, -0.5), 20.0, Color.WHITE],
			["box", Vector3(-1.3, 0.4, 0.4), 40.0, Color.WHITE],
			["box", Vector3(-2.2, 0.4, 0.5), 5.0, Color.WHITE],
		],
	})
	_area(van.get_child(0), "savoy")
	for s in [-1.0, 1.0]:
		k.words(van, "PARCELKIT", Vector3(-0.9, 1.55, s * 0.99), Vector3(0, 0.0 if s > 0 else 180.0, 0), 0.008, Color(0.25, 0.2, 0.15))
	# Parcels thrown out on the grass.
	for i in 5:
		f.cardboard_box(world, Vector3(61.5 + k.rng.randf_range(-1, 1), 0, -17 + k.rng.randf_range(-1, 1)), k.rng.randf() * 360)


func _shop() -> void:
	var h := houses.shell(world, Vector3(70, 0, -21), {
		"w": 11.0, "d": 7.0, "h": 3.0, "walls": Color(0.82, 0.8, 0.74), "pattern": Kit.Pattern.PLAIN,
		"inside": Color(0.85, 0.84, 0.78), "floor": Color(0.6, 0.6, 0.58), "roof": Color(0.3, 0.3, 0.32),
		"door_x": -2.3, "door": "open", "door_color": Color(0.7, 0.2, 0.15), "porch": false, "chimney": false,
		"partition": [2.5, -1.5],
		"windows": [["front", -4.3, "ok", null], ["front", 0.5, "broken", null]],
	})
	k.box(h, Vector3(11.2, 0.6, 0.1), Vector3(0, 3.0, 3.62), Color(0.7, 0.2, 0.15))
	k.words(h, "SAVOY  GARAGE  &  STORES", Vector3(0, 3.0, 3.68), Vector3.ZERO, 0.009, Color(0.95, 0.92, 0.8))
	k.words(h, "PRIVATE", Vector3(2.4, 2.4, -1.5), Vector3(0, -90, 0), 0.006, Color(0.6, 0.15, 0.1))

	# Shop floor: shelves, the counter, the drinks fridge.
	for z in [-0.3, 1.6]:
		_shop_shelf(h, Vector3(-2.4, 0, z))
	_search(h, Vector3(2.6, 1.5, 0.6), Vector3(-2.4, 0.75, -0.3), "Search the shelves",
		"Most of it's long gone. Behind the motor oil: two tins of soup somebody missed.", ["soup", "soup"], "savoy")
	_search(h, Vector3(2.6, 1.5, 0.6), Vector3(-2.4, 0.75, 1.6), "Search the sweets aisle",
		"The sweets went first, of course. But at the very back, a packet of custard creams and a tin of peaches.", ["biscuits", "peaches"], "savoy")
	k.box(h, Vector3(2.4, 1.0, 0.6), Vector3(0.6, 0.5, 2.3), Color(0.6, 0.35, 0.22), {"solid": true})  # counter
	k.box(h, Vector3(2.5, 0.05, 0.7), Vector3(0.6, 1.02, 2.3), Kit.WOOD_LIGHT)
	var till := k.thing(h, Vector3(0.4, 0.3, 0.35), Vector3(1.3, 1.2, 2.3), "Look at the till", [
		"The till drawer is open. £43.20 inside. Nobody took it. What would you even buy?",
		"You close the drawer. It feels like the polite thing to do.",
	])
	k.box(till, Vector3(0.4, 0.25, 0.35), Vector3.ZERO, Color(0.2, 0.2, 0.22))
	_area(till, "savoy")
	k.box(h, Vector3(0.2, 0.6, 0.02), Vector3(-0.2, 1.4, 2.62), Kit.PAPER)
	var card := _find(h, Vector3(0.0, 1.05, 2.25), "memory", "A postcard from the Savoy", "Pick up the postcard", [
		"A postcard of this forecourt, all new paint, 1971. On the back: \"Our first day! The pumps work, the kettle works, we're rich. - Ray & Lou\"",
	], [], "Ray and Lou opened the Savoy in 1971. I took their postcard. I'll keep it safe.")
	k.box(card, Vector3(0.14, 0.01, 0.1), Vector3(0, 0.01, 0), Color(0.5, 0.6, 0.7), {"rot": Vector3(0, 20, 0)})
	# Drinks fridge on the left wall, door open and dark.
	var fridge := k.group(h, Vector3(-5.05, 0, 0.8), 90)
	k.box(fridge, Vector3(1.2, 2.0, 0.7), Vector3(0, 1.0, 0), Color(0.2, 0.2, 0.22), {"solid": true})
	k.pane(fridge, Vector3(1.0, 1.7, 0.02), Vector3(0, 1.05, 0.36), Vector3.ZERO, 0.4)
	_search(h, Vector3(0.7, 2.0, 1.2), Vector3(-5.05, 1.0, 0.8), "Open the drinks fridge",
		"Warm cans of fizzy orange, mostly burst. One bottle of water rolled to the back.", ["water"], "savoy")
	f.cardboard_box(h, Vector3(-4.6, 0, -2.8), 15, "CRISPS")
	f.cardboard_box(h, Vector3(-4.0, 0, -3.0), -10)
	f.shards(h, Vector3(0.5, 0, 2.8), 0.6)
	f.chair(h, Vector3(1.4, 0, 3.1), 170, Kit.WOOD_DARK)

	# The back room, behind the jammed door.
	var lock := _lock(h, Vector3(0.25, 2.1, 0.9), Vector3(2.5, 1.05, -1.5), "Try the back room door", "The garage back room", "crowbar", [
		"PRIVATE. The door is locked, and the frame has swollen shut.",
		"You shoulder it. It doesn't care.",
		"Locked and jammed. You'd need something to lever it with.",
	], "You get the crowbar into the gap and lean. The frame splits with a crack like a gunshot, and the door swings in.",
		"Levered open the back room at the Savoy.")
	var hinge := k.group(lock, Vector3(0, -1.05, 0.45), 0)
	k.box(hinge, Vector3(0.05, 2.05, 0.88), Vector3(0, 1.03, -0.44), Color(0.55, 0.4, 0.3))
	k.box(hinge, Vector3(0.06, 0.05, 0.12), Vector3(-0.04, 1.0, -0.78), Color(0.75, 0.65, 0.35))
	lock.swing = hinge
	lock.swing_angle = -100.0
	# Ray's workshop: a workbench, a camp bed, his notes.
	k.box(h, Vector3(2.2, 0.9, 0.7), Vector3(4.4, 0.45, -3.0), Kit.WOOD, {"solid": true})
	k.box(h, Vector3(2.3, 0.06, 0.8), Vector3(4.4, 0.92, -3.0), Kit.WOOD_LIGHT)
	k.box(h, Vector3(2.0, 1.0, 0.04), Vector3(4.4, 1.6, -3.38), Color(0.55, 0.45, 0.32))  # pegboard
	for i in 6:
		k.box(h, Vector3(0.05, 0.3, 0.04), Vector3(3.6 + i * 0.3, 1.6, -3.33), [Kit.METAL, Kit.RUST, Color(0.7, 0.2, 0.15)][i % 3])
	k.box(h, Vector3(0.8, 0.05, 0.12), Vector3(4.6, 0.98, -2.8), Color(0.75, 0.15, 0.12), {"rot": Vector3(0, 20, 0)})  # the bolt cutters
	_search(h, Vector3(2.2, 0.8, 0.8), Vector3(4.4, 1.1, -3.0), "Search the workbench",
		"Ray's tools, oiled and hung in order. On the bench: a pair of red bolt cutters, and batteries in a jam jar.", ["bolt_cutters", "batteries"], "savoy",
		"Found bolt cutters in the Savoy back room. Every padlock on Mill Road just became a question.")
	f.bed(h, Vector3(4.6, 0, 0.6), 0, 0.8, Kit.FABRIC_GREEN, false)
	var note := k.thing(h, Vector3(0.3, 0.1, 0.3), Vector3(3.3, 0.72, 2.6), "Read Ray's note", [
		"\"Lou - gone to the allotment to get the last of the tomatoes, then the train. Keys to the sheds are on the hook. Love you. R\"",
		"There's no key on the hook.",
	])
	note.journal = "Ray from the Savoy went to the allotments for the last tomatoes, then to the train. The 6:40 is still on the crossing."
	_area(note, "savoy")
	f.crate(h, Vector3(3.3, 0, 2.6), 0, 0.8)
	k.box(note, Vector3(0.2, 0.01, 0.28), Vector3(0, -0.06, 0), Kit.PAPER)
	f.cardboard_box(h, Vector3(5.0, 0, 2.9), 5, "SPARES")

	# Out the back: bins, a tyre stack, and the first Ranger cache.
	for i in 4:
		k.cyl(world, 0.35, 0.22, Vector3(66.5, 0.11 + i * 0.22, -25.6), Color(0.1, 0.1, 0.1), {"sides": 9})
	_cache(world, Vector3(73.2, 0, -26.0), "Behind the Savoy", "A green tin under the back window, painted with an R. Inside, a ration pack and a note: \"If you're reading this, you're still here. Good. There are six of these. Eat the chocolate first. - Ranger Wren\"", ["rations", "batteries"])


func _shop_shelf(parent: Node, pos: Vector3) -> void:
	var g := k.group(parent, pos, 0)
	k.box(g, Vector3(2.6, 1.5, 0.08), Vector3(0, 0.75, 0), Kit.METAL.lightened(0.2), {"solid": true})
	for y in [0.1, 0.55, 1.0, 1.45]:
		k.box(g, Vector3(2.6, 0.04, 0.6), Vector3(0, y, 0), Kit.METAL.lightened(0.3))
	for i in 14:
		var side := -1.0 if i % 2 else 1.0
		var y: float = [0.12, 0.57, 1.02][k.rng.randi() % 3]
		var col: Color = [Color(0.7, 0.2, 0.15), Color(0.85, 0.8, 0.3), Color(0.3, 0.45, 0.6), Color(0.85, 0.85, 0.82)][k.rng.randi() % 4]
		k.cyl(g, 0.05, 0.12, Vector3(k.rng.randf_range(-1.2, 1.2), y + 0.06, side * 0.15), col, {"sides": 6})


# --- The allotments ------------------------------------------------------------------------

func _allotments() -> void:
	# Fence, with the gate standing open.
	_post_and_wire(Vector3(54, 0, 8.5), Vector3(59, 0, 8.5))
	_post_and_wire(Vector3(61.4, 0, 8.5), Vector3(94, 0, 8.5))
	_post_and_wire(Vector3(54, 0, 8.5), Vector3(54, 0, 27.5))
	_post_and_wire(Vector3(94, 0, 8.5), Vector3(94, 0, 27.5))
	var gate := k.group(world, Vector3(59.1, 0, 8.5), -110)
	for y in [0.3, 0.7, 1.1]:
		k.box(gate, Vector3(2.2, 0.08, 0.05), Vector3(1.1, y, 0), Kit.WOOD_LIGHT)
	k.beam(gate, Vector3(0.1, 0.3, 0), Vector3(2.1, 1.1, 0), 0.06, Kit.WOOD_LIGHT)
	var board := k.thing(world, Vector3(1.2, 0.9, 0.3), Vector3(62.6, 1.3, 8.2), "Read the noticeboard", [
		"MILL ROAD ALLOTMENTS. Watering rota: Mon Ray, Tue Lou, Wed Mrs Adeyemi, Thu \"whoever\", Fri the rain.",
		"A newer notice, typed: \"ALL PLOT HOLDERS. Sheds will be locked for the duration. Produce may be requisitioned.\"",
		"Someone has written under it: \"Over my dead body. - Lou\"",
	])
	board.journal = "The Mill Road allotments. The sheds are padlocked \"for the duration\". The greenhouse still has tomatoes in it."
	_area(board, "allotments")
	k.box(board, Vector3(1.2, 0.8, 0.05), Vector3.ZERO, Color(0.25, 0.32, 0.22))
	for x in [-0.55, 0.55]:
		k.box(world, Vector3(0.08, 1.7, 0.08), Vector3(62.6 + x, 0.85, 8.2), Kit.WOOD_DARK)
	# Raised beds: most gone to weeds, a few still green.
	var soil := Color(0.3, 0.24, 0.18)
	for p: Vector3 in [Vector3(58, 0, 12), Vector3(58, 0, 17), Vector3(63, 0, 12), Vector3(63, 0, 17), Vector3(77, 0, 18.5),
			Vector3(84, 0, 12), Vector3(84, 0, 17), Vector3(89, 0, 12), Vector3(89, 0, 17), Vector3(77, 0, 10.5)]:
		k.box(world, Vector3(3.2, 0.3, 1.8), p + Vector3(0, 0.15, 0), Kit.WOOD, {"solid": true})
		k.box(world, Vector3(3.0, 0.04, 1.6), p + Vector3(0, 0.3, 0), soil)
		var green := k.rng.randf() < 0.5
		for i in 6:
			var q := p + Vector3(-1.2 + (i % 3) * 1.2, 0.35, -0.4 + (i / 3) * 0.8)
			if green:
				k.ball(world, Vector3(0.45, 0.3, 0.45), q + Vector3(0, 0.08, 0), Kit.PLANT.lerp(Color(0.4, 0.5, 0.3), k.rng.randf()), {"sides": 6})
			else:
				k.beam(world, q, q + Vector3(k.rng.randf_range(-0.2, 0.2), 0.45, k.rng.randf_range(-0.2, 0.2)), 0.03, Kit.DEAD_GRASS.darkened(0.2))
	# Bean poles, a water butt and a wheelbarrow.
	for i in 4:
		var b := Vector3(84 + i * 0.6, 0, 21)
		k.beam(world, b + Vector3(0, 0, -0.4), b + Vector3(0, 2.0, 0), 0.03, Kit.WOOD_LIGHT)
		k.beam(world, b + Vector3(0, 0, 0.4), b + Vector3(0, 2.0, 0), 0.03, Kit.WOOD_LIGHT)
	k.cyl(world, 0.4, 1.0, Vector3(63.2, 0.5, 21.2), Color(0.2, 0.28, 0.2), {"sides": 8, "solid": true})
	var barrow := k.group(world, Vector3(72, 0, 11), 30)
	k.box(barrow, Vector3(1.0, 0.35, 0.65), Vector3(0, 0.45, 0), Kit.FABRIC_GREEN)
	k.cyl(barrow, 0.18, 0.08, Vector3(0.6, 0.18, 0), Color(0.1, 0.1, 0.1), {"rot": Vector3(90, 0, 0), "sides": 8})
	for s in [-0.25, 0.25]:
		k.beam(barrow, Vector3(0.3, 0.35, s), Vector3(-1.0, 0.55, s), 0.04, Kit.WOOD)
	_greenhouse(Vector3(70, 0, 16))
	_scarecrow(Vector3(80, 0, 14))
	var x := 0
	for sx in [58.0, 66.0, 74.0, 82.0, 90.0]:
		_shed(Vector3(sx, 0, 24), x)
		x += 1


func _greenhouse(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	var frame := Color(0.85, 0.85, 0.82)
	var w := 6.0
	var d := 4.0
	var h := 2.2
	k.box(g, Vector3(w, 0.05, d), Vector3(0, 0.03, 0), Kit.CONCRETE)
	for x in [-3.0, -1.5, 0.0, 1.5, 3.0]:
		for z in [-2.0, 2.0]:
			k.box(g, Vector3(0.06, h, 0.06), Vector3(x, h / 2.0, z), frame)
		k.beam(g, Vector3(x, h, -2.0), Vector3(x, h + 0.9, 0.0), 0.05, frame)
		k.beam(g, Vector3(x, h, 2.0), Vector3(x, h + 0.9, 0.0), 0.05, frame)
	k.box(g, Vector3(w, 0.06, 0.06), Vector3(0, h + 0.9, 0), frame)
	# Glass, a few panes broken. The door is on the north side, toward the gate.
	for i in 4:
		var cx := -2.25 + i * 1.5
		k.pane(g, Vector3(1.44, h - 0.1, 0.02), Vector3(cx, h / 2.0, 2.0), Vector3.ZERO, 0.45)
		if i != 1:
			k.pane(g, Vector3(1.44, h - 0.1, 0.02), Vector3(cx, h / 2.0, -2.0), Vector3.ZERO, 0.45)
		for s in [-1.0, 1.0]:
			k.pane(g, Vector3(1.44, 0.02, 2.2), Vector3(cx, h + 0.45, s * 1.0), Vector3(-s * 24.2, 0, 0), 0.5)
	for s in [-1.0, 1.0]:
		k.pane(g, Vector3(0.02, h - 0.1, d - 0.1), Vector3(s * 3.0, h / 2.0, 0), Vector3.ZERO, 0.45)
	k.blocker(g, Vector3(w, h, 0.1), Vector3(0, h / 2.0, 2.0))
	k.blocker(g, Vector3(0.1, h, d), Vector3(-3.0, h / 2.0, 0))
	k.blocker(g, Vector3(0.1, h, d), Vector3(3.0, h / 2.0, 0))
	k.blocker(g, Vector3(1.5, h, 0.1), Vector3(-2.25, h / 2.0, -2.0))
	k.blocker(g, Vector3(3.0, h, 0.1), Vector3(1.5, h / 2.0, -2.0))
	# Benches with tomato plants, still fruiting.
	var ripe: Array = []
	for z in [-1.3, 1.3]:
		k.box(g, Vector3(5.0, 0.8, 0.8), Vector3(0, 0.4, z), Kit.WOOD, {"solid": true})
		for i in 6:
			var p := Vector3(-2.1 + i * 0.85, 0.8, z)
			k.cyl(g, 0.15, 0.25, p + Vector3(0, 0.12, 0), Color(0.55, 0.3, 0.2), {"sides": 6})
			k.beam(g, p + Vector3(0, 0.2, 0), p + Vector3(0.05, 1.2, 0), 0.02, Kit.WOOD_LIGHT)
			k.ball(g, Vector3(0.45, 0.65, 0.4), p + Vector3(0, 0.7, 0), Kit.PLANT.lightened(0.05), {"sides": 6})
			for j in 2:
				ripe.append(k.ball(g, Vector3(0.1, 0.09, 0.1), p + Vector3(k.rng.randf_range(-0.18, 0.18), 0.5 + j * 0.25, k.rng.randf_range(-0.2, 0.2)), Color(0.8, 0.22, 0.12), {"sides": 5}))
	var crop: StaticBody3D = k.thing(g, Vector3(5.0, 1.0, 0.8), Vector3(0, 1.3, -1.3), "Pick tomatoes", [
		"Tomatoes. Real ones, red and warm from the glass. Someone kept these watered for a long time.",
		"A few more have ripened since yesterday.",
	], Harvest)
	crop.ripe = ripe
	crop.journal = "The greenhouse at the allotments still has tomatoes. A few ripen every day. I'll come back."
	_area(crop, "allotments")
	var gloves := _find(g, Vector3(-2.2, 0.82, 1.3), "memory", "Lou's gardening gloves", "Pick up the gloves", [
		"Flowery gardening gloves, the fingers worn through. LOU is written inside the cuff.",
	], [], "Lou's gardening gloves, from the greenhouse. I think she kept the tomatoes going after Ray left.")
	k.box(gloves, Vector3(0.22, 0.04, 0.14), Vector3(0, 0.01, 0), Color(0.75, 0.45, 0.55), {"rot": Vector3(0, 30, 0)})
	k.cyl(g, 0.2, 0.35, Vector3(2.6, 0.18, -2.5), Color(0.7, 0.2, 0.15), {"top": 0.15, "sides": 8})  # watering can


func _scarecrow(pos: Vector3) -> void:
	var g := k.group(world, pos, 200)
	k.cyl(g, 0.05, 2.0, Vector3(0, 1.0, 0), Kit.WOOD, {"sides": 5})
	k.box(g, Vector3(1.6, 0.06, 0.06), Vector3(0, 1.5, 0), Kit.WOOD)
	k.box(g, Vector3(0.55, 0.8, 0.3), Vector3(0, 1.3, 0), Color(0.3, 0.35, 0.45))  # coat
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.55, 0.16, 0.18), Vector3(s * 0.5, 1.5, 0), Color(0.3, 0.35, 0.45))
	k.ball(g, Vector3(0.36, 0.4, 0.34), Vector3(0, 1.95, 0), Color(0.75, 0.65, 0.45), {"sides": 6})
	k.cyl(g, 0.28, 0.04, Vector3(0, 2.15, 0), Color(0.35, 0.28, 0.2), {"sides": 8})
	k.cyl(g, 0.15, 0.18, Vector3(0, 2.25, 0), Color(0.35, 0.28, 0.2), {"sides": 8})
	k.box(g, Vector3(0.6, 0.12, 0.31), Vector3(0, 1.0, 0), Kit.FABRIC_RED)  # someone gave him a scarf
	k.blocker(world, Vector3(0.4, 2, 0.4), pos + Vector3(0, 1, 0))
	var look := k.thing(world, Vector3(0.6, 1.0, 0.6), pos + Vector3(0, 1.6, 0), "Look at the scarecrow", [
		"A scarecrow in a good wool coat. Someone has knitted him a scarf since the strikes. The crows face north anyway.",
	])
	_area(look, "allotments")
	_cache(world, pos + Vector3(0.6, 0, 0.8), "The scarecrow's cache", "Tucked between the scarecrow's boots, half buried: a Ranger tin. \"He's a good guard. Better than me. - W\"", ["rations", "matches"], 20)


func _shed(pos: Vector3, i: int) -> void:
	# Faces north (-z), toward the path. The padlocked door is in the front wall.
	var colors := [Color(0.35, 0.45, 0.4), Color(0.55, 0.42, 0.3), Color(0.4, 0.42, 0.55), Color(0.6, 0.55, 0.35), Color(0.5, 0.3, 0.28)]
	var col: Color = colors[i]
	var g := k.group(world, pos, 180)
	var w := 3.0
	var d := 2.4
	var h := 2.1
	var dx := 0.4  # door offset
	k.box(g, Vector3(w, 0.06, d), Vector3(0, 0.03, 0), Kit.WOOD_DARK)
	k.box(g, Vector3(w, h + 0.3, 0.1), Vector3(0, (h + 0.3) / 2.0, -d / 2.0), col, {"solid": true, "pattern": Kit.Pattern.PLANKS})
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.1, h + 0.15, d), Vector3(s * w / 2.0, (h + 0.15) / 2.0, 0), col, {"solid": true, "pattern": Kit.Pattern.PLANKS})
	# Front wall with the door gap.
	var left := -w / 2.0
	var dl := dx - 0.45
	var dr := dx + 0.45
	k.box(g, Vector3(dl - left, h, 0.1), Vector3((left + dl) / 2.0, h / 2.0, d / 2.0), col, {"solid": true, "pattern": Kit.Pattern.PLANKS})
	k.box(g, Vector3(w / 2.0 - dr, h, 0.1), Vector3((dr + w / 2.0) / 2.0, h / 2.0, d / 2.0), col, {"solid": true, "pattern": Kit.Pattern.PLANKS})
	k.box(g, Vector3(0.9, 0.2, 0.1), Vector3(dx, h - 0.1, d / 2.0), col, {"solid": true})
	k.box(g, Vector3(w + 0.3, 0.08, d + 0.4), Vector3(0, h + 0.2, 0), Color(0.18, 0.18, 0.2), {"rot": Vector3(-6, 0, 0)})  # felt roof
	k.box(g, Vector3(0.5, 0.4, 0.04), Vector3(-0.8, 1.3, d / 2.0 + 0.04), Kit.GLASS)
	k.words(g, str(i + 1), Vector3(-0.8, 1.75, d / 2.0 + 0.06), Vector3.ZERO, 0.01, Color(0.92, 0.9, 0.82))
	var names := ["shed 1 (Ray & Lou's)", "shed 2 (Mrs Adeyemi's)", "shed 3", "shed 4", "shed 5"]
	var lock := _lock(g, Vector3(0.9, h - 0.2, 0.2), Vector3(dx, (h - 0.2) / 2.0, d / 2.0), "Try the shed door", "Allotment " + names[i], "bolt_cutters", [
		"Padlocked. A good, heavy padlock, the kind you buy when you mean it.",
		"Still padlocked. You'd need to cut it.",
	], "The bolt cutters bite through the shackle. The padlock drops into the grass and the door creaks open.")
	var hinge := k.group(lock, Vector3(-0.45, -(h - 0.2) / 2.0, 0.03), 0)
	k.box(hinge, Vector3(0.88, h - 0.22, 0.05), Vector3(0.44, (h - 0.2) / 2.0, 0), col.darkened(0.15), {"pattern": Kit.Pattern.PLANKS})
	var pl := _padlock(lock, Vector3(0.38, 0.0, 0.08))
	lock.swing = hinge
	lock.swing_angle = -100.0
	lock.hide_on_open = [pl]
	_area(lock, "allotments")
	# Inside: a shelf, and what each plot holder left.
	k.box(g, Vector3(2.6, 0.04, 0.35), Vector3(0, 1.2, -d / 2.0 + 0.25), Kit.WOOD)
	for j in 5:
		k.cyl(g, 0.06, 0.14, Vector3(-1.0 + j * 0.45, 1.29, -d / 2.0 + 0.25), [Kit.RUST, Color(0.3, 0.45, 0.3), Kit.PAPER][j % 3], {"sides": 6})
	k.beam(g, Vector3(1.3, 0, -0.9), Vector3(1.35, 1.5, -1.05), 0.04, Kit.WOOD)  # a spade
	k.box(g, Vector3(0.2, 0.3, 0.04), Vector3(1.3, 0.15, -0.88), Kit.METAL)
	match i:
		0:
			_search(g, Vector3(2.6, 0.5, 0.5), Vector3(0, 1.3, -d / 2.0 + 0.25), "Search Ray and Lou's shed",
				"Seed packets in a biscuit tin, labelled in two different handwritings. And a candle, for the dark evenings.", ["seeds", "candle"], "allotments",
				"Ray and Lou's shed. Seed packets labelled in both their handwriting. Runner beans, marigolds. Next year's garden.")
		1:
			_cache(g, Vector3(-0.7, 0, -0.3), "In the allotment sheds", "A Ranger tin on the floor of the shed, under a sack. \"Lock it behind you. Not everyone's as nice as you. - W\"", ["rations", "candle", "candle"])
		2:
			_search(g, Vector3(2.6, 0.5, 0.5), Vector3(0, 1.3, -d / 2.0 + 0.25), "Search the shed shelf",
				"Slug pellets, twine, a tin of soup and a box of matches someone was saving for something.", ["soup", "matches"], "allotments")
		3:
			var rosette := _find(g, Vector3(0.6, 0, -0.5), "memory", "A prize rosette", "Pick up the rosette", [
				"A faded blue rosette: MILL ROAD SHOW, 1ST PRIZE, MARROWS. Pinned under it, a photo of an enormous marrow and a very proud man.",
			], [], "A first prize rosette for marrows from the Mill Road Show. The man in the photo looks like he's never been happier.")
			k.cyl(rosette, 0.09, 0.02, Vector3(0, 0.06, 0), Color(0.25, 0.4, 0.75), {"rot": Vector3(90, 0, 0), "sides": 8})
		4:
			k.box(g, Vector3(0.5, 0.05, 0.5), Vector3(0.0, 0.45, 0.0), Color(0.55, 0.3, 0.25))  # deckchair
			k.beam(g, Vector3(-0.25, 0.45, -0.25), Vector3(-0.25, 1.0, -0.6), 0.05, Color(0.55, 0.3, 0.25), {"depth": 0.5})
			_search(g, Vector3(0.8, 1.0, 0.8), Vector3(0.0, 0.5, -0.2), "Look at the deckchair",
				"A deckchair facing the window, a flask, and a crossword finished in pen. A tea caddy, still half full.", ["tea"], "allotments",
				"Someone sat in shed 5 and watched the train through the window. They finished the crossword.")


# --- The railway ---------------------------------------------------------------------------

func _railway() -> void:
	var z0 := -47.5
	var z1 := 27.5
	var L := z1 - z0
	var cz := (z0 + z1) / 2.0
	k.box(world, Vector3(4.6, 0.12, L), Vector3(RAIL_X, 0.06, cz), Color(0.4, 0.38, 0.35), {"pattern": Kit.Pattern.CONCRETE})  # ballast
	var sleeper := BoxMesh.new()
	sleeper.size = Vector3(2.4, 0.08, 0.22)
	var xf: Array = []
	var z := z0
	while z < z1:
		if absf(z) > 3.6:
			xf.append(Transform3D(Basis(), Vector3(RAIL_X, 0.14, z)))
		z += 0.65
	k.scatter(world, sleeper, Color(0.28, 0.22, 0.18), xf)
	for s in [-0.72, 0.72]:
		k.box(world, Vector3(0.08, 0.1, L), Vector3(RAIL_X + s, 0.22, cz), Color(0.45, 0.35, 0.3))
		k.box(world, Vector3(0.06, 0.02, L), Vector3(RAIL_X + s, 0.28, cz), Kit.METAL.lightened(0.2))
	# The crossing: rubber panels between the rails, lights, barriers up.
	k.box(world, Vector3(4.6, 0.04, 7), Vector3(RAIL_X, 0.2, 0), Color(0.18, 0.18, 0.18), {"pattern": Kit.Pattern.TILES})
	for p: Vector3 in [Vector3(96.8, 0, -4.4), Vector3(103.2, 0, 4.4)]:
		var g := k.group(world, p, 0.0 if p.z < 0 else 180.0)
		k.cyl(g, 0.08, 3.0, Vector3(0, 1.5, 0), Color(0.85, 0.85, 0.82), {"sides": 6})
		for r in [45.0, -45.0]:
			k.box(g, Vector3(1.2, 0.18, 0.03), Vector3(0, 2.7, 0.1), Color(0.9, 0.9, 0.88), {"rot": Vector3(0, 0, r)})
		k.box(g, Vector3(0.9, 0.35, 0.15), Vector3(0, 2.05, 0.1), Color(0.1, 0.1, 0.1))
		for x in [-0.3, 0.3]:
			k.cyl(g, 0.12, 0.05, Vector3(x, 2.05, 0.2), Color(0.5, 0.1, 0.08), {"rot": Vector3(90, 0, 0), "sides": 8})
		k.beam(g, Vector3(0.3, 1.1, 0), Vector3(1.2, 6.0, 0), 0.12, Color(0.9, 0.9, 0.88))  # barrier arm, stuck up
	# The railway fence, with the crossing gate chained across the road.
	_post_and_wire(Vector3(96, 0, -47.5), Vector3(96, 0, -4.2), 1.6, Kit.CONCRETE)
	_post_and_wire(Vector3(96, 0, 4.2), Vector3(96, 0, 27.5), 1.6, Kit.CONCRETE)
	var lock := _lock(world, Vector3(0.3, 1.6, 8.4), Vector3(96, 0.8, 0), "Try the crossing gate", "The level crossing gate", "bolt_cutters", [
		"The crossing gates are chained together across the road. A sign: DANGER - DO NOT CROSS THE LINE.",
		"The chain is thick and new. Someone wanted people to stay off the tracks.",
		"Still chained. You'd need to cut it.",
	], "You cut the chain. It slithers off the gate and coils on the road. The gates swing apart.",
		"Cut the chain on the crossing gate. The 6:40 is right there.")
	_area(lock, "train")
	var halves: Array = []
	for s in [-1.0, 1.0]:
		var hinge := k.group(lock, Vector3(0, -0.8, s * 4.1), 0)
		for y in [0.3, 0.8, 1.3]:
			k.box(hinge, Vector3(0.06, 0.1, 4.0), Vector3(0, y, -s * 2.0), Color(0.85, 0.85, 0.82))
		k.box(hinge, Vector3(0.06, 0.25, 4.0), Vector3(0, 0.8, -s * 2.0), Color(0.75, 0.15, 0.1))
		halves.append(hinge)
	var chain := k.group(lock, Vector3(0, 0, 0), 0)
	for i in 6:
		k.ring(chain, 0.025, 0.05, Vector3(0.08, -0.2 + i * 0.08, 0), Kit.METAL.darkened(0.2), Vector3(0, 90 * (i % 2), 90))
	_padlock(chain, Vector3(0.1, -0.3, 0))
	lock.hide_on_open = [chain]
	lock.swing = halves[0]
	lock.swing2 = halves[1]
	lock.swing_angle = 95.0


func _train() -> void:
	_locomotive(-26.0)
	_carriage(-12.5, 1)
	_carriage(0.5, 2)
	_carriage(13.5, 3)
	_guard_van(24.5)
	# The trail of things dropped by people walking north along the track.
	var cols := [Color(0.3, 0.35, 0.5), Color(0.5, 0.2, 0.18), Color(0.6, 0.5, 0.3), Kit.FABRIC_GREEN]
	for i in 7:
		var p := Vector3(RAIL_X - 2.0 + k.rng.randf_range(-0.6, 0.6), 0.12, -36.0 - i * 1.6)
		var g := k.group(world, p, k.rng.randf() * 360)
		if i % 3 == 0:
			k.box(g, Vector3(0.45, 0.22, 0.6), Vector3(0, 0.11, 0), cols[i % 4])  # suitcase on its side
		elif i % 3 == 1:
			k.box(g, Vector3(0.1, 0.08, 0.25), Vector3(0, 0.04, 0), Color(0.15, 0.12, 0.1))  # a shoe
		else:
			k.box(g, Vector3(0.6, 0.04, 0.4), Vector3(0, 0.02, 0), Kit.FABRIC_RED.darkened(0.2))  # a coat


## One passenger carriage, 12 m long, its doors on the west side open.
func _carriage(cz: float, n: int) -> void:
	var g := k.group(world, Vector3(RAIL_X, 0, cz), 0)
	var L := 12.0
	var fl := 1.1
	_underframe(g, L)
	k.box(g, Vector3(2.8, 0.1, L), Vector3(0, fl - 0.05, 0), Color(0.3, 0.3, 0.3), {"solid": true})
	k.box(g, Vector3(2.6, 0.02, L - 0.2), Vector3(0, fl + 0.01, 0), Color(0.35, 0.3, 0.4), {"pattern": Kit.Pattern.TILES})
	var doors := [-L / 2.0 + 1.0, L / 2.0 - 1.0]
	_body_side(g, -1.0, L, fl, doors, true)
	_body_side(g, 1.0, L, fl, doors, false)
	_ends_and_roof(g, L, fl)
	k.words(g, "C%d" % n, Vector3(-1.46, fl + 1.6, -L / 2.0 + 2.2), Vector3(0, -90, 0), 0.012, CREAM)
	# Bays of seats with tables between.
	var seat := Color(0.3, 0.35, 0.55)
	var z := -L / 2.0 + 2.2
	var bay := 0
	while z < L / 2.0 - 3.6:
		for s in [-1.0, 1.0]:
			for face in [-1.0, 1.0]:
				var sz: float = z + 0.9 + face * 0.65
				k.box(g, Vector3(0.95, 0.45, 0.5), Vector3(s * 0.85, fl + 0.22, sz), seat, {"solid": true, "pattern": Kit.Pattern.WALLPAPER})
				k.box(g, Vector3(0.95, 0.75, 0.12), Vector3(s * 0.85, fl + 0.75, sz + face * 0.28), seat, {"pattern": Kit.Pattern.WALLPAPER})
			k.box(g, Vector3(0.7, 0.04, 0.6), Vector3(s * 1.05, fl + 0.72, z + 0.9), Color(0.55, 0.5, 0.42))
			k.box(g, Vector3(0.06, 0.7, 0.06), Vector3(s * 0.85, fl + 0.36, z + 0.9), Kit.METAL)
		z += 1.8
		bay += 1
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.4, 0.03, L - 2.6), Vector3(s * 1.15, fl + 1.95, 0), Kit.METAL)  # luggage racks
	# What was left behind: coats on hooks, a newspaper, a lot of bags.
	for i in 5:
		var s := -1.0 if i % 2 else 1.0
		var p := Vector3(s * 1.15, fl + 2.05, -3.5 + i * 1.7 + k.rng.randf_range(-0.3, 0.3))
		k.box(g, Vector3(0.35, 0.22, 0.5), p, [Color(0.3, 0.35, 0.5), Color(0.5, 0.2, 0.18), Color(0.6, 0.5, 0.3)][i % 3])
	match n:
		1:
			_search(g, Vector3(0.6, 0.4, 1.0), Vector3(1.1, fl + 2.1, -1.8), "Search the luggage rack",
				"A sports bag full of someone's office lunch for the week, sealed and fine, apparently. You take the biscuits.", ["biscuits"], "train")
			_search(g, Vector3(0.6, 0.5, 0.6), Vector3(-0.85, fl + 0.6, 3.1), "Open the suitcase",
				"A nurse's suitcase: uniforms, sensible shoes, a first aid kit and a bottle of water.", ["bandages", "water"], "train")
			k.box(g, Vector3(0.55, 0.35, 0.22), Vector3(-0.85, fl + 0.62, 3.1), Color(0.5, 0.2, 0.18), {"rot": Vector3(90, 10, 0)})
			var ring := _find(g, Vector3(0.85, fl + 0.46, -0.6), "memory", "A wedding ring", "Pick up the ring", [
				"A wedding ring, pushed down the side of a seat. Inside, engraved: \"R & L, 1969. Still.\"",
			], [], "A wedding ring in carriage C1: \"R & L, 1969. Still.\" Ray made it to the train, then. Why did he take it off?")
			k.ring(ring, 0.012, 0.022, Vector3(0, 0.01, 0), Color(0.85, 0.7, 0.3), Vector3(90, 0, 0))
		2:
			var paper := k.thing(g, Vector3(0.4, 0.1, 0.4), Vector3(-1.05, fl + 0.78, -2.9), "Read the newspaper", [
				"The morning paper. HEATWAVE TO END THIS WEEKEND. On page six, a tiny column: \"Tensions\". You'd never have read it.",
				"The crossword is half done in pencil. 14 across: \"Shelter, for the time being (9)\". They didn't get it.",
			])
			paper.journal = "The 6:40's newspaper headline was about a heatwave. The war was on page six."
			_area(paper, "train")
			k.box(paper, Vector3(0.4, 0.01, 0.3), Vector3(0, -0.04, 0), Kit.PAPER, {"rot": Vector3(0, 15, 0)})
			_search(g, Vector3(0.7, 0.6, 0.6), Vector3(0.85, fl + 0.6, 3.15), "Search the lost property bag",
				"A guard's sack labelled LOST PROPERTY. Gloves, umbrellas, and at the bottom, batteries and a candle.", ["batteries", "candle"], "train")
			k.ball(g, Vector3(0.6, 0.5, 0.5), Vector3(0.85, fl + 0.6, 3.15), Color(0.45, 0.42, 0.35), {"sides": 6})
			var photo := _find(g, Vector3(-0.85, fl + 0.46, 1.35), "memory", "A school photo", "Pick up the photo", [
				"A school photo in a card frame: thirty children in rows, and a teacher at the end trying not to laugh. ALDER HOLLOW PRIMARY.",
				"You look closer. Third row, second from the left: Ada Bell. And at the front, cross-legged and blurry: Tom.",
			], [], "A school photo from Alder Hollow Primary on the train. Ada and Tom Bell are in it. Did their teacher get on the 6:40?")
			k.box(photo, Vector3(0.22, 0.02, 0.16), Vector3(0, 0.01, 0), Color(0.7, 0.65, 0.5), {"rot": Vector3(0, -20, 0)})
		3:
			_search(g, Vector3(0.6, 0.5, 0.6), Vector3(0.85, fl + 0.6, -1.8), "Open the holdall",
				"A holdall packed for a weekend: pyjamas, a tin of peaches, a box of tea bags. Someone was going to their mum's.", ["peaches", "tea"], "train")
			k.box(g, Vector3(0.6, 0.35, 0.3), Vector3(0.85, fl + 0.62, -1.8), Color(0.25, 0.3, 0.25))
			var letter := _find(g, Vector3(-1.05, fl + 0.76, 2.5), "memory", "A love letter", "Read the letter", [
				"A letter, never posted. \"I'm on the 6:40 so I'll be there by eight. I've decided. The answer is yes. It was always yes.\"",
			], [], "A letter in carriage C3, never sent: \"The answer is yes. It was always yes.\" I hope they got there some other way.")
			k.box(letter, Vector3(0.2, 0.01, 0.14), Vector3(0, -0.01, 0), Kit.PAPER.lightened(0.05), {"rot": Vector3(0, 30, 0)})
			# Outside, on the east side where nobody looks: a Ranger cache wedged on the bogie.
			_cache(world, Vector3(RAIL_X + 1.9, 0.12, cz + 3.0), "By the last carriage", "On the far side of the train, on the ballast where nobody walks: a Ranger tin. \"Most people never check the other side. You did. - W\"", ["rations", "bandages"], 90)


func _underframe(g: Node3D, L: float) -> void:
	k.box(g, Vector3(2.5, 0.35, L - 0.6), Vector3(0, 0.82, 0), Color(0.12, 0.12, 0.12))
	for bz in [-L / 2.0 + 2.0, L / 2.0 - 2.0]:
		k.box(g, Vector3(2.0, 0.3, 2.4), Vector3(0, 0.55, bz), Color(0.16, 0.16, 0.16))
		for wz in [-0.85, 0.85]:
			for s in [-0.72, 0.72]:
				k.cyl(g, 0.36, 0.12, Vector3(s, 0.6, bz + wz), Color(0.2, 0.18, 0.17), {"rot": Vector3(0, 0, 90), "sides": 8})
	k.blocker(g, Vector3(2.8, 1.0, L), Vector3(0, 0.5, 0))


## One long side of a carriage (s = -1 is west). Doors at `doors` (z), open on the west.
func _body_side(g: Node3D, s: float, L: float, fl: float, doors: Array, open: bool) -> void:
	var x := s * 1.4
	var top := fl + 2.3
	var win_b := fl + 0.95
	var win_t := fl + 1.9
	var pieces: Array = []  # [z0, z1] spans of wall between doors
	var zc := -L / 2.0
	for dz in doors:
		pieces.append([zc, dz - 0.5])
		zc = dz + 0.5
	pieces.append([zc, L / 2.0])
	for p in pieces:
		var a: float = p[0]
		var b: float = p[1]
		var len := b - a
		var mid := (a + b) / 2.0
		k.box(g, Vector3(0.08, win_b - fl, len), Vector3(x, (fl + win_b) / 2.0, mid), LIVERY, {"solid": true})
		k.box(g, Vector3(0.08, top - win_t, len), Vector3(x, (win_t + top) / 2.0, mid), CREAM, {"solid": true})
		k.box(g, Vector3(0.09, 0.08, len), Vector3(x, win_b, mid), Color(0.7, 0.55, 0.2))  # a yellow stripe
		# Windows with pillars between.
		var n := maxi(1, int(len / 1.6))
		var ww := len / n
		for i in n:
			var wz := a + ww * (i + 0.5)
			k.box(g, Vector3(0.08, win_t - win_b, 0.2), Vector3(x, (win_b + win_t) / 2.0, a + ww * i + 0.1), CREAM, {"solid": true})
			if (i + int(mid)) % 4 == 1:
				k.quad(g, Vector3(x, win_b, wz - ww / 2.0 + 0.2), Vector3(x, win_b, wz + ww / 2.0 - 0.1),
					Vector3(x, win_b + 0.4, wz + ww / 2.0 - 0.1), Vector3(x, win_b + 0.2, wz), k.glass_mat(0.5))  # broken
			else:
				k.pane(g, Vector3(0.02, win_t - win_b, ww - 0.2), Vector3(x, (win_b + win_t) / 2.0, wz + 0.05), Vector3.ZERO, 0.55)
		k.box(g, Vector3(0.08, win_t - win_b, 0.15), Vector3(x, (win_b + win_t) / 2.0, b - 0.075), CREAM, {"solid": true})
		k.blocker(g, Vector3(0.1, win_t - win_b, len), Vector3(x, (win_b + win_t) / 2.0, mid))
	for dz in doors:
		k.box(g, Vector3(0.1, top - fl - 2.0, 1.0), Vector3(x, fl + 2.0 + (top - fl - 2.0) / 2.0, dz), CREAM)
		if open:
			# The door slid open; a ramp of planks someone laid down to the ballast.
			k.box(g, Vector3(0.06, 2.0, 0.98), Vector3(x - s * 0.06, fl + 1.0, dz + 1.0), LIVERY)
			var ramp := k.box(g, Vector3(2.3, 0.08, 0.95), Vector3(x + s * 1.0, fl / 2.0 - 0.02, dz), Kit.WOOD_LIGHT.darkened(0.15),
				{"solid": true, "rot": Vector3(0, 0, -s * 29.0), "pattern": Kit.Pattern.PLANKS})
			ramp.name = "Ramp"
		else:
			k.box(g, Vector3(0.08, 2.0, 0.98), Vector3(x, fl + 1.0, dz), LIVERY, {"solid": true})
			k.pane(g, Vector3(0.09, 0.5, 0.4), Vector3(x, fl + 1.45, dz), Vector3.ZERO, 0.55)


func _ends_and_roof(g: Node3D, L: float, fl: float) -> void:
	var top := fl + 2.3
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(2.8, top - fl, 0.1), Vector3(0, (fl + top) / 2.0, s * L / 2.0), LIVERY.darkened(0.2), {"solid": true})
		k.box(g, Vector3(0.8, 1.9, 0.02), Vector3(0, fl + 0.95, s * (L / 2.0 - 0.06)), Color(0.4, 0.4, 0.42))  # gangway door
		k.box(g, Vector3(1.4, 2.0, 0.4), Vector3(0, fl + 1.1, s * (L / 2.0 + 0.2)), Color(0.12, 0.12, 0.12))  # bellows
	k.box(g, Vector3(2.9, 0.12, L + 0.1), Vector3(0, top + 0.06, 0), ROOF, {"solid": true})
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.6, 0.1, L + 0.1), Vector3(s * 1.2, top + 0.02, 0), ROOF, {"rot": Vector3(0, 0, -s * 20.0)})
	k.box(g, Vector3(2.0, 0.08, L), Vector3(0, top + 0.16, 0), ROOF.lightened(0.1))
	k.box(g, Vector3(2.7, 0.03, L - 0.2), Vector3(0, top - 0.02, 0), Color(0.82, 0.8, 0.75))  # ceiling


func _locomotive(cz: float) -> void:
	var g := k.group(world, Vector3(RAIL_X, 0, cz), 0)
	var L := 14.0
	var fl := 1.1
	var yellow := Color(0.85, 0.7, 0.2)
	_underframe(g, L)
	k.box(g, Vector3(2.8, 0.1, L), Vector3(0, fl - 0.05, 0), Color(0.25, 0.25, 0.25), {"solid": true})
	# Engine compartment (solid) from z -3.5 to the back.
	k.box(g, Vector3(2.6, 2.4, 10.4), Vector3(0, fl + 1.2, 1.8), LIVERY, {"solid": true})
	for i in 6:
		for s in [-1.0, 1.0]:
			k.box(g, Vector3(0.02, 0.7, 1.0), Vector3(s * 1.31, fl + 1.5, -2.0 + i * 1.6), Color(0.15, 0.15, 0.17), {"pattern": Kit.Pattern.TILES})
	k.box(g, Vector3(2.0, 0.3, 10.0), Vector3(0, fl + 2.55, 1.8), ROOF)
	k.cyl(g, 0.25, 0.4, Vector3(0, fl + 2.8, 3.5), Color(0.15, 0.15, 0.15), {"sides": 6})  # exhaust
	# The cab, at the north end.
	var c0 := -L / 2.0
	var c1 := -3.4
	var top := fl + 2.3
	k.box(g, Vector3(2.8, top - fl, 0.1), Vector3(0, (fl + top) / 2.0, c1), LIVERY.darkened(0.1), {"solid": true})
	# Front with two big windows and a yellow nose.
	k.box(g, Vector3(2.8, 1.0, 0.1), Vector3(0, fl + 0.5, c0), yellow, {"solid": true})
	k.box(g, Vector3(2.8, 0.3, 0.1), Vector3(0, top - 0.15, c0), yellow, {"solid": true})
	for s in [-1.0, 1.0]:
		k.pane(g, Vector3(1.1, 1.0, 0.03), Vector3(s * 0.65, fl + 1.5, c0), Vector3.ZERO, 0.6)
		k.box(g, Vector3(0.15, 1.0, 0.1), Vector3(s * 1.33, fl + 1.5, c0), yellow, {"solid": true})
		k.cyl(g, 0.12, 0.06, Vector3(s * 0.9, fl + 0.4, c0 - 0.06), Color(0.85, 0.85, 0.7), {"rot": Vector3(90, 0, 0), "sides": 8})
	k.box(g, Vector3(0.2, 1.0, 0.1), Vector3(0, fl + 1.5, c0), yellow, {"solid": true})
	k.blocker(g, Vector3(2.8, 1.0, 0.1), Vector3(0, fl + 1.5, c0))
	k.box(g, Vector3(2.8, 1.0, 0.6), Vector3(0, 0.6, c0 - 0.3), Color(0.15, 0.15, 0.15))  # buffer beam
	for s in [-0.8, 0.8]:
		k.cyl(g, 0.16, 0.4, Vector3(s, 0.85, c0 - 0.7), Kit.METAL, {"rot": Vector3(90, 0, 0), "sides": 8})
	# Cab sides: a door gap on the west, a window on the east.
	var dz := (c0 + c1) / 2.0
	for s in [-1.0, 1.0]:
		var x: float = s * 1.4
		if s < 0:
			k.box(g, Vector3(0.08, top - fl, (dz - 0.5) - c0), Vector3(x, (fl + top) / 2.0, (c0 + dz - 0.5) / 2.0), LIVERY, {"solid": true})
			k.box(g, Vector3(0.08, top - fl, c1 - (dz + 0.5)), Vector3(x, (fl + top) / 2.0, (c1 + dz + 0.5) / 2.0), LIVERY, {"solid": true})
			k.box(g, Vector3(0.08, top - fl - 2.0, 1.0), Vector3(x, fl + 2.15, dz), LIVERY)
			k.box(g, Vector3(2.3, 0.08, 0.95), Vector3(x - 1.0, fl / 2.0 - 0.02, dz), Kit.WOOD_LIGHT.darkened(0.15),
				{"solid": true, "rot": Vector3(0, 0, 29.0), "pattern": Kit.Pattern.PLANKS})
		else:
			k.box(g, Vector3(0.08, 1.0, c1 - c0), Vector3(x, fl + 0.5, dz), LIVERY, {"solid": true})
			k.box(g, Vector3(0.08, 0.3, c1 - c0), Vector3(x, top - 0.15, dz), LIVERY, {"solid": true})
			k.pane(g, Vector3(0.03, 1.0, c1 - c0 - 0.2), Vector3(x, fl + 1.5, dz), Vector3.ZERO, 0.55)
			k.blocker(g, Vector3(0.1, 1.0, c1 - c0), Vector3(x, fl + 1.5, dz))
	k.box(g, Vector3(2.9, 0.15, c1 - c0 + 0.1), Vector3(0, top + 0.07, dz), ROOF, {"solid": true})
	k.words(g, "47 211", Vector3(-1.46, fl + 1.2, 2.0), Vector3(0, -90, 0), 0.014, CREAM)
	# Inside: the driver's desk, the seat, the log.
	k.box(g, Vector3(2.4, 0.9, 0.7), Vector3(0, fl + 0.45, c0 + 0.45), Color(0.3, 0.32, 0.3), {"solid": true})
	k.box(g, Vector3(2.4, 0.3, 0.5), Vector3(0, fl + 0.95, c0 + 0.4), Color(0.2, 0.22, 0.2), {"rot": Vector3(-30, 0, 0)})
	for i in 4:
		k.cyl(g, 0.07, 0.02, Vector3(-0.6 + i * 0.35, fl + 1.08, c0 + 0.4), Color(0.85, 0.85, 0.75), {"rot": Vector3(60, 0, 0), "sides": 8, "glow": 0.2})
	f.chair(g, Vector3(0.5, fl, c0 + 1.4), 180, Color(0.25, 0.25, 0.3))
	var log := k.thing(g, Vector3(0.35, 0.15, 0.3), Vector3(-0.6, fl + 0.98, c0 + 0.7), "Read the driver's log", [
		"\"06:38. Signal at Mill Road crossing held at red. Waiting. 06:40 held. 06:41 held.\" The word HELD, eleven times, the writing getting smaller.",
		"\"06:52. Three flashes, south. Told passengers to stay on the train. Most didn't. Can't blame them.\"",
		"The last line, much later, in pencil: \"Walking north with the ones who stayed. If the signal ever goes green, it wasn't me. - D. Ames, driver.\"",
	])
	log.journal = "The 6:40 was held at a red signal at Mill Road at 06:38. The driver wrote HELD eleven times. Then the flashes. Then they walked north."
	_area(log, "train")
	k.box(log, Vector3(0.3, 0.04, 0.22), Vector3(0, -0.06, 0), Color(0.25, 0.2, 0.15))


func _guard_van(cz: float) -> void:
	var g := k.group(world, Vector3(RAIL_X, 0, cz), 0)
	var L := 6.0
	var fl := 1.1
	_underframe(g, L)
	k.box(g, Vector3(2.8, 0.1, L), Vector3(0, fl - 0.05, 0), Color(0.3, 0.3, 0.3), {"solid": true})
	k.box(g, Vector3(2.6, 0.02, L - 0.2), Vector3(0, fl + 0.01, 0), Kit.WOOD, {"pattern": Kit.Pattern.PLANKS})
	_body_side(g, -1.0, L, fl, [0.0], true)
	_body_side(g, 1.0, L, fl, [0.0], false)
	_ends_and_roof(g, L, fl)
	k.words(g, "GUARD", Vector3(-1.46, fl + 1.6, -1.8), Vector3(0, -90, 0), 0.012, CREAM)
	# A desk, mail sacks, a locker, a bike someone loaded at the last stop.
	k.box(g, Vector3(0.6, 0.8, 1.2), Vector3(1.05, fl + 0.4, -1.9), Kit.WOOD_DARK, {"solid": true})
	for i in 4:
		k.ball(g, Vector3(0.6, 0.5, 0.5), Vector3(-0.8 + (i % 2) * 0.45, fl + 0.25 + (i / 2) * 0.35, 2.2 - (i % 2) * 0.3), Color(0.5, 0.45, 0.35), {"sides": 6})
	var locker := k.group(g, Vector3(1.1, fl, 1.8), -90)
	k.box(locker, Vector3(0.7, 1.9, 0.5), Vector3(0, 0.95, 0), Color(0.35, 0.4, 0.38), {"solid": true})
	k.box(locker, Vector3(0.02, 0.4, 0.02), Vector3(0.25, 1.0, 0.26), Kit.METAL)
	k.ring(locker, 0.14, 0.2, Vector3(0, 0.6, 0.28), Color(0.15, 0.15, 0.15))  # the coil of wire, through the grille
	_search(g, Vector3(0.6, 1.9, 0.8), Vector3(1.1, fl + 0.95, 1.8), "Search the guard's locker",
		"The guard's locker: a hi-vis jacket, a flask, a whistle, and a long coil of antenna wire with a clip on the end, for the van's old radio.", ["antenna"], "train",
		"Took the guard's long-wire antenna from the 6:40. If I hang it from the radio at home, I might hear further.")
	var bike := k.group(g, Vector3(-0.9, fl, -1.5), 90)
	for z in [-0.5, 0.5]:
		k.ring(bike, 0.28, 0.32, Vector3(z, 0.32, 0), Color(0.1, 0.1, 0.1))
	k.beam(bike, Vector3(-0.5, 0.32, 0), Vector3(0.1, 0.75, 0), 0.04, Color(0.6, 0.15, 0.12))
	k.beam(bike, Vector3(0.5, 0.32, 0), Vector3(0.1, 0.75, 0), 0.04, Color(0.6, 0.15, 0.12))
	var teddy := _find(g, Vector3(0.95, fl + 0.82, -1.7), "memory", "A teddy bear", "Pick up the teddy", [
		"A small teddy bear with a luggage label round its neck: \"If found, please return to Platform 2. He is called Mr Buttons and he is very important.\"",
	], [], "Mr Buttons, a teddy bear, was handed in to the guard on the 6:40. Very important, says the label. He's coming home with me.")
	k.ball(teddy, Vector3(0.18, 0.22, 0.15), Vector3(0, 0.1, 0), Color(0.6, 0.45, 0.3), {"sides": 6})
	k.ball(teddy, Vector3(0.13, 0.13, 0.12), Vector3(0, 0.28, 0), Color(0.6, 0.45, 0.3), {"sides": 6})


func _signal_box() -> void:
	# On the far side of the line. Its signal is still red.
	var g := k.group(world, Vector3(105.5, 0, -16), -90)
	var col := Color(0.6, 0.35, 0.25)
	var w := 3.6
	var d := 3.0
	var h := 2.6
	k.box(g, Vector3(w, 0.06, d), Vector3(0, 0.03, 0), Kit.WOOD_DARK)
	k.box(g, Vector3(w, h, 0.15), Vector3(0, h / 2.0, -d / 2.0), col, {"solid": true, "pattern": Kit.Pattern.BRICK})
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.15, h, d), Vector3(s * w / 2.0, h / 2.0, 0), col, {"solid": true, "pattern": Kit.Pattern.BRICK})
	# Front: big windows over the line, door on the left.
	k.box(g, Vector3(w - 1.0, 1.0, 0.15), Vector3(0.5, 0.5, d / 2.0), col, {"solid": true, "pattern": Kit.Pattern.BRICK})
	k.pane(g, Vector3(w - 1.0, 1.3, 0.03), Vector3(0.5, 1.65, d / 2.0), Vector3.ZERO, 0.5)
	k.blocker(g, Vector3(w - 1.0, 1.3, 0.15), Vector3(0.5, 1.65, d / 2.0))
	k.box(g, Vector3(w + 0.1, 0.3, 0.15), Vector3(0, h - 0.15, d / 2.0), col, {"solid": true})
	k.prism(g, Vector3(w + 0.5, 1.0, d + 0.5), Vector3(0, h + 0.5, 0), Color(0.25, 0.25, 0.28), {"rot": Vector3(0, 90, 0)})
	k.box(g, Vector3(1.0, 0.4, 0.05), Vector3(0.5, h + 0.2, d / 2.0 + 0.1), CREAM)
	k.words(g, "MILL ROAD", Vector3(0.5, h + 0.2, d / 2.0 + 0.13), Vector3.ZERO, 0.007, Color(0.15, 0.15, 0.15))
	# The lever frame.
	for i in 8:
		var c: Color = [Color(0.7, 0.15, 0.1), Color(0.7, 0.15, 0.1), Color(0.15, 0.25, 0.6), Color(0.1, 0.1, 0.1)][i % 4]
		k.beam(g, Vector3(-1.2 + i * 0.3, 0.2, -0.6), Vector3(-1.2 + i * 0.3, 1.2, -0.75 if i != 2 else -0.3), 0.05, c)
	k.box(g, Vector3(2.6, 0.2, 0.4), Vector3(-0.15, 0.1, -0.7), Color(0.2, 0.2, 0.2))
	var book := k.thing(g, Vector3(0.6, 0.6, 0.5), Vector3(1.3, 0.9, -1.0), "Read the signal box register", [
		"The train register. \"06:31 6:40 offered from Hollow Junction. 06:33 accepted.\"",
		"\"06:36 ORDER RECEIVED: HOLD ALL TRAINS. NO MOVEMENTS. 06:37 6:40 held at Mill Road.\" Then the signaller's handwriting gives up on columns.",
		"\"They wouldn't say why. I could have let it through. It would have been at the junction by 6:50. I keep doing the sum.\"",
	])
	book.journal = "The signal box register: an order came at 06:36 to hold all trains. The signaller kept the 6:40 at red. They keep doing the sum."
	_area(book, "train")
	k.box(g, Vector3(0.6, 0.8, 0.5), Vector3(1.3, 0.4, -1.0), Kit.WOOD, {"solid": true})
	k.box(g, Vector3(0.4, 0.04, 0.3), Vector3(1.3, 0.82, -1.0), Color(0.25, 0.2, 0.15))
	f.chair(g, Vector3(0.8, 0, 0.2), 150, Kit.WOOD)
	# The signal itself, on a post by the line, still red.
	var sig := k.group(world, Vector3(103.3, 0, -36), 0)
	k.cyl(sig, 0.08, 5.0, Vector3(0, 2.5, 0), Color(0.2, 0.2, 0.2), {"sides": 6})
	k.box(sig, Vector3(0.5, 1.0, 0.2), Vector3(0, 4.6, 0.12), Color(0.1, 0.1, 0.1))
	k.cyl(sig, 0.13, 0.05, Vector3(0, 4.85, 0.25), Color(1.0, 0.15, 0.1), {"rot": Vector3(90, 0, 0), "sides": 8, "glow": 2.5})
	k.cyl(sig, 0.13, 0.05, Vector3(0, 4.4, 0.25), Color(0.1, 0.25, 0.12), {"rot": Vector3(90, 0, 0), "sides": 8})


# --- Around the edges -------------------------------------------------------------------------

func _forest_edge() -> void:
	k.box(world, Vector3(45, 0.02, 60), Vector3(92.5, 0.01, -78), Color(0.26, 0.3, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 60:
		var p := Vector3(rng.randf_range(70, 114), 0, rng.randf_range(-48.5, -100))
		var tall := rng.randf_range(7, 15)
		if absf(p.x - 85.0) < 2.5 and p.z > -62.0:
			continue  # keep the trail clear
		if p.z > -56.0 and rng.randf() < 0.2:
			trees.birch(world, p, tall * 0.6, {"solid": false})
		else:
			trees.pine(world, p, tall)
	# The trail head: a Ranger post with a green ribbon, and the last cache by a log.
	var post := k.group(world, Vector3(85, 0, -45.5), 0)
	k.box(post, Vector3(0.15, 1.3, 0.15), Vector3(0, 0.65, 0), Kit.WOOD)
	k.box(post, Vector3(0.18, 0.15, 0.18), Vector3(0, 1.1, 0), RANGER.lightened(0.2))
	k.box(post, Vector3(0.04, 0.4, 0.02), Vector3(0.1, 0.9, 0.09), Color(0.3, 0.6, 0.3), {"rot": Vector3(0, 0, 15)})
	var sign := k.thing(world, Vector3(0.4, 0.5, 0.4), Vector3(85, 1.1, -45.5), "Read the trail post", [
		"A trail marker: ALDER HOLLOW FOREST. RANGER STATION 4 KM. A green ribbon has been tied on recently.",
	])
	_area(sign, "alder")
	k.beam(world, Vector3(82.5, 0.25, -46.5), Vector3(86.5, 0.25, -46.0), 0.45, Color(0.28, 0.24, 0.2))
	_cache(world, Vector3(84.0, 0, -45.3), "Where the trail meets the trees", "A Ranger tin by the trail post. \"Four kilometres up this trail to the station. It's still manned, more or less. I'm the more or less. - W\"", ["rations", "water"], 10)
	# A few dead trees behind the garage.
	for p: Vector3 in [Vector3(62, 0, -30), Vector3(78, 0, -33), Vector3(90, 0, -26), Vector3(57, 0, -22)]:
		trees.dead(world, p, k.rng.randf_range(4.5, 6.5), {"leaves": 0.2})
	trees.oak(world, Vector3(70, 0, -38), 7.5, {"bare": 0.4})  # one old oak that made it
	trees.birch(world, Vector3(92, 0, 20.5), 6.0)
	trees.dead(world, Vector3(56.5, 0, 25), 5.0, {"extras": true})


func _grass() -> void:
	var tuft := PrismMesh.new()
	tuft.size = Vector3(0.3, 0.38, 0.02)
	for c in [Color(0.45, 0.43, 0.3), Color(0.38, 0.4, 0.28), Color(0.52, 0.48, 0.34)]:
		var xf: Array = []
		var tries := 0
		while xf.size() < 900 and tries < 5000:
			tries += 1
			var p := Vector3(k.rng.randf_range(46, 112), 0, k.rng.randf_range(-47, 27))
			if absf(p.z) < 5.3 or absf(p.x - RAIL_X) < 2.4:
				continue
			if p.x > 57 and p.x < 79 and p.z < -5 and p.z > -25:
				continue  # forecourt and shop
			if p.x > 102 and p.x < 109 and p.z < -13 and p.z > -19:
				continue  # signal box
			var s := k.rng.randf_range(0.7, 1.6)
			xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).scaled(Vector3(s, s, s)), p + Vector3(0, 0.17 * s, 0)))
		k.scatter(world, tuft, c, xf)


func _ash() -> void:
	var ash := CPUParticles3D.new()
	ash.add_to_group("ash")
	ash.amount = 300
	ash.lifetime = 18.0
	ash.preprocess = 18.0
	ash.position = Vector3(82, 9, -6)
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(27, 0.5, 18)
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


## One lost thing back on Alder Street, at the bus stop that never got a bus.
func _bus_ticket() -> void:
	var t := _find(world, Vector3(35.4, 0.5, 6.5), "memory", "A bus ticket", "Pick up the ticket", [
		"A child's bus pass, tucked into the bench slats. ADA BELL, AGE 12. On the back in biro: \"Waited 4 hours. Mum says we'll walk.\"",
	], [], "Ada Bell's bus pass, at the evacuation stop. They waited four hours, then walked. To the bus, Tom said. There was no bus.")
	k.box(t, Vector3(0.1, 0.01, 0.07), Vector3(0, 0.03, 0), Color(0.3, 0.5, 0.75), {"rot": Vector3(0, 15, 0)})
