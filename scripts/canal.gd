## The canal path: the long way round to the Hollow Junction camp, since the
## overpass came down. Reached from the Ranger Station's west side once Wren
## has drawn you a map. A towpath runs east beside the water, past a
## narrowboat and the lock-keeper's cottage, to a lock. Beyond the lock the
## canal has burst onto the towpath. Cut the chain on the paddle gear and
## wind it with the lock-keeper's windlass to let the water down; Grace
## Okafor is waiting under the bridge at the far end.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Houses := preload("res://scripts/houses.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Survivor := preload("res://scripts/survivor.gd")
const Trail := preload("res://scripts/trail.gd")
const LockedDoor := preload("res://scripts/locked_door.gd")
const Trees := preload("res://scripts/trees.gd")
const Paddle := preload("res://scripts/canal_paddle.gd")
const Grace := preload("res://scripts/people/grace.gd")

const ORIGIN := Vector3(-400, 0, -400)
const ARRIVE := ORIGIN + Vector3(-55, 0.1, 2.0)
## Where the canal path leaves the station (station.gd builds the start).
const STATION_SIDE := Vector3(-21.0, 0.1, -394.0)

const WATER_LOW := -0.6     # the canal's normal level
const WATER_HIGH := 0.22    # the flooded stretch, over the towpath
const BRICK := Color(0.5, 0.33, 0.27)
const STONE := Color(0.55, 0.53, 0.48)
const PATH := Color(0.42, 0.36, 0.28)
const WATER := Color(0.24, 0.31, 0.31)

var k: Kit
var world: Node3D
var root: Node3D
var houses: Houses
var f: Furniture
var trees: Trees

var _upper: Node3D          # the canal water above the lock
var _flood: Node3D          # the water over the towpath
var _flood_wall: StaticBody3D
var _flood_sign: StaticBody3D
var _mud: Node3D


func _init(kit: Kit, w: Node3D) -> void:
	k = kit
	world = w
	houses = Houses.new(kit)
	f = Furniture.new(kit)
	trees = Trees.new(kit, 77)


func build() -> void:
	root = k.group(world, ORIGIN, 0)
	_ground()
	_water()
	_lock()
	_narrowboat()
	_cottage()
	_bridge_and_grace()
	_ends()
	_trees_and_reeds()


func _area(n: Node) -> Node:
	n.set_meta("area", "canal")
	return n


# --- Ground and water --------------------------------------------------------------

