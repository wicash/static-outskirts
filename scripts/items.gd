## Everything Sam can carry. [name, one-line description]
extends RefCounted

## Items that open new places. They get a gold toast when found.
const KEY_ITEMS := ["crowbar", "bolt_cutters", "antenna", "walkie", "walkman", "tape", "tower_key"]

const ITEMS := {
	"cat_food": ["Tin of cat food", "Fish in jelly. Biscuit's favourite, according to Grace."],
	"candle": ["Candle", "Plain white. Makes a room feel like a room."],
	"matches": ["Box of matches", "Half full. Keep them dry."],
	"tea": ["Tea bags", "A whole box. A small fortune."],
	"peaches": ["Tin of peaches", "For a good day."],
	"soup": ["Tin of soup", "Tomato. Dented, but fine."],
	"biscuits": ["Packet of biscuits", "Custard creams, slightly soft."],
	"batteries": ["Batteries", "Two AAs that might still work."],
	"socks": ["Wool socks", "Thick, warm, and nobody else is using them."],
	"walkman": ["Tape player", "A yellow Walkman with a cracked lid. Tom Bell's, according to the sticker."],
	"tape": ["Cassette tape", "Labelled \"For whoever finds this\" in a child's careful writing."],
	"collar": ["Red collar", "\"BISCUIT. If found, call Grace, 6 Alder St.\""],
	"notebook": ["Tom's notebook", "Drawings of the street, the cat, and the tower with a face."],
	"bandages": ["Bandages", "Still sealed."],
	"crowbar": ["Crowbar", "Opens things that were nailed shut for a reason. Probably a good reason."],
	"bolt_cutters": ["Bolt cutters", "For padlocks and chains. Heavy, red, very satisfying."],
	"antenna": ["Long-wire antenna", "A coil of wire from the train's guard van. Hang it from the radio and listen further."],
	"walkie": ["Walkie-talkie", "Yellow, the Bells'. Hold R to listen for Ranger caches: faster beeps mean closer."],
	"tomatoes": ["Tomatoes", "Small, a bit lumpy, and the best thing you've eaten in weeks."],
	"water": ["Bottled water", "Sealed. Tastes of plastic and safety."],
	"seeds": ["Seed packets", "Runner beans and marigolds. Something to plant, one day."],
	"tower_key": ["Wren's key", "A brass key on a bootlace. TOWER ROAD, in Wren's writing."],
	"rations": ["Ranger ration pack", "Oats, dried fruit, a chocolate bar. A note: \"Eat the chocolate first.\""],
}


static func name_of(id: String) -> String:
	return ITEMS.get(id, [id, ""])[0]


static func describe(id: String) -> String:
	return ITEMS.get(id, ["", ""])[1]
