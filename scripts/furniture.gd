## Furniture and household objects, built from kit blocks.
## Every function takes a parent, a position on the floor, and a turn in degrees.
## Pieces face local +Z (the side you sit on or open faces +Z).
extends RefCounted

const Kit := preload("res://scripts/kit.gd")

var k: Kit


func _init(kit: Kit) -> void:
	k = kit


func _g(parent: Node, pos: Vector3, turn: float) -> Node3D:
	return k.group(parent, pos, turn)


# --- Sleeping ---------------------------------------------------------------------

func bed(parent: Node, pos: Vector3, turn: float, width := 0.95, blanket := Kit.FABRIC_BLUE, made := true) -> Node3D:
	var g := _g(parent, pos, turn)
	var L := 2.0
	k.box(g, Vector3(width + 0.06, 0.3, L + 0.06), Vector3(0, 0.2, 0), Kit.WOOD)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			k.box(g, Vector3(0.07, 0.25, 0.07), Vector3(x * width / 2.0, 0.06, z * L / 2.0), Kit.WOOD_DARK)
	k.box(g, Vector3(width + 0.1, 0.85, 0.06), Vector3(0, 0.45, -L / 2.0 - 0.02), Kit.WOOD)  # headboard
	k.box(g, Vector3(width, 0.16, L), Vector3(0, 0.43, 0), Color(0.85, 0.83, 0.78))  # mattress
	var pillows := 1 if width < 1.2 else 2
	for i in pillows:
		var px := 0.0 if pillows == 1 else (i - 0.5) * width * 0.5
		k.box(g, Vector3(width / pillows - 0.1, 0.1, 0.38), Vector3(px, 0.56, -L / 2.0 + 0.28), Color(0.9, 0.88, 0.84))
	if made:
		k.box(g, Vector3(width + 0.06, 0.06, L * 0.7), Vector3(0, 0.53, L * 0.15), blanket)
		k.box(g, Vector3(width + 0.08, 0.3, 0.04), Vector3(0, 0.38, L * 0.15 + L * 0.35), blanket)  # overhang at the foot
		k.box(g, Vector3(width + 0.07, 0.07, 0.25), Vector3(0, 0.57, -L * 0.18), blanket.lightened(0.25))  # folded edge
	else:
		k.box(g, Vector3(width * 0.9, 0.1, L * 0.6), Vector3(0.1, 0.55, L * 0.1), blanket, {"rot": Vector3(0, 12, 4)})
	k.blocker(g, Vector3(width + 0.1, 0.8, L + 0.1), Vector3(0, 0.4, 0))
	return g


func bunk_bed(parent: Node, pos: Vector3, turn: float, top := Kit.FABRIC_RED, bottom := Kit.FABRIC_BLUE) -> Node3D:
	var g := _g(parent, pos, turn)
	var W := 0.95
	var L := 2.0
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			k.box(g, Vector3(0.07, 1.75, 0.07), Vector3(x * W / 2.0, 0.875, z * L / 2.0), Kit.WOOD_LIGHT)
	for y in [0.3, 1.25]:
		k.box(g, Vector3(W, 0.08, L), Vector3(0, y, 0), Kit.WOOD_LIGHT)
		k.box(g, Vector3(W - 0.06, 0.12, L - 0.06), Vector3(0, y + 0.1, 0), Color(0.85, 0.83, 0.78))
		k.box(g, Vector3(W - 0.15, 0.08, 0.3), Vector3(0, y + 0.2, -L / 2.0 + 0.25), Color(0.9, 0.88, 0.84))
		k.box(g, Vector3(W, 0.05, L * 0.65), Vector3(0, y + 0.18, L * 0.15), top if y > 1.0 else bottom)
	k.box(g, Vector3(W, 0.2, 0.04), Vector3(0, 1.5, 0), Kit.WOOD_LIGHT)  # rail
	for i in 5:
		k.box(g, Vector3(0.04, 0.04, 0.35), Vector3(W / 2.0 + 0.02, 0.25 + i * 0.3, L / 2.0 - 0.3), Kit.WOOD_LIGHT)  # ladder rung
	k.blocker(g, Vector3(W + 0.1, 1.8, L + 0.1), Vector3(0, 0.9, 0))
	return g


