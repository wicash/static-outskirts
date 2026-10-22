## Sam's third-person body: a small girl in an oversized yellow raincoat, red
## wellies, a teal pompom beanie and two brown braids. Big head, big eyes,
## chunky low-poly proportions. Arms, legs and braids swing as she walks.
extends Node3D

const Kit := preload("res://scripts/kit.gd")

const HIP := 0.62

var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _braids: Array[Node3D] = []
var _torso: Node3D
var _head: Node3D
var _phase := 0.0


## `look` lets other people reuse the body (see station.gd for Ranger Wren):
## coat, tights, boots, skin, hair, hat, scarf, iris colours; "hat_style"
## ("beanie" or "brim"); "backpack" (bool).
var look := {}


func build(k: Kit, with_look := {}) -> void:
	look = with_look
	var coat: Color = look.get("coat", Color(0.93, 0.72, 0.2))
	var coat_dark := coat.darkened(0.18)
	var tights: Color = look.get("tights", Color(0.2, 0.2, 0.28))
	var boots: Color = look.get("boots", Color(0.72, 0.16, 0.14))
	var skin: Color = look.get("skin", Color(0.96, 0.8, 0.68))
	var hair: Color = look.get("hair", Color(0.45, 0.25, 0.15))
	var hat: Color = look.get("hat", Color(0.2, 0.55, 0.55))
	var scarf: Color = look.get("scarf", Kit.FABRIC_RED)
	var cream := Color(0.95, 0.92, 0.84)

	# Legs pivot at the hips: dark tights and chunky red wellies.
	for s in [-1.0, 1.0]:
		var hip := k.group(self, Vector3(s * 0.075, HIP, 0), 0)
		k.box(hip, Vector3(0.1, 0.36, 0.11), Vector3(0, -0.2, 0), tights)
		k.box(hip, Vector3(0.13, 0.24, 0.15), Vector3(0, -0.47, -0.01), boots)  # welly
		k.box(hip, Vector3(0.14, 0.04, 0.22), Vector3(0, -0.6, -0.04), boots.darkened(0.3))  # sole
		k.box(hip, Vector3(0.14, 0.03, 0.16), Vector3(0, -0.36, -0.01), boots.lightened(0.15))  # welly rim
		_legs.append(hip)

	# Body: a roomy raincoat that flares out at the hem.
	_torso = k.group(self, Vector3(0, HIP, 0), 0)
	k.box(_torso, Vector3(0.36, 0.42, 0.26), Vector3(0, 0.3, 0), coat)
	k.box(_torso, Vector3(0.42, 0.2, 0.3), Vector3(0, 0.02, 0), coat)  # flared hem
	k.box(_torso, Vector3(0.43, 0.03, 0.31), Vector3(0, -0.07, 0), coat_dark)  # hem seam
	for i in 3:
		k.box(_torso, Vector3(0.035, 0.035, 0.02), Vector3(0.05, 0.42 - i * 0.13, -0.135), Color(0.2, 0.18, 0.15))  # toggles
	for s in [-1.0, 1.0]:
		k.box(_torso, Vector3(0.11, 0.08, 0.02), Vector3(s * 0.12, 0.05, -0.155), coat_dark)  # pockets
	k.box(_torso, Vector3(0.3, 0.07, 0.28), Vector3(0, 0.53, 0), coat_dark)  # collar
	# Little red-and-cream knitted scarf.
	k.box(_torso, Vector3(0.24, 0.07, 0.22), Vector3(0, 0.58, 0), scarf)
	k.box(_torso, Vector3(0.07, 0.18, 0.03), Vector3(-0.07, 0.48, -0.14), scarf)
	k.box(_torso, Vector3(0.071, 0.025, 0.031), Vector3(-0.07, 0.44, -0.14), cream)

	# Head: big, with a painted anime-style face (see _face_texture), spiky
	# bangs, long side locks, braids and a cowlick poking out of the beanie.
	_head = k.group(_torso, Vector3(0, 0.64, 0), 0)
	k.box(_head, Vector3(0.32, 0.31, 0.29), Vector3(0, 0.16, 0), skin)
	var face := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.3, 0.3)
	face.mesh = q
	face.material_override = _face_material(skin)
	face.position = Vector3(0, 0.155, -0.1465)
	face.rotation_degrees.y = 180
	_head.add_child(face)
	k.box(_head, Vector3(0.34, 0.24, 0.3), Vector3(0, 0.21, 0.02), hair)  # hair cap
	k.box(_head, Vector3(0.33, 0.05, 0.03), Vector3(0, 0.275, -0.15), hair)  # fringe root
	var spikes := [[-0.13, 0.05], [-0.075, 0.075], [-0.02, 0.06], [0.035, 0.085], [0.09, 0.06], [0.135, 0.05]]
	for sp in spikes:
		var tall: float = sp[1]
		k.prism(_head, Vector3(0.065, tall, 0.025), Vector3(sp[0], 0.255 - tall / 2.0, -0.155), hair, {"rot": Vector3(0, 0, 180)})
	for s in [-1.0, 1.0]:
		k.box(_head, Vector3(0.04, 0.18, 0.25), Vector3(s * 0.165, 0.15, 0.03), hair)  # side hair
		k.prism(_head, Vector3(0.06, 0.24, 0.04), Vector3(s * 0.15, 0.13, -0.13), hair, {"rot": Vector3(0, 0, 180 + s * 4)})  # side locks
		# Braids hang from behind the ears and swing a little.
		var braid := k.group(_head, Vector3(s * 0.14, 0.1, 0.06), 0)
		for j in 3:
			k.box(braid, Vector3(0.065, 0.075, 0.065), Vector3(s * 0.01, -0.06 - j * 0.07, 0), hair if j % 2 == 0 else hair.darkened(0.15))
		k.box(braid, Vector3(0.07, 0.025, 0.07), Vector3(s * 0.01, -0.26, 0), hat)  # hair tie
		k.prism(braid, Vector3(0.06, 0.07, 0.06), Vector3(s * 0.01, -0.31, 0), hair, {"rot": Vector3(0, 0, 180)})  # tuft
		_braids.append(braid)
	if look.get("hat_style", "beanie") == "brim":
		# A ranger's wide-brimmed hat with a band.
		k.cyl(_head, 0.29, 0.025, Vector3(0, 0.31, 0.02), hat, {"sides": 10})
		k.cyl(_head, 0.17, 0.14, Vector3(0, 0.39, 0.02), hat, {"top": 0.15, "sides": 8})
		k.cyl(_head, 0.175, 0.035, Vector3(0, 0.34, 0.02), hat.darkened(0.35), {"sides": 8})
	else:
		# Beanie with a folded brim and a pompom.
		k.box(_head, Vector3(0.35, 0.13, 0.32), Vector3(0, 0.375, 0.02), hat)
		k.box(_head, Vector3(0.36, 0.05, 0.33), Vector3(0, 0.315, 0.02), hat.darkened(0.2))
		k.ball(_head, Vector3(0.12, 0.12, 0.12), Vector3(0, 0.475, 0.03), cream)
		# The cowlick that no hat can hold down.
		k.beam(_head, Vector3(0.1, 0.33, -0.12), Vector3(0.15, 0.4, -0.16), 0.016, hair)
		k.beam(_head, Vector3(0.15, 0.4, -0.16), Vector3(0.12, 0.44, -0.2), 0.014, hair)

	# Arms pivot at the shoulders: long raincoat sleeves and mittens.
	for s in [-1.0, 1.0]:
		var shoulder := k.group(_torso, Vector3(s * 0.22, 0.47, 0), 0)
		k.box(shoulder, Vector3(0.1, 0.3, 0.11), Vector3(0, -0.14, 0), coat)
		k.box(shoulder, Vector3(0.12, 0.05, 0.13), Vector3(0, -0.29, 0), coat_dark)  # cuff
		k.box(shoulder, Vector3(0.08, 0.08, 0.08), Vector3(0, -0.35, 0), look.get("mitten", Kit.FABRIC_RED))  # mitten
		_arms.append(shoulder)

	if not look.get("backpack", true):
		return
	# Small backpack with a cat patch and a dangling keyring torch.
	k.box(_torso, Vector3(0.26, 0.28, 0.13), Vector3(0, 0.3, 0.19), Color(0.42, 0.5, 0.62))
	k.box(_torso, Vector3(0.2, 0.1, 0.03), Vector3(0, 0.2, 0.26), Color(0.36, 0.43, 0.55))
	k.box(_torso, Vector3(0.06, 0.06, 0.01), Vector3(0.06, 0.34, 0.258), Color(0.9, 0.55, 0.25))  # cat patch
	k.cyl(_torso, 0.015, 0.07, Vector3(-0.1, 0.12, 0.26), Kit.METAL, {"sides": 5})
	for s in [-1.0, 1.0]:
		k.box(_torso, Vector3(0.04, 0.32, 0.02), Vector3(s * 0.11, 0.32, -0.14), Color(0.3, 0.36, 0.45))  # straps


