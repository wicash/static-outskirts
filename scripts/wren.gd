## Ranger Wren, at the Ranger Station up the trail. Pressing E opens a
## conversation on the paper overlay (main.gd, talk_to_wren): topics unlock
## as you find things out, and "Wren's list" asks for a few things the
## station needs in exchange for supplies.
extends "res://scripts/interactable.gd"

var met := false
var topics: Array = []    # topic ids already talked about
var errands: Array = []   # errand ids done
var tower_day := -1       # the day she promised to ask Ines (she has an answer the next day)
var body: Node3D          # her figure, idly animated


func _ready() -> void:
	add_to_group("wren")
	prompt = "Talk to Wren"


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	if game:
		game.talk_to_wren(self)
	return ""


func _process(delta: float) -> void:
	if body and body.has_method("animate"):
		body.animate(0.0, delta)


## What you can ask her about: [id, button, what she says, journal line].
## Which ones show up depends on what you've found (main.gd, _wren_topics).
const TOPICS := {
	"who": ["Who are you?",
		"\"Wren. Ranger for this patch for nineteen years, and for the last ninety-one days, the only one. I keep the station running, the lanterns lit and the tins stocked. Somebody has to keep the lights on.\"",
		""],
	"lights": ["The lights in the woods",
		"\"Mine. Lanterns along every trail, so anyone walking at night can find their way here. A solar panel, two car batteries and a lot of swearing.\"",
		"The lights in the woods are Wren's lanterns, so people can find the station at night. Not ghosts. Just a ranger who swears a lot."],
	"voice": ["The voice on 91.3",
		"\"That's Ines Varga. She used to read the traffic on Hollow FM. She was alone at the tower when the order came to read the drill message, and she read it.\" Wren pokes the fire. \"Now every night at two she reads the names of everyone who's checked in alive. I radio them up to her. It's how people find each other.\"",
		"The tower voice is Ines Varga. She read the \"drill\" message the morning of the strikes. Now she reads the names of the living every night at two, from lists Wren sends her."],
	"list": ["Why is my name on her list?",
		"\"That's the thing.\" She goes quiet. \"I didn't send it. Somebody pinned your card on my board, and somebody gave Ines your name, and I don't know who. The hospital had you down as dead, Sam. Someone out there knows you're not.\"",
		"Wren didn't put my name on Ines's list. Someone else did. The hospital listed me as dead. Someone out there knows I'm not."],
	"grace": ["Grace Okafor, from No. 6",
		"\"Grace? She's at the junction camp. She radios in every few days, and every single time she asks about her cat.\" Wren grins. \"Biscuit, isn't it? I'll tell her tonight he's with you. She'll cry. The good kind.\"",
		"Grace Okafor is ALIVE, at the Hollow Junction camp. She asks about Biscuit every time she radios in. Wren is going to tell her he's with me."],
	"train": ["The 6:40",
		"\"Dee Ames walked eleven passengers up this trail on day three. Most of them went on to the junction. Dee still radios in. Still says sorry about the signal, like it was his fault.\"",
		"The driver of the 6:40, Dee Ames, walked eleven passengers up to the station. They're alive, at the junction camp."],
	"caches": ["Your tins",
		"",
		""],
	"tower": ["The tower road",
		"\"Ines locked that gate herself and asked me to keep it locked. She's not ready to see anyone.\" Wren looks at the red light over the trees. \"But your name's on her list, Sam, and she's never met a name on her list. I'll ask her tonight. Come back tomorrow.\"",
		"Wren is going to ask Ines if I can come to the tower. The tower road gate stays locked until then."],
	"ines_answer": ["Did Ines answer?",
		"\"She did. Took her two nights to say it.\" Wren unhooks a brass key from her belt and folds your hand round it. \"'If it's really her, send her up. Tell her to come at night. I'll be on air.'\" She holds on a moment longer. \"Go gently, Sam. She hasn't had a visitor in ninety days.\"",
		"Ines said yes. Wren gave me the key to the tower road gate. \"Come at night. I'll be on air.\""],
	"junction": ["The way to the junction",
		"\"Course you're going. I'd go.\" She spreads her map on her knees. \"The overpass is down, so it's the old canal path. Lock gates are chained and the towpath floods, mind.\" She taps a blue pin. \"I'll radio Grace tonight. She'll meet you halfway.\" Then, softer: \"Not tonight, though. Tonight you sleep.\"",
		"Wren says the long way to the junction camp is the old canal path. She's radioing Grace to meet me halfway. Next: the canal."],
}

## Wren's list: [label, item, how many, what she says, reward items].
const ERRANDS := {
	"tomatoes": ["3 tomatoes for the station", "tomatoes", 3,
		"\"Proper tomatoes! From Lou's greenhouse? She'd be so pleased somebody kept it going.\" She gives you two candles from a drawer full of them.",
		["candle", "candle"]],
	"batteries": ["2 batteries for the mast", "batteries", 2,
		"\"That's tonight's call to Ines sorted. Thank you, love.\" She swaps them for two ration packs.",
		["rations", "rations"]],
	"seeds": ["Seeds for the vegetable patch", "seeds", 1,
		"\"Runner beans! Right. Deal's a deal: I'll hang lanterns at the end of your street tonight, so I can see from the mast that you're home.\"",
		[]],
}
