## Helen Hale, Sam's mum: the nurse at the Hollow Junction camp. She has
## asked Ines to read Sam's name every night since day thirty. The first time
## you talk to her is the reunion (main.gd, play_scene).
extends "res://scripts/npc.gd"


func _init() -> void:
	id = "mum"
	who = "Mum"


func topic_list() -> Dictionary:
	return {
		"names": ["You kept sending my name",
			"\"Every night.\" She doesn't let go of your hand. \"The list from the hospital came round on day twenty-nine. Your name was on it. I read it and I thought: no. I'd know. So I asked Ines to read you with the living, and I kept asking.\" She squeezes. \"I'd have kept asking for a hundred years.\"",
			"Mum never believed the hospital list. \"I'd know.\" She'd have kept asking Ines to read my name for a hundred years."],
		"camp": ["What you do here",
			"\"Same as always. Plasters, splinters, the odd baby.\" She nods at the tent with the red cross. \"Two of us were nurses before. Now it's just me, and Dee, who faints.\"",
			""],
		"biscuit": ["This is Biscuit",
			"\"So this is the famous Biscuit. Grace has told me about him every single day for two months.\" He sniffs her fingers and allows her to do his ears. \"Oh, he's lovely. He looks like he's had a lot of dinners.\"",
			""],
		"home": ["Come home with me",
			"She looks at the tents, the medical tent, the queue already forming outside it. \"I can't, love. Not yet. They need a nurse.\" She takes the patchwork blanket off her own shoulders and wraps it round yours. \"Take this home for me. Put it on your bed. And come back. It's only a canal.\"",
			"Mum can't leave the camp: she's the only nurse. She gave me her patchwork blanket to take home. \"It's only a canal.\""],
		"hospital": ["Is there anything you need?",
			"\"Antibiotics. Insulin, for Dee. Bandages, always.\" She hesitates. \"St. Brigid's pharmacy was in the east wing, the one still standing. Nobody's been in. Nobody wants to go into the city.\" She sees your face and grips your arm. \"I'm not asking you to. I'm just telling you what I'd need.\"",
			"Mum needs antibiotics and insulin. The pharmacy at St. Brigid's was in the east wing, the one still standing. Nobody's been into the city since."],
	}


func greeting(game: Node) -> String:
	if not met:
		return ""  # the reunion (main.gd, _reunion) plays instead
	var line := "Mum looks up from a boy's grazed knee and her whole face changes. \"Sam.\""
	if game._biscuit_here() and not "biscuit" in topics:
		line += " She looks down. \"And who's this?\""
	return line


func can_ask(game: Node, t: String) -> bool:
	match t:
		"biscuit":
			return game._biscuit_here()
		"hospital":
			return "home" in topics
	return true


func asked(game: Node, t: String) -> String:
	if t == "home":
		game.add_items(["mum_blanket"])
	if t == "hospital":
		game.chime(true)
		game.toast("Next: St. Brigid's, in the city", game.GOLD)
	return ""
