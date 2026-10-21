## Something the player can look at and press E on.
## Shows its lines one after another; the last line repeats.
extends StaticBody3D

signal used(times: int)

var prompt := "Look"
var lines: PackedStringArray = []
var times_used := 0


func interact() -> String:
	var text := ""
	if not lines.is_empty():
		text = lines[mini(times_used, lines.size() - 1)]
	times_used += 1
	used.emit(times_used)
	return text