## speed in metres per second.
func animate(speed: float, delta: float) -> void:
	var amount := clampf(speed / 3.0, 0.0, 1.6)
	_phase += delta * (3.5 + speed * 2.6)
	var swing := sin(_phase) * 0.6 * amount
	for i in 2:
		var s := 1.0 if i == 0 else -1.0
		_legs[i].rotation.x = lerp_angle(_legs[i].rotation.x, swing * s, delta * 12.0)
		_arms[i].rotation.x = lerp_angle(_arms[i].rotation.x, -swing * s * 0.9, delta * 12.0)
		_arms[i].rotation.z = lerp_angle(_arms[i].rotation.z, s * 0.12, delta * 6.0)
		_braids[i].rotation.x = lerp_angle(_braids[i].rotation.x, 0.25 * amount + sin(_phase * 2.0 + s) * 0.15 * amount, delta * 8.0)
		_braids[i].rotation.z = sin(_phase + s) * 0.12 * amount
	var t := Time.get_ticks_msec() / 1000.0
	# A bouncy step when moving, slow breathing when still.
	_torso.position.y = HIP + absf(sin(_phase)) * 0.035 * amount + sin(t * 1.4) * 0.005
	_torso.rotation.x = lerp_angle(_torso.rotation.x, -0.07 * amount, delta * 5.0)
	_head.rotation.z = sin(t * 0.6) * 0.04 * (1.0 - minf(amount, 1.0))


