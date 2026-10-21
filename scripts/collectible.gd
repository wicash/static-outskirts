## A lost thing or a Ranger cache. It glints so you notice it from a distance,
## counts toward the map, and plays a chime when found.
extends "res://scripts/interactable.gd"

var kind := "memory"   # "memory" or "cache"
var title := ""        # shown on the map once found
var _glint: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	add_to_group(kind)
	_glint = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.95, 0.75, 0.9) if kind == "memory" else Color(0.7, 1.0, 0.7, 0.9)
	m.no_depth_test = false
	q.material = m
	_glint.mesh = q
	_glint.position = Vector3(0, 0.15, 0)
	add_child(_glint)
	_t = randf() * 10.0


func found() -> bool:
	return times_used > 0


func interact() -> String:
	var first := times_used == 0
	var text := super.interact()
	if first:
		_put_away()
		var game := get_tree().get_first_node_in_group("game")
		if game:
			game.chime(true)
			game.collected(kind)
	return text


## Lost things go into your backpack (and onto the board at home).
func _put_away() -> void:
	if kind != "memory":
		return
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)
		elif c is Node3D and c != _glint:
			c.visible = false


func after_load() -> void:
	if times_used > 0:
		_put_away()


func _process(delta: float) -> void:
	if times_used > 0:
		_glint.visible = false
		return
	# A small sparkle every couple of seconds.
	_t += delta
	var p := fmod(_t, 2.4)
	var s := maxf(0.0, 1.0 - absf(p - 0.2) * 5.0)
	_glint.scale = Vector3.ONE * (0.2 + s * 1.3)
	_glint.visible = s > 0.02
