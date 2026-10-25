## Someone you can talk to (from chapter two on; Wren and Ines have their own
## scripts). Pressing E opens a conversation on the paper overlay: a greeting
## and a button for each thing you can ask about (main.gd, talk_to).
##
## Each person's script extends this one and fills in:
##   who        the name at the top of the page
##   TOPICS     id -> [button, what they say, journal line]
##   greeting() what they say when you walk up
##   can_ask()  which topics show up right now
##   asked()    anything that happens after a topic (items, chimes, travel)
extends "res://scripts/interactable.gd"

var id := ""             # save id, e.g. "grace"
var who := ""
var met := false
var topics: Array = []   # topic ids already talked about
var body: Node3D


func _ready() -> void:
	add_to_group("npc")
	prompt = "Talk to " + who


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.talk_to(self)
	return ""


func _process(delta: float) -> void:
	if body and body.has_method("animate") and visible:
		body.animate(0.0, delta)


func topic_list() -> Dictionary:
	return {}


func greeting(_game: Node) -> String:
	return "\"Hello.\""


func can_ask(_game: Node, _topic: String) -> bool:
	return true


## Called after a topic is picked. Return a different line to say instead,
## or "" to use the topic's own line.
func asked(_game: Node, _topic: String) -> String:
	return ""


## Topics still to ask, in order.
func available(game: Node) -> Array:
	var out: Array = []
	var all := topic_list()
	for t in all:
		if not t in topics and can_ask(game, t):
			out.append(t)
	return out


## Hides someone who has moved on (they're somewhere else in the world now).
func set_gone(gone: bool) -> void:
	visible = not gone
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", gone)


func after_load() -> void:
	pass
