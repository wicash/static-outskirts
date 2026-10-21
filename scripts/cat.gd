## Biscuit: a ginger stray who hangs around your house. He keeps his distance at
## first; each time you pet him, he trusts you a little more.
extends Node3D

const Kit := preload("res://scripts/kit.gd")

var home := Vector3.ZERO
var player: Node3D
var trust := 0

var _target := Vector3.ZERO
var _wait := 0.0
var _speed := 1.2
var _moving := 0.0
var _phase := 0.0

var _body: Node3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []


## Builds the cat's look and its "Pet the cat" interaction.
func build(k: Kit) -> void:
	var fur := Color(0.85, 0.52, 0.26)
	var stripe := fur.darkened(0.25)
	var cream := Color(0.92, 0.85, 0.72)
	_body = k.group(self, Vector3(0, 0.2, 0), 0)
	k.box(_body, Vector3(0.18, 0.16, 0.42), Vector3(0, 0.02, 0), fur)
	k.box(_body, Vector3(0.14, 0.06, 0.3), Vector3(0, -0.06, 0.02), cream)  # belly
	for z in [-0.12, 0.0, 0.12]:
		k.box(_body, Vector3(0.185, 0.03, 0.04), Vector3(0, 0.08, z), stripe)  # tabby stripes
	_head = k.group(_body, Vector3(0, 0.1, 0.24), 0)
	k.box(_head, Vector3(0.16, 0.14, 0.14), Vector3(0, 0.02, 0), fur)
	k.box(_head, Vector3(0.09, 0.06, 0.05), Vector3(0, -0.02, 0.08), cream)  # muzzle
	k.box(_head, Vector3(0.025, 0.02, 0.02), Vector3(0, 0.0, 0.11), Color(0.8, 0.45, 0.45))  # nose
	for s in [-1.0, 1.0]:
		k.prism(_head, Vector3(0.06, 0.07, 0.03), Vector3(s * 0.05, 0.12, -0.01), fur)
		k.box(_head, Vector3(0.03, 0.025, 0.01), Vector3(s * 0.04, 0.04, 0.071), Color(0.55, 0.65, 0.25))  # eyes
		for i in 2:
			k.box(_head, Vector3(0.12, 0.004, 0.004), Vector3(s * 0.08, -0.02 + i * 0.015, 0.09), Color(0.95, 0.95, 0.9), {"rot": Vector3(0, s * 15, 0)})  # whiskers
	k.ring(_head, 0.06, 0.075, Vector3(0, -0.06, -0.02), Color(0.7, 0.15, 0.12), Vector3(90, 0, 0))  # collar
	for x in [-0.06, 0.06]:
		for z in [-0.14, 0.14]:
			var hip := k.group(self, Vector3(x, 0.18, z), 0)
			k.box(hip, Vector3(0.05, 0.16, 0.05), Vector3(0, -0.09, 0), fur.darkened(0.08))
			k.box(hip, Vector3(0.055, 0.03, 0.07), Vector3(0, -0.17, 0.01), cream)  # paws
			_legs.append(hip)
	_tail = k.group(_body, Vector3(0, 0.06, -0.2), 0)
	for i in 4:
		k.box(_tail, Vector3(0.04, 0.04, 0.1), Vector3(0, i * 0.04, -0.04 - i * 0.07), fur if i % 2 == 0 else stripe, {"rot": Vector3(-25 - i * 10, 0, 0)})

	var pet := k.thing(self, Vector3(0.3, 0.4, 0.6), Vector3(0, 0.22, 0), "Pet the cat", [
		"The cat flinches and backs away. Maybe next time.",
		"The cat sniffs your hand, then lets you touch its ears.",
		"The cat purrs. It seems to have decided you're alright.",
		"The cat headbutts your knee. Its collar tag says BISCUIT.",
		"Biscuit purrs.",
	])
	pet.used.connect(on_petted)


func _ready() -> void:
	_target = global_position


func on_petted(times: int) -> void:
	trust = times


func _process(delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if trust == 0 and dist < 1.8:
		# Too shy: back away from the player.
		_target = global_position - to_player.normalized() * 2.0
		_speed = 2.2
	elif trust >= 2 and dist > 1.4 and dist < 8.0:
		# Friendly: follow the player around.
		_target = player.global_position - to_player.normalized() * 1.1
		_speed = 1.6
	else:
		_wait -= delta
		if _wait <= 0.0:
			_wait = randf_range(2.0, 6.0)
			_target = home + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.0, 2.0))
			_speed = 1.0

	_target.y = global_position.y
	var step := _target - global_position
	var moving := step.length() > 0.1
	if moving:
		var dir := step.normalized()
		global_position += dir * minf(_speed * delta, step.length())
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
	_animate(moving, delta)


func _animate(moving: bool, delta: float) -> void:
	if _body == null:
		return
	_moving = move_toward(_moving, 1.0 if moving else 0.0, delta * 4.0)
	_phase += delta * (4.0 + _speed * 6.0)
	for i in _legs.size():
		var offset := 0.0 if i == 0 or i == 3 else PI  # diagonal pairs move together
		_legs[i].rotation.x = sin(_phase + offset) * 0.6 * _moving
	# Sit when idle: back end lowers, head looks around.
	_body.rotation.x = lerp_angle(_body.rotation.x, (1.0 - _moving) * -0.28, delta * 3.0)
	_body.position.y = 0.2 + (1.0 - _moving) * 0.04
	var t := Time.get_ticks_msec() / 1000.0
	_head.rotation.y = sin(t * 0.7) * 0.5 * (1.0 - _moving)
	_head.rotation.x = (1.0 - _moving) * 0.4
	_tail.rotation.y = sin(t * 2.0) * 0.4
	_tail.rotation.x = -0.3 * _moving
