## Signs of what happened, spread over Alder Street. The strikes were far enough
## away that the street still stands, but close enough to leave marks:
##   - the flash: pale "flash shadows" burnt onto walls, blistered paint on the
##     sides that faced the city (south, +Z)
##   - the blast wind: trees and poles leaning north, fallen trunks, roof tiles
##     on the lawns, blown-in glass on the pavements, a melted bin
##   - the fallout: grey ash drifted into the gutters, dead birds
##   - the days after: leaflets, sandbags, search marks, a decontamination tent,
##     a family shelter, a memorial, HELP painted on the road
##   - the strange: crows on the wires all facing the tower, pale moths around
##     the one working light, flowers that only open after dark, the city still
##     smoking on the horizon with a glow at night
extends RefCounted

const Kit := preload("res://scripts/kit.gd")
const Furniture := preload("res://scripts/furniture.gd")

const ASH := Color(0.62, 0.6, 0.57)
const BLEACHED := Color(0.86, 0.83, 0.76)
const SPRAY := Color(0.9, 0.42, 0.12)

var k: Kit
var f: Furniture
var world: Node3D


func _init(kit: Kit, root: Node3D) -> void:
	k = kit
	f = Furniture.new(kit)
	world = root


func build() -> void:
	_flash_wall(Vector3(-16, 0, -16.2))
	_blistered_paint()
	_fallen_trees()
	_roof_tiles()
	_glass_on_pavements()
	_ash_drifts()
	_dead_birds()
	_leaflets()
	_sandbags(Vector3(12.6, 0, -8.0))
	_search_marks()
	_decon_tent(Vector3(41, 0, -8.5))
	_warning_sign(Vector3(41.0, 0, 6.8))
	_family_shelter(Vector3(-30, 0, 19.5))
	_memorial(Vector3(-15, 0, 5.2))
	_dog_lead(Vector3(-8, 0, 5.3))
	_help_on_road(Vector3(-11, 0.03, -0.6))
	_chalk(Vector3(-26.5, 0.125, 4.4))
	_crows_on_wires()
	_moths(Vector3(3.5, 5.4, -3.9))
	_night_flowers()
	_city_smoke()
	_hotspots()


# --- The flash -------------------------------------------------------------------

