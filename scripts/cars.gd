## Detailed placeholder cars: several body shapes, see-through windows,
## furnished interiors and the belongings people left behind.
## A car's front points along its local +X.
extends RefCounted

const Kit := preload("res://scripts/kit.gd")

## Body shapes, in metres.
## hood/tail: length in front of / behind the cabin. belt: height of the window line.
## front_slope/rear_slope: how far the windscreen / rear window lean.
const MODELS := {
	"estate": {"length": 4.6, "width": 1.8, "hood": 1.0, "tail": 0.1, "belt": 0.95, "roof": 1.5, "front_slope": 0.7, "rear_slope": 0.08, "wheel": 0.32},
	"sedan": {"length": 4.5, "width": 1.78, "hood": 1.15, "tail": 0.95, "belt": 0.92, "roof": 1.42, "front_slope": 0.65, "rear_slope": 0.5, "wheel": 0.31},
	"hatchback": {"length": 3.8, "width": 1.68, "hood": 0.85, "tail": 0.18, "belt": 0.92, "roof": 1.45, "front_slope": 0.6, "rear_slope": 0.35, "wheel": 0.29},
	"van": {"length": 5.0, "width": 1.95, "hood": 0.55, "tail": 0.0, "belt": 1.15, "roof": 2.15, "front_slope": 0.45, "rear_slope": 0.0, "wheel": 0.34},
	"pickup": {"length": 5.2, "width": 1.85, "hood": 1.2, "tail": 1.9, "belt": 1.05, "roof": 1.75, "front_slope": 0.55, "rear_slope": 0.0, "wheel": 0.38},
}

const BOTTOM := 0.28
const T := 0.06
const TRIM := Color(0.13, 0.13, 0.14)
const CHROME := Color(0.62, 0.63, 0.64)
const ASH := Color(0.74, 0.72, 0.68)

var k: Kit


func _init(kit: Kit) -> void:
	k = kit


