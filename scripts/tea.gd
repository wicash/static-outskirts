## The kettle in your kitchen. Tea once a day makes the house cozier.
extends "res://scripts/interactable.gd"

var tea_day := -1


func _ready() -> void:
	add_to_group("kettle")


func interact() -> String:
	var text := super.interact()
	var clock := get_tree().get_first_node_in_group("clock")
	var game := get_tree().get_first_node_in_group("game")
	if clock:
		tea_day = clock.day
	if game:
		game.write_journal("Made tea.")
	return text
