## Trees with character. Each tree is built into one mesh with vertex
## colours (so hundreds of them stay cheap) and sways a little in the wind.
##
##   pine(...)   spruce-like tiers, shaggy drooping tips, the odd brown tier;
##               "scots" style: tall bare trunk with a flat crown;
##               "snag" style: dead, grey, broken off.
##   dead(...)   a bare, gnarled deciduous tree; extras like a birdhouse,
##               a tyre swing, a ribbon or a crow's nest when `extras` is on.
##   birch(...)  white bark with black marks and a few yellow leaves.
##   oak(...)    a broad crown in autumn colours over a carpet of leaves.
##
## Every tree leans a little north, away from the city, like everything else.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")

var k: Kit
var rng := RandomNumberGenerator.new()
var _st: SurfaceTool


func _init(kit: Kit, seed_value := 101) -> void:
	k = kit
	rng.seed = seed_value


# --- Mesh helpers ------------------------------------------------------------------

func _begin() -> void:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


## Shapes below are wound counter-clockwise seen from outside; Godot's front
## faces are clockwise, so each triangle is added the other way round.
func _tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	_st.set_color(ca)
	_st.add_vertex(a)
	_st.set_color(cc)
	_st.add_vertex(c)
	_st.set_color(cb)
	_st.add_vertex(b)


