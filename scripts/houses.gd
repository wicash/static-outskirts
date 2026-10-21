## The houses of Alder Street: shells with real window and door openings,
## roofs, porches, and furnished interiors that each tell a small story.
## A house's front faces local +Z; the street side.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Furniture := preload("res://scripts/furniture.gd")
const Radio := preload("res://scripts/radio.gd")
const Bed := preload("res://scripts/bed.gd")

const T := 0.2          # wall thickness
const DOOR_W := 1.0
const DOOR_H := 2.1
const TRIM := Color(0.85, 0.83, 0.76)

var k: Kit
var f: Furniture


func _init(kit: Kit) -> void:
	k = kit
	f = Furniture.new(kit)


# --- Shell ---------------------------------------------------------------------------

## spec keys: w, d, h, walls, pattern, inside, floor, roof, door_x, door ("open", "closed",
## "boarded", "missing"), windows ([side, offset, state, curtain]), partition ([x, door_z]),
## chimney, porch, number, burnt, roofless.
func shell(parent: Node, pos: Vector3, spec: Dictionary) -> Node3D:
	var w: float = spec.get("w", 8.0)
	var d: float = spec.get("d", 7.0)
	var h: float = spec.get("h", 2.7)
	var walls: Color = spec.get("walls", Color(0.7, 0.65, 0.55))
	var pattern: int = spec.get("pattern", Kit.Pattern.SIDING)
	var inside: Color = spec.get("inside", Color(0.78, 0.74, 0.64))
	var burnt: bool = spec.get("burnt", false)
	var door_x: float = spec.get("door_x", 0.0)

	var root := k.group(parent, pos, 0.0 if pos.z < 0 else 180.0)
	root.set_meta("size", Vector3(w, h, d))

	# Gather openings per wall, in each wall's own left-to-right coordinates.
	var openings := {"front": [], "back": [], "left": [], "right": []}
	openings.front.append([door_x, DOOR_W, 0.0, DOOR_H, "door"])
	for win in spec.get("windows", []):
		var side: String = win[0]
		var off: float = win[1]
		var local_x := off if side == "front" else (-off if side == "back" else (off if side == "left" else -off))
		var bottom := 1.45 if win.size() > 4 and win[4] == "high" else 0.9
		openings[side].append([local_x, 1.1, bottom, 2.05, win[2], win[3] if win.size() > 3 else null])

	_wall(root, Vector3(0, 0, d / 2.0), 0, w + T, h, openings.front, walls, pattern, inside, burnt)
	_wall(root, Vector3(0, 0, -d / 2.0), 180, w + T, h, openings.back, walls, pattern, inside, burnt)
	_wall(root, Vector3(-w / 2.0, 0, 0), -90, d - T, h, openings.left, walls, pattern, inside, burnt)
	_wall(root, Vector3(w / 2.0, 0, 0), 90, d - T, h, openings.right, walls, pattern, inside, burnt)

	if spec.has("partition"):
		var p: Array = spec.partition
		_wall(root, Vector3(p[0], 0, 0), -90, d - T, h, [[p[1], 0.9, 0.0, DOOR_H, "gap"]], inside, Kit.Pattern.WALLPAPER, inside, burnt, 0.1)

	# Door.
	_door(root, Vector3(door_x, 0, d / 2.0), spec.get("door", "open"), spec.get("door_color", Color(0.45, 0.2, 0.18)))

	# Floor, skirting, ceiling.
	var floor_col: Color = spec.get("floor", Kit.WOOD_LIGHT)
	k.box(root, Vector3(w, 0.03, d), Vector3(0, 0.015, 0), floor_col.darkened(0.5) if burnt else floor_col, {"pattern": Kit.Pattern.PLANKS})
	for s in [-1.0, 1.0]:
		k.box(root, Vector3(w - 0.2, 0.1, 0.02), Vector3(0, 0.08, s * (d / 2.0 - T / 2.0 - 0.02)), inside.darkened(0.35))
		k.box(root, Vector3(0.02, 0.1, d - 0.2), Vector3(s * (w / 2.0 - T / 2.0 - 0.02), 0.08, 0), inside.darkened(0.35))
	if not spec.get("roofless", false):
		k.box(root, Vector3(w, 0.06, d), Vector3(0, h + 0.03, 0), inside.lightened(0.25))
		_roof(root, w, d, h, walls, pattern, spec.get("roof", Color(0.35, 0.22, 0.18)), spec.get("chimney", true))
	else:
		_ruined_roof(root, w, d, h)

	# Plinth and porch.
	for s in [-1.0, 1.0]:
		k.box(root, Vector3(0.04, 0.3, d + T), Vector3(s * (w / 2.0 + T / 2.0 + 0.02), 0.15, 0), Kit.CONCRETE)
	k.box(root, Vector3(w + T, 0.3, 0.04), Vector3(0, 0.15, -d / 2.0 - T / 2.0 - 0.02), Kit.CONCRETE)
	if spec.get("porch", true):
		_porch(root, door_x, d, spec.get("number", ""), burnt)
	return root


## A wall along local X with openings cut out of it. Its outside faces local +Z.
func _wall(root: Node3D, pos: Vector3, turn: float, length: float, h: float, openings: Array,
		outer: Color, pattern: int, inside: Color, burnt: bool, thick := T) -> void:
	var g := k.group(root, pos, turn)
	openings.sort_custom(func(a, b): return a[0] < b[0])
	var x := -length / 2.0
	for o in openings:
		var left: float = o[0] - o[1] / 2.0
		var right: float = o[0] + o[1] / 2.0
		_segment(g, x, left, 0.0, h, outer, pattern, inside, burnt, thick, h)
		if o[2] > 0.0:
			_segment(g, left, right, 0.0, o[2], outer, pattern, inside, false, thick, h)
		_segment(g, left, right, o[3], h, outer, pattern, inside, burnt, thick, h)
		if o[4] != "door" and o[4] != "gap":
			_window(g, o[0], o[1], o[2], o[3], o[4], o[5], thick)
		x = right
	_segment(g, x, length / 2.0, 0.0, h, outer, pattern, inside, burnt, thick, h)


