## Biscuit: a ginger stray who hangs around your house. He keeps his distance at
## first; each time you pet him, he trusts you a little more.
##
## Once he trusts you and wears his collar you can ask him to come along: he
## follows your footsteps (so he goes round walls, not through them) and walks
## the trails with you. Once he's moved in he keeps his own routine at home:
## asleep on your bed at night, on the radio table when there's music.
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
var _collar: Node3D
var _pet: Node
var _route: Array[Vector3] = []   # waypoints to the food bowl
var _eating := 0.0
var _home_radius := 2.5

var following := false            # asked to come along (cat_pet.gd)
var sleeping := false
var _crumbs: Array[Vector3] = []  # your footsteps, for following round corners
var _spot := ""                   # where at home he's settled: "", "bed" or "radio"
var _want_spot := ""
var _purpose := ""                # what the current route is for: "eat", "spot" or ""

## Your front door, outside and inside, so Biscuit doesn't walk through walls.
const DOOR_OUT := Vector3(0.6, 0, -7.4)
const DOOR_IN := Vector3(0.6, 0, -9.4)
## The gap in the bedroom partition, living-room side and bedroom side.
const GAP_LIVING := Vector3(-0.8, 0, -10.2)
const GAP_BED := Vector3(-2.1, 0, -10.4)
## His places at home: the foot of your bed, and the table by the radio.
const SPOTS := {
	"bed": [Vector3(-2.75, 0, -13.2), Vector3(-2.75, 0.63, -13.6)],
	"radio": [Vector3(2.0, 0, -11.2), Vector3(2.55, 0.79, -11.75)],
}


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
	_collar = k.ring(_head, 0.06, 0.075, Vector3(0, -0.06, -0.02), Color(0.7, 0.15, 0.12), Vector3(90, 0, 0))
	_collar.visible = false  # it's on Grace's nightstand at No. 6
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
		"The cat headbutts your knee. Grace called him Biscuit. It suits him.",
		"Biscuit purrs.",
	], preload("res://scripts/cat_pet.gd"))
	pet.cat = self
	pet.used.connect(on_petted)
	_pet = pet


func _ready() -> void:
	_target = global_position
	add_to_group("cat")


## Called when you fill the bowl: walk in through the front door and eat.
func come_eat(bowl: Vector3) -> void:
	bowl.y = 0.0
	_settle_off()
	_route = _path(global_position, bowl + Vector3(0, 0, -0.3))
	_purpose = "eat"
	_want_spot = ""


## Which part of your house a point is in: "out", "living" or "bedroom".
static func _room(p: Vector3) -> String:
	if p.z > -8.5 or absf(p.x) > 4.0 or p.z < -15.5:
		return "out"
	return "bedroom" if p.x < -1.4 else "living"