func _ring(center: Vector3, axis: Vector3, r: float, sides: int, turn: float) -> Array:
	var up := axis.normalized()
	var side := Vector3.RIGHT if absf(up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var u := up.cross(side).normalized()
	var v := up.cross(u).normalized()
	var pts: Array = []
	for i in sides:
		var a := turn + i * TAU / sides
		pts.append(center + (u * cos(a) + v * sin(a)) * r)
	return pts


## A tapered tube (or a cone when r1 is 0) from a to b.
func _tube(a: Vector3, b: Vector3, r0: float, r1: float, sides: int, c0: Color, c1: Color) -> void:
	var axis := b - a
	if axis.length() < 0.001:
		return
	var turn := rng.randf() * TAU
	var lo := _ring(a, axis, r0, sides, turn)
	if r1 <= 0.001:
		for i in sides:
			_tri(lo[i], lo[(i + 1) % sides], b, c0, c0, c1)
		return
	var hi := _ring(b, axis, r1, sides, turn)
	for i in sides:
		var j := (i + 1) % sides
		_tri(lo[i], lo[j], hi[j], c0, c0, c1)
		_tri(lo[i], hi[j], hi[i], c0, c1, c1)
	for i in range(1, sides - 1):
		_tri(b, hi[i], hi[i + 1], c1, c1, c1)  # cap


## A lumpy ball (leaf clumps, nests, cones).
func _blob(center: Vector3, size: Vector3, c_top: Color, c_bottom: Color, sides := 6, rings := 4, lumpy := 0.25) -> void:
	var grid: Array = []
	for r in rings + 1:
		var lat := PI * r / rings - PI / 2.0
		var row: Array = []
		for s in sides:
			var lon := TAU * s / sides
			var j := 1.0 + rng.randf_range(-lumpy, lumpy) if r > 0 and r < rings else 1.0
			row.append(center + Vector3(cos(lat) * cos(lon) * size.x, sin(lat) * size.y, cos(lat) * sin(lon) * size.z) * 0.5 * j)
		grid.append(row)
	for r in rings:
		var ca := c_bottom.lerp(c_top, float(r) / rings)
		var cb := c_bottom.lerp(c_top, float(r + 1) / rings)
		for s in sides:
			var t := (s + 1) % sides
			_tri(grid[r][s], grid[r + 1][s], grid[r + 1][t], ca, cb, cb)
			_tri(grid[r][s], grid[r + 1][t], grid[r][t], ca, cb, ca)


func _box(center: Vector3, size: Vector3, c: Color, turn := 0.0) -> void:
	var b := Basis(Vector3.UP, turn)
	var h := size / 2.0
	var p := []
	for i in 8:
		p.append(center + b * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
	for f in [[2, 3, 1, 0], [5, 7, 6, 4], [1, 5, 4, 0], [6, 7, 3, 2], [4, 6, 2, 0], [3, 7, 5, 1]]:
		_tri(p[f[0]], p[f[1]], p[f[2]], c, c, c)
		_tri(p[f[0]], p[f[2]], p[f[3]], c, c, c)


## Turns what was drawn into a tree in the world.
func _finish(parent: Node, pos: Vector3, trunk: float, solid: bool, lean := 6.0) -> MeshInstance3D:
	_st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = _st.commit()
	mi.material_override = k.tree_mat()
	mi.position = pos
	mi.rotation_degrees = Vector3(-rng.randf_range(lean * 0.4, lean), rng.randf() * 360.0, 0)
	parent.add_child(mi)
	if solid:
		k.blocker(parent, Vector3(trunk * 2.2, 3.0, trunk * 2.2), pos + Vector3(0, 1.5, 0))
	return mi


func _roots(r: float, bark: Color) -> void:
	for i in 4:
		var a := rng.randf() * TAU
		var out := Vector3(cos(a), 0, sin(a))
		_tube(out * r * 2.4 + Vector3(0, -0.05, 0), Vector3(0, r * 3.0, 0), r * 0.35, r * 0.6, 4, bark.darkened(0.15), bark)


# --- Pines -------------------------------------------------------------------------

const NEEDLES := [Color(0.18, 0.3, 0.2), Color(0.22, 0.33, 0.22), Color(0.26, 0.36, 0.25), Color(0.2, 0.28, 0.24)]
const BROWN_NEEDLES := Color(0.45, 0.33, 0.2)
const BARK := Color(0.27, 0.21, 0.16)


func pine(parent: Node, pos: Vector3, tall: float, opts := {}) -> MeshInstance3D:
	var style: String = opts.get("style", "")
	if style == "":
		var roll := rng.randf()
		style = "snag" if roll < 0.08 else ("scots" if roll < 0.25 else "spruce")
	_begin()
	var r := 0.1 + tall * 0.013
	match style:
		"scots":
			_scots(tall, r)
		"snag":
			_snag(tall, r)
		_:
			_spruce(tall, r)
	return _finish(parent, pos, r, opts.get("solid", false), opts.get("lean", 5.0))


func _spruce(tall: float, r: float) -> void:
	_roots(r, BARK)
	var bend := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
	_tube(Vector3.ZERO, Vector3(0, tall * 0.5, 0) + bend * 0.5, r, r * 0.7, 6, BARK.darkened(0.2), BARK)
	_tube(Vector3(0, tall * 0.5, 0) + bend * 0.5, Vector3(0, tall * 0.92, 0) + bend, r * 0.7, r * 0.25, 5, BARK, BARK.lightened(0.1))
	var base: Color = NEEDLES[rng.randi() % NEEDLES.size()]
	var tiers := rng.randi_range(4, 6)
	var bottom := tall * rng.randf_range(0.18, 0.3)
	for i in tiers:
		var t := float(i) / tiers
		var y := bottom + (tall * 0.95 - bottom) * t
		var rad := tall * 0.2 * (1.0 - t * 0.82) * rng.randf_range(0.8, 1.2)
		var h := (tall * 0.95 - bottom) / tiers * rng.randf_range(1.5, 2.0)
		var off := bend * (y / tall) + Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15)) * rad
		var col := base.lerp(Color(0.32, 0.4, 0.28), t * 0.5)
		if rng.randf() < 0.1:
			col = BROWN_NEEDLES  # a dead patch
		var c := Vector3(0, y, 0) + off
		_tube(c, c + Vector3(0, h, 0), rad, 0.0, rng.randi_range(6, 8), col.darkened(0.35), col.lightened(0.1))
		# Shaggy branch tips drooping out of each tier.
		for j in rng.randi_range(3, 5):
			var a := rng.randf() * TAU
			var out := Vector3(cos(a), 0, sin(a))
			var from := c + out * rad * 0.55 + Vector3(0, h * 0.12, 0)
			var to := c + out * rad * rng.randf_range(1.05, 1.3) + Vector3(0, -h * 0.12, 0)
			_tube(from, to, rad * 0.2, 0.0, 4, col.darkened(0.3), col)
		if rng.randf() < 0.3:
			var a := rng.randf() * TAU
			_blob(c + Vector3(cos(a), 0, sin(a)) * rad * 0.5 - Vector3(0, 0.08, 0), Vector3(0.09, 0.14, 0.09), Color(0.45, 0.32, 0.2), Color(0.35, 0.25, 0.15), 5, 3, 0.1)
	if rng.randf() < 0.3:
		# A broken leader: the top snapped and hangs sideways.
		var top := Vector3(0, tall * 0.95, 0) + bend
		_tube(top, top + Vector3(rng.randf_range(0.4, 0.8), -0.3, rng.randf_range(-0.3, 0.3)), r * 0.25, 0.0, 4, BARK, BROWN_NEEDLES)