## A garden wall at the back of the empty lot. The flash bleached the whole
## face pale, except where something stood in front of it.
func _flash_wall(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	k.box(g, Vector3(7.0, 2.6, 0.3), Vector3(0, 1.3, 0), Color(0.5, 0.3, 0.24), {"solid": true, "pattern": Kit.Pattern.BRICK})
	k.box(g, Vector3(7.2, 0.1, 0.4), Vector3(0, 2.65, 0), Kit.CONCRETE)
	# Bleached face.
	var z := 0.16
	k.box(g, Vector3(6.8, 2.4, 0.01), Vector3(0, 1.25, z), BLEACHED, {"pattern": Kit.Pattern.BRICK})
	var dark := Color(0.42, 0.26, 0.21)
	var s := z + 0.008
	# Someone walking past with a bicycle. Their shadow stayed.
	k.ball(g, Vector3(0.24, 0.28, 0.01), Vector3(-1.0, 1.62, s), dark)
	k.box(g, Vector3(0.36, 0.6, 0.01), Vector3(-1.0, 1.18, s), dark, {"rot": Vector3(0, 0, -4)})
	k.box(g, Vector3(0.13, 0.75, 0.01), Vector3(-1.1, 0.5, s), dark, {"rot": Vector3(0, 0, -14)})
	k.box(g, Vector3(0.13, 0.75, 0.01), Vector3(-0.86, 0.5, s), dark, {"rot": Vector3(0, 0, 16)})
	k.box(g, Vector3(0.1, 0.55, 0.01), Vector3(-0.72, 1.12, s), dark, {"rot": Vector3(0, 0, 55)})  # arm on the handlebar
	for x: float in [-0.15, 1.15]:
		k.ring(g, 0.26, 0.33, Vector3(x, 0.36, s), dark, Vector3(90, 0, 0))
	k.beam(g, Vector3(-0.15, 0.36, s), Vector3(0.45, 0.75, s), 0.05, dark, {"depth": 0.01})
	k.beam(g, Vector3(0.45, 0.75, s), Vector3(1.15, 0.36, s), 0.05, dark, {"depth": 0.01})
	k.beam(g, Vector3(0.45, 0.75, s), Vector3(-0.45, 0.85, s), 0.05, dark, {"depth": 0.01})
	k.beam(g, Vector3(1.0, 0.95, s), Vector3(1.15, 0.36, s), 0.05, dark, {"depth": 0.01})
	# A garden ladder that was leaning here, and the outline of a tap.
	for x: float in [2.2, 2.65]:
		k.box(g, Vector3(0.07, 2.3, 0.01), Vector3(x + 0.12, 1.15, s), dark, {"rot": Vector3(0, 0, -6)})
	for i in 6:
		k.box(g, Vector3(0.5, 0.05, 0.01), Vector3(2.5 - i * 0.04, 0.3 + i * 0.36, s), dark, {"rot": Vector3(0, 0, -6)})
	k.box(g, Vector3(0.12, 0.2, 0.01), Vector3(-2.6, 0.7, s), dark)
	var t := k.thing(g, Vector3(6.8, 2.4, 0.4), Vector3(0, 1.25, 0.1), "Look at the wall", [
		"The paint is bleached pale all over, except for one shape: a person walking a bicycle, mid-step.",
		"It's only a shadow. The flash lit everything else, and whoever it was stood in the way for one second.",
		"You've started noticing them everywhere. A pale wall, a darker shape. Always on the side facing the city.",
	])
	t.position = Vector3(0, 1.25, 0.1)


## Paint blistered and bleached on the sides that faced the city.
func _blistered_paint() -> void:
	# [house x, windows (x offsets), door x]
	var fronts := [[0.0, [-2.6, 2.6], 0.6], [16.0, [-2.5, 2.7], 0.0], [32.0, [-2.7, 2.2], -0.5]]
	for h in fronts:
		var hx: float = h[0]
		var i := 0
		var tries := 0
		while i < 45 and tries < 400:
			tries += 1
			var x := k.rng.randf_range(-3.9, 3.9)
			var y := k.rng.randf_range(0.35, 2.6)
			if absf(x - h[2]) < 0.75 and y < 2.3:
				continue  # door
			var on_window := false
			for wx in h[1]:
				if absf(x - wx) < 0.75 and y > 0.8 and y < 2.15:
					on_window = true
			if on_window:
				continue
			var c := BLEACHED if k.rng.randf() < 0.6 else Color(0.32, 0.28, 0.25)
			k.box(world, Vector3(k.rng.randf_range(0.06, 0.3), k.rng.randf_range(0.04, 0.16), 0.01), Vector3(hx + x, y, -8.37), c)
			i += 1


# --- The blast wind ---------------------------------------------------------------

func _fallen_trees() -> void:
	# Trunks snapped and thrown north, away from the city.
	for p: Vector3 in [Vector3(-6, 0, -18), Vector3(22, 0, -19), Vector3(-38, 0, -14), Vector3(8, 0, 20)]:
		var bark := Color(0.3, 0.25, 0.2)
		k.cyl(world, 0.16, 0.9, p + Vector3(0, 0.45, 0), bark, {"top": 0.12, "sides": 6, "solid": true})
		k.prism(world, Vector3(0.3, 0.25, 0.3), p + Vector3(0, 0.98, 0), Color(0.55, 0.45, 0.32), {"rot": Vector3(0, 0, 180)})  # splintered top
		var tip := p + Vector3(k.rng.randf_range(-1.0, 1.0), 0.15, -4.5)
		k.beam(world, p + Vector3(0, 0.3, -0.3), tip, 0.26, bark)
		for i in 3:
			var a := p.lerp(tip, 0.5 + i * 0.15) + Vector3(0, 0.2, 0)
			k.beam(world, a, a + Vector3(k.rng.randf_range(-1, 1), k.rng.randf_range(0.2, 0.8), -0.6), 0.06, bark)


func _roof_tiles() -> void:
	var tile := BoxMesh.new()
	tile.size = Vector3(0.3, 0.02, 0.2)
	var xf: Array = []
	for hx in [0.0, 16.0, 32.0]:
		for i in 14:
			var p := Vector3(hx + k.rng.randf_range(-4, 4), 0.02, k.rng.randf_range(-7.4, -5.8))
			xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU).rotated(Vector3.RIGHT, k.rng.randf_range(-0.2, 0.2)), p))
	k.scatter(world, tile, Color(0.3, 0.24, 0.22), xf)