func nightstand(parent: Node, pos: Vector3, turn: float) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(0.45, 0.5, 0.4), Vector3(0, 0.25, 0), Kit.WOOD)
	k.box(g, Vector3(0.4, 0.18, 0.02), Vector3(0, 0.36, 0.2), Kit.WOOD_LIGHT)
	k.box(g, Vector3(0.08, 0.02, 0.02), Vector3(0, 0.36, 0.22), Kit.METAL)
	return g


func wardrobe(parent: Node, pos: Vector3, turn: float, open := false) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(1.1, 1.9, 0.58), Vector3(0, 0.95, 0), Kit.WOOD_DARK, {"solid": true})
	k.box(g, Vector3(1.14, 0.06, 0.62), Vector3(0, 1.93, 0), Kit.WOOD)
	if open:
		var door := k.group(g, Vector3(0.55, 0, 0.29), 70)
		k.box(door, Vector3(0.54, 1.8, 0.03), Vector3(-0.27, 0.95, 0), Kit.WOOD)
		k.box(g, Vector3(1.0, 1.7, 0.02), Vector3(0, 0.95, 0.3), Color(0.08, 0.07, 0.06))  # dark inside
		for i in 4:
			k.box(g, Vector3(0.05, 0.6, 0.35), Vector3(-0.35 + i * 0.12, 1.35, 0.15), [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.PAPER, Kit.FABRIC_GREEN][i])
	else:
		for x in [-0.275, 0.275]:
			k.box(g, Vector3(0.52, 1.8, 0.02), Vector3(x, 0.95, 0.3), Kit.WOOD)
			k.box(g, Vector3(0.02, 0.12, 0.03), Vector3(x * 0.12, 1.0, 0.32), Kit.METAL)
	return g


# --- Sitting and tables -------------------------------------------------------------

func chair(parent: Node, pos: Vector3, turn: float, color := Kit.WOOD, tipped := false) -> Node3D:
	var g := _g(parent, pos, turn)
	var body := k.group(g)
	k.box(body, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.45, 0), color)
	k.box(body, Vector3(0.42, 0.45, 0.04), Vector3(0, 0.7, -0.19), color)
	k.box(body, Vector3(0.36, 0.06, 0.03), Vector3(0, 0.82, -0.19), color.lightened(0.1))
	for lx in [-0.18, 0.18]:
		for lz in [-0.18, 0.18]:
			k.box(body, Vector3(0.04, 0.45, 0.04), Vector3(lx, 0.22, lz), color.darkened(0.2))
	if tipped:
		body.rotation_degrees = Vector3(-90, 0, 0)
		body.position = Vector3(0, 0.21, 0.4)
	return g


func table(parent: Node, pos: Vector3, turn: float, size := Vector2(1.2, 0.8), color := Kit.WOOD, cloth := Color(0, 0, 0, 0)) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(size.x, 0.05, size.y), Vector3(0, 0.74, 0), color)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			k.box(g, Vector3(0.06, 0.72, 0.06), Vector3(x * (size.x / 2.0 - 0.06), 0.36, z * (size.y / 2.0 - 0.06)), color.darkened(0.2))
	if cloth.a > 0.0:
		k.box(g, Vector3(size.x * 0.7, 0.01, size.y + 0.1), Vector3(0, 0.77, 0), cloth)
	k.blocker(g, Vector3(size.x, 0.76, size.y), Vector3(0, 0.38, 0))
	return g


