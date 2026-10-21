## Everything Sam can carry. [name, one-line description]
extends RefCounted

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
}


static func name_of(id: String) -> String:
	return ITEMS.get(id, [id, ""])[0]


static func describe(id: String) -> String:
	return ITEMS.get(id, ["", ""])[1]