func _scots(tall: float, r: float) -> void:
	var bark_top := Color(0.55, 0.36, 0.22)  # the orange upper bark
	_roots(r, BARK)
	var kink := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
	var mid := Vector3(0, tall * 0.55, 0) + kink * 0.4
	var top := Vector3(0, tall * 0.82, 0) + kink
	_tube(Vector3.ZERO, mid, r * 1.1, r * 0.8, 6, BARK.darkened(0.2), BARK.lerp(bark_top, 0.5))
	_tube(mid, top, r * 0.8, r * 0.45, 6, BARK.lerp(bark_top, 0.5), bark_top)
	# Dead stubs where lower branches fell off.
	for i in 4:
		var y := rng.randf_range(0.2, 0.5) * tall
		var a := rng.randf() * TAU
		var p := Vector3(0, y, 0) + kink * (y / tall)
		_tube(p, p + Vector3(cos(a) * 0.5, 0.15, sin(a) * 0.5), r * 0.25, 0.0, 4, BARK, BARK)
	# A flat, cloudy crown on a few crooked limbs.
	var base: Color = NEEDLES[rng.randi() % NEEDLES.size()]
	for i in rng.randi_range(3, 5):
		var a := i * TAU / 4.0 + rng.randf_range(-0.5, 0.5)
		var reach := rng.randf_range(0.6, 1.4) * tall * 0.12
		var end := top + Vector3(cos(a) * reach, rng.randf_range(-0.4, 0.6), sin(a) * reach)
		_tube(top - Vector3(0, 0.4, 0), end, r * 0.35, r * 0.15, 4, bark_top, bark_top)
		var s := tall * rng.randf_range(0.14, 0.2)
		_blob(end + Vector3(0, s * 0.15, 0), Vector3(s * 1.6, s * 0.7, s * 1.5), base.lightened(0.12), base.darkened(0.35), 7, 4, 0.3)
	_blob(top + Vector3(0, tall * 0.06, 0), Vector3(tall * 0.22, tall * 0.1, tall * 0.2), base.lightened(0.1), base.darkened(0.3), 7, 4, 0.3)


func _snag(tall: float, r: float) -> void:
	var grey := Color(0.48, 0.45, 0.42)
	var h := tall * rng.randf_range(0.45, 0.7)
	_roots(r, grey.darkened(0.3))
	var lean := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	_tube(Vector3.ZERO, Vector3(0, h, 0) + lean, r * 1.1, r * 0.8, 6, grey.darkened(0.35), grey)
	# The jagged break at the top.
	var top := Vector3(0, h, 0) + lean
	for i in 3:
		var a := i * TAU / 3.0 + rng.randf()
		_tube(top + Vector3(cos(a), 0, sin(a)) * r * 0.4, top + Vector3(cos(a) * r * 0.3, rng.randf_range(0.3, 0.9), sin(a) * r * 0.3), r * 0.35, 0.0, 3, grey, grey.lightened(0.2))
	for i in 5:
		var y := rng.randf_range(0.25, 0.9) * h
		var a := rng.randf() * TAU
		var p := Vector3(0, y, 0) + lean * (y / h)
		_tube(p, p + Vector3(cos(a) * rng.randf_range(0.4, 1.2), rng.randf_range(-0.2, 0.4), sin(a) * rng.randf_range(0.4, 1.2)), r * 0.25, 0.01, 4, grey, grey)
	# Woodpecker holes.
	for i in 3:
		var y := rng.randf_range(0.3, 0.8) * h
		var a := rng.randf() * TAU
		_box(Vector3(cos(a) * r * 0.85, y, sin(a) * r * 0.85) + lean * (y / h), Vector3(0.06, 0.08, 0.06), Color(0.08, 0.07, 0.06), a)


