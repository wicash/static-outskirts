## A door, gate or padlock that opens with a tool (needs). Until then it shows
## its locked lines and the game remembers you tried it (for the map, and a
## reminder when you find the right tool). Once open it swings away and you
## can walk through.
extends "res://scripts/interactable.gd"

var lock_name := "A locked door"   # how the map lists it
var tool_hint := ""                # what the map says it needs once tried
var open_line := "It opens."
var swing: Node3D                  # the part that swings open (optional)
var swing_angle := 100.0
var swing2: Node3D                 # a second part that swings the other way (double gates)
var hide_on_open: Array = []       # boards, chains, padlocks
var tried := false
var is_open := false


func _ready() -> void:
	add_to_group("lock")


func interact() -> String:
	if is_open:
		return ""
	var game := get_tree().get_first_node_in_group("game")
	if game == null or not game.has_item(needs):
		tried = true
		_tries += 1
		if _tries <= lines.size():
			return lines[_tries - 1]
		return needs_line
	times_used = 1
	open()
	if journal != "":
		game.write_journal(journal)
	game.chime(true)
	return open_line


var _tries := 0


func open() -> void:
	is_open = true
	prompt = ""
	for n in hide_on_open:
		if is_instance_valid(n):
			n.visible = false
	if swing:
		var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(swing, "rotation_degrees:y", swing.rotation_degrees.y + swing_angle, 0.8)
	if swing2:
		var t2 := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t2.tween_property(swing2, "rotation_degrees:y", swing2.rotation_degrees.y - swing_angle, 0.8)
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)


func after_load() -> void:
	if times_used > 0 and not is_open:
		is_open = true
		prompt = ""
		for n in hide_on_open:
			if is_instance_valid(n):
				n.visible = false
		if swing:
			swing.rotation_degrees.y += swing_angle
		if swing2:
			swing2.rotation_degrees.y -= swing_angle
		for c in get_children():
			if c is CollisionShape3D:
				c.disabled = true