func _glass_on_pavements() -> void:
	for p: Vector3 in [Vector3(13.5, 0.13, -4.8), Vector3(18.6, 0.13, -4.6), Vector3(-29, 0.13, 4.7), Vector3(-16, 0.13, -4.5), Vector3(33, 0.13, -4.6)]:
		f.shards(world, p, 0.8)


# --- Fallout ----------------------------------------------------------------------

func _ash_drifts() -> void:
	for s in [-1.0, 1.0]:
		var x := -50.0
		while x < 50.0:
			var length := k.rng.randf_range(1.0, 4.0)
			if k.rng.randf() < 0.65:
				k.box(world, Vector3(length, 0.05, 0.22), Vector3(x + length / 2.0, 0.03, s * 3.32), ASH)
				k.box(world, Vector3(length * 0.6, 0.03, 0.12), Vector3(x + length / 2.0, 0.155, s * 3.75), ASH)  # on the kerb
			x += length + k.rng.randf_range(0.5, 3.0)
	# Drifts against the north side of the fences, where the wind dropped it.
	for i in 30:
		var x := k.rng.randf_range(-45, 45)
		var s := -1.0 if k.rng.randf() < 0.5 else 1.0
		k.prism(world, Vector3(0.35, 0.12, k.rng.randf_range(0.8, 2.0)), Vector3(x, 0.06, s * 5.62), ASH.darkened(0.08), {"rot": Vector3(0, 90, 0)})


func _dead_birds() -> void:
	for p: Vector3 in [Vector3(-3.0, 0.13, -4.6), Vector3(9.5, 0.13, 4.3), Vector3(25, 0.02, -7.2), Vector3(-21, 0.13, 4.9), Vector3(5.2, 0.02, -6.5), Vector3(-33, 0.02, -7.0)]:
		var g := k.group(world, p, k.rng.randf() * 360)
		k.ball(g, Vector3(0.18, 0.08, 0.1), Vector3(0, 0.04, 0), Color(0.12, 0.12, 0.13))
		k.ball(g, Vector3(0.07, 0.06, 0.07), Vector3(0.11, 0.03, 0.02), Color(0.12, 0.12, 0.13))
		k.box(g, Vector3(0.14, 0.01, 0.12), Vector3(-0.02, 0.02, 0.08), Color(0.16, 0.16, 0.17), {"rot": Vector3(0, 20, 0)})  # a wing spread out
		k.box(g, Vector3(0.03, 0.01, 0.015), Vector3(0.16, 0.03, 0.02), Color(0.6, 0.5, 0.25))


# --- The days after ---------------------------------------------------------------

func _leaflets() -> void:
	var sheet := BoxMesh.new()
	sheet.size = Vector3(0.21, 0.004, 0.3)
	var xf: Array = []
	for i in 70:
		var p := Vector3(k.rng.randf_range(-45, 45), 0.0, k.rng.randf_range(-9, 9))
		p.y = 0.125 if absf(p.z) > 3.6 and absf(p.z) < 5.2 else (0.025 if absf(p.z) <= 3.6 else 0.02)
		xf.append(Transform3D(Basis(Vector3.UP, k.rng.randf() * TAU), p))
	k.scatter(world, sheet, Color(0.86, 0.84, 0.72), xf)
	var lines := [
		"A government leaflet, grey with ash. CIVIL EMERGENCY, LEAFLET 3: \"If you hear the sirens, go indoors, stay indoors, tune to 104.1.\"",
		"\"Do not look at the flash. Fill your bath with water. Tape your windows in an X. Keep pets inside.\"",
		"On the back, someone has written a shopping list: candles, batteries, tins, cat food, \"Mum's tablets!!\"",
	]
	for p: Vector3 in [Vector3(0.9, 0.14, -4.4), Vector3(34.5, 0.14, 4.4)]:
		var t := k.thing_box(world, Vector3(0.21, 0.01, 0.3), p, Color(0.92, 0.9, 0.78), "Read the leaflet", lines, {"rot": Vector3(0, k.rng.randf_range(0, 90), 0)})
		k.box(t, Vector3(0.16, 0.012, 0.05), Vector3(0, 0.001, -0.1), Color(0.7, 0.2, 0.15))  # red header band


