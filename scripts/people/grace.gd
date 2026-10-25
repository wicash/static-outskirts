## Grace Okafor, from No. 6: Biscuit's person. She walks down from the
## junction camp to meet Sam at the far end of the canal path ("canal"), and
## afterwards she's at the camp's fire ("junction").
extends "res://scripts/npc.gd"

var place := "canal"


func _init() -> void:
	id = "grace"
	who = "Grace Okafor"


func topic_list() -> Dictionary:
	if place == "canal":
		return {
			"biscuit": ["Biscuit's with me",
				"", "Grace met Biscuit again at the canal. He purred so loud she laughed. She says he's mine now. He picked."],
			"ask_biscuit": ["Biscuit's at my house",
				"\"Wren told me. Fed every day, she said, and sleeps on your bed.\" She has to stop for a second. \"Thank you. I left him a note and six tins and I thought that was it.\"", ""],
			"sister": ["Your sister",
				"\"Made it. We both did. She's at the camp knitting socks for a hundred and sixty people.\" Grace holds up her feet. \"These are the prototype.\"", ""],
			"water": ["The flood",
				"\"Two days I've been sat here waiting for that water to go down. And then I hear this great glug and there you are, walking up the towpath like it's Sunday.\"", ""],
			"go": ["Walk to the junction with her", "", ""],
		}
	return {
		"camp": ["The camp",
			"\"Hollow Junction. A hundred and sixty of us, give or take. Your mum keeps us alive, Dee keeps the lights on, and I keep the kettle going.\" She smiles. \"Same job as before, really.\"", ""],
		"thanks": ["Thank you for the note",
			"\"Feed Biscuit! Tins in the cupboard.\" She laughs. \"I wrote that like I'd be back on Sunday. I'm glad it was you who found it.\"", ""],
	}


func greeting(game: Node) -> String:
	var biscuit: bool = game._biscuit_here()
	if place == "junction":
		return "\"There she is!\" Grace waves a ladle. \"Soup's on. It's always on.\"" + (" Biscuit goes straight to her boots." if biscuit else "")
	if not met:
		met = true
		game.write_journal("Grace Okafor was waiting for me at the end of the canal path. Number six. Biscuit's person. Alive.")
		game.chime(true)
		var line := "A woman in a green parka gets up from a little fire under the bridge. \"Sam? Sam Hale, from number four?\" She's thinner than you remember, and she's crying a bit, and so are you. \"Wren said you'd be the one in yellow.\""
		if biscuit:
			line += "\n\nThen she sees who's at your heel. \"Biscuit?\" He trots straight past you, headbutts her shin, and purrs like an engine."
		return line
	return "Grace pokes the fire. \"Ready when you are, love.\""


func can_ask(game: Node, t: String) -> bool:
	match t:
		"biscuit":
			return game._biscuit_here() and not "ask_biscuit" in topics
		"ask_biscuit":
			return not game._biscuit_here() and not "biscuit" in topics
		"water":
			return game.canal_drained()
		"go":
			return "sister" in topics
	return true


func asked(game: Node, t: String) -> String:
	match t:
		"biscuit":
			game.chime(true)
			return "She kneels on the towpath and he climbs into her lap like he never left. \"Hello, you. Hello.\" A long time later she looks up. \"He's yours now, isn't he. He's got that look. He picked you.\" She puts him down and he walks straight back to your feet. \"See?\""
		"go":
			game.close_talk()
			game.travel(game.Junction.ARRIVE, 0.0, "Two hours along the towpath and then up through the cutting, Grace talking the whole way. Then smoke, voices, a dog barking, the old junction signals, and tents. A lot of tents.", 2.0)
			set_gone(true)
			return "-"
	return ""


func after_load() -> void:
	if place == "canal" and "go" in topics:
		set_gone(true)