# --- Bare trees -----------------------------------------------------------------------

## A bare, gnarled tree. opts: color, extras (birdhouse, swing...), leaves (0..1), solid.
func dead(parent: Node, pos: Vector3, tall: float, opts := {}) -> MeshInstance3D:
	_begin()
	var bark: Color = opts.get("color", Color(0.3, 0.25, 0.2))
	var r := 0.07 + tall * 0.03
	_roots(r, bark)
	var leaves: float = opts.get("leaves", 0.22)
	# A trunk in three crooked pieces.
	var pts := [Vector3.ZERO]
	for i in 3:
		var y := tall * (0.18 + i * 0.14)
		pts.append(Vector3(rng.randf_range(-0.25, 0.25), y, rng.randf_range(-0.25, 0.25)))
	for i in 3:
		var rr := r * (1.0 - i * 0.22)
		_tube(pts[i], pts[i + 1], rr, rr * 0.8, 6, bark.darkened(0.3 - i * 0.1), bark.darkened(0.15 - i * 0.07))
	var top: Vector3 = pts[3]
	for i in rng.randi_range(3, 4):
		var a := i * TAU / 4.0 + rng.randf_range(-0.4, 0.4)
		var dir := Vector3(cos(a), rng.randf_range(0.7, 1.4), sin(a)).normalized()
		_branch(top - Vector3(0, i * 0.1, 0), dir, tall * rng.randf_range(0.22, 0.3), r * 0.55, 3, bark, leaves)
	# A burl or two, and a scar where a limb tore off.
	_blob(pts[1] + Vector3(r * 0.8, 0, 0), Vector3(r * 1.2, r * 1.0, r * 1.2), bark.darkened(0.1), bark.darkened(0.25), 5, 3, 0.2)
	if opts.get("extras", false):
		_extras(pts, r, bark)
	return _finish(parent, pos, r, opts.get("solid", true), opts.get("lean", 9.0))


func _branch(start: Vector3, dir: Vector3, length: float, radius: float, depth: int, bark: Color, leaves: float) -> void:
	var end := start + dir * length
	# A slight bend halfway, so branches look grown rather than placed.
	var mid := start.lerp(end, 0.5) + Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.05, 0.1), rng.randf_range(-0.1, 0.1)) * length
	_tube(start, mid, radius, radius * 0.8, 4, bark.darkened(0.1), bark)
	_tube(mid, end, radius * 0.8, radius * 0.55, 4, bark, bark.lightened(0.05))
	if depth <= 0:
		if rng.randf() < leaves:
			var col: Color = [Color(0.55, 0.35, 0.18), Color(0.62, 0.45, 0.2), Color(0.45, 0.3, 0.18)][rng.randi() % 3]
			_blob(end + Vector3(0, -0.05, 0), Vector3(rng.randf_range(0.25, 0.4), 0.2, rng.randf_range(0.25, 0.4)), col.lightened(0.1), col.darkened(0.2), 5, 3, 0.45)
		return
	for i in rng.randi_range(2, 3):
		var d := (dir + Vector3(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.1, 0.5), rng.randf_range(-0.8, 0.8))).normalized()
		_branch(end, d, length * rng.randf_range(0.55, 0.75), radius * 0.6, depth - 1, bark, leaves)