func _sandbags(pos: Vector3) -> void:
	# A low wall of sandbags under the Okafors' front window.
	for row in 3:
		for i in 5 - row:
			k.ball(world, Vector3(0.55, 0.22, 0.32), pos + Vector3(i * 0.5 + row * 0.25, 0.11 + row * 0.2, 0), Color(0.58, 0.52, 0.38).darkened(k.rng.randf() * 0.15), {"sides": 6})
	k.blocker(world, Vector3(2.5, 0.6, 0.4), pos + Vector3(1.0, 0.3, 0))


## Search-team marks sprayed on the doors: an X, the date, the team, and how
## many people they found inside.
func _search_marks() -> void:
	_search_x(world, Vector3(31.5, 1.35, -8.25), 0.0, ["3/22", "T-4", "GONE", "0"])
	_search_x(world, Vector3(16.0, 1.35, 8.19), 180.0, ["3/22", "T-4", "NO ENTRY", "?"])
	_search_x(world, Vector3(-14.0, 1.2, 8.25), 180.0, ["3/23", "T-4", "FIRE", "1"])


func _search_x(parent: Node3D, pos: Vector3, turn: float, text: Array) -> void:
	var g := k.group(parent, pos, turn)
	k.beam(g, Vector3(-0.4, -0.4, 0), Vector3(0.4, 0.4, 0), 0.06, SPRAY, {"depth": 0.01})
	k.beam(g, Vector3(-0.4, 0.4, 0), Vector3(0.4, -0.4, 0), 0.06, SPRAY, {"depth": 0.01})
	var spots := [Vector3(0, 0.3, 0.01), Vector3(-0.3, 0, 0.01), Vector3(0.3, 0, 0.01), Vector3(0, -0.3, 0.01)]
	for i in 4:
		k.words(g, text[i], spots[i], Vector3.ZERO, 0.004, SPRAY)