## Builds a car. Options:
## color, interior (seat colour), plate, dirt (0..1 ash on glass), rust (0..1),
## ash (bool), flat (bool), crashed (bool), driver_door_open (bool), side_door_open (bool, van),
## cargo (Array of [name, Vector3 pos, float turn, Color]), prompt, lines, writing (text in the dust).
func build(parent: Node, model: String, pos: Vector3, turn: float, opts := {}) -> Node3D:
	var m: Dictionary = MODELS[model]
	var L: float = m.length
	var W: float = m.width
	var belt: float = m.belt
	var roof: float = m.roof
	var fs: float = m.front_slope
	var rs: float = m.rear_slope
	var wr: float = m.wheel
	var half := W / 2.0
	var xf: float = L / 2.0 - m.hood        # base of the windscreen
	var xb: float = -L / 2.0 + m.tail       # back of the cabin
	var xrf := xf - fs                      # roof front edge
	var xrb := xb + rs                      # roof back edge
	var xd := xf - minf(1.05, (xf - xb) * 0.5)  # front door / rear door split
	var paint: Color = opts.get("color", Color(0.5, 0.55, 0.6))
	var seat: Color = opts.get("interior", Color(0.3, 0.3, 0.33))
	var crashed: bool = opts.get("crashed", false)

	var root := k.group(parent, pos, turn)

	# What you aim at to interact, and what stops you walking through the car.
	var t := k.thing(root, Vector3(L, roof - 0.1, W), Vector3(0, (roof + 0.1) / 2.0, 0),
		opts.get("prompt", "Look inside the car"), opts.get("lines", ["Nothing useful. Just someone's car."]))
	t.gives = opts.get("gives", [])
	t.journal = opts.get("journal", "")

	# --- Body -------------------------------------------------------------------
	var hood := k.box(root, Vector3(m.hood, belt - BOTTOM, W), Vector3(L / 2.0 - m.hood / 2.0, (belt + BOTTOM) / 2.0, 0), paint)
	if crashed:
		hood.rotation_degrees = Vector3(0, 0, 9)
		hood.position.y += 0.08
		hood.scale.x = 0.8
	# Bonnet line and grille.
	k.box(root, Vector3(0.02, 0.02, W - 0.1), Vector3(xf + 0.02, belt + 0.005, 0), paint.darkened(0.3))
	if model == "pickup":
		_pickup_bed(root, L, W, m.tail, belt, paint)
	elif m.tail > 0.0:
		k.box(root, Vector3(m.tail, belt - BOTTOM - 0.04, W), Vector3(-L / 2.0 + m.tail / 2.0, (belt - 0.04 + BOTTOM) / 2.0, 0), paint)
	if model == "pickup" or model == "van":
		k.box(root, Vector3(T, belt - BOTTOM, W), Vector3(xb + T / 2.0, (belt + BOTTOM) / 2.0, 0), paint)  # back wall of the cab / van

	# Cabin floor and the dark underside you see through the wheel gaps.
	k.box(root, Vector3(xf - xb, 0.06, W - 2 * T), Vector3((xf + xb) / 2.0, BOTTOM + 0.05, 0), TRIM)
	k.box(root, Vector3(L - 0.4, 0.12, W - 0.2), Vector3(0, BOTTOM - 0.02, 0), Color(0.08, 0.08, 0.08))

	for s in [-1.0, 1.0]:
		var z: float = s * (half - T / 2.0)
		var open_driver: bool = opts.get("driver_door_open", false) and s < 0
		var open_side: bool = opts.get("side_door_open", false) and s > 0
		# Door panels below the window line.
		if open_driver:
			_open_door(root, xf, xd, belt, roof, fs, half, s, paint, seat)
		else:
			k.box(root, Vector3(xf - xd, belt - BOTTOM, T), Vector3((xf + xd) / 2.0, (belt + BOTTOM) / 2.0, z), paint)
			k.box(root, Vector3(0.14, 0.03, 0.03), Vector3(xd + 0.2, belt - 0.12, s * (half + 0.01)), CHROME)  # handle
		if not open_side:
			k.box(root, Vector3(xd - xb, belt - BOTTOM, T), Vector3((xd + xb) / 2.0, (belt + BOTTOM) / 2.0, z), paint)
			if model != "van" and model != "pickup":
				k.box(root, Vector3(0.14, 0.03, 0.03), Vector3(xd - 0.75, belt - 0.12, s * (half + 0.01)), CHROME)
		# Door seams, rubbing strip and sill.
		k.box(root, Vector3(0.015, belt - BOTTOM - 0.06, 0.01), Vector3(xd, (belt + BOTTOM) / 2.0, s * (half + 0.005)), TRIM)
		k.box(root, Vector3(xf - xb, 0.05, 0.02), Vector3((xf + xb) / 2.0, BOTTOM + 0.22, s * (half + 0.01)), TRIM)
		k.box(root, Vector3(L - 0.3, 0.06, 0.03), Vector3(0, BOTTOM + 0.02, s * (half - 0.01)), TRIM)

		# Pillars: A (along the windscreen), B (between doors), C (by the rear window).
		_beam(root, Vector3(xf, belt, s * (half - 0.04)), Vector3(xrf, roof, s * (half - 0.06)), 0.07, paint)
		k.box(root, Vector3(0.08, roof - belt, 0.07), Vector3(xd, (belt + roof) / 2.0, s * (half - 0.05)), paint)
		_beam(root, Vector3(xb + 0.03, belt, s * (half - 0.04)), Vector3(xrb + 0.03, roof, s * (half - 0.06)), 0.09, paint)

		# Side windows (trapezoids that follow the pillars).
		var gz: float = s * (half - 0.05)
		if not open_driver:
			k.quad(root, Vector3(xd, belt, gz), Vector3(xf, belt, gz), Vector3(xrf, roof, gz), Vector3(xd, roof, gz), k.glass_mat(opts.get("dirt", 0.35)))
		if not open_side:
			# Vans have solid panels where cars have rear side windows.
			var rear_mat: Material = k.mat(paint) if model == "van" else k.glass_mat(opts.get("dirt", 0.35))
			k.quad(root, Vector3(xb, belt, gz), Vector3(xd, belt, gz), Vector3(xd, roof, gz), Vector3(xrb, roof, gz), rear_mat)

		# Wing mirror.
		k.box(root, Vector3(0.05, 0.03, 0.1), Vector3(xf - 0.12, belt + 0.03, s * (half + 0.04)), TRIM)
		k.box(root, Vector3(0.1, 0.11, 0.13), Vector3(xf - 0.12, belt + 0.09, s * (half + 0.12)), paint)

		# Lights.
		k.box(root, Vector3(0.04, 0.12, 0.3), Vector3(L / 2.0 + 0.005, belt - 0.2, s * (half - 0.27)), Color(0.85, 0.83, 0.7))
		k.box(root, Vector3(0.04, 0.06, 0.12), Vector3(L / 2.0 + 0.005, belt - 0.33, s * (half - 0.2)), Color(0.85, 0.5, 0.15))
		k.box(root, Vector3(0.04, 0.16, 0.22), Vector3(-L / 2.0 - 0.005, belt - 0.2, s * (half - 0.18)), Color(0.55, 0.08, 0.06))

	# Windscreen, rear window, roof.
	var hz := half - T
	k.quad(root, Vector3(xf, belt, -hz), Vector3(xf, belt, hz), Vector3(xrf, roof, hz), Vector3(xrf, roof, -hz), k.glass_mat(opts.get("dirt", 0.35) * 0.6))
	if model != "pickup":
		k.quad(root, Vector3(xb, belt, -hz), Vector3(xb, belt, hz), Vector3(xrb, roof, hz), Vector3(xrb, roof, -hz), k.glass_mat(opts.get("dirt", 0.35)))
	else:
		k.pane(root, Vector3(0.02, roof - belt - 0.15, W * 0.6), Vector3(xb + 0.02, (belt + roof) / 2.0, 0))
	k.box(root, Vector3(xrf - xrb + 0.06, 0.06, W - 0.08), Vector3((xrf + xrb) / 2.0, roof, 0), paint)
	k.box(root, Vector3(0.06, 0.06, W - 0.1), Vector3(xf + 0.02, belt + 0.02, 0), TRIM)  # wiper well
	for z in [-0.35, 0.25]:
		k.box(root, Vector3(0.02, 0.015, 0.5), Vector3(xf - 0.05, belt + 0.05, z), TRIM, {"rot": Vector3(0, 12, 0)})  # wipers
	if crashed:
		_cracks(root, xf, xrf, belt, roof)

	# Bumpers, grille, number plates.
	for e in [-1.0, 1.0]:
		k.box(root, Vector3(0.14, 0.16, W + 0.04), Vector3(e * (L / 2.0 + 0.02), BOTTOM + 0.1, 0), Color(0.2, 0.2, 0.21),
			{"rot": Vector3(0, 14 if crashed and e > 0 else 0, 0)})
		k.box(root, Vector3(0.02, 0.12, 0.5), Vector3(e * (L / 2.0 + 0.1), BOTTOM + 0.1, 0), Color(0.9, 0.88, 0.8))
		k.words(root, opts.get("plate", "AH 51 KR"), Vector3(e * (L / 2.0 + 0.115), BOTTOM + 0.1, 0), Vector3(0, 90 * e, 0), 0.0022)
	k.box(root, Vector3(0.03, 0.17, W * 0.42), Vector3(L / 2.0 + 0.01, belt - 0.22, 0), Color(0.1, 0.1, 0.1))
	for i in 4:
		k.box(root, Vector3(0.035, 0.012, W * 0.42), Vector3(L / 2.0 + 0.012, belt - 0.29 + i * 0.045, 0), CHROME)

	# Wheels with hubcaps.
	var axles := [L / 2.0 - maxf(0.75, m.hood * 0.6), -L / 2.0 + (1.15 if model == "pickup" else 0.85)]
	for ax in axles:
		for s in [-1.0, 1.0]:
			var y := wr * (0.72 if opts.get("flat", false) else 1.0)
			k.cyl(root, wr, 0.22, Vector3(ax, y, s * (half - 0.1)), Color(0.07, 0.07, 0.07), {"rot": Vector3(90, 0, 0), "sides": 10})
			k.cyl(root, wr * 0.55, 0.23, Vector3(ax, y, s * (half - 0.1)), CHROME.darkened(0.2), {"rot": Vector3(90, 0, 0), "sides": 8})
			k.box(root, Vector3(wr * 2.3, 0.08, 0.1), Vector3(ax, wr * 2.0 + 0.02, s * (half - 0.02)), TRIM)  # arch lip

	# Roof rails on estates, aerial on everything else.
	if model == "estate":
		for s in [-1.0, 1.0]:
			k.box(root, Vector3(xrf - xrb - 0.2, 0.05, 0.05), Vector3((xrf + xrb) / 2.0, roof + 0.07, s * (half - 0.2)), TRIM)
	else:
		k.cyl(root, 0.006, 0.7, Vector3(xrb + 0.2, roof + 0.35, half - 0.3), TRIM, {"sides": 3, "rot": Vector3(0, 0, 15)})

	# --- Interior ---------------------------------------------------------------
	_interior(root, xf, xb, xd, xrf, belt, roof, half, seat, model)

	# --- Wear and tear ----------------------------------------------------------
	var rust: float = opts.get("rust", 0.0)
	for i in int(rust * 10):
		var rx := k.rng.randf_range(-L / 2.0 + 0.3, L / 2.0 - 0.3)
		var s := 1.0 if k.rng.randf() < 0.5 else -1.0
		k.box(root, Vector3(k.rng.randf_range(0.1, 0.35), k.rng.randf_range(0.05, 0.2), 0.01),
			Vector3(rx, BOTTOM + k.rng.randf_range(0.05, 0.3), s * (half + 0.006)), Kit.RUST)
	if opts.get("ash", true):
		k.box(root, Vector3((xrf - xrb) * 0.92, 0.015, W * 0.82), Vector3((xrf + xrb) / 2.0, roof + 0.04, 0), ASH)
		k.box(root, Vector3(m.hood * 0.85, 0.015, W * 0.8), Vector3(L / 2.0 - m.hood / 2.0, belt + 0.01, 0), ASH,
			{"rot": Vector3(0, 0, 9 if crashed else 0)})
	if opts.has("writing"):
		var back_x := (xb + xrb) / 2.0 - 0.02
		var lean := rad_to_deg(atan2(rs, roof - belt))
		k.words(root, opts.writing, Vector3(back_x, (belt + roof) / 2.0, 0), Vector3(-lean, -90, 0), 0.006, Color(0.8, 0.78, 0.72))

	# --- Belongings ---------------------------------------------------------------
	for item in opts.get("cargo", []):
		_cargo(root, item[0], item[1], item[2], item[3])

	return root