func _segment(g: Node3D, x0: float, x1: float, y0: float, y1: float, outer: Color, pattern: int, inside: Color, burnt: bool, thick: float, h: float) -> void:
	if x1 - x0 < 0.01 or y1 - y0 < 0.01:
		return
	if burnt and y1 >= h - 0.01:
		y1 = h * k.rng.randf_range(0.45, 1.0)  # walls broken off at uneven heights
		if y1 - y0 < 0.1:
			return
	var size := Vector3(x1 - x0, y1 - y0, thick)
	var centre := Vector3((x0 + x1) / 2.0, (y0 + y1) / 2.0, 0)
	k.box(g, size, centre, outer, {"solid": true, "pattern": pattern})
	k.box(g, Vector3(size.x, size.y, 0.01), centre - Vector3(0, 0, thick / 2.0 + 0.006), inside, {"pattern": Kit.Pattern.WALLPAPER})


func _window(g: Node3D, cx: float, w: float, b: float, top: float, state: String, curtain: Variant, thick: float) -> void:
	var hh := top - b
	var cy := (b + top) / 2.0
	var out := thick / 2.0
	# Frame and cross bars.
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.07, hh + 0.1, thick + 0.04), Vector3(cx + s * (w / 2.0 - 0.02), cy, 0), TRIM)
	k.box(g, Vector3(w + 0.1, 0.07, thick + 0.04), Vector3(cx, top - 0.02, 0), TRIM)
	k.box(g, Vector3(w + 0.1, 0.06, thick + 0.04), Vector3(cx, b + 0.02, 0), TRIM)
	k.box(g, Vector3(w + 0.25, 0.05, 0.16), Vector3(cx, b - 0.03, out + 0.06), TRIM.darkened(0.15))  # sill
	if state != "boarded" and state != "none":
		k.box(g, Vector3(0.04, hh, 0.05), Vector3(cx, cy, 0), TRIM)
		k.box(g, Vector3(w, 0.04, 0.05), Vector3(cx, b + hh * 0.62, 0), TRIM)
	match state:
		"ok":
			k.pane(g, Vector3(w - 0.08, hh - 0.08, 0.015), Vector3(cx, cy, 0))
		"broken":
			k.quad(g, Vector3(cx - w / 2.0 + 0.04, b + 0.04, 0), Vector3(cx + w / 2.0 - 0.04, b + 0.04, 0),
				Vector3(cx + w / 2.0 - 0.04, b + hh * 0.3, 0), Vector3(cx - w * 0.1, b + hh * 0.55, 0), k.glass_mat(0.5))
			k.quad(g, Vector3(cx - w / 2.0 + 0.04, top - 0.04, 0), Vector3(cx - w * 0.15, top - 0.04, 0),
				Vector3(cx - w / 2.0 + 0.04, top - hh * 0.4, 0), Vector3(cx - w / 2.0 + 0.04, top - hh * 0.4, 0), k.glass_mat(0.5))
			f.shards(g, Vector3(cx, 0, -0.6), 0.5)
		"boarded":
			k.box(g, Vector3(w - 0.08, hh - 0.08, 0.02), Vector3(cx, cy, -0.02), Color(0.08, 0.08, 0.08))
			for i in 3:
				var y := b + 0.15 + i * (hh - 0.3) / 2.0
				k.box(g, Vector3(w + 0.3, 0.16, 0.03), Vector3(cx, y, out + 0.03), Kit.WOOD_LIGHT.darkened(k.rng.randf_range(0.0, 0.3)),
					{"rot": Vector3(0, 0, k.rng.randf_range(-8, 8))})
	if curtain != null:
		var cc: Color = curtain
		k.box(g, Vector3(w + 0.4, 0.03, 0.03), Vector3(cx, top + 0.1, -out - 0.08), Kit.METAL)
		for s in [-1.0, 1.0]:
			k.box(g, Vector3(w * 0.32, hh + 0.25, 0.04), Vector3(cx + s * (w / 2.0 - w * 0.1 + 0.08), cy - 0.02, -out - 0.08), cc, {"pattern": Kit.Pattern.WALLPAPER})


func _door(root: Node3D, pos: Vector3, state: String, color: Color) -> void:
	var g := k.group(root, pos, 0)
	for s in [-1.0, 1.0]:
		k.box(g, Vector3(0.08, DOOR_H + 0.05, T + 0.05), Vector3(s * (DOOR_W / 2.0 + 0.0), DOOR_H / 2.0, 0), TRIM)
	k.box(g, Vector3(DOOR_W + 0.16, 0.08, T + 0.05), Vector3(0, DOOR_H + 0.02, 0), TRIM)
	if state == "missing":
		return
	var hinge := k.group(g, Vector3(-DOOR_W / 2.0 + 0.04, 0, -T / 2.0 + 0.03), 75.0 if state == "open" else 0.0)
	var panel_w := DOOR_W - 0.08
	k.box(hinge, Vector3(panel_w, DOOR_H - 0.03, 0.05), Vector3(panel_w / 2.0, DOOR_H / 2.0, 0), color, {"solid": true})
	for z in [-0.03, 0.03]:
		for i in 2:
			for j in 2:
				k.box(hinge, Vector3(panel_w * 0.36, 0.7, 0.01), Vector3(panel_w * (0.27 + j * 0.46), 0.45 + i * 0.95, z), color.darkened(0.15))
		k.ball(hinge, Vector3(0.06, 0.06, 0.04), Vector3(panel_w - 0.1, 1.0, z * 1.6), Color(0.75, 0.65, 0.35))
	k.box(hinge, Vector3(0.25, 0.04, 0.06), Vector3(panel_w / 2.0, 1.25, 0), Color(0.7, 0.62, 0.35))  # letterbox
	if state == "boarded":
		for i in 3:
			k.box(g, Vector3(DOOR_W + 0.3, 0.16, 0.03), Vector3(0, 0.5 + i * 0.6, T / 2.0 + 0.05), Kit.WOOD_LIGHT.darkened(0.2),
				{"rot": Vector3(0, 0, 25.0 if i == 1 else -10.0)})


