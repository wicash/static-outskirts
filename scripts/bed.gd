## Your bed. In the evening it lets you sleep until the next morning.
extends "res://scripts/interactable.gd"


func interact() -> String:
	var clock := get_tree().get_first_node_in_group("clock")
	if clock and clock.is_evening():
		get_tree().call_group("game", "sleep")
		return ""
	if clock and clock.hour < 12.0:
		return "You only just got up. The day's barely started."
	return "Not yet. There's still some light out."