## Little signs that people loved these trees.
func _extras(pts: Array, r: float, bark: Color) -> void:
	var roll := rng.randf()
	var p: Vector3 = pts[2]
	if roll < 0.25:
		# A birdhouse.
		var a := rng.randf() * TAU
		var out := Vector3(cos(a), 0, sin(a))
		var c := p + out * (r + 0.12)
		var wood: Color = [Color(0.6, 0.3, 0.25), Color(0.35, 0.5, 0.55), Color(0.75, 0.68, 0.45)][rng.randi() % 3]
		_box(c, Vector3(0.22, 0.26, 0.2), wood, -a)
		_box(c + Vector3(0, 0.16, 0), Vector3(0.28, 0.05, 0.26), wood.darkened(0.3), -a)
		_box(c + out * 0.101 + Vector3(0, 0.03, 0), Vector3(0.06, 0.06, 0.06), Color(0.05, 0.05, 0.05), -a)
	elif roll < 0.45:
		# A rope swing on the lowest strong branch.
		var a := rng.randf() * TAU
		var out := Vector3(cos(a), 0, sin(a))
		var hang: Vector3 = pts[1] + out * 1.2 + Vector3(0, 0.6, 0)
		_tube(pts[1] + Vector3(0, 0.5, 0), hang, r * 0.4, r * 0.3, 4, bark, bark)
		var seat := hang - Vector3(0, 1.4, 0)
		for s: float in [-0.18, 0.18]:
			var side: Vector3 = out.cross(Vector3.UP).normalized() * s
			_tube(hang + side, seat + side, 0.012, 0.012, 3, Color(0.7, 0.62, 0.45), Color(0.7, 0.62, 0.45))
		_box(seat, Vector3(0.45, 0.04, 0.18), Color(0.55, 0.4, 0.28), atan2(out.x, out.z) + PI / 2.0)
	elif roll < 0.6:
		# A faded ribbon tied round the trunk.
		_tube(pts[1] + Vector3(0, 0.2, 0), pts[1] + Vector3(0, 0.3, 0), r * 0.95, r * 0.95, 6, Color(0.75, 0.6, 0.3), Color(0.75, 0.6, 0.3))
		_tube(pts[1] + Vector3(r, 0.25, 0), pts[1] + Vector3(r + 0.05, -0.3, 0.05), 0.03, 0.01, 3, Color(0.75, 0.6, 0.3), Color(0.75, 0.6, 0.3))
	elif roll < 0.8:
		# A crow's nest of twigs in the fork.
		_blob(pts[3] + Vector3(0, 0.1, 0), Vector3(0.6, 0.25, 0.6), Color(0.3, 0.25, 0.18), Color(0.18, 0.14, 0.1), 7, 3, 0.4)


func birch(parent: Node, pos: Vector3, tall: float, opts := {}) -> MeshInstance3D:
	_begin()
	var white := Color(0.85, 0.83, 0.78)
	var gold := [Color(0.85, 0.7, 0.25), Color(0.75, 0.6, 0.2), Color(0.9, 0.78, 0.35)]
	var r := 0.05 + tall * 0.011
	# Birches often grow in a clump of two or three stems.
	var stems := 1 if rng.randf() < 0.45 else rng.randi_range(2, 3)
	for n in stems:
		var a0 := n * TAU / stems + rng.randf()
		var foot := Vector3(cos(a0), 0, sin(a0)) * (0.15 if stems > 1 else 0.0)
		var lean := Vector3(cos(a0), 0, sin(a0)) * (0.6 if stems > 1 else 0.2) + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		var h := tall * (1.0 - n * 0.15)
		var rr := r * (1.0 - n * 0.2)
		var mid := foot + Vector3(0, h * 0.45, 0) + lean * 0.35
		var top := foot + Vector3(0, h * 0.95, 0) + lean
		_tube(foot, mid, rr, rr * 0.75, 6, white.darkened(0.4), white)
		_tube(mid, top, rr * 0.75, rr * 0.2, 5, white, white.lightened(0.05))
		# The black marks.
		for i in 8:
			var t := rng.randf_range(0.05, 0.85)
			var p := foot.lerp(top, t)
			var a := rng.randf() * TAU
			_box(p + Vector3(cos(a), 0, sin(a)) * rr * (1.0 - t * 0.6) * 0.9, Vector3(0.05, 0.03, rr * 1.1), Color(0.1, 0.1, 0.1), a)
		# Thin branches, drooping a little at the ends, with yellow leaves.
		for i in rng.randi_range(6, 9):
			var t := rng.randf_range(0.4, 0.92)
			var p := foot.lerp(top, t)
			var a := rng.randf() * TAU
			var reach := h * rng.randf_range(0.12, 0.2) * (1.2 - t * 0.6)
			var elbow := p + Vector3(cos(a) * reach, h * 0.08, sin(a) * reach)
			var tip := elbow + Vector3(cos(a) * reach * 0.6, -h * 0.05, sin(a) * reach * 0.6)
			_tube(p, elbow, rr * 0.25, rr * 0.15, 4, white.darkened(0.3), white.darkened(0.45))
			_tube(elbow, tip, rr * 0.15, 0.01, 3, white.darkened(0.45), Color(0.3, 0.25, 0.2))
			if rng.randf() < opts.get("leaves", 0.8):
				var col: Color = gold[rng.randi() % 3]
				var sz := h / 7.5 * rng.randf_range(0.8, 1.2)
				_blob(elbow.lerp(tip, 0.6), Vector3(0.75, 0.5, 0.75) * sz, col, col.darkened(0.3), 6, 3, 0.4)
	return _finish(parent, pos, r, opts.get("solid", true), opts.get("lean", 6.0))