func _roof(root: Node3D, w: float, d: float, h: float, walls: Color, pattern: int, color: Color, chimney: bool) -> void:
	var rise := 1.5
	var over := 0.45
	var ridge := Vector3(0, h + rise, 0)
	for s in [-1.0, 1.0]:
		var eave := Vector3(0, h + rise - (d / 2.0 + over) * rise / (d / 2.0), s * (d / 2.0 + over))
		var slab := k.box(root, Vector3(w + 0.7, 0.12, 1.0), Vector3.ZERO, color, {"pattern": Kit.Pattern.SHINGLES})
		# Turn the slab so its depth runs from the ridge down to the eave.
		var dir := (eave - ridge)
		var z := dir.normalized()
		var x := Vector3.RIGHT
		slab.basis = Basis(x, z.cross(x), z * dir.length())
		slab.position = (ridge + eave) / 2.0 + Vector3(0, 0.06, 0)
		# Gutter and fascia along the eave.
		k.box(root, Vector3(w + 0.7, 0.16, 0.04), eave + Vector3(0, -0.02, s * 0.02), TRIM.darkened(0.2))
		k.box(root, Vector3(w + 0.7, 0.08, 0.1), eave + Vector3(0, -0.1, s * 0.08), Kit.METAL.darkened(0.2))
		k.box(root, Vector3(0.07, eave.y - 0.1, 0.07), Vector3(w / 2.0 + 0.2, (eave.y - 0.1) / 2.0, s * (d / 2.0 + 0.4)), Kit.METAL.darkened(0.2))  # downpipe
	k.box(root, Vector3(w + 0.72, 0.1, 0.22), ridge + Vector3(0, 0.1, 0), color.darkened(0.25))  # ridge cap
	# Gable ends in the wall colour.
	for s in [-1.0, 1.0]:
		k.prism(root, Vector3(d, rise, 0.2), Vector3(s * (w / 2.0), h + rise / 2.0, 0), walls, {"rot": Vector3(0, 90, 0), "pattern": pattern})
		k.box(root, Vector3(0.5, 0.4, 0.04), Vector3(s * (w / 2.0 + 0.11), h + rise * 0.45, 0), Color(0.18, 0.18, 0.18), {"rot": Vector3(0, 90, 0)})  # vent
	if chimney:
		var cx := -w / 2.0 + 1.2
		k.box(root, Vector3(0.6, 2.0, 0.6), Vector3(cx, h + rise + 0.2, -0.7), Color(0.5, 0.3, 0.24), {"pattern": Kit.Pattern.BRICK})
		k.box(root, Vector3(0.72, 0.08, 0.72), Vector3(cx, h + rise + 1.22, -0.7), Kit.CONCRETE)
		k.cyl(root, 0.1, 0.3, Vector3(cx, h + rise + 1.4, -0.7), Color(0.55, 0.35, 0.28), {"sides": 6})
	# An aerial bent toward the north.
	k.cyl(root, 0.02, 1.4, Vector3(w / 2.0 - 1.0, h + rise + 0.7, 0), Kit.METAL, {"sides": 4})
	for i in 4:
		k.box(root, Vector3(0.02, 0.02, 0.8 - i * 0.12), Vector3(w / 2.0 - 1.0 + 0.1 * i, h + rise + 1.3, 0), Kit.METAL, {"rot": Vector3(0, 0, 0)})


func _ruined_roof(root: Node3D, w: float, d: float, h: float) -> void:
	# Charred rafters, some still up, some fallen into the house.
	for i in 6:
		var x := -w / 2.0 + 0.6 + i * (w - 1.2) / 5.0
		if i % 2 == 0:
			k.beam(root, Vector3(x, h, -d / 2.0), Vector3(x, h + 1.3, -0.3), 0.14, Kit.SOOT)
		else:
			k.beam(root, Vector3(x, h * 0.8, -d / 2.0 + 0.3), Vector3(x + 0.6, 0.1, 0.5), 0.14, Kit.SOOT)
	k.beam(root, Vector3(-w / 2.0, h, -d / 2.0 + 0.1), Vector3(w / 2.0, h, -d / 2.0 + 0.1), 0.18, Kit.SOOT)
	var slab := k.box(root, Vector3(3.5, 0.12, 2.6), Vector3(1.2, 1.1, -0.6), Color(0.15, 0.13, 0.12), {"pattern": Kit.Pattern.SHINGLES})
	slab.rotation_degrees = Vector3(32, 10, 5)


func _porch(root: Node3D, door_x: float, d: float, number: String, burnt: bool) -> void:
	var z := d / 2.0
	k.box(root, Vector3(1.8, 0.16, 0.9), Vector3(door_x, 0.08, z + 0.55), Kit.CONCRETE, {"pattern": Kit.Pattern.CONCRETE})
	k.box(root, Vector3(1.6, 0.08, 0.4), Vector3(door_x, 0.04, z + 1.2), Kit.CONCRETE.darkened(0.1))
	k.box(root, Vector3(0.7, 0.02, 0.45), Vector3(door_x, 0.17, z + 0.45), Color(0.35, 0.28, 0.2))  # doormat
	if burnt:
		return
	k.box(root, Vector3(2.0, 0.08, 1.2), Vector3(door_x, 2.55, z + 0.6), Color(0.3, 0.3, 0.32), {"rot": Vector3(-8, 0, 0)})
	for s in [-1.0, 1.0]:
		k.box(root, Vector3(0.1, 2.5, 0.1), Vector3(door_x + s * 0.9, 1.25, z + 1.1), TRIM)
	# Porch lamp (no power) and house number.
	k.box(root, Vector3(0.14, 0.2, 0.12), Vector3(door_x + 0.75, 1.9, z + 0.17), Color(0.15, 0.15, 0.15))
	k.box(root, Vector3(0.1, 0.14, 0.04), Vector3(door_x + 0.75, 1.88, z + 0.23), Color(0.85, 0.82, 0.65))
	if number != "":
		k.box(root, Vector3(0.22, 0.26, 0.02), Vector3(door_x - 0.8, 1.6, z + 0.11), Color(0.15, 0.2, 0.25))
		k.words(root, number, Vector3(door_x - 0.8, 1.6, z + 0.125), Vector3.ZERO, 0.007, Color(0.9, 0.88, 0.8))