func sofa(parent: Node, pos: Vector3, turn: float, color := Kit.FABRIC_GREEN, seats := 3) -> Node3D:
	var g := _g(parent, pos, turn)
	var W := 0.62 * seats + 0.3
	k.box(g, Vector3(W, 0.3, 0.85), Vector3(0, 0.2, 0), color.darkened(0.15))
	for i in seats:
		k.box(g, Vector3(0.6, 0.14, 0.62), Vector3(-W / 2.0 + 0.15 + 0.31 + i * 0.62, 0.42, 0.06), color)  # cushions
		k.box(g, Vector3(0.58, 0.45, 0.16), Vector3(-W / 2.0 + 0.15 + 0.31 + i * 0.62, 0.68, -0.3), color, {"rot": Vector3(-8, 0, 0)})
	k.box(g, Vector3(W, 0.6, 0.16), Vector3(0, 0.55, -0.36), color.darkened(0.1))
	for x in [-1.0, 1.0]:
		k.box(g, Vector3(0.16, 0.55, 0.85), Vector3(x * (W / 2.0 - 0.08), 0.42, 0), color.darkened(0.05))
	k.blocker(g, Vector3(W, 0.8, 0.85), Vector3(0, 0.4, 0))
	return g


func armchair(parent: Node, pos: Vector3, turn: float, color := Kit.FABRIC_MUSTARD) -> Node3D:
	return sofa(parent, pos, turn, color, 1)


func coffee_table(parent: Node, pos: Vector3, turn: float) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(1.0, 0.05, 0.55), Vector3(0, 0.42, 0), Kit.WOOD_LIGHT)
	k.box(g, Vector3(0.9, 0.03, 0.45), Vector3(0, 0.12, 0), Kit.WOOD_LIGHT.darkened(0.2))
	for x in [-0.45, 0.45]:
		for z in [-0.22, 0.22]:
			k.box(g, Vector3(0.05, 0.42, 0.05), Vector3(x, 0.21, z), Kit.WOOD)
	k.blocker(g, Vector3(1.0, 0.45, 0.55), Vector3(0, 0.22, 0))
	return g


func desk(parent: Node, pos: Vector3, turn: float, color := Kit.WOOD_LIGHT) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(1.0, 0.04, 0.55), Vector3(0, 0.7, 0), color)
	k.box(g, Vector3(0.4, 0.68, 0.53), Vector3(0.28, 0.34, 0), color.darkened(0.1))
	for i in 3:
		k.box(g, Vector3(0.36, 0.18, 0.02), Vector3(0.28, 0.12 + i * 0.21, 0.27), color)
		k.box(g, Vector3(0.08, 0.02, 0.02), Vector3(0.28, 0.16 + i * 0.21, 0.29), Kit.METAL)
	for z in [-0.24, 0.24]:
		k.box(g, Vector3(0.04, 0.68, 0.04), Vector3(-0.47, 0.34, z), color.darkened(0.2))
	k.blocker(g, Vector3(1.0, 0.72, 0.55), Vector3(0, 0.36, 0))
	return g


# --- Kitchen -----------------------------------------------------------------------

