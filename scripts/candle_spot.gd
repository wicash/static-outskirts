## A saucer in your house where you can put a candle. Lit candles make the
## house cozier (see main.gd comfort()).
extends "res://scripts/interactable.gd"

const Kit := preload("res://scripts/kit.gd")
const Furniture := preload("res://scripts/furniture.gd")

var lit := false


func _ready() -> void:
	add_to_group("candle_spot")
	prompt = "Put a candle here"


func interact() -> String:
	if lit:
		return "The candle flickers. It makes the room feel like a room."
	var game := get_tree().get_first_node_in_group("game")
	if game == null or not game.has_item("candle"):
		return "A saucer that would hold a candle nicely. You'll need to find one."
	if not game.has_item("matches"):
		return "You've got a candle, but nothing to light it with."
	game.take_item("candle")
	light()
	game.write_journal("Lit a candle at home. It's starting to feel like mine again.")
	return "You set the candle on the saucer and light it. The room gets smaller and warmer."


func light() -> void:
	lit = true
	prompt = "Look at the candle"
	Furniture.new(Kit.new()).candle(self, Vector3(0, -0.02, 0), true)