# --- The houses ----------------------------------------------------------------------

## No. 4: your house. Lamp-lit, a little shabby, slowly becoming home.
func your_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Color(0.72, 0.64, 0.52), "inside": Color(0.8, 0.72, 0.58), "roof": Color(0.42, 0.24, 0.2),
		"door_x": 0.6, "door": "open", "door_color": Color(0.3, 0.42, 0.38), "number": "4",
		"partition": [-1.4, 1.8],
		"windows": [["front", -2.6, "ok", Kit.FABRIC_BLUE], ["front", 2.6, "ok", Kit.FABRIC_MUSTARD],
			["back", 1.9, "ok", null, "high"], ["left", -1.0, "boarded", null], ["right", 1.4, "ok", Kit.FABRIC_MUSTARD]],
	})

	# Bedroom.
	f.bed(h, Vector3(-2.75, 0, -2.3), 0, 0.95, Kit.FABRIC_BLUE)
	k.thing(h, Vector3(0.95, 0.6, 2.0), Vector3(-2.75, 0.3, -2.3), "Go to bed", [], Bed)
	f.nightstand(h, Vector3(-1.9, 0, -3.05), 0)
	f.candle(h, Vector3(-1.95, 0.5, -3.1), true)
	var photo := k.thing(h, Vector3(0.14, 0.18, 0.06), Vector3(-1.75, 0.6, -3.1), "Look at the photo",
		["You and your mum at the seaside. You were nine and furious about the sand."])
	f.picture(photo, Vector3.ZERO, 0, Vector2(0.14, 0.18), Color(0.45, 0.6, 0.7))
	f.wardrobe(h, Vector3(-3.6, 0, 0.3), 90)
	f.rug(h, Vector3(-2.7, 0, 0.2), 0, Vector2(1.4, 1.0), Kit.FABRIC_BLUE)
	f.chair(h, Vector3(-2.0, 0, 0.9), -120, Kit.WOOD_LIGHT)
	k.box(h, Vector3(0.38, 0.06, 0.36), Vector3(-2.0, 0.5, 0.9), Kit.FABRIC_GREEN, {"rot": Vector3(0, 30, 3)})  # jumper on the chair
	f.boots(h, Vector3(-3.4, 0, 1.6), 30)

	# Kitchen along the back wall.
	f.stove(h, Vector3(0.35, 0, -3.1), 0)
	var kettle := k.thing(h, Vector3(0.3, 0.25, 0.3), Vector3(0.35, 1.0, -3.0), "Make tea", [
		"You light the camping burner and wait for the kettle. Tea tastes of smoke now. It's perfect.",
		"Another cup. Biscuit watches the steam.",
	])
	f.kettle(kettle, Vector3(0, -0.1, 0))
	f.counter(h, Vector3(1.9, 0, -3.1), 0, 2.4, Color(0.6, 0.66, 0.6), -0.3)
	f.fridge(h, Vector3(3.5, 0, -3.05), 0)
	f.plant(h, Vector3(2.9, 0.9, -3.15), true, 0.8)
	f.crate(h, Vector3(3.45, 0, -2.1), 10)
	for i in 5:
		k.cyl(h, 0.04, 0.1, Vector3(3.3 + (i % 3) * 0.1, 0.45, -2.2 + (i / 3) * 0.1), Color(0.7, 0.3, 0.2) if i % 2 else Color(0.7, 0.7, 0.68), {"sides": 6})
	for i in 3:
		k.cyl(h, 0.12, 0.4, Vector3(3.6, 0.2, -1.5 + i * 0.28), Color(0.6, 0.7, 0.8), {"sides": 6})  # water jugs

	# Table with the radio.
	f.table(h, Vector3(2.7, 0, 0.0), 90, Vector2(1.2, 0.8), Kit.WOOD, Kit.FABRIC_RED.lightened(0.3))
	f.chair(h, Vector3(1.95, 0, 0.0), 90)
	f.chair(h, Vector3(3.45, 0, 0.0), -90)
	var radio := k.thing(h, Vector3(0.5, 0.3, 0.25), Vector3(2.7, 0.93, -0.3), "Switch on the radio", [
		"...kssh... this is... broadcasting on... if anyone can hear this...",
		"...the evacuation buses never came to Alder Street. We waited by the overpass until dark...",
		"...ninety-one days. The lights in the woods are still on. Who is keeping them on?...",
		"...follow the tower past the treeline. Someone is still reading the names...",
		"Only static now. The signal felt stronger when the dial pointed north, toward the trees.",
	], Radio)
	radio.rotation_degrees.y = -90
	k.box(radio, Vector3(0.5, 0.3, 0.25), Vector3.ZERO, Kit.WOOD_DARK)
	k.box(radio, Vector3(0.22, 0.2, 0.01), Vector3(-0.1, 0, 0.13), Color(0.6, 0.55, 0.45), {"pattern": Kit.Pattern.WALLPAPER})  # speaker cloth
	k.box(radio, Vector3(0.16, 0.06, 0.01), Vector3(0.14, 0.06, 0.13), Color(0.85, 0.8, 0.6), {"glow": 0.4})  # dial window
	for x in [0.09, 0.19]:
		k.cyl(radio, 0.025, 0.03, Vector3(x, -0.07, 0.135), Color(0.15, 0.12, 0.1), {"rot": Vector3(90, 0, 0), "sides": 6})
	k.beam(radio, Vector3(0.2, 0.15, -0.05), Vector3(0.35, 0.65, -0.1), 0.01, Kit.METAL)
	k.box(h, Vector3(0.2, 0.01, 0.28), Vector3(2.75, 0.775, 0.3), Kit.PAPER, {"rot": Vector3(0, 15, 0)})  # notebook
	f.bowl(h, Vector3(2.5, 0.77, 0.35), Color(0.85, 0.82, 0.75))
	var map := k.thing(h, Vector3(0.04, 0.6, 0.8), Vector3(3.87, 1.5, -1.3), "Look at the map", [
		"A paper map of Alder Hollow. You've circled the radio tower in red pencil.",
		"The forest takes up the whole top of the map. Someone, maybe you, wrote \"lights?\" over it.",
	])
	k.box(map, Vector3(0.01, 0.55, 0.75), Vector3.ZERO, Color(0.85, 0.82, 0.68))
	k.box(map, Vector3(0.012, 0.25, 0.4), Vector3(0, 0.1, -0.1), Color(0.4, 0.5, 0.35))  # the forest
	k.ring(map, 0.03, 0.045, Vector3(-0.01, 0.2, 0.15), Color(0.8, 0.15, 0.1), Vector3(0, 0, 90))
	f.clock(h, Vector3(3.88, 2.05, 0.6), -90)

	# Sitting corner.
	f.armchair(h, Vector3(-0.55, 0, -1.7), 45, Kit.FABRIC_MUSTARD)
	f.table(h, Vector3(-1.0, 0, -2.75), 0, Vector2(0.45, 0.45), Kit.WOOD_DARK)
	f.lamp(h, Vector3(-1.0, 0.77, -2.75), true)
	f.bookshelf(h, Vector3(-1.15, 0, -0.2), 90, 1.8, 0.9)
	k.thing(h, Vector3(0.3, 1.8, 0.9), Vector3(-1.15, 0.9, -0.2), "Browse the books", [
		"Gardening books, two thrillers, a road atlas, and a book about cats you don't remember buying.",
	])
	f.rug(h, Vector3(0.9, 0, 0.4), 0, Vector2(2.4, 1.6), Kit.FABRIC_RED)
	f.picture(h, Vector3(-1.29, 1.6, -1.8), 90, Vector2(0.5, 0.35), Color(0.5, 0.55, 0.4))

	# By the door: coats, boots and Biscuit's corner.
	f.coat_rack(h, Vector3(-0.6, 0, 3.0), Kit.FABRIC_GREEN)
	f.boots(h, Vector3(-0.05, 0, 3.1), 10)
	f.cat_bed(h, Vector3(2.0, 0, 2.85), 0, Kit.FABRIC_GREEN)
	k.thing(h, Vector3(0.6, 0.15, 0.6), Vector3(2.0, 0.07, 2.85), "Look at the old blanket", [
		"A folded blanket by the door. Something small has been sleeping on it.",
	])
	f.bowl(h, Vector3(2.6, 0, 3.05), Kit.FABRIC_RED)

	# The pendant lamp: the one warm light on the street.
	k.cyl(h, 0.008, 0.45, Vector3(1.0, 2.47, -0.3), Color(0.1, 0.1, 0.1), {"sides": 3})
	k.cyl(h, 0.2, 0.16, Vector3(1.0, 2.2, -0.3), Color(0.8, 0.55, 0.3), {"top": 0.06, "sides": 8, "glow": 0.8})
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.42)
	light.light_energy = 1.5
	light.omni_range = 7.5
	light.position = Vector3(1.0, 2.0, -0.3)
	h.add_child(light)
	return h


