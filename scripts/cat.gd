## A stray cat that hangs around your house. It keeps its distance at
## first; each time you pet it, it trusts you a little more.
extends Node3D

var home := Vector3.ZERO
var player: Node3D
var trust := 0

var _target := Vector3.ZERO
var _wait := 0.0
var _speed := 1.2


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
	if step.length() > 0.1:
		var dir := step.normalized()
		global_position += dir * minf(_speed * delta, step.length())
		var yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, yaw, delta * 6.0)