## An abandoned decontamination point at the end of the street.
func _decon_tent(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	var canvas := Color(0.78, 0.8, 0.74)
	for x: float in [-1.5, 1.5]:
		for z in [-1.2, 1.2]:
			k.cyl(g, 0.04, 2.2, Vector3(x, 1.1, z), Kit.METAL, {"sides": 5})
	var roof := k.prism(g, Vector3(3.2, 0.8, 2.6), Vector3(0, 2.6, 0), canvas)
	roof.rotation_degrees = Vector3(0, 90, 0)
	roof.scale = Vector3(1, 1, 1)
	k.box(g, Vector3(3.1, 1.2, 0.02), Vector3(0, 1.6, -1.2), canvas.darkened(0.1), {"rot": Vector3(4, 0, 0)})  # back wall, sagging
	k.words(g, "DECONTAMINATION", Vector3(0, 1.85, -1.17), Vector3.ZERO, 0.009, Color(0.15, 0.3, 0.55))
	k.words(g, "ALL EVACUEES", Vector3(0, 1.55, -1.17), Vector3.ZERO, 0.007, Color(0.15, 0.3, 0.55))
	# Folding table with a clipboard.
	k.box(g, Vector3(1.4, 0.04, 0.6), Vector3(-0.6, 0.75, -0.6), Color(0.85, 0.85, 0.82))
	for x: float in [-1.2, 0.0]:
		k.beam(g, Vector3(x, 0, -0.85), Vector3(x + 0.1, 0.73, -0.35), 0.03, Kit.METAL)
		k.beam(g, Vector3(x, 0, -0.35), Vector3(x + 0.1, 0.73, -0.85), 0.03, Kit.METAL)
	var clip := k.thing_box(g, Vector3(0.24, 0.02, 0.32), Vector3(-0.8, 0.78, -0.6), Color(0.55, 0.4, 0.25), "Read the clipboard", [
		"A list of names and times, ticked off one by one. Readings in another column: 0.2, 0.3, 0.2, 1.8, 0.2...",
		"The ticks stop halfway down the third page. The last name has a question mark next to it.",
	])
	k.box(clip, Vector3(0.2, 0.01, 0.26), Vector3(0, 0.012, 0.01), Kit.PAPER)
	k.cyl(g, 0.05, 0.08, Vector3(-0.2, 0.81, -0.5), Color(0.9, 0.85, 0.2), {"sides": 6})  # a dosimeter left behind
	# Tubs of clothes and shoes, and a coiled hose.
	for i in 3:
		var tub := k.group(g, Vector3(0.6 + i * 0.75, 0, 0.6), k.rng.randf_range(-10, 10))
		k.box(tub, Vector3(0.6, 0.45, 0.45), Vector3(0, 0.23, 0), Color(0.25, 0.4, 0.6) if i != 1 else Color(0.7, 0.25, 0.2))
		k.words(tub, ["CLOTHES", "SHOES", "BAGS"][i], Vector3(0, 0.3, 0.23), Vector3.ZERO, 0.004, Color(0.95, 0.95, 0.9))
		for j in 3:
			k.box(tub, Vector3(0.4, 0.08, 0.3), Vector3(k.rng.randf_range(-0.05, 0.05), 0.47 + j * 0.06, 0), [Kit.FABRIC_BLUE, Kit.FABRIC_GREEN, Kit.FABRIC_MUSTARD, Color(0.2, 0.2, 0.22)][(i + j) % 4], {"rot": Vector3(0, k.rng.randf_range(-30, 30), 0)})
	k.ring(g, 0.2, 0.3, Vector3(-1.2, 0.05, 0.8), Color(0.2, 0.5, 0.3))
	k.ring(g, 0.18, 0.27, Vector3(-1.2, 0.11, 0.8), Color(0.2, 0.5, 0.3))
	k.blocker(g, Vector3(3.2, 1.0, 0.3), Vector3(0, 0.5, -1.2))


func _warning_sign(pos: Vector3) -> void:
	var g := k.group(world, pos, 180)
	g.rotation_degrees.z = -6
	for x: float in [-0.55, 0.55]:
		k.cyl(g, 0.035, 2.0, Vector3(x, 1.0, 0), Kit.METAL, {"sides": 5})
	k.box(g, Vector3(1.3, 1.0, 0.03), Vector3(0, 1.75, 0), Color(0.92, 0.78, 0.15))
	k.box(g, Vector3(1.22, 0.92, 0.01), Vector3(0, 1.75, 0.012), Color(0.95, 0.82, 0.2))
	# A simple trefoil.
	var c := Vector3(0, 1.88, 0.02)
	k.cyl(g, 0.05, 0.01, c, Color(0.08, 0.08, 0.08), {"rot": Vector3(90, 0, 0), "sides": 8})
	for i in 3:
		var a := deg_to_rad(90.0 + i * 120.0)
		var blade := k.prism(g, Vector3(0.22, 0.2, 0.01), c + Vector3(cos(a), sin(a), 0) * 0.16, Color(0.08, 0.08, 0.08))
		blade.rotation_degrees = Vector3(0, 0, rad_to_deg(a) + 90.0)
	k.words(g, "RADIATION HAZARD", Vector3(0, 1.52, 0.02), Vector3.ZERO, 0.004, Color(0.08, 0.08, 0.08))
	k.words(g, "NO ENTRY SOUTH OF THE RAILWAY", Vector3(0, 1.4, 0.02), Vector3.ZERO, 0.0028, Color(0.08, 0.08, 0.08))
	k.thing(g, Vector3(1.3, 1.0, 0.2), Vector3(0, 1.75, 0), "Read the sign", [
		"RADIATION HAZARD. NO ENTRY SOUTH OF THE RAILWAY. Someone has added in marker: \"or north of the trees\".",
	])


## The Bells dug a shelter in their back garden: an old door, earth on top.
func _family_shelter(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	var earth := Color(0.3, 0.24, 0.18)
	k.prism(g, Vector3(3.0, 0.9, 2.2), Vector3(0, 0.45, 0), earth, {"rot": Vector3(0, 90, 0), "solid": true})
	k.box(g, Vector3(0.9, 0.06, 2.0), Vector3(0, 0.95, 0), Color(0.4, 0.3, 0.22), {"rot": Vector3(0, 0, 4)})  # old door on top
	k.box(g, Vector3(0.8, 0.6, 0.05), Vector3(0, 0.3, -1.12), Color(0.06, 0.05, 0.05))  # dark entrance
	for i in 4:
		k.ball(g, Vector3(0.45, 0.2, 0.3), Vector3(-0.75 + i * 0.5, 0.1, -1.35), Color(0.55, 0.5, 0.36), {"sides": 6})
	k.box(g, Vector3(0.5, 0.06, 0.4), Vector3(0.2, 0.03, -1.6), Color(0.6, 0.25, 0.3))  # a child's sleeping bag, pulled half out
	var t := k.thing(g, Vector3(1.0, 0.8, 0.4), Vector3(0, 0.4, -1.2), "Look in the shelter", [
		"A shelter dug into the Bells' garden: an old door, a mattress, three feet of earth. Two small sleeping bags inside.",
		"Inside the door, in crayon, a tally of days. It stops at eleven. Under it: \"Going to the bus. Love you house.\"",
	])
	t.position = Vector3(0, 0.4, -1.3)


## Dried flowers and candles on the fence of the burnt house.
func _memorial(pos: Vector3) -> void:
	var g := k.group(world, pos, 0)
	for i in 8:
		var x := k.rng.randf_range(-1.5, 1.5)
		k.beam(g, Vector3(x, 0.12, 0.1), Vector3(x + k.rng.randf_range(-0.1, 0.1), 0.5, 0.18), 0.02, Color(0.35, 0.33, 0.2))
		k.ball(g, Vector3(0.1, 0.08, 0.1), Vector3(x, 0.52, 0.18), [Color(0.5, 0.3, 0.3), Color(0.55, 0.5, 0.35), Color(0.45, 0.35, 0.45)][i % 3])
	for x: float in [-0.9, -0.2, 0.6, 1.3]:
		k.cyl(g, 0.04, 0.09, Vector3(x, 0.17, -0.05), Color(0.8, 0.75, 0.6), {"sides": 6})  # burnt-down candle jars
	for i in 6:
		k.box(g, Vector3(0.03, 0.25, 0.01), Vector3(-1.6 + i * 0.6, 0.6, 0.27), [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Color(0.9, 0.85, 0.3)][i % 3], {"rot": Vector3(0, 0, 10)})  # ribbons
	k.box(g, Vector3(0.18, 0.24, 0.01), Vector3(0.2, 0.62, 0.27), Color(0.5, 0.55, 0.6))  # photo pinned to the fence
	k.ball(g, Vector3(0.22, 0.25, 0.18), Vector3(-0.5, 0.25, -0.05), Color(0.55, 0.4, 0.28))  # teddy
	k.ball(g, Vector3(0.15, 0.15, 0.14), Vector3(-0.5, 0.45, -0.05), Color(0.55, 0.4, 0.28))
	k.thing(g, Vector3(3.2, 0.8, 0.5), Vector3(0, 0.4, 0.05), "Look at the flowers", [
		"Dried flowers, burnt-down candles, ribbons. A photo of an old man laughing, with a dog on his lap.",
		"A card in a child's handwriting: \"Mr Lindkvist gave us apples. Sorry about your house.\"",
	])


func _dog_lead(pole: Vector3) -> void:
	var red := Color(0.7, 0.18, 0.15)
	k.ring(world, 0.07, 0.1, pole + Vector3(0, 0.9, 0), red, Vector3.ZERO)
	k.beam(world, pole + Vector3(0.08, 0.9, 0), pole + Vector3(0.5, 0.14, -0.3), 0.025, red)
	k.ring(world, 0.08, 0.11, pole + Vector3(0.55, 0.13, -0.35), Color(0.25, 0.3, 0.55), Vector3(80, 0, 0))  # empty collar
	k.thing(world, Vector3(0.4, 1.0, 0.4), pole + Vector3(0.3, 0.5, -0.2), "Look at the lead", [
		"A dog lead, clipped to the lamppost. The collar on the end is still buckled, and empty.",
		"The tag says PIP. You think of the missing posters.",
	])


func _help_on_road(pos: Vector3) -> void:
	# Painted big enough to read from a helicopter. Then, later, in orange:
	k.words(world, "HELP", pos, Vector3(-90, 0, 0), 0.06, Color(0.9, 0.9, 0.86))
	k.words(world, "4 HERE  No.3", pos + Vector3(0, 0, 1.9), Vector3(-90, 0, 0), 0.022, Color(0.9, 0.9, 0.86))
	k.words(world, "GONE TO BUS 3/18", pos + Vector3(5.2, 0.003, 2.4), Vector3(-90, 12, 0), 0.016, Color(0.95, 0.5, 0.2))


## Hopscotch and a drawing of three suns, in chalk.
func _chalk(pos: Vector3) -> void:
	var chalk := Color(0.92, 0.9, 0.86)
	for i in 6:
		var p := pos + Vector3(i * 0.45, 0, 0)
		k.box(world, Vector3(0.42, 0.003, 0.02), p + Vector3(0, 0, -0.2), chalk)
		k.box(world, Vector3(0.42, 0.003, 0.02), p + Vector3(0, 0, 0.2), chalk)
		k.box(world, Vector3(0.02, 0.003, 0.42), p + Vector3(-0.21, 0, 0), chalk)
		k.words(world, str(i + 1), p + Vector3(0, 0.003, 0), Vector3(-90, 90, 0), 0.006, chalk)
	var sun_cols := [Color(0.95, 0.85, 0.3), Color(0.95, 0.6, 0.3), Color(0.95, 0.4, 0.35)]
	for i in 3:
		var c := pos + Vector3(3.5 + i * 0.5, 0.002, 0.1 - i * 0.05)
		k.ring(world, 0.1, 0.13, c, sun_cols[i])
		for r in 8:
			var a := r * TAU / 8.0
			k.box(world, Vector3(0.12, 0.003, 0.015), c + Vector3(cos(a), 0, sin(a)) * 0.22, sun_cols[i], {"rot": Vector3(0, -rad_to_deg(a), 0)})


# --- The strange ------------------------------------------------------------------

## Crows on the wires, every one of them facing north, toward the tower.
func _crows_on_wires() -> void:
	for i in 14:
		var seg := k.rng.randi_range(0, 4)
		var x0 := -35.0 + seg * 14.0
		var t := k.rng.randf_range(0.1, 0.9)
		var z: float = [-0.85, 0.0, 0.85][k.rng.randi_range(0, 2)]
		var sag := 0.5 * (1.0 - pow(2.0 * t - 1.0, 2.0))
		var p := Vector3(x0 + t * 14.0, 7.2 - sag + 0.02, -5.4 + z)
		var g := k.group(world, p, 180 + k.rng.randf_range(-8, 8))
		var black := Color(0.07, 0.07, 0.08)
		k.ball(g, Vector3(0.12, 0.14, 0.24), Vector3(0, 0.09, 0), black)
		k.ball(g, Vector3(0.09, 0.09, 0.09), Vector3(0, 0.18, -0.1), black)
		k.prism(g, Vector3(0.03, 0.06, 0.03), Vector3(0, 0.18, -0.16), Color(0.15, 0.15, 0.15), {"rot": Vector3(-90, 0, 0)})
		k.box(g, Vector3(0.08, 0.02, 0.14), Vector3(0, 0.06, 0.16), black, {"rot": Vector3(-20, 0, 0)})


## Pale moths circling the one working streetlight. Only out at night.
func _moths(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 4.0
	p.preprocess = 4.0
	p.position = pos
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.5
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.damping_min = 0.0
	p.damping_max = 0.1
	p.mesh = _glow_quad(0.06, Color(0.85, 0.95, 0.8))
	p.add_to_group("night_only")
	world.add_child(p)


## Little pale flowers that only open after dark, along the forest edge and
## in the empty lot. Nobody remembers them from before.
func _night_flowers() -> void:
	var spots: Array[Vector3] = []
	for i in 40:
		spots.append(Vector3(k.rng.randf_range(-40, 40), 0, k.rng.randf_range(-30, -24)))
	for i in 14:
		spots.append(Vector3(-16 + k.rng.randf_range(-3, 3), 0, -12 + k.rng.randf_range(-2.5, 2.5)))
	var blooms := k.group(world)
	blooms.add_to_group("night_only")
	for p in spots:
		k.beam(world, p, p + Vector3(0, 0.3, 0.05), 0.015, Color(0.3, 0.38, 0.32))
		k.ball(blooms, Vector3(0.12, 0.05, 0.12), p + Vector3(0, 0.31, 0.05), Color(0.6, 0.85, 0.95), {"glow": 1.5})
	k.thing(world, Vector3(0.6, 0.5, 0.6), Vector3(-15.0, 0.25, -10.5), "Look at the flowers", [
		"Little pale flowers. In daylight they're shut tight. After dark they open and glow, very faintly.",
		"You don't remember them from before. They only grow on the north side of things.",
	])


func _city_smoke() -> void:
	# The city is still smoking, months later.
	for p: Vector3 in [Vector3(-40, 15, 95), Vector3(5, 18, 105), Vector3(55, 12, 92)]:
		var s := CPUParticles3D.new()
		s.amount = 70
		s.lifetime = 45.0
		s.preprocess = 45.0
		s.position = p
		s.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		s.emission_sphere_radius = 3.0
		s.direction = Vector3(0.2, 1, 0)
		s.spread = 10.0
		s.gravity = Vector3(0.1, 0.0, 0)
		s.initial_velocity_min = 0.8
		s.initial_velocity_max = 1.4
		s.scale_amount_min = 1.0
		s.scale_amount_max = 2.0
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.5))
		curve.add_point(Vector2(1, 2.5))
		s.scale_amount_curve = curve
		var q := QuadMesh.new()
		q.size = Vector2(12, 12)
		var m := StandardMaterial3D.new()
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		m.albedo_color = Color(0.32, 0.3, 0.3, 0.4)
		m.albedo_texture = _soft_circle()
		q.material = m
		s.mesh = q
		world.add_child(s)
	# A low orange glow along the horizon at night, where something still burns.
	for x: float in [-45.0, 10.0, 50.0]:
		var glow := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(30, 6)
		glow.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.9, 0.38, 0.15, 0.18)
		glow.material_override = m
		glow.position = Vector3(x, 3.0, 78)
		glow.rotation_degrees.y = 180
		glow.add_to_group("night_only")
		world.add_child(glow)


## Invisible spots where the Geiger counter clicks faster.
func _hotspots() -> void:
	for h in [[Vector3(-19.2, 1, -3.9), 1.0], [Vector3(-15, 1, 12), 0.7], [Vector3(41.6, 1, -7.9), 1.4],
			[Vector3(-28, 0, -1.4), 0.6], [Vector3(-16, 1, -15.8), 0.5], [Vector3(0, 1, -40), 2.5], [Vector3(30, 1, -2.3), 0.4]]:
		var n := Marker3D.new()
		n.position = h[0]
		n.set_meta("strength", h[1])
		n.add_to_group("hotspot")
		world.add_child(n)


var _circle: GradientTexture2D


## A soft round puff for smoke.
func _soft_circle() -> GradientTexture2D:
	if _circle:
		return _circle
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	_circle = GradientTexture2D.new()
	_circle.gradient = grad
	_circle.fill = GradientTexture2D.FILL_RADIAL
	_circle.fill_from = Vector2(0.5, 0.5)
	_circle.fill_to = Vector2(0.5, 0.0)
	_circle.width = 32
	_circle.height = 32
	return _circle


func _glow_quad(size: float, color: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = color
	q.material = m
	return q