## No. 6: the Okafors. Grace left for her sister's "back Sunday" and asked someone to feed Biscuit.
func okafor_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Color(0.58, 0.64, 0.68), "inside": Color(0.76, 0.68, 0.6), "roof": Color(0.3, 0.3, 0.34),
		"door_x": 0.0, "door": "open", "door_color": Color(0.55, 0.15, 0.15), "number": "6",
		"partition": [1.6, -1.8], "floor": Color(0.55, 0.42, 0.3),
		"windows": [["front", -2.5, "ok", Kit.FABRIC_RED], ["front", 2.7, "ok", Kit.FABRIC_RED],
			["back", -1.5, "ok", null, "high"], ["left", 0.0, "ok", Kit.FABRIC_RED], ["right", 1.5, "ok", null]],
	})
	# Living room.
	f.sofa(h, Vector3(-3.4, 0, -0.6), 90, Color(0.5, 0.35, 0.45))
	k.box(h, Vector3(0.7, 0.05, 0.9), Vector3(-3.4, 0.62, -0.1), Color(0.75, 0.6, 0.3), {"rot": Vector3(0, 80, 8), "pattern": Kit.Pattern.TILES})  # knitted throw
	f.coffee_table(h, Vector3(-2.3, 0, -0.6), 90)
	k.cyl(h, 0.045, 0.1, Vector3(-2.25, 0.5, -0.4), Color(0.85, 0.85, 0.8), {"sides": 7})
	k.box(h, Vector3(0.3, 0.02, 0.22), Vector3(-2.35, 0.46, -0.9), Kit.PAPER, {"rot": Vector3(0, 20, 0)})
	f.tv(h, Vector3(-0.8, 0, -0.6), -90)
	k.thing(h, Vector3(0.6, 0.6, 0.6), Vector3(-0.8, 0.75, -0.6), "Look at the TV", [
		"Dead, of course. A sticky note on the screen in neat handwriting: \"Emergency channel: radio 4\".",
	])
	f.rug(h, Vector3(-2.3, 0, -0.6), 90, Vector2(2.4, 1.8), Color(0.45, 0.3, 0.4))
	var photos := k.thing(h, Vector3(0.1, 0.8, 1.6), Vector3(-3.86, 1.65, 1.7), "Look at the photos", [
		"Grace Okafor and a woman with the same smile. On the back: \"Me and Patience, Lagos, 1998.\"",
		"A younger Grace holding a tiny ginger kitten up to the camera.",
	])
	for i in 3:
		f.picture(photos, Vector3(0, (i % 2) * 0.3 - 0.15, -0.55 + i * 0.55), 90, Vector2(0.35, 0.28), [Color(0.6, 0.5, 0.4), Color(0.45, 0.55, 0.6), Color(0.7, 0.55, 0.35)][i])
	f.plant(h, Vector3(-3.5, 0, -2.9), false, 1.4)
	f.clock(h, Vector3(-1.0, 2.0, -3.38), 0)

	# Kitchen and the note.
	f.counter(h, Vector3(-1.2, 0, -3.1), 0, 2.4, Color(0.75, 0.72, 0.6), 0.2, -0.8)
	f.table(h, Vector3(0.4, 0, -1.6), 0, Vector2(0.9, 0.7), Kit.WOOD_LIGHT)
	f.chair(h, Vector3(0.4, 0, -0.95), 180)
	var note := k.thing(h, Vector3(0.3, 0.05, 0.22), Vector3(0.4, 0.79, -1.6), "Read the note", [
		"\"Gone to my sister's in the city. Back Sunday. Feed Biscuit! Tins are in the cupboard. - G.\"",
		"The note is from March. She only took a small bag; her good coat is still on the hook.",
	])
	k.box(note, Vector3(0.28, 0.005, 0.2), Vector3(0, -0.02, 0), Kit.PAPER, {"rot": Vector3(0, 10, 0)})
	var tins := k.thing(h, Vector3(0.6, 0.3, 0.3), Vector3(-0.5, 0.95, -3.2), "Take the cat food", [
		"Six tins of cat food. Biscuit is going to like you a lot more now.",
		"The cupboard is empty.",
	])
	for i in 6:
		k.cyl(tins, 0.04, 0.06, Vector3(-0.2 + i * 0.08, -0.12, 0), Color(0.75, 0.55, 0.3), {"sides": 6})

	# Biscuit's things.
	var bowl := k.thing(h, Vector3(0.3, 0.1, 0.3), Vector3(-0.8, 0.05, 2.9), "Look at the bowl", ["A cat bowl with BISCUIT painted on it. Empty."])
	f.bowl(bowl, Vector3(0, -0.05, 0), Color(0.75, 0.3, 0.25))
	k.cyl(h, 0.06, 0.8, Vector3(-1.6, 0.4, 2.9), Color(0.75, 0.65, 0.45), {"sides": 6, "pattern": Kit.Pattern.TILES})  # scratching post
	k.cyl(h, 0.22, 0.04, Vector3(-1.6, 0.02, 2.9), Kit.FABRIC_GREEN, {"sides": 6})
	f.coat_rack(h, Vector3(0.9, 0, 3.0), Color(0.55, 0.4, 0.55))

	# The half-packed suitcase she never needed.
	k.box(h, Vector3(0.6, 0.18, 0.42), Vector3(0.8, 0.09, 1.0), Color(0.3, 0.35, 0.5))
	k.box(h, Vector3(0.6, 0.42, 0.04), Vector3(0.8, 0.3, 0.77), Color(0.3, 0.35, 0.5), {"rot": Vector3(-20, 0, 0)})
	k.box(h, Vector3(0.5, 0.06, 0.34), Vector3(0.8, 0.19, 1.0), Color(0.8, 0.6, 0.6), {"pattern": Kit.Pattern.WALLPAPER})

	# Bedroom behind the partition.
	f.bed(h, Vector3(2.75, 0, -2.3), 0, 1.4, Color(0.6, 0.45, 0.6))
	f.nightstand(h, Vector3(3.68, 0, -3.05), 0)
	var tag := k.thing(h, Vector3(0.12, 0.08, 0.12), Vector3(3.68, 0.54, -3.0), "Pick up the collar", [
		"A red collar with a brass tag: \"BISCUIT. If found, call Grace, 6 Alder St.\"",
		"You pocket it. It feels like a promise.",
	])
	k.ring(tag, 0.04, 0.055, Vector3(0, -0.03, 0), Color(0.7, 0.15, 0.12))
	k.cyl(tag, 0.02, 0.005, Vector3(0.05, -0.03, 0.04), Color(0.8, 0.65, 0.3), {"sides": 6})
	f.wardrobe(h, Vector3(3.55, 0, 0.9), -90, true)
	f.picture(h, Vector3(2.75, 1.6, -3.38), 0, Vector2(0.6, 0.4), Color(0.35, 0.5, 0.45))
	return h