## Unshaded-ish textured material for the painted face.
func _face_material(skin: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(_face_texture(skin))
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return m


## Paints a 32x32 anime-style face: tall shiny eyes, lashes, blush, small mouth.
func _face_texture(skin: Color) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(skin)
	var lash := Color(0.16, 0.08, 0.07)
	var iris_top: Color = look.get("iris", Color(0.32, 0.16, 0.1))
	var iris_low: Color = look.get("iris_low", Color(0.88, 0.58, 0.26))
	var pupil := Color(0.18, 0.08, 0.06)
	for side: int in [0, 1]:
		var x0: int = 6 if side == 0 else 19
		var outer: int = x0 - 1 if side == 0 else x0 + 7
		# Upper lash line, thick, flicking out at the outer corner.
		for x in range(x0, x0 + 7):
			img.set_pixel(x, 12, lash)
			img.set_pixel(x, 13, lash)
		img.set_pixel(outer, 12, lash)
		img.set_pixel(outer, 11, lash)
		# Eyebrow, thin and high.
		for x in range(x0 + 1, x0 + 6):
			img.set_pixel(x, 9, skin.darkened(0.35))
		# White of the eye at the outer edge, iris filling the rest.
		for y in range(14, 21):
			var t := float(y - 14) / 6.0
			for x in range(x0, x0 + 7):
				var edge: bool = (x == x0 and side == 0) or (x == x0 + 6 and side == 1)
				img.set_pixel(x, y, Color(0.97, 0.96, 0.95) if edge else iris_top.lerp(iris_low, t))
		for y in range(15, 19):
			for x in range(x0 + 2, x0 + 5):
				img.set_pixel(x, y, pupil.lerp(iris_top, float(y - 15) / 5.0))
		# Sparkles.
		var hx: int = x0 + 1 if side == 0 else x0 + 1
		img.set_pixel(hx, 14, Color.WHITE)
		img.set_pixel(hx + 1, 14, Color.WHITE)
		img.set_pixel(hx, 15, Color.WHITE)
		img.set_pixel(hx + 1, 15, Color.WHITE)
		img.set_pixel(x0 + 4, 19, Color(1, 1, 1, 1))
		# Lower lash, faint.
		for x in range(x0 + 1, x0 + 6):
			img.set_pixel(x, 21, skin.darkened(0.25))
		# Blush: three little diagonal strokes.
		var bx: int = 4 if side == 0 else 22
		for i in 3:
			img.set_pixel(bx + i * 2, 23, Color(0.95, 0.5, 0.5))
			img.set_pixel(bx + i * 2 + 1, 22, Color(0.95, 0.5, 0.5))
		for x in range(bx, bx + 6):
			var c: Color = img.get_pixel(x, 24)
			img.set_pixel(x, 24, c.lerp(Color(0.97, 0.62, 0.6), 0.6))
	# Tiny nose and a small open smile.
	img.set_pixel(16, 22, skin.darkened(0.15))
	for x in range(14, 18):
		img.set_pixel(x, 25, Color(0.45, 0.18, 0.18))
	img.set_pixel(15, 26, Color(0.85, 0.42, 0.45))
	img.set_pixel(16, 26, Color(0.85, 0.42, 0.45))
	img.flip_x()  # the quad is turned around to face forward
	return img