## A run of kitchen cabinets along local X. `sink_at`/`stove_at` are x offsets (or null).
func counter(parent: Node, pos: Vector3, turn: float, length := 2.4, color := Color(0.62, 0.66, 0.58), sink_at: Variant = null, stove_at: Variant = null) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(length, 0.86, 0.6), Vector3(0, 0.43, 0), color, {"solid": true})
	k.box(g, Vector3(length + 0.02, 0.04, 0.64), Vector3(0, 0.88, 0.02), Color(0.75, 0.72, 0.65), {"pattern": Kit.Pattern.TILES})
	k.box(g, Vector3(length, 0.1, 0.02), Vector3(0, 0.05, 0.27), Color(0.15, 0.15, 0.15))  # kick board
	var doors := int(length / 0.6)
	for i in doors:
		var x := -length / 2.0 + 0.3 + i * (length / doors)
		k.box(g, Vector3(length / doors - 0.04, 0.6, 0.02), Vector3(x, 0.45, 0.305), color.lightened(0.08))
		k.box(g, Vector3(0.12, 0.02, 0.02), Vector3(x, 0.7, 0.32), Kit.METAL)
	# Splashback tiles and a shelf with jars.
	k.box(g, Vector3(length, 0.5, 0.02), Vector3(0, 1.15, -0.29), Color(0.82, 0.8, 0.72), {"pattern": Kit.Pattern.TILES})
	k.box(g, Vector3(length * 0.8, 0.03, 0.22), Vector3(0, 1.6, -0.2), Kit.WOOD)
	for i in int(length * 3):
		var jc: Color = [Color(0.6, 0.35, 0.2), Color(0.7, 0.65, 0.5), Color(0.4, 0.5, 0.3), Color(0.8, 0.8, 0.75)][i % 4]
		k.cyl(g, 0.05, k.rng.randf_range(0.1, 0.2), Vector3(-length * 0.38 + i * 0.3, 1.68, -0.2), jc, {"sides": 6})
	if sink_at != null:
		k.box(g, Vector3(0.6, 0.02, 0.42), Vector3(sink_at, 0.905, 0.02), Kit.METAL.lightened(0.2))
		k.box(g, Vector3(0.5, 0.02, 0.34), Vector3(sink_at, 0.91, 0.02), Color(0.2, 0.22, 0.24))
		k.cyl(g, 0.015, 0.3, Vector3(sink_at, 1.05, -0.2), Kit.METAL.lightened(0.3), {"sides": 4})
		k.box(g, Vector3(0.03, 0.03, 0.18), Vector3(sink_at, 1.19, -0.12), Kit.METAL.lightened(0.3))
	if stove_at != null:
		stove(g, Vector3(stove_at, 0, 0.0), 0)
	return g


func stove(parent: Node, pos: Vector3, turn: float) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(0.6, 0.9, 0.6), Vector3(0, 0.45, 0.01), Color(0.85, 0.83, 0.78), {"solid": true})
	k.box(g, Vector3(0.5, 0.35, 0.02), Vector3(0, 0.35, 0.32), Color(0.15, 0.15, 0.15))  # oven door glass
	k.box(g, Vector3(0.4, 0.03, 0.03), Vector3(0, 0.58, 0.33), Kit.METAL)
	for x in [-0.15, 0.15]:
		for z in [-0.12, 0.14]:
			k.cyl(g, 0.09, 0.02, Vector3(x, 0.91, z), Color(0.1, 0.1, 0.1), {"sides": 8})
	for i in 4:
		k.cyl(g, 0.02, 0.03, Vector3(-0.2 + i * 0.13, 0.8, 0.32), Color(0.1, 0.1, 0.1), {"rot": Vector3(90, 0, 0), "sides": 6})
	return g


func kettle(parent: Node, pos: Vector3) -> Node3D:
	var g := _g(parent, pos, 0)
	k.cyl(g, 0.1, 0.16, Vector3(0, 0.08, 0), Color(0.75, 0.3, 0.2), {"top": 0.07, "sides": 8})
	k.cyl(g, 0.025, 0.03, Vector3(0, 0.18, 0), Color(0.1, 0.1, 0.1))
	k.beam(g, Vector3(0.08, 0.08, 0), Vector3(0.16, 0.16, 0), 0.025, Color(0.75, 0.3, 0.2))  # spout
	k.ring(g, 0.05, 0.07, Vector3(-0.04, 0.2, 0), Color(0.1, 0.1, 0.1), Vector3(90, 0, 0))
	return g


func fridge(parent: Node, pos: Vector3, turn: float, color := Color(0.85, 0.84, 0.8)) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(0.65, 1.75, 0.65), Vector3(0, 0.875, 0), color, {"solid": true})
	k.box(g, Vector3(0.64, 0.015, 0.02), Vector3(0, 1.2, 0.33), color.darkened(0.3))
	k.box(g, Vector3(0.03, 0.4, 0.04), Vector3(0.26, 1.45, 0.34), Kit.METAL)
	k.box(g, Vector3(0.03, 0.3, 0.04), Vector3(0.26, 0.9, 0.34), Kit.METAL)
	# Magnets and a child's drawing.
	k.box(g, Vector3(0.2, 0.25, 0.005), Vector3(-0.1, 1.45, 0.33), Kit.PAPER)
	for i in 3:
		k.box(g, Vector3(0.04, 0.04, 0.02), Vector3(-0.2 + i * 0.1, 1.6 - i * 0.2, 0.335), [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.FABRIC_MUSTARD][i])
	return g