## No. 3: the Bells. A young family who left in a hurry on the morning of the "drill".
func bell_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Color(0.74, 0.66, 0.5), "inside": Color(0.82, 0.78, 0.6), "roof": Color(0.25, 0.32, 0.27),
		"door_x": 0.3, "door": "open", "door_color": Color(0.2, 0.35, 0.55), "number": "3",
		"partition": [-1.2, 1.9],
		"windows": [["front", -2.6, "broken", Kit.FABRIC_BLUE], ["front", 2.6, "ok", Kit.FABRIC_MUSTARD],
			["back", 1.5, "ok", null, "high"], ["right", 0.2, "ok", null]],
	})
	# Kids' room.
	f.bunk_bed(h, Vector3(-3.35, 0, -2.3), 0)
	var walkie := k.thing(h, Vector3(0.12, 0.22, 0.1), Vector3(-3.3, 0.55, -1.6), "Pick up the walkie-talkie", [
		"A child's yellow walkie-talkie. Taped to the back: a card with \"96.4\" written in crayon.",
		"You turn the radio dial to 96.4 in your head. You'll try it tonight.",
	])
	k.box(walkie, Vector3(0.1, 0.2, 0.06), Vector3.ZERO, Color(0.9, 0.75, 0.2))
	k.cyl(walkie, 0.008, 0.15, Vector3(0.03, 0.16, 0), Color(0.1, 0.1, 0.1), {"sides": 3})
	f.desk(h, Vector3(-2.3, 0, -3.1), 0, Color(0.8, 0.75, 0.6))
	f.chair(h, Vector3(-2.4, 0, -2.5), 180, Kit.FABRIC_RED)
	for i in 6:
		k.box(h, Vector3(0.012, 0.012, 0.1), Vector3(-2.6 + i * 0.05, 0.73, -3.0), [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.FABRIC_MUSTARD, Kit.FABRIC_GREEN, Color(0.6, 0.3, 0.6), Color(0.1, 0.1, 0.1)][i], {"rot": Vector3(0, k.rng.randf_range(-40, 40), 0)})  # crayons
	f.toys(h, Vector3(-2.3, 0, 0.3))
	var drawing := k.thing(h, Vector3(0.05, 0.4, 0.5), Vector3(-1.31, 1.4, -0.8), "Look at the drawing", [
		"A child's drawing of the street: the houses, a cat, a family of four. There are three suns in the sky.",
	])
	k.box(drawing, Vector3(0.01, 0.38, 0.48), Vector3.ZERO, Kit.PAPER)
	for i in 3:
		k.cyl(drawing, 0.04, 0.012, Vector3(-0.01, 0.12, -0.15 + i * 0.13), Color(0.95, 0.6, 0.1), {"rot": Vector3(0, 0, 90), "sides": 6})
	k.box(drawing, Vector3(0.012, 0.12, 0.4), Vector3(-0.01, -0.12, 0), Color(0.4, 0.55, 0.3))
	f.boots(h, Vector3(-0.3, 0, 3.1), 0, Color(0.85, 0.25, 0.2), true)

	# Kitchen and table.
	f.stove(h, Vector3(0.2, 0, -3.1), 0)
	f.counter(h, Vector3(1.8, 0, -3.1), 0, 2.4, Color(0.85, 0.82, 0.72), 0.3)
	f.fridge(h, Vector3(3.5, 0, -3.05), 0, Color(0.7, 0.85, 0.8))
	var cal := k.thing(h, Vector3(0.05, 0.6, 0.45), Vector3(3.86, 1.6, -2.0), "Read the calendar", [
		"The calendar is still on March. Someone circled the 14th and wrote \"drill?\" next to it.",
		"Under it, in different handwriting: \"School says it's just a drill. Don't panic the kids.\"",
	])
	k.box(cal, Vector3(0.01, 0.6, 0.42), Vector3.ZERO, Kit.PAPER)
	k.box(cal, Vector3(0.012, 0.25, 0.4), Vector3(0, 0.15, 0), Color(0.45, 0.6, 0.7))
	k.ring(cal, 0.03, 0.04, Vector3(-0.01, -0.12, 0.08), Color(0.8, 0.15, 0.1), Vector3(0, 0, 90))
	f.table(h, Vector3(1.6, 0, -0.6), 0, Vector2(1.2, 0.8), Kit.WOOD_LIGHT)
	f.chair(h, Vector3(1.6, 0, -1.25), 0, Kit.WOOD_LIGHT)
	f.chair(h, Vector3(0.75, 0, -0.6), 90, Kit.WOOD_LIGHT)
	f.chair(h, Vector3(1.6, 0, 0.3), 180, Kit.WOOD_LIGHT, true)
	k.box(h, Vector3(0.3, 0.9, 0.3), Vector3(2.55, 0.45, -0.6), Color(0.85, 0.8, 0.7))  # high chair
	k.box(h, Vector3(0.45, 0.04, 0.35), Vector3(2.55, 0.9, -0.6), Color(0.85, 0.8, 0.7))
	for i in 3:
		f.bowl(h, Vector3(1.2 + i * 0.4, 0.77, -0.6), [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.FABRIC_MUSTARD][i])  # breakfast, never eaten
	f.sofa(h, Vector3(2.7, 0, 2.75), 180, Kit.FABRIC_BLUE)
	f.rug(h, Vector3(1.6, 0, 1.6), 0, Vector2(2.2, 1.4), Kit.FABRIC_MUSTARD)
	f.plant(h, Vector3(3.6, 0, 1.4), false, 1.3)
	f.clock(h, Vector3(-1.07, 2.05, 0.6), 90)
	return h


