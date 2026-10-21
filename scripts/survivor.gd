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


func build(k: Kit) -> void:
	var coat := Color(0.93, 0.72, 0.2)
	var coat_dark := coat.darkened(0.18)
	var tights := Color(0.2, 0.2, 0.28)
	var boots := Color(0.72, 0.16, 0.14)
	var skin := Color(0.96, 0.8, 0.68)
	var hair := Color(0.36, 0.22, 0.13)
	var hat := Color(0.2, 0.55, 0.55)
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
	k.box(_torso, Vector3(0.24, 0.07, 0.22), Vector3(0, 0.58, 0), Kit.FABRIC_RED)
	k.box(_torso, Vector3(0.07, 0.18, 0.03), Vector3(-0.07, 0.48, -0.14), Kit.FABRIC_RED)
	k.box(_torso, Vector3(0.071, 0.025, 0.031), Vector3(-0.07, 0.44, -0.14), cream)

	# Head: big and round-ish, with bangs, rosy cheeks and big dark eyes.
	_head = k.group(_torso, Vector3(0, 0.64, 0), 0)
	k.box(_head, Vector3(0.3, 0.29, 0.28), Vector3(0, 0.15, 0), skin)
	k.box(_head, Vector3(0.32, 0.22, 0.3), Vector3(0, 0.2, 0.02), hair)  # hair cap
	k.box(_head, Vector3(0.31, 0.07, 0.04), Vector3(0, 0.25, -0.135), hair)  # bangs
	k.box(_head, Vector3(0.08, 0.04, 0.04), Vector3(-0.09, 0.21, -0.135), hair)  # a stray fringe bit
	for s in [-1.0, 1.0]:
		k.box(_head, Vector3(0.04, 0.16, 0.24), Vector3(s * 0.155, 0.12, 0.02), hair)  # side hair
		k.box(_head, Vector3(0.055, 0.07, 0.01), Vector3(s * 0.065, 0.14, -0.141), Color(0.1, 0.08, 0.08))  # eyes
		k.box(_head, Vector3(0.02, 0.02, 0.01), Vector3(s * 0.065 - 0.012, 0.16, -0.147), Color(1, 1, 1))  # eye shine
		k.box(_head, Vector3(0.05, 0.03, 0.01), Vector3(s * 0.095, 0.08, -0.141), Color(0.95, 0.55, 0.52))  # cheeks
		# Braids hang from behind the ears and swing a little.
		var braid := k.group(_head, Vector3(s * 0.13, 0.1, 0.06), 0)
		for j in 3:
			k.box(braid, Vector3(0.065, 0.075, 0.065), Vector3(s * 0.01, -0.06 - j * 0.07, 0), hair if j % 2 == 0 else hair.darkened(0.15))
		k.box(braid, Vector3(0.07, 0.025, 0.07), Vector3(s * 0.01, -0.26, 0), hat)  # hair tie
		k.box(braid, Vector3(0.05, 0.05, 0.05), Vector3(s * 0.01, -0.3, 0), hair)  # tuft
		_braids.append(braid)
	k.box(_head, Vector3(0.05, 0.015, 0.01), Vector3(0, 0.06, -0.141), Color(0.6, 0.3, 0.3))  # small smile
	# Beanie with a folded brim and a pompom.
	k.box(_head, Vector3(0.33, 0.13, 0.31), Vector3(0, 0.34, 0.02), hat)
	k.box(_head, Vector3(0.34, 0.05, 0.32), Vector3(0, 0.28, 0.02), hat.darkened(0.2))
	k.ball(_head, Vector3(0.12, 0.12, 0.12), Vector3(0, 0.44, 0.03), cream)

	# Arms pivot at the shoulders: long raincoat sleeves and mittens.
	for s in [-1.0, 1.0]:
		var shoulder := k.group(_torso, Vector3(s * 0.22, 0.47, 0), 0)
		k.box(shoulder, Vector3(0.1, 0.3, 0.11), Vector3(0, -0.14, 0), coat)
		k.box(shoulder, Vector3(0.12, 0.05, 0.13), Vector3(0, -0.29, 0), coat_dark)  # cuff
		k.box(shoulder, Vector3(0.08, 0.08, 0.08), Vector3(0, -0.35, 0), Kit.FABRIC_RED)  # mitten
		_arms.append(shoulder)

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
