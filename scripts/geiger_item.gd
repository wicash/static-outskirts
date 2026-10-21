## The Geiger counter on the crate in your kitchen. Picking it up gives it to Sam.
extends "res://scripts/interactable.gd"


func _ready() -> void:
	add_to_group("geiger_item")


func interact() -> String:
	get_tree().call_group("game", "pick_up_geiger")
	queue_free()
	return "An old yellow Geiger counter, from the hospital. It ticks softly. Most of the street is fine. Some places aren't. (G to check it)"