## No. 5: Mr. Lindqvist's house. He stayed. The fire came weeks later, from a candle.
func burnt_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Kit.SOOT, "inside": Color(0.18, 0.16, 0.14), "pattern": Kit.Pattern.BRICK,
		"door_x": 0.0, "door": "missing", "burnt": true, "roofless": true, "porch": true,
		"windows": [["front", -2.5, "none", null], ["front", 2.5, "none", null], ["left", 0.5, "none", null]],
	})
	f.bed(h, Vector3(2.8, 0, -2.3), 0, 1.2, Color(0.1, 0.09, 0.08), false)
	f.armchair(h, Vector3(-2.6, 0, -1.6), 30, Color(0.12, 0.1, 0.09))
	f.chair(h, Vector3(-0.5, 0, 0.5), 60, Kit.SOOT, true)
	f.stove(h, Vector3(-3.3, 0, -3.0), 0)
	for p in [Vector3(0.5, 0, -1.0), Vector3(-1.5, 0, 1.5), Vector3(2.0, 0, 1.0)]:
		f.ash_pile(h, p, k.rng.randf_range(0.8, 1.4))
	var photos := k.thing(h, Vector3(0.55, 0.45, 0.55), Vector3(1.2, 0.22, -1.4), "Look at the scorched box", [
		"Photographs, curled from the heat. The faces have all burned away except one: a small dog, smiling.",
	])
	k.box(photos, Vector3(0.5, 0.4, 0.5), Vector3.ZERO, Color(0.28, 0.22, 0.16))
	var tag := k.thing(h, Vector3(0.3, 0.12, 0.3), Vector3(-1.2, 0.05, -2.8), "Look at the dog bowl", [
		"A dented dog bowl. Next to it, a tag on a burnt lead: \"PIP. If lost, return to A. Lindqvist, 5 Alder St.\"",
	])
	f.bowl(tag, Vector3(0, -0.05, 0), Color(0.3, 0.3, 0.32))
	f.candle(h, Vector3(-2.6, 0.02, -2.6), false)
	return h


