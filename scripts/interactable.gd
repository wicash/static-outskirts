## Something the player can look at and press E on.
## Shows its lines one after another; the last line repeats.
##
## Optional extras (all handled through the "game" node, see main.gd):
##   gives        item ids added to the backpack the first time
##   needs        an item id you must carry; needs_line is shown otherwise
##   journal      a line Sam writes in her journal the first time
##   empty_prompt prompt to show once it has been used (for searched places)
extends StaticBody3D

signal used(times: int)

var prompt := "Look"
var lines: PackedStringArray = []
var times_used := 0
var gives: Array = []
var needs := ""
var needs_line := ""
var journal := ""
var empty_prompt := ""


func interact() -> String:
	var game := get_tree().get_first_node_in_group("game")
	if needs != "" and game and not game.has_item(needs):
		return needs_line
	var text := ""
	if not lines.is_empty():
		text = lines[mini(times_used, lines.size() - 1)]
	if times_used == 0 and game:
		if not gives.is_empty():
			text += "\n" + game.add_items(gives)
		if journal != "":
			game.write_journal(journal)
	times_used += 1
	if empty_prompt != "":
		prompt = empty_prompt
	used.emit(times_used)
	return text