# --- Storage and decoration ----------------------------------------------------------

func bookshelf(parent: Node, pos: Vector3, turn: float, height := 1.8, width := 0.9) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(width, height, 0.03), Vector3(0, height / 2.0, -0.14), Kit.WOOD_DARK, {"solid": true})
	for x in [-1.0, 1.0]:
		k.box(g, Vector3(0.03, height, 0.3), Vector3(x * width / 2.0, height / 2.0, 0), Kit.WOOD)
	var shelves := int(height / 0.4)
	for i in shelves + 1:
		var y := 0.03 + i * (height - 0.06) / shelves
		k.box(g, Vector3(width, 0.03, 0.3), Vector3(0, y, 0), Kit.WOOD)
		if i == shelves:
			break
		var x := -width / 2.0 + 0.04
		while x < width / 2.0 - 0.1:
			var bw := k.rng.randf_range(0.03, 0.07)
			var bh := k.rng.randf_range(0.2, 0.32)
			var col: Color = [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.FABRIC_GREEN, Kit.FABRIC_MUSTARD, Kit.PAPER, Color(0.3, 0.25, 0.3)][k.rng.randi() % 6]
			var lean := 0.0 if k.rng.randf() < 0.85 else -12.0
			k.box(g, Vector3(bw, bh, 0.22), Vector3(x + bw / 2.0, y + 0.015 + bh / 2.0, 0.0), col, {"rot": Vector3(0, 0, lean)})
			x += bw + 0.005
			if k.rng.randf() < 0.08:
				x += 0.12
	return g


func rug(parent: Node, pos: Vector3, turn: float, size := Vector2(2.2, 1.5), color := Kit.FABRIC_RED) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(size.x, 0.015, size.y), Vector3(0, 0.03, 0), color)
	k.box(g, Vector3(size.x - 0.3, 0.016, size.y - 0.3), Vector3(0, 0.031, 0), color.lightened(0.18))
	k.box(g, Vector3(size.x - 0.6, 0.017, size.y - 0.6), Vector3(0, 0.032, 0), color.darkened(0.1), {"pattern": Kit.Pattern.TILES})
	return g


func picture(parent: Node, pos: Vector3, turn: float, size := Vector2(0.4, 0.3), image := Color(0.4, 0.5, 0.45)) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(size.x, size.y, 0.03), Vector3.ZERO, Kit.WOOD_DARK)
	k.box(g, Vector3(size.x - 0.06, size.y - 0.06, 0.01), Vector3(0, 0, 0.016), image)
	k.box(g, Vector3(size.x * 0.5, size.y * 0.3, 0.005), Vector3(0, -size.y * 0.08, 0.022), image.lightened(0.25))
	return g


func clock(parent: Node, pos: Vector3, turn: float) -> Node3D:
	var g := _g(parent, pos, turn)
	k.cyl(g, 0.16, 0.04, Vector3.ZERO, Kit.WOOD_DARK, {"rot": Vector3(90, 0, 0), "sides": 10})
	k.cyl(g, 0.14, 0.045, Vector3.ZERO, Kit.PAPER, {"rot": Vector3(90, 0, 0), "sides": 10})
	# Stopped at 6:40, the time of the strikes.
	k.box(g, Vector3(0.012, 0.1, 0.01), Vector3(0, -0.05, 0.03), Color(0.1, 0.1, 0.1))
	k.box(g, Vector3(0.012, 0.07, 0.01), Vector3(-0.025, 0.02, 0.03), Color(0.1, 0.1, 0.1), {"rot": Vector3(0, 0, 60)})
	return g