## Waypoints from a to b through doors rather than walls.
func _path(a: Vector3, b: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var ra := _room(a)
	var rb := _room(b)
	if ra == rb:
		out.append(b)
		return out
	if ra == "out":
		out.append_array([DOOR_OUT, DOOR_IN])
	elif ra == "bedroom":
		out.append_array([GAP_BED, GAP_LIVING])
		if rb == "out":
			out.append_array([DOOR_IN, DOOR_OUT])
	else:  # living
		if rb == "out":
			out.append_array([DOOR_IN, DOOR_OUT])
	if rb == "bedroom":
		out.append_array([GAP_LIVING, GAP_BED])
	out.append(b)
	return out


func _settle_off() -> void:
	_spot = ""
	sleeping = false
	global_position.y = 0.0 if global_position.y < 1.0 else global_position.y


## Called by cat_pet.gd: start or stop following you.
func set_following(on: bool) -> void:
	following = on
	_crumbs.clear()
	_route.clear()
	if on:
		_settle_off()
	else:
		home = global_position
		home.y = 0.0
		_home_radius = 0.6


## Called when you walk a trail with him: he arrives with you.
func arrive_with(p: Vector3, behind: Vector3) -> void:
	global_position = p + behind
	if global_position.y < 1.0:
		global_position.y = 0.0
	_crumbs.clear()
	_route.clear()


## Called when you go to sleep: he's with you, at home, on the bed.
func back_home_for_the_night() -> void:
	following = false
	_crumbs.clear()
	_route.clear()
	if moved_in:
		home = Vector3(2.0, 0, -9.15)
		_home_radius = 0.8
		var spot: Array = SPOTS["bed"]
		global_position = spot[1]
		_spot = "bed"
		_want_spot = "bed"
		sleeping = true
	elif global_position.distance_to(home) > 30.0:
		global_position = home


var moved_in := false


func collar_on() -> bool:
	return _collar.visible


## Used when loading a saved game.
func restore(t: int, inside: bool, collar: bool) -> void:
	trust = t
	if _pet:
		_pet.times_used = t
	if inside:
		_move_in()
		global_position = home
	_collar.visible = collar


## Where he'd like to be at home right now (see SPOTS).
func _wanted_spot() -> String:
	if not moved_in or following or trust < 2:
		return ""
	if Vector2(global_position.x, global_position.z + 12.0).length() > 25.0:
		return ""  # not at home (you asked him to stay somewhere else)
	var clock := get_tree().get_first_node_in_group("clock")
	if clock and (clock.hour >= 21.0 or clock.hour < 6.5):
		return "bed"
	var radio := get_tree().get_first_node_in_group("radio")
	if radio and radio.on and absf(radio.freq - 96.4) < 0.3:
		return "radio"
	return ""


func _move_in() -> void:
	# Biscuit has decided your house is his house now.
	moved_in = true
	home = Vector3(2.0, 0, -9.15)
	_home_radius = 0.8


## Called from the backpack once Biscuit trusts you enough.
func wear_collar() -> void:
	_collar.visible = true


func _bump_trust() -> void:
	trust += 1
	if _pet:
		_pet.times_used = maxi(_pet.times_used, trust)


func on_petted(times: int) -> void:
	trust = times


func _process(delta: float) -> void:
	if player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var friendly := (following and dist < 30.0) or (trust >= 2 and dist < 8.0 and not moved_in)
	if friendly:
		_leave_crumb()

	if not _route.is_empty():
		# On the way somewhere: the bowl, or one of his spots.
		_target = _route[0]
		_speed = 1.5
		var flat := _target - global_position
		if flat.length() < 0.15:
			_route.pop_front()
			if _route.is_empty():
				if _purpose == "eat":
					_eating = 6.0
				elif _purpose == "spot":
					global_position = _target  # land the hop
					_spot = _want_spot
					sleeping = _spot == "bed"
				_purpose = ""
	elif _eating > 0.0:
		_eating -= delta
		_target = global_position
		if _eating <= 0.0:
			_bump_trust()
			get_tree().call_group("cat_bowl", "eaten")
			_move_in()
	elif trust == 0 and dist < 1.8:
		# Too shy: back away from the player.
		_target = global_position - to_player.normalized() * 2.0
		_target.y = global_position.y
		_speed = 2.2
	elif friendly and dist > 1.3:
		# Following: walk your footsteps, hurrying if he's fallen behind.
		while _crumbs.size() > 1 and _crumbs[0].distance_to(global_position) < 0.25:
			_crumbs.pop_front()
		_target = _crumbs[0] if not _crumbs.is_empty() else player.global_position
		_speed = clampf(dist * 0.9, 1.6, 5.6)
	elif friendly or following:
		_target = global_position  # close enough, or waiting for you to come back
	else:
		_home_routine(delta)

	var step := _target - global_position
	if absf(step.y) < 0.02 or (_route.is_empty() and not friendly and _spot == ""):
		step.y = 0.0
	var moving := Vector2(step.x, step.z).length() > 0.1
	if moving or absf(step.y) > 0.02:
		var dir := step.normalized()
		global_position += dir * minf(_speed * delta, step.length())
		if moving:
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
	_animate(moving, delta)


func _leave_crumb() -> void:
	var p: Vector3 = player.global_position
	p.y = maxf(p.y, 0.0)
	if not _crumbs.is_empty() and _crumbs[-1].distance_to(p) > 3.0:
		# You jumped (a trail or a ladder) and he didn't come: he waits here
		# until you're back.
		_crumbs.clear()
		return
	if _crumbs.is_empty() or _crumbs[-1].distance_to(p) > 0.4:
		_crumbs.append(p)
		if _crumbs.size() > 400:
			_crumbs.pop_front()


## At home and not busy: go to his spot if he wants one, otherwise potter.
func _home_routine(delta: float) -> void:
	var want := _wanted_spot()
	if want != _spot or (want != "" and _want_spot != want):
		_want_spot = want
		var from := global_position
		_settle_off()
		if want != "":
			var spot: Array = SPOTS[want]
			_route = _path(from, spot[0])
			_route.append(spot[1])  # the hop up
			_purpose = "spot"
		else:
			_route = _path(from, home)
		return
	if _spot != "":
		_target = global_position
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = randf_range(2.0, 6.0)
		_target = home + Vector3(randf_range(-_home_radius, _home_radius), 0, randf_range(-_home_radius, _home_radius) * 0.8)
		if _room(_target) != _room(global_position):
			_target = global_position
		_speed = 1.0
	_target.y = global_position.y


func _animate(moving: bool, delta: float) -> void:
	if _body == null:
		return
	_moving = move_toward(_moving, 1.0 if moving else 0.0, delta * 4.0)
	if sleeping and not moving:
		# Curled up: tucked down low, head on his paws, tail wrapped round.
		_body.rotation.x = lerp_angle(_body.rotation.x, 0.0, delta * 3.0)
		_body.position.y = lerpf(_body.position.y, 0.1, delta * 3.0)
		_head.rotation.x = 0.35
		_head.rotation.y = 0.6
		_tail.rotation.y = 1.4
		_tail.rotation.x = 0.4
		var breathe := 1.0 + sin(Time.get_ticks_msec() / 700.0) * 0.03
		_body.scale = Vector3(1.0, breathe, 1.0)
		for l in _legs:
			l.rotation.x = 0.0
			l.visible = false
		return
	_body.scale = Vector3.ONE
	for l in _legs:
		l.visible = true
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