func _beam(parent: Node, a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	k.beam(parent, a, b, thick, color)


func _open_door(root: Node3D, xf: float, xd: float, belt: float, roof: float, fs: float, half: float, s: float, paint: Color, seat: Color) -> void:
	var len := xf - xd
	# Hinge at the front edge of the door, swung outwards.
	var door := Node3D.new()
	door.position = Vector3(xf, 0, s * (half - T / 2.0))
	door.rotation_degrees.y = s * 62.0
	root.add_child(door)
	k.box(door, Vector3(len, belt - BOTTOM, T), Vector3(-len / 2.0, (belt + BOTTOM) / 2.0, 0), paint)
	k.box(door, Vector3(len - 0.1, belt - BOTTOM - 0.15, 0.03), Vector3(-len / 2.0, (belt + BOTTOM) / 2.0, -s * 0.04), seat.darkened(0.2))  # inner trim
	k.box(door, Vector3(0.25, 0.04, 0.06), Vector3(-len / 2.0, belt - 0.2, -s * 0.07), TRIM)  # armrest
	k.box(door, Vector3(0.05, roof - belt, 0.05), Vector3(-len + 0.03, (belt + roof) / 2.0, 0), paint)  # window frame
	k.box(door, Vector3(len - fs * 0.5, 0.04, 0.05), Vector3(-len / 2.0 - fs * 0.25, roof - 0.02, 0), paint)
	k.pane(door, Vector3(len - fs * 0.5 - 0.06, roof - belt - 0.08, 0.015), Vector3(-len / 2.0 - fs * 0.25, (belt + roof) / 2.0, 0))
	k.box(door, Vector3(0.05, 0.03, 0.1), Vector3(-0.12, belt + 0.03, s * 0.04), TRIM)


func _cracks(root: Node3D, xf: float, xrf: float, belt: float, roof: float) -> void:
	# A spider-web crack where something hit the windscreen.
	var centre := Vector3(lerpf(xf, xrf, 0.45) + 0.01, lerpf(belt, roof, 0.45) + 0.01, -0.3)
	for i in 7:
		var ang := i * TAU / 7.0 + 0.3
		var tip := centre + Vector3(-sin(ang) * 0.18, cos(ang) * 0.25, sin(ang * 1.7) * 0.35).limit_length(0.45)
		_beam(root, centre, tip, 0.008, Color(0.85, 0.87, 0.88))


func _pickup_bed(root: Node3D, L: float, W: float, tail: float, belt: float, paint: Color) -> void:
	var x := -L / 2.0 + tail / 2.0
	k.box(root, Vector3(tail, 0.42, W), Vector3(x, BOTTOM + 0.21, 0), paint)
	k.box(root, Vector3(tail - 0.1, 0.03, W - 0.14), Vector3(x, BOTTOM + 0.43, 0), Color(0.18, 0.18, 0.18), {"pattern": Kit.Pattern.PLANKS})
	for s in [-1.0, 1.0]:
		k.box(root, Vector3(tail, belt - BOTTOM - 0.42, T), Vector3(x, (belt + BOTTOM + 0.42) / 2.0, s * (W / 2.0 - T / 2.0)), paint)
		k.box(root, Vector3(tail, 0.04, 0.1), Vector3(x, belt, s * (W / 2.0 - 0.05)), TRIM)
	k.box(root, Vector3(T, belt - BOTTOM - 0.42, W), Vector3(-L / 2.0 + T / 2.0, (belt + BOTTOM + 0.42) / 2.0, 0), paint)


func _interior(root: Node3D, xf: float, xb: float, xd: float, xrf: float, belt: float, roof: float, half: float, seat: Color, model: String) -> void:
	var floor_y := BOTTOM + 0.08
	var driver_z := -0.4
	# Dashboard, instrument cluster, glovebox, centre console.
	k.box(root, Vector3(0.45, 0.26, half * 2.0 - 0.14), Vector3(xf - 0.2, belt - 0.09, 0), Color(0.16, 0.16, 0.17))
	k.box(root, Vector3(0.3, 0.05, half * 2.0 - 0.16), Vector3(xf - 0.3, belt + 0.03, 0), Color(0.12, 0.12, 0.13))
	k.box(root, Vector3(0.03, 0.12, 0.34), Vector3(xf - 0.43, belt - 0.04, driver_z), Color(0.06, 0.06, 0.06))
	for gz in [-0.08, 0.08]:
		k.cyl(root, 0.045, 0.01, Vector3(xf - 0.445, belt - 0.04, driver_z + gz), Color(0.75, 0.72, 0.6), {"rot": Vector3(0, 0, 90), "sides": 8})
		k.box(root, Vector3(0.005, 0.035, 0.006), Vector3(xf - 0.452, belt - 0.03, driver_z + gz), Color(0.7, 0.15, 0.1), {"rot": Vector3(30, 0, 0)})
	k.box(root, Vector3(0.03, 0.12, 0.32), Vector3(xf - 0.43, belt - 0.12, -driver_z), Color(0.13, 0.13, 0.14))  # glovebox
	k.box(root, Vector3(0.03, 0.08, 0.2), Vector3(xf - 0.43, belt - 0.16, 0), Color(0.08, 0.08, 0.08))  # radio slot
	for i in 3:
		k.box(root, Vector3(0.02, 0.02, 0.025), Vector3(xf - 0.445, belt - 0.16, -0.06 + i * 0.06), Color(0.6, 0.6, 0.55))
	k.box(root, Vector3(0.7, 0.18, 0.22), Vector3(xf - 0.7, floor_y + 0.09, 0), Color(0.14, 0.14, 0.15))  # console
	k.cyl(root, 0.012, 0.22, Vector3(xf - 0.62, floor_y + 0.28, 0), Color(0.1, 0.1, 0.1), {"rot": Vector3(0, 0, 15), "sides": 4})  # gear stick
	k.ball(root, Vector3(0.05, 0.05, 0.05), Vector3(xf - 0.65, floor_y + 0.39, 0), Color(0.12, 0.12, 0.12))
	k.box(root, Vector3(0.22, 0.03, 0.04), Vector3(xf - 0.95, floor_y + 0.2, 0), Color(0.1, 0.1, 0.1), {"rot": Vector3(0, 0, 18)})  # handbrake

	# Steering wheel and column.
	var wheel_x := xf - 0.58
	k.ring(root, 0.15, 0.185, Vector3(wheel_x, belt + 0.02, driver_z), Color(0.08, 0.08, 0.08), Vector3(0, 0, 70))
	k.box(root, Vector3(0.012, 0.3, 0.025), Vector3(wheel_x, belt + 0.02, driver_z), Color(0.08, 0.08, 0.08), {"rot": Vector3(0, 0, 70)})
	k.cyl(root, 0.05, 0.05, Vector3(wheel_x + 0.01, belt + 0.02, driver_z), Color(0.12, 0.12, 0.12), {"rot": Vector3(0, 0, 70), "sides": 6})
	k.cyl(root, 0.03, 0.35, Vector3(wheel_x + 0.17, belt - 0.05, driver_z), Color(0.1, 0.1, 0.1), {"rot": Vector3(0, 0, 70), "sides": 5})
	# Pedals.
	for pz in [-0.5, -0.4, -0.3]:
		k.box(root, Vector3(0.03, 0.08, 0.06), Vector3(xf - 0.12, floor_y + 0.12, pz), Color(0.2, 0.2, 0.2), {"rot": Vector3(0, 0, 25)})

	# Mirror, sun visors, interior light.
	k.box(root, Vector3(0.03, 0.06, 0.22), Vector3(xrf - 0.08, roof - 0.13, 0), Color(0.1, 0.1, 0.1))
	k.box(root, Vector3(0.005, 0.045, 0.2), Vector3(xrf - 0.1, roof - 0.13, 0), Color(0.55, 0.6, 0.62))
	for vz in [-0.38, 0.38]:
		k.box(root, Vector3(0.18, 0.02, 0.36), Vector3(xrf - 0.1, roof - 0.06, vz), seat.lightened(0.2), {"rot": Vector3(0, 0, -15)})
	k.box(root, Vector3(0.1, 0.02, 0.06), Vector3((xrf + xb) / 2.0, roof - 0.04, 0), Color(0.8, 0.78, 0.7))
	# Headliner and carpet.
	k.box(root, Vector3(xrf - xb - 0.1, 0.02, half * 2.0 - 0.16), Vector3((xrf + xb) / 2.0, roof - 0.035, 0), seat.lightened(0.35))
	k.box(root, Vector3(xf - xb - 0.1, 0.02, half * 2.0 - 0.16), Vector3((xf + xb) / 2.0, floor_y, 0), Color(0.18, 0.17, 0.16))
	# Inner door trim and armrests on both sides.
	for s in [-1.0, 1.0]:
		k.box(root, Vector3(xf - xb - 0.1, belt - BOTTOM - 0.2, 0.02), Vector3((xf + xb) / 2.0, (belt + BOTTOM) / 2.0 + 0.05, s * (half - T - 0.01)), seat.darkened(0.25))
		k.box(root, Vector3(0.3, 0.04, 0.06), Vector3(xd + 0.4, belt - 0.2, s * (half - T - 0.04)), Color(0.12, 0.12, 0.12))

	# Front seats.
	var sx := xf - 1.0
	for z in [driver_z, -driver_z]:
		_seat(root, Vector3(sx, floor_y, z), 0.5, seat)
	# Rear seats or cargo floor.
	if model == "van":
		k.box(root, Vector3(0.05, roof - floor_y - 0.2, half * 2.0 - 0.2), Vector3(sx - 0.45, (roof + floor_y) / 2.0 - 0.1, 0), Color(0.3, 0.3, 0.3), {"pattern": Kit.Pattern.SIDING})  # bulkhead
		k.box(root, Vector3(sx - 0.5 - xb, 0.03, half * 2.0 - 0.16), Vector3((sx - 0.5 + xb) / 2.0, floor_y + 0.02, 0), Kit.WOOD, {"pattern": Kit.Pattern.PLANKS})
	elif model != "pickup":
		var rx := maxf(sx - 0.95, xb + 0.5)
		k.box(root, Vector3(0.5, 0.14, half * 2.0 - 0.3), Vector3(rx, floor_y + 0.3, 0), seat)
		k.box(root, Vector3(0.12, 0.58, half * 2.0 - 0.3), Vector3(rx - 0.28, floor_y + 0.64, 0), seat, {"rot": Vector3(0, 0, 14)})
		for hz in [-0.5, 0.0, 0.5]:
			k.box(root, Vector3(0.08, 0.15, 0.24), Vector3(rx - 0.38, floor_y + 1.0, hz), seat.darkened(0.1), {"rot": Vector3(0, 0, 14)})
		if model == "estate" or model == "hatchback":
			k.box(root, Vector3(maxf(rx - 0.35 - xb, 0.1), 0.03, half * 2.0 - 0.16), Vector3((rx - 0.35 + xb) / 2.0, floor_y + 0.25, 0), Color(0.15, 0.15, 0.15))  # boot floor
		else:
			k.box(root, Vector3(0.3, 0.05, half * 2.0 - 0.2), Vector3(xb + 0.15, belt - 0.03, 0), Color(0.15, 0.15, 0.15))  # parcel shelf


func _seat(root: Node3D, base: Vector3, width: float, color: Color) -> void:
	k.box(root, Vector3(0.12, 0.18, 0.3), base + Vector3(0, 0.09, 0), Color(0.1, 0.1, 0.1))
	k.box(root, Vector3(0.52, 0.13, width), base + Vector3(0, 0.25, 0), color)
	k.box(root, Vector3(0.48, 0.03, width - 0.12), base + Vector3(0, 0.32, 0), color.darkened(0.12))  # cushion seam
	k.box(root, Vector3(0.13, 0.65, width), base + Vector3(-0.3, 0.62, 0), color, {"rot": Vector3(0, 0, 14)})
	k.box(root, Vector3(0.1, 0.17, width * 0.55), base + Vector3(-0.42, 1.05, 0), color.darkened(0.08), {"rot": Vector3(0, 0, 14)})
	k.box(root, Vector3(0.02, 0.6, 0.04), base + Vector3(-0.22, 0.65, width * 0.4), Color(0.12, 0.12, 0.12), {"rot": Vector3(30, 0, 14)})  # seat belt


## Things people packed or left behind.
func _cargo(root: Node3D, name: String, pos: Vector3, turn: float, color: Color) -> void:
	var g := k.group(root, pos, turn)
	match name:
		"suitcase":
			k.box(g, Vector3(0.55, 0.22, 0.38), Vector3(0, 0.11, 0), color)
			k.box(g, Vector3(0.56, 0.02, 0.39), Vector3(0, 0.12, 0), color.darkened(0.3))
			k.box(g, Vector3(0.14, 0.03, 0.03), Vector3(0, 0.24, 0), Color(0.1, 0.1, 0.1))
			for cx in [-0.2, 0.2]:
				k.box(g, Vector3(0.03, 0.225, 0.39), Vector3(cx, 0.11, 0), Color(0.3, 0.25, 0.2))  # straps
		"bag":
			k.ball(g, Vector3(0.45, 0.25, 0.3), Vector3(0, 0.12, 0), color)
			k.ring(g, 0.06, 0.08, Vector3(0, 0.25, 0), color.darkened(0.3), Vector3(90, 0, 0))
		"box":
			k.box(g, Vector3(0.4, 0.3, 0.32), Vector3(0, 0.15, 0), Color(0.6, 0.48, 0.32))
			k.box(g, Vector3(0.41, 0.02, 0.06), Vector3(0, 0.3, 0), Color(0.75, 0.7, 0.55))  # tape
		"birdcage":
			k.cyl(g, 0.15, 0.03, Vector3(0, 0.015, 0), Color(0.75, 0.65, 0.35), {"sides": 8})
			for i in 8:
				var a := i * TAU / 8.0
				k.box(g, Vector3(0.008, 0.34, 0.008), Vector3(cos(a) * 0.14, 0.18, sin(a) * 0.14), Color(0.75, 0.65, 0.35))
			k.cyl(g, 0.15, 0.12, Vector3(0, 0.4, 0), Color(0.75, 0.65, 0.35), {"top": 0.0, "sides": 8})
			k.box(g, Vector3(0.2, 0.01, 0.01), Vector3(0, 0.15, 0), Color(0.4, 0.3, 0.2))  # perch, empty
		"child_seat":
			k.box(g, Vector3(0.38, 0.1, 0.38), Vector3(0, 0.05, 0), color)
			k.box(g, Vector3(0.1, 0.55, 0.38), Vector3(-0.18, 0.3, 0), color)
			for s in [-1.0, 1.0]:
				k.box(g, Vector3(0.3, 0.3, 0.06), Vector3(-0.03, 0.2, s * 0.19), color.darkened(0.15))
		"raincoat":
			k.box(g, Vector3(0.4, 0.04, 0.32), Vector3(0, 0.02, 0), Color(0.9, 0.75, 0.2), {"rot": Vector3(0, 0, 8)})
			k.box(g, Vector3(0.1, 0.03, 0.16), Vector3(0.2, 0.05, 0.1), Color(0.9, 0.75, 0.2), {"rot": Vector3(0, 30, 0)})  # sleeve
		"map":
			k.box(g, Vector3(0.45, 0.005, 0.32), Vector3(0, 0.003, 0), Color(0.86, 0.84, 0.72))
			k.box(g, Vector3(0.3, 0.006, 0.01), Vector3(0, 0.004, 0.02), Color(0.7, 0.2, 0.15), {"rot": Vector3(0, 25, 0)})  # route in red pen
		"mug":
			k.cyl(g, 0.04, 0.09, Vector3(0, 0.045, 0), color, {"sides": 7})
		"bottle":
			k.cyl(g, 0.04, 0.24, Vector3(0, 0.12, 0), Color(0.5, 0.6, 0.65), {"sides": 6})
			k.cyl(g, 0.018, 0.04, Vector3(0, 0.26, 0), Color(0.2, 0.4, 0.7), {"sides": 5})
		"teddy":
			k.ball(g, Vector3(0.16, 0.18, 0.13), Vector3(0, 0.09, 0), Color(0.55, 0.4, 0.28))
			k.ball(g, Vector3(0.12, 0.12, 0.12), Vector3(0, 0.23, 0), Color(0.55, 0.4, 0.28))
			for s in [-1.0, 1.0]:
				k.ball(g, Vector3(0.04, 0.04, 0.03), Vector3(0, 0.3, s * 0.05), Color(0.45, 0.32, 0.22))
		"blanket":
			k.box(g, Vector3(0.6, 0.06, 0.5), Vector3(0, 0.03, 0), color, {"rot": Vector3(4, 0, -3)})
			k.box(g, Vector3(0.5, 0.05, 0.4), Vector3(0.05, 0.08, -0.04), color.lightened(0.15), {"rot": Vector3(-3, 20, 2)})
		"jerrycan":
			k.box(g, Vector3(0.35, 0.45, 0.16), Vector3(0, 0.225, 0), Color(0.6, 0.15, 0.1))
			k.cyl(g, 0.025, 0.06, Vector3(0.12, 0.48, 0), Color(0.15, 0.15, 0.15))
		"mattress":
			k.box(g, Vector3(1.9, 0.18, 1.3), Vector3(0, 0.09, 0), Color(0.82, 0.8, 0.72), {"pattern": Kit.Pattern.WALLPAPER})
		"chair":
			k.box(g, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.45, 0), Kit.WOOD)
			k.box(g, Vector3(0.04, 0.45, 0.42), Vector3(-0.19, 0.7, 0), Kit.WOOD)
			for lx in [-0.18, 0.18]:
				for lz in [-0.18, 0.18]:
					k.box(g, Vector3(0.04, 0.45, 0.04), Vector3(lx, 0.22, lz), Kit.WOOD_DARK)
		"airbag":
			k.ball(g, Vector3(0.12, 0.38, 0.4), Vector3(0, 0, 0), Color(0.88, 0.87, 0.84))
		"photo":
			k.box(g, Vector3(0.1, 0.004, 0.07), Vector3(0, 0.002, 0), Color(0.9, 0.9, 0.88))
			k.box(g, Vector3(0.08, 0.005, 0.05), Vector3(0, 0.003, 0), color)
		"tissues":
			k.box(g, Vector3(0.22, 0.09, 0.12), Vector3(0, 0.045, 0), color)
			k.box(g, Vector3(0.04, 0.05, 0.03), Vector3(0, 0.1, 0), Color(0.95, 0.95, 0.95))