func plant(parent: Node, pos: Vector3, alive := true, size := 1.0) -> Node3D:
	var g := _g(parent, pos, k.rng.randf_range(0, 360))
	k.cyl(g, 0.1 * size, 0.18 * size, Vector3(0, 0.09 * size, 0), Color(0.6, 0.35, 0.25), {"top": 0.12 * size, "sides": 7})
	var leaf := Kit.PLANT if alive else Color(0.45, 0.38, 0.25)
	for i in 5:
		var a := i * TAU / 5.0
		var tip := Vector3(cos(a) * 0.15, 0.35 + k.rng.randf() * 0.1, sin(a) * 0.15) * size
		if not alive:
			tip.y *= 0.5
		k.beam(g, Vector3(0, 0.17 * size, 0), tip, 0.03 * size, leaf, {"depth": 0.08 * size})
	return g


func lamp(parent: Node, pos: Vector3, lit := false) -> Node3D:
	var g := _g(parent, pos, 0)
	k.cyl(g, 0.09, 0.03, Vector3(0, 0.015, 0), Kit.METAL.darkened(0.3), {"sides": 8})
	k.cyl(g, 0.015, 0.35, Vector3(0, 0.2, 0), Kit.METAL.darkened(0.3), {"sides": 4})
	k.cyl(g, 0.16, 0.2, Vector3(0, 0.42, 0), Color(0.85, 0.75, 0.55), {"top": 0.09, "sides": 8, "glow": 1.2 if lit else 0.0})
	return g


func candle(parent: Node, pos: Vector3, lit := true) -> Node3D:
	var g := _g(parent, pos, 0)
	k.cyl(g, 0.06, 0.015, Vector3(0, 0.008, 0), Kit.METAL, {"sides": 8})
	k.cyl(g, 0.025, 0.12, Vector3(0, 0.075, 0), Color(0.92, 0.9, 0.8), {"sides": 6})
	if lit:
		k.ball(g, Vector3(0.025, 0.05, 0.025), Vector3(0, 0.16, 0), Color(1, 0.75, 0.35), {"glow": 3.0})
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.7, 0.4)
		light.light_energy = 0.5
		light.omni_range = 2.5
		light.position = Vector3(0, 0.25, 0)
		g.add_child(light)
	return g


func tv(parent: Node, pos: Vector3, turn: float) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(0.9, 0.45, 0.4), Vector3(0, 0.225, 0), Kit.WOOD_DARK, {"solid": true})  # stand
	k.box(g, Vector3(0.62, 0.5, 0.5), Vector3(0, 0.71, -0.02), Color(0.2, 0.2, 0.2))
	k.box(g, Vector3(0.5, 0.38, 0.02), Vector3(0, 0.72, 0.24), Color(0.12, 0.14, 0.14))
	k.beam(g, Vector3(-0.05, 0.96, 0), Vector3(-0.2, 1.3, -0.05), 0.01, Kit.METAL)
	k.beam(g, Vector3(0.05, 0.96, 0), Vector3(0.22, 1.28, -0.05), 0.01, Kit.METAL)
	return g


func coat_rack(parent: Node, pos: Vector3, coat := Kit.FABRIC_GREEN) -> Node3D:
	var g := _g(parent, pos, 0)
	k.cyl(g, 0.2, 0.03, Vector3(0, 0.015, 0), Kit.WOOD_DARK, {"sides": 6})
	k.cyl(g, 0.025, 1.75, Vector3(0, 0.88, 0), Kit.WOOD_DARK, {"sides": 5})
	for a in [0, 120, 240]:
		var d := Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
		k.beam(g, Vector3(0, 1.6, 0), Vector3(0, 1.72, 0) + d * 0.15, 0.02, Kit.WOOD_DARK)
	k.box(g, Vector3(0.4, 0.8, 0.2), Vector3(0.05, 1.18, 0.1), coat, {"rot": Vector3(5, 0, 3)})
	return g


