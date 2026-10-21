## Saves and loads the game to user://save.json. The world is always built
## the same way, so a save only stores what changed: the clock, the backpack,
## the journal, which things were used, candles, Biscuit and the radio.
extends RefCounted

const PATH := "user://save.json"


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


## A stable id for a thing in the world, from where it is.
static func key(n: Node3D) -> String:
	var p := n.global_position * 10.0
	return "%d,%d,%d" % [roundi(p.x), roundi(p.y), roundi(p.z)]


static func interactables(world: Node, skip: Node) -> Array:
	var out: Array = []
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == skip:
			continue
		if n.has_method("interact") and "times_used" in n:
			out.append(n)
		stack.append_array(n.get_children())
	return out


static func save(game: Node) -> void:
	var tree := game.get_tree()
	var used := {}
	for n in interactables(game.world, game.cat):
		if n.times_used > 0:
			used[key(n)] = n.times_used
	var candles: Array = []
	for c in tree.get_nodes_in_group("candle_spot"):
		if c.lit:
			candles.append(key(c))
	var radio := tree.get_first_node_in_group("radio")
	var bowl := tree.get_first_node_in_group("cat_bowl")
	var kettle := tree.get_first_node_in_group("kettle")
	var data := {
		"day": game.clock.day, "hour": game.clock.hour,
		"inventory": game.inventory, "journal": game.journal_entries,
		"used": used, "candles": candles,
		"geiger": game._geiger != null,
		"cat": {"trust": game.cat.trust, "inside": game.cat.moved_in, "collar": game.cat.collar_on()},
		"radio": {"on": radio.on, "freq": radio.freq, "heard": radio.heard_counts()},
		"bowl_day": bowl.fed_day if bowl else -1,
		"tea_day": kettle.tea_day if kettle else -1,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))


static func load_into(game: Node) -> bool:
	if not exists():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var tree := game.get_tree()
	game.clock.day = int(data.day)
	game.clock.hour = float(data.hour)
	game.inventory = {}
	for id in data.inventory:
		game.inventory[id] = int(data.inventory[id])
	game.journal_entries = []
	for e in data.journal:
		game.journal_entries.append([int(e[0]), str(e[1])])
	var used: Dictionary = data.used
	for n in interactables(game.world, game.cat):
		var k := key(n)
		if used.has(k):
			n.times_used = int(used[k])
			if n.empty_prompt != "":
				n.prompt = n.empty_prompt
	for c in tree.get_nodes_in_group("candle_spot"):
		if key(c) in data.candles:
			c.light()
	if data.geiger:
		for g in tree.get_nodes_in_group("geiger_item"):
			g.queue_free()
		game.pick_up_geiger()
	game.cat.restore(int(data.cat.trust), bool(data.cat.inside), bool(data.cat.collar))
	var radio := tree.get_first_node_in_group("radio")
	if data.radio.on:
		radio.power_on()
	radio.freq = float(data.radio.freq)
	radio.restore_heard(data.radio.heard)
	var bowl := tree.get_first_node_in_group("cat_bowl")
	if bowl:
		bowl.fed_day = int(data.bowl_day)
	var kettle := tree.get_first_node_in_group("kettle")
	if kettle:
		kettle.tea_day = int(data.tea_day)
	return true
