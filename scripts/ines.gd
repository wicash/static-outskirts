## Ines Varga, at the Hollow FM tower. She read the "drill" message on the
## morning of the strikes, and now reads the names of the living every night
## at two. Pressing E opens a conversation on the paper overlay (main.gd,
## talk_to_ines). "Read the names with her" plays the two o'clock broadcast.
extends "res://scripts/interactable.gd"

var met := false
var topics: Array = []    # topic ids already talked about
var body: Node3D


func _ready() -> void:
	add_to_group("ines")
	prompt = "Talk to Ines"


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.talk_to_ines(self)
	return ""


func _process(delta: float) -> void:
	if body and body.has_method("animate"):
		body.animate(0.0, delta)


## [button, what she says, journal line]. Which ones show up depends on what
## you've already asked (main.gd, _ines_topics).
const TOPICS := {
	"voice": ["You're the voice on 91.3",
		"\"Hollow FM. I did the traffic and the overnight show. Now I do the names.\" She touches a stack of Wren's lists. \"Two hundred and fourteen tonight. People listen for the ones they love. It's the only news anybody wants.\"",
		""],
	"drill": ["The drill message",
		"\"The order came at twelve minutes past six. 'Read the notice. It's a scheduled drill.' So I read it. Twice.\" She doesn't look away. \"Three minutes later the sky went white. People stayed in their houses because I told them to.\" A long breath. \"So now I read the names of everyone who lived. It doesn't fix anything. It's just the thing I can do.\"",
		"Ines read the drill message because she was ordered to. She thinks people stayed home because of her. That's why she reads the names of the living, every night."],
	"name": ["Who sent you my name?",
		"\"Your mum.\" She says it simply, like the weather. \"Helen Hale. She's at the junction camp. She's radioed me every night since day thirty, and she says the same thing every time: 'Read my daughter's name. Sam Hale, Four Alder Street. She's alive. I'd know.'\" Ines smiles for the first time. \"The hospital list had you dead. I told her so. She said read it anyway. She got Dee Ames to pin a card on Wren's board, in case you ever came up the trail.\" She looks at you. \"And here you are.\"",
		"Mum is ALIVE. Helen Hale, at the Hollow Junction camp. She's asked Ines to read my name every night since day 30, even though the hospital said I was dead. She never believed it. She had Dee Ames pin my card on Wren's board."],
	"hospital": ["Why did the hospital say I was dead?",
		"\"St. Brigid's lost the west wing. Everyone on the morning rota went on the list.\" She tilts her head. \"Were you on the rota?\" You were. You'd swapped your Saturday shift at the last minute, and you'd forgotten until now. The list never knew.",
		"St. Brigid's had me on the morning rota, so they listed me with the west wing. I'd swapped my shift. The list never knew."],
	"wall": ["The wall of names",
		"\"Everyone who's checked in. A pin goes in when somebody finds somebody.\" There are a lot of pins. \"That one's Grace and her sister. That's the Patels, all four of them.\" She touches a bare patch of wall with two pins ready in it. \"That's for you and your mum.\"",
		""],
	"read": ["Read the names with her", "", ""],
	"now": ["What do I do now?",
		"\"Now you go and find her. Hollow Junction camp, past the overpass. Two days on foot, and the overpass is down, so ask Wren for the long way.\" She hooks the headphones back over her ears. \"And Sam? Take the cat. Grace will want to see him.\"",
		"Ines says go to the junction camp and find Mum. The overpass is down: ask Wren about the long way round. Take Biscuit."],
}

## The two o'clock broadcast, a line at a time.
const BROADCAST := [
	"Ines flicks the switch. Over the door, ON AIR glows red. She leans into the microphone.",
	"\"Good morning, Alder Hollow. It's two o'clock. These are the names of the living.\"",
	"\"Ames, Dee, and ten from the 6:40. Hollow Junction. Alive.\"",
	"\"Bell. Tom, Ada, and their mum and dad. Aunt Ruth's farm, out past Kesterton. Alive.\"",
	"\"Okafor, Grace. Hollow Junction. Alive.\" %s",
	"\"Patel. Anjali, Dev, Mira and Rohan. Alive.\"",
	"Two hundred and eight more. She reads every one the same way, like each one is the only one. You listen to all of them.",
	"\"Hale, Sam. Four Alder Street.\" Ines covers the microphone with her hand and looks at you. \"Your turn.\"",
]