func oak(parent: Node, pos: Vector3, tall: float, opts := {}) -> MeshInstance3D:
	_begin()
	var bark := Color(0.33, 0.27, 0.21)
	var r := 0.12 + tall * 0.035
	_roots(r, bark)
	var fork := Vector3(rng.randf_range(-0.2, 0.2), tall * 0.35, rng.randf_range(-0.2, 0.2))
	_tube(Vector3.ZERO, fork, r * 1.1, r * 0.85, 7, bark.darkened(0.3), bark)
	var autumn := [Color(0.62, 0.36, 0.16), Color(0.7, 0.5, 0.2), Color(0.45, 0.42, 0.2), Color(0.55, 0.25, 0.15)]
	var bare: float = opts.get("bare", 0.2)
	var limbs := rng.randi_range(4, 5)
	for i in limbs:
		var a := i * TAU / limbs + rng.randf_range(-0.3, 0.3)
		var reach := tall * rng.randf_range(0.22, 0.32)
		var elbow := fork + Vector3(cos(a) * reach * 0.5, tall * rng.randf_range(0.08, 0.15), sin(a) * reach * 0.5)
		var end := fork + Vector3(cos(a) * reach, tall * rng.randf_range(0.2, 0.35), sin(a) * reach)
		_tube(fork, elbow, r * 0.55, r * 0.4, 5, bark, bark)
		_tube(elbow, end, r * 0.4, r * 0.18, 5, bark, bark.lightened(0.05))
		if rng.randf() < bare:
			_branch(end, (end - fork).normalized(), tall * 0.15, r * 0.15, 1, bark, 0.0)
			continue
		for j in 3:
			var col: Color = autumn[rng.randi() % autumn.size()]
			var s := tall * rng.randf_range(0.11, 0.16)
			var off := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.3, 0.6), rng.randf_range(-1.0, 1.0)) * s
			_blob(end + off, Vector3(s * 1.6, s * 1.1, s * 1.6), col.lightened(0.12), col.darkened(0.35), 7, 4, 0.35)
	var crown: Color = autumn[rng.randi() % autumn.size()]
	_blob(fork + Vector3(0, tall * 0.45, 0), Vector3(tall * 0.35, tall * 0.22, tall * 0.35), crown.lightened(0.1), crown.darkened(0.35), 8, 4, 0.3)
	# Fallen leaves in a ring around the trunk.
	var leaf: Color = autumn[rng.randi() % 2]
	_blob(Vector3(0, 0.0, 0), Vector3(tall * 0.75, 0.06, tall * 0.7), leaf.darkened(0.1), leaf.darkened(0.3), 9, 2, 0.15)
	return _finish(parent, pos, r, opts.get("solid", true), opts.get("lean", 4.0))