func _ground() -> void:
	k.box(root, Vector3(130, 0.2, 18), Vector3(0, -0.1, 9), Color(0.3, 0.32, 0.23), {"solid": true})       # south bank
	k.box(root, Vector3(130, 0.2, 30), Vector3(0, -0.1, -22), Color(0.28, 0.3, 0.22), {"solid": true})     # north bank
	k.box(root, Vector3(130, 0.2, 8), Vector3(0, -1.6, -4), Color(0.18, 0.16, 0.12), {"solid": true})       # canal bed
	# The towpath: packed earth with a brick edge along the water.
	k.box(root, Vector3(124, 0.03, 2.6), Vector3(0, 0.015, 1.6), PATH)
	k.box(root, Vector3(124, 0.12, 0.35), Vector3(0, 0.0, 0.1), BRICK, {"pattern": Kit.Pattern.BRICK})
	k.box(root, Vector3(124, 0.12, 0.35), Vector3(0, 0.0, -8.1), BRICK, {"pattern": Kit.Pattern.BRICK})
	# Canal walls under the water line.
	k.box(root, Vector3(124, 1.6, 0.3), Vector3(0, -0.8, -0.1), BRICK.darkened(0.3))
	k.box(root, Vector3(124, 1.6, 0.3), Vector3(0, -0.8, -7.9), BRICK.darkened(0.3))
	# Walls: the water to the north, a hedge and fence to the south, with the
	# cottage garden let into it.
	k.blocker(root, Vector3(124, 4, 0.5), Vector3(0, 2, -0.35))
	for seg in [[-62.0, -36.0], [-24.0, 62.0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		k.blocker(root, Vector3(b - a, 4, 0.5), Vector3((a + b) / 2.0, 2, 4.4))
		_hedge(a, b, 4.6)
	k.blocker(root, Vector3(0.5, 4, 10), Vector3(-36.2, 2, 9.4))
	k.blocker(root, Vector3(0.5, 4, 10), Vector3(-23.8, 2, 9.4))
	k.blocker(root, Vector3(12.4, 4, 0.5), Vector3(-30, 2, 14.4))
	for x in [-36.2, -23.8]:
		for i in 4:
			k.box(root, Vector3(0.1, 1.0, 0.1), Vector3(x, 0.5, 5.5 + i * 2.8), Kit.WOOD_DARK)
		k.box(root, Vector3(0.05, 0.05, 9.5), Vector3(x, 0.85, 9.6), Kit.WOOD)
	k.box(root, Vector3(12.4, 0.05, 0.05), Vector3(-30, 0.85, 14.3), Kit.WOOD)


func _hedge(a: float, b: float, z: float) -> void:
	var x := a + 0.6
	while x < b:
		var s := k.rng.randf_range(0.9, 1.5)
		k.ball(root, Vector3(1.6 * s, 1.3 * s, 1.1), Vector3(x, 0.55 * s, z + k.rng.randf_range(-0.1, 0.2)),
			Color(0.24, 0.32, 0.2).lightened(k.rng.randf_range(0.0, 0.12)), {"sides": 6})
		x += 1.3 * s


func _water() -> void:
	# Below the lock, at the normal level.
	k.box(root, Vector3(56, 0.05, 7.6), Vector3(-34, WATER_LOW, -4), WATER, {"glow": 0.15})
	k.box(root, Vector3(12, 0.05, 5.0), Vector3(0, WATER_LOW, -4), WATER, {"glow": 0.15})
	# Above the lock: high, and over the towpath from x 8 to 40.
	_upper = k.group(root, Vector3(0, WATER_HIGH, 0), 0)
	k.box(_upper, Vector3(56, 0.05, 7.6), Vector3(34, 0, -4), WATER, {"glow": 0.15})
	_flood = k.group(root, Vector3.ZERO, 0)
	k.box(_flood, Vector3(32, 0.05, 4.2), Vector3(24, WATER_HIGH, 2.0), WATER.lightened(0.12), {"glow": 0.25})
	for i in 14:
		k.box(_flood, Vector3(k.rng.randf_range(0.6, 2.0), 0.02, 0.05), Vector3(k.rng.randf_range(9, 39), WATER_HIGH + 0.03, k.rng.randf_range(0.2, 3.8)), Color(0.5, 0.55, 0.52))  # ripples
	_flood_wall = StaticBody3D.new()
	_flood_wall.position = Vector3(8.2, 1.5, 2.2)
	k.add_shape(_flood_wall, Vector3(0.4, 3, 4.4))
	_flood_wall.collision_layer = 2
	root.add_child(_flood_wall)
	_flood_sign = k.thing(root, Vector3(0.4, 1.2, 4.0), Vector3(8.0, 0.6, 2.2), "Wade into the flood", [
		"The canal has come over the bank. The towpath disappears into brown water, knee-deep here and deeper further on. It's freezing.",
		"You get one welly full and come back out. No. It's too deep along there.",
		"The lock's paddle gear would let the water down through the gate. If it isn't seized. Or chained.",
	])
	_area(_flood_sign)
	# What the water leaves behind.
	_mud = k.group(root, Vector3.ZERO, 0)
	for i in 18:
		k.box(_mud, Vector3(k.rng.randf_range(0.6, 2.5), 0.02, k.rng.randf_range(0.4, 1.4)), Vector3(k.rng.randf_range(9, 39), 0.035, k.rng.randf_range(0.6, 3.2)), Color(0.24, 0.2, 0.15))
	for i in 6:
		k.ball(_mud, Vector3(0.6, 0.15, 0.4), Vector3(k.rng.randf_range(9, 39), 0.05, k.rng.randf_range(0.4, 3.5)), Color(0.3, 0.33, 0.22), {"sides": 5})  # weed
	_mud.visible = false


## Lets the flooded stretch down (canal_paddle.gd). `now` skips the slow bit.
func drain(now: bool) -> void:
	_flood_wall.queue_free()
	_flood_sign.prompt = ""
	for c in _flood_sign.get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)
	_mud.visible = true
	if now:
		_upper.position.y = WATER_LOW
		_flood.visible = false
		return
	var t := _upper.create_tween().set_parallel()
	t.tween_property(_upper, "position:y", WATER_LOW, 9.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(_flood, "position:y", WATER_LOW - WATER_HIGH, 6.0).set_trans(Tween.TRANS_SINE)
	t.chain().tween_callback(func(): _flood.visible = false)


# --- The lock ----------------------------------------------------------------------------

func _lock() -> void:
	# The chamber narrows the canal; the gates are at each end.
	for z in [-1.5, -6.5]:
		k.box(root, Vector3(13, 1.7, 1.0), Vector3(0, -0.75, z), STONE, {"pattern": Kit.Pattern.CONCRETE})
		k.box(root, Vector3(13, 0.12, 1.1), Vector3(0, 0.06, z), STONE.lightened(0.1))
	for x in [-6.0, 6.0]:
		var g := k.group(root, Vector3(x, 0, -4), 0)
		for s in [-1.0, 1.0]:
			k.box(g, Vector3(0.35, 1.5, 2.4), Vector3(0, -0.4, s * 1.2), Kit.WOOD_DARK.darkened(0.2), {"rot": Vector3(0, s * 12, 0)})
			# Balance beams, the long arms you push to open the gates.
			k.box(g, Vector3(0.3, 0.3, 4.2), Vector3(s * 0.0 + (1.6 if x > 0 else -1.6), 0.55, s * 2.3 + s * 1.2), Color(0.85, 0.85, 0.82), {"rot": Vector3(0, s * (60 if x > 0 else -60), 0)})
		k.box(g, Vector3(0.25, 0.04, 5.0), Vector3(0, 0.3, 0), Kit.METAL)  # walkway rail
	# Painted on the lock: name and number.
	k.words(root, "LOCK 14 - HOLLOW TOP LOCK", Vector3(0, 0.2, -0.95), Vector3.ZERO, 0.006, Color(0.95, 0.95, 0.9))
	# The paddle gear on the top gate, on the towpath side.
	var gear: StaticBody3D = k.thing(root, Vector3(0.6, 1.0, 0.6), Vector3(6.0, 0.5, 0.75), "Look at the paddle gear", [], Paddle)
	gear.canal = self
	_area(gear)
	k.box(gear, Vector3(0.35, 0.9, 0.3), Vector3(0, 0, 0), Color(0.12, 0.12, 0.13))
	k.cyl(gear, 0.18, 0.08, Vector3(0, 0.3, -0.2), Color(0.12, 0.12, 0.13), {"rot": Vector3(90, 0, 0), "sides": 10})
	k.box(gear, Vector3(0.06, 0.06, 0.12), Vector3(0, 0.3, -0.28), Kit.METAL)  # the spindle
	var chain := k.group(gear, Vector3.ZERO, 0)
	for i in 6:
		k.ring(chain, 0.03, 0.05, Vector3(0, -0.2 + i * 0.09, 0.17), Kit.METAL.lightened(0.1), Vector3(0, 0, 90 * (i % 2)))
	k.box(chain, Vector3(0.1, 0.12, 0.05), Vector3(0.0, 0.1, 0.22), Color(0.7, 0.6, 0.3))  # padlock
	gear.chain = chain
	# A bench and a notice by the lock.
	var notice := k.thing(root, Vector3(1.0, 0.8, 0.1), Vector3(-3.0, 1.3, 4.0), "Read the lock notice", [
		"CANAL & RIVER TRUST. Boaters: please leave the lock as you find it. And a newer notice, in marker: TOP POUND FLOODING - DON'T OPEN PADDLES - ALF.",
		"Under it, newer still, a different hand: \"Alf's gone to the junction. We need the path. Sorry Alf.\" And an arrow to the paddle gear.",
	])
	_area(notice)
	k.box(notice, Vector3(1.0, 0.7, 0.04), Vector3.ZERO, Color(0.2, 0.3, 0.45))
	k.box(root, Vector3(0.08, 1.4, 0.08), Vector3(-3.0, 0.7, 4.1), Kit.WOOD_DARK)


# --- The narrowboat --------------------------------------------------------------------

func _narrowboat() -> void:
	var g := k.group(root, Vector3(-16, WATER_LOW, -2.4), 0)
	var hull := Color(0.15, 0.3, 0.2)
	k.box(g, Vector3(16, 0.9, 2.0), Vector3(0, 0.2, 0), hull)
	k.box(g, Vector3(16.1, 0.12, 2.05), Vector3(0, 0.6, 0), Color(0.7, 0.15, 0.12))  # red band
	k.prism(g, Vector3(2.0, 0.9, 1.2), Vector3(8.4, 0.2, 0), hull, {"rot": Vector3(0, 0, -90)})  # bow
	k.box(g, Vector3(11, 1.0, 1.8), Vector3(-1.0, 1.15, 0), Color(0.82, 0.78, 0.6))  # cabin
	k.box(g, Vector3(11.2, 0.1, 2.0), Vector3(-1.0, 1.7, 0), Color(0.3, 0.3, 0.3))  # roof
	for i in 6:
		k.box(g, Vector3(0.5, 0.35, 0.03), Vector3(-5.5 + i * 1.8, 1.25, 0.92), Color(0.3, 0.35, 0.38))  # portholes
	k.words(g, "KINGFISHER", Vector3(3.5, 1.2, 0.93), Vector3.ZERO, 0.008, Color(0.95, 0.8, 0.3))
	for i in 5:
		k.cyl(g, 0.14, 0.25, Vector3(-4.0 + i * 1.3, 1.85, 0.3), [Color(0.6, 0.3, 0.2), Color(0.3, 0.5, 0.3)][i % 2], {"sides": 6})  # plant pots
		k.ball(g, Vector3(0.3, 0.3, 0.3), Vector3(-4.0 + i * 1.3, 2.05, 0.3), Kit.PLANT, {"sides": 5})
	k.cyl(g, 0.06, 0.6, Vector3(1.5, 2.0, -0.4), Color(0.2, 0.2, 0.2), {"sides": 6})  # chimney
	var search := k.search(root, Vector3(3.0, 1.4, 0.5), Vector3(-14.0, 0.4, -1.3), "Search the narrowboat",
		"The back doors aren't locked. Inside: two bunks, a tiny stove, a kettle, a calendar stopped in March. In the cupboard: tea, a candle, and a note to someone called Jo: \"Gone to the junction with Alf. Path floods past the lock, his windlass is on the hook in his kitchen. Love you. M.\"",
		["tea", "candle"])
	search.journal = "The narrowboat Kingfisher. A note: Alf the lock-keeper keeps his windlass on the hook in his kitchen. The path floods past the lock."
	_area(search)
	# Mooring posts and a rope.
	for x in [-23.5, -8.5]:
		k.cyl(root, 0.1, 0.5, Vector3(x, 0.25, 0.4), Kit.WOOD_DARK, {"sides": 6})
		k.beam(root, Vector3(x, 0.4, 0.4), Vector3(x + (1.0 if x < -16 else -1.0), WATER_LOW + 0.6, -1.5), 0.03, Color(0.75, 0.68, 0.5))
	# Further down, a sunk boat with just its cabin roof above the water.
	var sunk := k.group(root, Vector3(-44, WATER_LOW - 0.6, -4.5), 8)
	k.box(sunk, Vector3(12, 0.9, 1.8), Vector3(0, 0, 0), Color(0.3, 0.2, 0.4), {"rot": Vector3(0, 0, -4)})
	k.box(sunk, Vector3(6, 0.1, 1.9), Vector3(-1, 0.5, 0), Color(0.25, 0.25, 0.25), {"rot": Vector3(0, 0, -4)})


# --- Alf's cottage ----------------------------------------------------------------------

func _cottage() -> void:
	var h := houses.shell(root, Vector3(-30, 0, 9.5), {
		"w": 6.0, "d": 5.0, "h": 2.5, "walls": Color(0.8, 0.78, 0.7), "pattern": Kit.Pattern.SIDING,
		"inside": Color(0.75, 0.7, 0.58), "floor": Kit.WOOD, "roof": Color(0.3, 0.3, 0.32),
		"door_x": 0.0, "door": "missing", "number": "", "chimney": true,
		"windows": [["front", -1.8, "boarded", null], ["front", 1.8, "ok", Kit.FABRIC_RED], ["left", 0.0, "ok", null]],
	})
	k.words(h, "LOCK COTTAGE", Vector3(0, 2.35, 2.6), Vector3.ZERO, 0.006, Color(0.2, 0.25, 0.3))
	var lock: StaticBody3D = k.thing(h, Vector3(1.0, 2.1, 0.3), Vector3(0, 1.05, 2.6), "Try the cottage door", [
		"Locked, and the windows either side are boarded. A sign in the window: GONE TO JUNCTION. NOTHING WORTH TAKING. - A.",
		"Locked tight. The frame's old, though. You could lever it.",
	], LockedDoor)
	lock.lock_name = "Alf's cottage at the lock"
	lock.tool_hint = "The frame's old: lever it"
	lock.needs = "crowbar"
	lock.needs_line = "Locked tight. The frame's old, though. You could lever it."
	lock.open_line = "The crowbar goes in by the lock and the old frame splits with a crack. Sorry, Alf."
	_area(lock)
	var hinge := k.group(lock, Vector3(-0.46, -1.05, -0.12), 0)
	k.box(hinge, Vector3(0.92, 2.06, 0.05), Vector3(0.46, 1.03, 0), Color(0.2, 0.35, 0.3))
	k.ball(hinge, Vector3(0.06, 0.06, 0.05), Vector3(0.82, 1.0, 0.04), Color(0.75, 0.65, 0.35))
	lock.swing = hinge
	lock.swing_angle = 100.0
	# Inside: a kitchen with the windlass on its hook, an armchair, the log.
	f.stove(h, Vector3(-2.3, 0, -1.9), 0)
	f.kettle(h, Vector3(-2.3, 0.9, -1.9))
	f.counter(h, Vector3(-0.6, 0, -2.1), 0, 1.6, Color(0.7, 0.6, 0.45))
	var windlass := k.search(h, Vector3(0.5, 0.6, 0.2), Vector3(1.3, 1.4, -2.3), "Take the windlass off its hook",
		"An L-shaped iron handle, heavy and greasy, ALF scratched into the grip. Next to the hook, a card: \"Wind slow. Stand back from the gate.\"", ["windlass"])
	_area(windlass)
	k.box(h, Vector3(0.05, 0.05, 0.1), Vector3(1.3, 1.65, -2.4), Kit.METAL)  # the hook
	k.box(windlass, Vector3(0.04, 0.4, 0.04), Vector3(0, -0.05, 0), Color(0.15, 0.15, 0.15))
	k.box(windlass, Vector3(0.25, 0.04, 0.04), Vector3(0.1, -0.23, 0), Color(0.15, 0.15, 0.15))
	f.armchair(h, Vector3(2.0, 0, 0.6), -120, Color(0.45, 0.35, 0.3))
	f.rug(h, Vector3(0.6, 0, 0.4), 0, Vector2(2.0, 1.4), Color(0.4, 0.3, 0.45))
	f.table(h, Vector3(-1.6, 0, 0.6), 0, Vector2(1.0, 0.8), Kit.WOOD_DARK)
	var log := k.thing(h, Vector3(0.5, 0.2, 0.4), Vector3(-1.6, 0.85, 0.6), "Read Alf's lock log", [
		"Boats through, day by day, in neat capitals. Then: \"DAY 1. No boats. Sky wrong. DAY 2. Top pound rising, bank going by the bend. Chained the paddles so nobody drains it onto the Jo's mooring.\"",
		"\"DAY 9. Bank's gone. Path under. Going to the junction with M. and the dog. If you need the path, the windlass is on the hook. Wind slow. - Alf.\"",
	])
	log.journal = "Alf the lock-keeper chained the lock paddles on day 2 to save a mooring, then the bank went. His windlass is on the hook in his kitchen."
	_area(log)
	k.box(log, Vector3(0.4, 0.06, 0.3), Vector3.ZERO, Color(0.2, 0.25, 0.35))
	f.bed(h, Vector3(2.3, 0, -1.3), 90, 0.9, Color(0.3, 0.4, 0.3))
	f.picture(h, Vector3(-2.9, 1.5, 0.0), 90, Vector2(0.5, 0.35), Color(0.3, 0.45, 0.55))
	# The garden: a bench, a water butt, cabbages gone to seed.
	k.box(root, Vector3(1.4, 0.08, 0.45), Vector3(-26.0, 0.45, 6.2), Kit.WOOD)
	for x in [-26.6, -25.4]:
		k.box(root, Vector3(0.08, 0.45, 0.4), Vector3(x, 0.22, 6.2), Kit.WOOD_DARK)
	k.cyl(root, 0.35, 0.9, Vector3(-34.5, 0.45, 6.0), Color(0.2, 0.3, 0.25), {"sides": 8, "solid": true})
	for i in 8:
		k.ball(root, Vector3(0.45, 0.6, 0.45), Vector3(-34.5 + (i % 4) * 0.8, 0.3, 12.5 + (i / 4) * 0.8), Color(0.35, 0.45, 0.3), {"sides": 5})


# --- The bridge and Grace ---------------------------------------------------------------

func _bridge_and_grace() -> void:
	# A humpbacked brick bridge over the canal.
	var g := k.group(root, Vector3(50, 0, -4), 0)
	for i in 7:
		var x := -3.0 + i
		var y := 1.4 + sin(float(i) / 6.0 * PI) * 0.8
		k.box(g, Vector3(1.05, 0.4, 5.0), Vector3(x, y, 0), BRICK, {"pattern": Kit.Pattern.BRICK})
		for s in [-1.0, 1.0]:
			k.box(g, Vector3(1.05, 0.6, 0.25), Vector3(x, y + 0.5, s * 2.4), BRICK.darkened(0.1), {"pattern": Kit.Pattern.BRICK})
	for x in [-3.5, 3.5]:
		k.box(g, Vector3(1.0, 2.4, 5.0), Vector3(x, 0.2, 0), BRICK, {"pattern": Kit.Pattern.BRICK})
	# Grace's little fire on the towpath under the arch's end.
	var c := Vector3(52.5, 0, 2.6)
	for i in 7:
		var a := i * TAU / 7.0
		k.ball(root, Vector3(0.25, 0.16, 0.22), c + Vector3(cos(a) * 0.5, 0.08, sin(a) * 0.5), Color(0.45, 0.43, 0.4), {"sides": 5})
	k.prism(root, Vector3(0.35, 0.5, 0.35), c + Vector3(0, 0.3, 0), Color(1.0, 0.55, 0.15), {"glow": 2.5})
	k.blocker(root, Vector3(1.0, 1, 1.0), c + Vector3(0, 0.5, 0))
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.6, 0.3)
	fire.light_energy = 1.6
	fire.omni_range = 7.0
	fire.position = c + Vector3(0, 0.9, 0)
	root.add_child(fire)
	k.box(root, Vector3(0.6, 0.45, 0.4), c + Vector3(1.4, 0.22, 0.6), Color(0.35, 0.4, 0.3))  # her rucksack
	var grace: StaticBody3D = Grace.new()
	grace.place = "canal"
	grace.position = c + Vector3(-1.2, 0.85, 0.7)
	grace.rotation_degrees.y = 110
	k.add_shape(grace, Vector3(0.6, 1.7, 0.6))
	root.add_child(grace)
	_area(grace)
	grace.body = _grace_body(grace)


func _grace_body(parent: Node3D) -> Node3D:
	var body: Node3D = Survivor.new()
	body.position = Vector3(0, -0.85, 0)
	body.scale = Vector3.ONE * 1.1
	parent.add_child(body)
	body.build(k, {
		"coat": Color(0.3, 0.38, 0.28), "tights": Color(0.25, 0.22, 0.2), "boots": Color(0.25, 0.18, 0.12),
		"skin": Color(0.45, 0.3, 0.22), "hair": Color(0.12, 0.1, 0.1), "hat": Color(0.85, 0.55, 0.2),
		"scarf": Color(0.8, 0.5, 0.2), "mitten": Color(0.85, 0.55, 0.2), "iris": Color(0.2, 0.12, 0.08),
		"iris_low": Color(0.45, 0.3, 0.2), "hat_style": "beanie", "braids": false, "backpack": true,
	})
	return body


# --- The ends of the path ------------------------------------------------------------------

func _ends() -> void:
	var back: StaticBody3D = k.thing(root, Vector3(0.8, 2.2, 3.4), Vector3(-59.5, 1.1, 2.0), "Walk back to the station", [], Trail)
	back.destination = STATION_SIDE
	back.facing = -PI / 2.0
	back.arrive_line = "Back up through the woods to Wren's clearing. The fire's still going. It always is."
	_area(back)
	k.blocker(root, Vector3(0.5, 4, 5), Vector3(-60.2, 2, 2.2))
	k.blocker(root, Vector3(0.5, 4, 5), Vector3(60.2, 2, 2.2))
	# Past Grace, the path carries on round a bend, and that's the way.
	var sign := k.group(root, Vector3(57.5, 0, 3.8), 0)
	k.box(sign, Vector3(0.1, 1.8, 0.1), Vector3(0, 0.9, 0), Kit.WOOD_DARK)
	k.box(sign, Vector3(1.2, 0.25, 0.04), Vector3(0.3, 1.6, 0), Kit.WOOD_LIGHT, {"rot": Vector3(0, 0, 4)})
	k.words(sign, "HOLLOW JUNCTION 3", Vector3(0.3, 1.6, 0.03), Vector3(0, 0, 4), 0.004, Color(0.2, 0.15, 0.1))


func _trees_and_reeds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1414
	# The far bank: willows and pines. The near side: a few behind the hedge.
	for i in 40:
		var p := Vector3(rng.randf_range(-62, 62), 0, rng.randf_range(-30, -10))
		if rng.randf() < 0.35:
			trees.oak(root, p, rng.randf_range(6, 9), {"bare": 0.5})
		else:
			trees.pine(root, p, rng.randf_range(9, 16), {"solid": false})
	for i in 22:
		var p := Vector3(rng.randf_range(-62, 62), 0, rng.randf_range(7, 17))
		if p.x > -38 and p.x < -22:
			continue
		if rng.randf() < 0.3:
			trees.dead(root, p, rng.randf_range(5, 8), {"extras": false})
		else:
			trees.birch(root, p, rng.randf_range(5, 7))
	# Reeds along both banks.
	var reed := PrismMesh.new()
	reed.size = Vector3(0.12, 0.9, 0.02)
	var xf: Array = []
	for i in 400:
		var z := -0.5 if rng.randf() < 0.5 else -7.6
		var p := Vector3(rng.randf_range(-60, 60), WATER_LOW + 0.4, z + rng.randf_range(-0.3, 0.3))
		if absf(p.x) < 7.0 or (p.x > -24 and p.x < -7 and z > -1):
			continue  # the lock, the narrowboat
		var s := rng.randf_range(0.6, 1.3)
		xf.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), ORIGIN + p))
	k.scatter(world, reed, Color(0.45, 0.48, 0.3), xf)
	# A heron, standing very still in the shallows.
	var heron := k.group(root, Vector3(-36, WATER_LOW, -6.8), 30)
	k.box(heron, Vector3(0.03, 0.6, 0.03), Vector3(0, 0.3, 0), Color(0.4, 0.38, 0.3))
	k.ball(heron, Vector3(0.25, 0.3, 0.5), Vector3(0, 0.75, 0), Color(0.6, 0.62, 0.65), {"sides": 6})
	k.beam(heron, Vector3(0, 0.85, 0.2), Vector3(0, 1.25, 0.3), 0.05, Color(0.75, 0.75, 0.75))
	k.ball(heron, Vector3(0.1, 0.1, 0.14), Vector3(0, 1.28, 0.33), Color(0.85, 0.85, 0.85), {"sides": 5})
	k.box(heron, Vector3(0.025, 0.025, 0.25), Vector3(0, 1.27, 0.48), Color(0.8, 0.65, 0.3))