func boots(parent: Node, pos: Vector3, turn: float, color := Color(0.2, 0.18, 0.15), small := false) -> Node3D:
	var g := _g(parent, pos, turn)
	var s := 0.7 if small else 1.0
	for x in [-0.08, 0.08]:
		k.box(g, Vector3(0.1, 0.25, 0.12) * s, Vector3(x * s, 0.125 * s, 0), color)
		k.box(g, Vector3(0.1, 0.08, 0.26) * s, Vector3(x * s, 0.04 * s, 0.06 * s), color)
	return g


func crate(parent: Node, pos: Vector3, turn: float, size := 0.5) -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(size, size * 0.8, size), Vector3(0, size * 0.4, 0), Kit.WOOD_LIGHT, {"solid": true})
	for y in [0.15, 0.65]:
		k.box(g, Vector3(size + 0.01, 0.06, size + 0.01), Vector3(0, size * 0.8 * y, 0), Kit.WOOD)
	return g


func cardboard_box(parent: Node, pos: Vector3, turn: float, label := "") -> Node3D:
	var g := _g(parent, pos, turn)
	k.box(g, Vector3(0.5, 0.38, 0.4), Vector3(0, 0.19, 0), Color(0.62, 0.5, 0.34), {"solid": true})
	k.box(g, Vector3(0.51, 0.02, 0.07), Vector3(0, 0.38, 0), Color(0.78, 0.72, 0.55))
	if label != "":
		k.words(g, label, Vector3(0, 0.22, 0.205), Vector3.ZERO, 0.0035, Color(0.15, 0.15, 0.2))
	return g


func cat_bed(parent: Node, pos: Vector3, turn: float, color := Kit.FABRIC_GREEN) -> Node3D:
	var g := _g(parent, pos, turn)
	k.cyl(g, 0.3, 0.1, Vector3(0, 0.05, 0), color, {"sides": 8})
	k.cyl(g, 0.24, 0.04, Vector3(0, 0.1, 0), color.lightened(0.2), {"sides": 8})
	return g


func bowl(parent: Node, pos: Vector3, color := Kit.FABRIC_RED) -> Node3D:
	var g := _g(parent, pos, 0)
	k.cyl(g, 0.09, 0.05, Vector3(0, 0.025, 0), color, {"top": 0.11, "sides": 8})
	return g


func toys(parent: Node, pos: Vector3) -> Node3D:
	var g := _g(parent, pos, 0)
	var cols := [Kit.FABRIC_RED, Kit.FABRIC_BLUE, Kit.FABRIC_MUSTARD, Kit.FABRIC_GREEN]
	for i in 7:
		k.box(g, Vector3(0.08, 0.08, 0.08), Vector3(k.rng.randf_range(-0.3, 0.3), 0.04 + (0.08 if i == 6 else 0.0), k.rng.randf_range(-0.3, 0.3)), cols[i % 4], {"rot": Vector3(0, k.rng.randf() * 90, 0)})
	k.ball(g, Vector3(0.18, 0.18, 0.18), Vector3(0.4, 0.09, 0.2), Kit.FABRIC_RED)
	return g


func shards(parent: Node, pos: Vector3, spread := 0.6) -> Node3D:
	var g := _g(parent, pos, 0)
	for i in 10:
		k.box(g, Vector3(k.rng.randf_range(0.03, 0.12), 0.005, k.rng.randf_range(0.03, 0.1)),
			Vector3(k.rng.randf_range(-spread, spread), 0.025, k.rng.randf_range(-spread, spread)), Color(0.7, 0.75, 0.78),
			{"rot": Vector3(0, k.rng.randf() * 180, 0)})
	return g


func ash_pile(parent: Node, pos: Vector3, size := 1.0) -> Node3D:
	var g := _g(parent, pos, 0)
	k.ball(g, Vector3(0.9, 0.12, 0.7) * size, Vector3(0, 0.02, 0), Color(0.35, 0.33, 0.31))
	k.ball(g, Vector3(0.5, 0.08, 0.4) * size, Vector3(0.4, 0.02, 0.3) * size, Color(0.25, 0.24, 0.22))
	return g
