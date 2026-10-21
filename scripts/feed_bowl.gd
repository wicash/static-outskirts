## Biscuit's bowl by your front door. Fill it with a tin of cat food once a
## day and Biscuit comes in to eat, trusting you a little more each time.
extends "res://scripts/interactable.gd"

var fed_day := -1
var _food: Node3D


func _ready() -> void:
	add_to_group("cat_bowl")
	var k := preload("res://scripts/kit.gd").new()
	_food = k.ball(self, Vector3(0.14, 0.05, 0.14), Vector3(0, -0.04, 0), Color(0.55, 0.38, 0.28))
	_food.visible = false


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	var clock := get_tree().get_first_node_in_group("clock")
	if clock and fed_day == clock.day:
		return "There's still food in it. Biscuit eats like a duchess, a little at a time."
	if game == null or not game.has_item("cat_food"):
		return "Biscuit's bowl is empty. Grace's note said the tins are in her cupboard, at No. 6."
	game.take_item("cat_food")
	fed_day = clock.day if clock else 0
	_food.visible = true
	get_tree().call_group("cat", "come_eat", global_position)
	game.write_journal("Fed Biscuit.")
	return "You open a tin and spoon it into the bowl. Somewhere outside, a cat has heard the tin."


func eaten() -> void:
	_food.visible = false
