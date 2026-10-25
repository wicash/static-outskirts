## Dee Ames, who drove the 6:40 and walked its eleven passengers up to the
## station on day three. Now he keeps the camp's lights on.
extends "res://scripts/npc.gd"


func _init() -> void:
	id = "dee"
	who = "Dee Ames"


func topic_list() -> Dictionary:
	return {
		"card": ["You pinned my card",
			"\"I did. Your mum asked, and I don't say no to your mum. Nobody does.\" He grins. \"Wren nearly caught me. I said I was checking the noticeboard for a lost glove.\"",
			"Dee Ames pinned my card on Wren's board, because Mum asked him to."],
		"signal": ["The signal at the crossing",
			"\"Red. It went red and the line went dead and I stopped her where she stood.\" He turns his cap round in his hands. \"I keep saying sorry to people for it. Your mum says I have to stop. I'm trying.\"",
			""],
		"lights": ["The lights here",
			"\"Wind turbine off a farm, car batteries, and a lot of string.\" He points at the bulbs strung between the tents. \"Wren taught me. Don't tell her I said she was right.\"",
			""],
	}


func greeting(_game: Node) -> String:
	if not met:
		met = true
		return "A big man in a train driver's jacket stands up from a crate of wires. \"Sam Hale! In the flesh.\" He shakes your hand with both of his. \"Dee. I drove the 6:40. Sorry about... well. Sorry.\""
	return "Dee touches his cap. \"All right, Sam.\""
