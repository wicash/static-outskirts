## Something that grows back every day (tomatoes in the greenhouse).
extends "res://scripts/interactable.gd"

var crop := "tomatoes"
var amount := 3
var picked_day := -1
var ripe: Array = []   # the visible fruit, hidden once picked


func _ready() -> void:
	add_to_group("harvest")


func interact() -> String:
	var clock := get_tree().get_first_node_in_group("clock")
	var game := get_tree().get_first_node_in_group("game")
	var day: int = clock.day if clock else 1
	if picked_day == day:
		return "Nothing ripe yet. Tomorrow, maybe."
	picked_day = day
	for f in ripe:
		f.visible = false
	var ids: Array = []
	for i in amount:
		ids.append(crop)
	var text := lines[mini(times_used, lines.size() - 1)] if not lines.is_empty() else ""
	if times_used == 0 and journal != "" and game:
		game.write_journal(journal)
	times_used += 1
	return text + "\n" + game.add_items(ids)


func _process(_delta: float) -> void:
	# Picked fruit is gone for the day and back the next morning.
	if ripe.is_empty():
		return
	var clock := get_tree().get_first_node_in_group("clock")
	var picked: bool = clock != null and clock.day == picked_day
	if ripe[0].visible == picked:
		for f in ripe:
			f.visible = not picked
