## The trail between Mill Road and the Ranger Station. It's four kilometres,
## so walking it is a fade and an hour on the clock (main.gd, travel).
extends "res://scripts/interactable.gd"

var destination := Vector3.ZERO
var facing := 0.0          # yaw when you arrive
var arrive_line := ""
var hours := 1.0           # how long the walk takes


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	if game and needs != "" and not game.has_item(needs):
		return needs_line
	if game:
		game.travel(destination, facing, arrive_line, hours)
	return ""