## No. 8: the Patels. Locked. Through the windows: boxes, packed and labelled.
func patel_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Color(0.6, 0.63, 0.55), "inside": Color(0.78, 0.76, 0.7), "roof": Color(0.32, 0.26, 0.24),
		"door_x": -0.5, "door": "closed", "door_color": Color(0.22, 0.25, 0.22), "number": "8",
		"windows": [["front", -2.7, "ok", Color(0.85, 0.82, 0.72)], ["front", 2.2, "ok", null],
			["back", 0.0, "ok", null], ["left", 0.0, "ok", null], ["right", -1.0, "ok", null]],
	})
	k.thing(h, Vector3(1.0, 2.1, 0.3), Vector3(-0.5, 1.05, 3.6), "Try the door", [
		"Locked. Through the glass you can see boxes stacked in the hall, all labelled in the same neat hand.",
		"A note through the letterbox, addressed to nobody: \"We've gone to Priya's school. Car won't start. Love, D.\"",
	])
	for item in [[Vector3(1.6, 0, 2.2), 10.0, "KITCHEN"], [Vector3(2.2, 0, 2.1), -5.0, "BOOKS"], [Vector3(1.9, 0.38, 2.15), 3.0, "PRIYA'S ROOM"],
			[Vector3(-2.0, 0, 1.8), 20.0, "FRAGILE"], [Vector3(-2.4, 0, 2.5), 0.0, "WINTER"]]:
		f.cardboard_box(h, item[0], item[1], item[2])
	# Furniture under dust sheets.
	k.box(h, Vector3(2.0, 0.85, 0.95), Vector3(-2.2, 0.42, -2.4), Color(0.85, 0.84, 0.8))
	k.box(h, Vector3(1.0, 1.4, 0.7), Vector3(2.5, 0.7, -2.6), Color(0.84, 0.83, 0.79))
	k.box(h, Vector3(1.2, 0.8, 0.8), Vector3(0.6, 0.4, -1.0), Color(0.86, 0.85, 0.8))
	f.rug(h, Vector3(0, 0, 0.5), 0, Vector2(2.6, 1.8), Color(0.45, 0.35, 0.55))
	return h


## No. 7: boarded up from the inside. Nobody answers.
func boarded_house(parent: Node, pos: Vector3) -> Node3D:
	var h := shell(parent, pos, {
		"walls": Color(0.55, 0.32, 0.25), "pattern": Kit.Pattern.BRICK, "inside": Color(0.6, 0.55, 0.5), "roof": Color(0.22, 0.22, 0.24),
		"door_x": 0.0, "door": "boarded", "door_color": Color(0.25, 0.25, 0.25), "number": "7", "chimney": false,
		"windows": [["front", -2.5, "boarded", null], ["front", 2.5, "boarded", null], ["left", 0.0, "boarded", null],
			["right", 0.0, "boarded", null], ["back", 0.0, "boarded", null]],
	})
	k.thing(h, Vector3(1.0, 2.1, 0.4), Vector3(0, 1.05, 3.65), "Knock on the door", [
		"You knock. Nothing. The boards are nailed from the inside.",
		"You knock again. For a second you think you hear the floor creak.",
		"Nothing. Someone has painted on the wall: NO ONE HERE.",
	])
	k.words(h, "NO ONE HERE", Vector3(2.3, 1.0, 3.62), Vector3.ZERO, 0.012, Color(0.85, 0.85, 0.82))
	return h


## The empty lot: a wild garden with a swing set, and something buried.
func empty_lot(parent: Node, pos: Vector3) -> Node3D:
	var g := k.group(parent, pos, 0)
	var steel := Color(0.4, 0.45, 0.55)
	for s in [-1.0, 1.0]:
		k.beam(g, Vector3(s * 1.4, 0, -0.7), Vector3(s * 1.4, 2.2, 0), 0.07, steel)
		k.beam(g, Vector3(s * 1.4, 0, 0.7), Vector3(s * 1.4, 2.2, 0), 0.07, steel)
	k.beam(g, Vector3(-1.5, 2.2, 0), Vector3(1.5, 2.2, 0), 0.08, steel)
	var swings: Array[Node3D] = []
	for x in [-0.6, 0.6]:
		var pivot := k.group(g, Vector3(x, 2.18, 0), 0)
		for s in [-0.2, 0.2]:
			k.box(pivot, Vector3(0.015, 1.7, 0.015), Vector3(s, -0.85, 0), Kit.METAL)
		k.box(pivot, Vector3(0.5, 0.04, 0.2), Vector3(0, -1.72, 0), Color(0.25, 0.25, 0.25))
		swings.append(pivot)
	# One swing moves a little in the wind.
	var tw := swings[1].create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(swings[1], "rotation:x", 0.18, 1.6)
	tw.tween_property(swings[1], "rotation:x", -0.12, 1.6)
	# Old tyre, wheelbarrow, dead sunflowers.
	k.ring(g, 0.2, 0.36, Vector3(2.8, 0.36, 1.5), Color(0.08, 0.08, 0.08), Vector3(75, 20, 0))
	var wb := k.group(g, Vector3(-2.8, 0, 1.8), 30)
	k.box(wb, Vector3(0.9, 0.3, 0.6), Vector3(0, 0.45, 0), Color(0.3, 0.45, 0.35), {"rot": Vector3(0, 0, 6)})
	k.cyl(wb, 0.18, 0.08, Vector3(0.55, 0.18, 0), Color(0.1, 0.1, 0.1), {"rot": Vector3(90, 0, 0), "sides": 8})
	for s in [-0.25, 0.25]:
		k.beam(wb, Vector3(0.4, 0.3, s), Vector3(-0.9, 0.55, s * 1.2), 0.04, Kit.WOOD)
	for i in 7:
		var p := Vector3(-3.5 + i * 0.5, 0, -2.4 + sin(i * 1.3) * 0.3)
		var tall := k.rng.randf_range(1.2, 1.9)
		k.beam(g, p, p + Vector3(0.1, tall, 0), 0.04, Color(0.4, 0.38, 0.25))
		k.cyl(g, 0.15, 0.05, p + Vector3(0.12, tall, 0.05), Color(0.35, 0.25, 0.15), {"rot": Vector3(70, 0, 0), "sides": 8})
	var tin := k.thing(g, Vector3(0.3, 0.15, 0.3), Vector3(0.4, 0.05, -0.9), "Dig up the tin", [
		"A biscuit tin, half buried under the swing. Inside: a cassette tape labelled \"For whoever finds this\".",
		"You'll need something that plays tapes.",
	])
	k.cyl(tin, 0.14, 0.1, Vector3.ZERO, Color(0.6, 0.2, 0.2), {"sides": 8})
	k.cyl(tin, 0.145, 0.02, Vector3(0, 0.05, 0), Color(0.75, 0.6, 0.3), {"sides": 8})
	return g
