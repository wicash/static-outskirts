## Sam's third-person body: parka, scarf, beanie, backpack with a bedroll.
## Arms and legs swing with walking speed.
extends Node3D

const Kit := preload("res://scripts/kit.gd")

var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _torso: Node3D
var _phase := 0.0


func build(k: Kit) -> void:
	var parka := Color(0.33, 0.38, 0.28)
	var trousers := Color(0.22, 0.22, 0.26)
	var skin := Color(0.78, 0.6, 0.48)
	# Legs pivot at the hips.
	for s in [-1.0, 1.0]:
		var hip := k.group(self, Vector3(s * 0.11, 0.9, 0), 0)
		k.box(hip, Vector3(0.15, 0.48, 0.17), Vector3(0, -0.24, 0), trousers)
		k.box(hip, Vector3(0.14, 0.4, 0.15), Vector3(0, -0.66, 0), trousers.darkened(0.1))
		k.box(hip, Vector3(0.16, 0.12, 0.28), Vector3(0, -0.85, -0.05), Color(0.25, 0.18, 0.12))  # boot
		_legs.append(hip)
	_torso = k.group(self, Vector3(0, 0.9, 0), 0)
	k.box(_torso, Vector3(0.46, 0.62, 0.28), Vector3(0, 0.33, 0), parka)
	k.box(_torso, Vector3(0.5, 0.2, 0.3), Vector3(0, 0.0, 0), parka.darkened(0.1))  # coat hem
	k.box(_torso, Vector3(0.03, 0.55, 0.01), Vector3(0, 0.33, -0.145), Color(0.15, 0.15, 0.15))  # zip
	for s in [-1.0, 1.0]:
		k.box(_torso, Vector3(0.14, 0.1, 0.02), Vector3(s * 0.13, 0.12, -0.15), parka.darkened(0.2))  # pockets
	k.box(_torso, Vector3(0.36, 0.12, 0.3), Vector3(0, 0.66, 0), Color(0.6, 0.25, 0.2))  # scarf
	k.box(_torso, Vector3(0.1, 0.3, 0.04), Vector3(0.08, 0.5, -0.16), Color(0.6, 0.25, 0.2))  # scarf tail
	var head := k.group(_torso, Vector3(0, 0.78, 0), 0)
	k.box(head, Vector3(0.24, 0.26, 0.24), Vector3(0, 0.1, 0), skin)
	k.box(head, Vector3(0.27, 0.15, 0.27), Vector3(0, 0.26, 0.01), Color(0.55, 0.45, 0.3))  # beanie
	k.box(head, Vector3(0.28, 0.04, 0.28), Vector3(0, 0.19, 0.01), Color(0.5, 0.4, 0.27))
	for s in [-1.0, 1.0]:
		k.box(head, Vector3(0.04, 0.03, 0.01), Vector3(s * 0.06, 0.12, -0.125), Color(0.12, 0.1, 0.08))  # eyes
	# Arms pivot at the shoulders.
	for s in [-1.0, 1.0]:
		var shoulder := k.group(_torso, Vector3(s * 0.29, 0.58, 0), 0)
		k.box(shoulder, Vector3(0.13, 0.36, 0.15), Vector3(0, -0.18, 0), parka)
		k.box(shoulder, Vector3(0.12, 0.3, 0.14), Vector3(0, -0.5, 0), parka.darkened(0.05))
		k.box(shoulder, Vector3(0.1, 0.1, 0.1), Vector3(0, -0.7, 0), Color(0.3, 0.28, 0.25))  # gloves
		_arms.append(shoulder)
	# Backpack with a rolled blanket on top.
	k.box(_torso, Vector3(0.38, 0.48, 0.2), Vector3(0, 0.33, 0.24), Color(0.5, 0.36, 0.22))
	k.box(_torso, Vector3(0.3, 0.18, 0.04), Vector3(0, 0.22, 0.35), Color(0.45, 0.32, 0.2))
	k.cyl(_torso, 0.09, 0.44, Vector3(0, 0.62, 0.25), Kit.FABRIC_RED, {"rot": Vector3(0, 0, 90), "sides": 6})
	for s in [-1.0, 1.0]:
		k.box(_torso, Vector3(0.05, 0.5, 0.03), Vector3(s * 0.15, 0.36, -0.15), Color(0.35, 0.25, 0.15))  # straps


## speed in metres per second.
func animate(speed: float, delta: float) -> void:
	var amount := clampf(speed / 3.0, 0.0, 1.6)
	_phase += delta * (3.0 + speed * 2.2)
	var swing := sin(_phase) * 0.55 * amount
	for i in 2:
		var s := 1.0 if i == 0 else -1.0
		_legs[i].rotation.x = lerp_angle(_legs[i].rotation.x, swing * s, delta * 12.0)
		_arms[i].rotation.x = lerp_angle(_arms[i].rotation.x, -swing * s * 0.8, delta * 12.0)
	# A small bob and lean when moving, slow breathing when still.
	_torso.position.y = 0.9 + absf(sin(_phase)) * 0.04 * amount + sin(Time.get_ticks_msec() / 900.0) * 0.006
	_torso.rotation.x = lerp_angle(_torso.rotation.x, -0.08 * amount, delta * 5.0)
