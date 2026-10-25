## The paddle gear on the canal lock's top gate. Chained up (bolt cutters),
## and wound with a windlass, it lets the flooded stretch of canal down so
## the towpath comes out of the water (canal.gd, drain).
extends "res://scripts/interactable.gd"

var canal: RefCounted       # the Canal builder, which knows the water
var stage := 0              # 0 chained, 1 chain cut, 2 wound and drained
var chain: Node3D


func _ready() -> void:
	add_to_group("canal_paddle")
	prompt = "Look at the paddle gear"


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	match stage:
		0:
			if not game.has_item("bolt_cutters"):
				return "The paddle gear that lets water through the gate. Someone's wrapped it in chain and padlocked it. Kids, probably, years ago."
			stage = 1
			times_used = 1
			chain.visible = false
			prompt = "Wind the paddle"
			game.chime()
			return "The bolt cutters bite through the chain. It slithers off into the canal with a plop. Now you need something to wind it with."
		1:
			if not game.has_item("windlass"):
				return "The spindle's square and greasy. You'd need a windlass, the L-shaped handle lock-keepers carry. There's a cottage back up the towpath."
			stage = 2
			times_used = 2
			prompt = ""
			canal.drain(false)
			game.write_journal("Wound the lock paddles with Alf's windlass. The flooded stretch drained into the lower canal. The towpath's walkable again.")
			game.chime(true)
			return "You fit the windlass and lean on it. Click. Click. Click. Then a deep glug, and the water starts to pour through the gate, roaring. Further up, the towpath slowly comes up out of the flood."
	return ""


func after_load() -> void:
	stage = times_used
	chain.visible = stage == 0
	prompt = ["Look at the paddle gear", "Wind the paddle", ""][stage]
	if stage == 2:
		canal.drain(true)
