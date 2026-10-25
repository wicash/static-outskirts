## Quality-control checks, run with `godot --headless --path . -- --qa`.
##
## 1. Save keys: every interactable needs its own key (its position), or two
##    things would share one saved state.
## 2. Prompts: everything you can press E on says what it is.
## 3. Press everything: presses E on every interactable three times with an
##    empty backpack and again with every key item, watching for script
##    errors (they show up in the output as SCRIPT ERROR).
## 4. Wanderers: little bots walk about at random from each area's start
##    point, looking for places you can fall out of the world, walk out of
##    bounds, or get stuck.
##
## Prints one line per problem and a summary at the end.
extends Node

const SaveGame := preload("res://scripts/save_game.gd")
const Items := preload("res://scripts/items.gd")
const Trail := preload("res://scripts/trail.gd")

## Where you're allowed to be: [min x, max x, min z, max z].
const BOUNDS := [
	[-45.0, 108.0, -48.0, 28.0],      # Alder Street and Mill Road
	[-24.0, 24.0, -427.5, -374.0],    # the Ranger Station
	[-2.4, 2.4, -470.5, -427.0],      # the tower road
	[-20.0, 20.0, -510.0, -470.0],    # the tower clearing
	[-460.0, -340.0, -400.5, -395.5], # the towpath
	[-436.5, -423.5, -396.0, -385.5], # Alf's cottage garden
	[-425.0, -375.0, -722.0, -676.0], # Hollow Junction camp
]

## Where the wanderers start: [name, position].
const STARTS := [
	["home", Vector3(0.6, 0.1, -10.5)],
	["street west", Vector3(-30, 0.1, 3)],
	["street east", Vector3(35, 0.1, 2)],
	["garage", Vector3(62, 0.1, -3)],
	["allotments", Vector3(65, 0.1, 10)],
	["railway", Vector3(95, 0.1, -10)],
	["station", Vector3(0, 0.1, -379.5)],
	["station yard", Vector3(4, 0.1, -405)],
	["tower", Vector3(0, 0.1, -478)],
	["hut", Vector3(-4, 0.1, -496)],
	["canal west", Vector3(-455, 0.1, -398)],
	["cottage", Vector3(-430, 0.1, -390)],
	["canal east", Vector3(-350, 0.1, -398)],
	["junction", Vector3(-400, 0.1, -683)],
	["clinic", Vector3(-410, 0.1, -694)],
]

var game: Node
var problems: Array = []


func run() -> void:
	game = get_parent()
	await get_tree().process_frame
	print("=== QA ===")
	_check_keys()
	_check_prompts()
	_check_reach()
	await _press_everything()
	if not "--quick" in OS.get_cmdline_user_args():
		await _wander()
	print("=== QA done: %d problems ===" % problems.size())
	for p in problems:
		print("  * ", p)
	get_tree().quit()


func _problem(text: String) -> void:
	problems.append(text)
	print("PROBLEM: ", text)


func _things() -> Array:
	return SaveGame.interactables(game.world, game.cat)


func _check_keys() -> void:
	var seen := {}
	for n in _things():
		var k := SaveGame.key(n)
		if seen.has(k):
			_problem("two things share a save key at %s: \"%s\" and \"%s\"" % [k, seen[k].prompt, n.prompt])
		else:
			seen[k] = n
	print("save keys: %d things checked" % seen.size())


func _check_prompts() -> void:
	var n := 0
	for t in _things():
		n += 1
		if t.prompt == "" and not ("is_open" in t and t.is_open):
			_problem("no prompt on %s at %s" % [t.get_script().resource_path.get_file(), t.global_position])
		if t.lines.is_empty() and t.get_script() == preload("res://scripts/interactable.gd"):
			_problem("no lines on \"%s\" at %s" % [t.prompt, t.global_position])
	print("prompts: %d things checked" % n)


## Can you stand somewhere near each thing and point at it? Tries spots in a
## ring around it: there has to be floor, room for Sam, and a clear line from
## her eyes to the thing within reach.
func _check_reach() -> void:
	var space: PhysicsDirectSpaceState3D = game.world.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	var bad := 0
	for t in _things():
		if not t.is_inside_tree() or ("is_open" in t and t.is_open):
			continue
		var c: Vector3 = t.global_position
		var targets := _aim_points(t)
		var ok := false
		for r in [0.9, 1.4, 1.9, 2.3]:
			for i in 16:
				var a := i * TAU / 16.0
				# Look for floor from just above the thing (not above the ceiling).
				var top := c + Vector3(cos(a) * r, 0.25, sin(a) * r)
				var floor_hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top - Vector3(0, 3.5, 0), 1))
				if floor_hit.is_empty() or floor_hit.collider == t:
					continue
				var feet: Vector3 = floor_hit.position
				var q := PhysicsShapeQueryParameters3D.new()
				q.shape = capsule
				q.collision_mask = 1 | 2
				q.transform = Transform3D(Basis(), feet + Vector3(0, 0.8, 0))
				if not space.intersect_shape(q, 1).is_empty():
					continue
				var eye := feet + Vector3(0, 1.38, 0)
				for aim: Vector3 in targets:
					var look := PhysicsRayQueryParameters3D.create(eye, eye + (aim - eye).normalized() * 2.6, 1)
					var hit: Dictionary = space.intersect_ray(look)
					if not hit.is_empty() and hit.collider == t:
						ok = true
						break
				if ok:
					break
			if ok:
				break
		if not ok:
			bad += 1
			_problem("can't find a spot to reach \"%s\" at %s" % [t.prompt, c])
	print("reach: checked, %d unreachable" % bad)


## Points on a thing to aim at: its middle, the middle of its top, and a bit
## in from each side.
func _aim_points(t: Node3D) -> Array:
	var out: Array = [t.global_position]
	for c in t.get_children():
		if c is CollisionShape3D and c.shape is BoxShape3D:
			var h: Vector3 = (c.shape as BoxShape3D).size * 0.45
			var b: Basis = c.global_basis
			var o: Vector3 = c.global_position
			out = [o, o + b.y * h.y]
			for v: Vector3 in [b.x * h.x, -b.x * h.x, b.z * h.z, -b.z * h.z]:
				out.append(o + v)
				out.append(o + v + b.y * h.y)
			break
	return out


## Presses E on everything, skipping things that move you or put you to bed
## (those are covered by the selftest).
func _press_everything() -> void:
	var skipped := 0
	var pressed := 0
	for pass_i in 2:
		if pass_i == 1:
			for id in Items.KEY_ITEMS:
				game.inventory[id] = 1
		for t in _things():
			if not is_instance_valid(t) or t is Trail or t.get_script().resource_path.ends_with("bed.gd"):
				skipped += 1
				continue
			for i in 3:
				var out = t.interact()
				if out != null and typeof(out) != TYPE_STRING:
					_problem("\"%s\" returned %s" % [t.prompt, type_string(typeof(out))])
				pressed += 1
				if game._radio:
					game.stop_tuning()
				if game._paper_mode != "":
					game._close_paper()
			await get_tree().process_frame
	game.player.frozen = false
	print("pressed E %d times (%d skipped: trails and beds)" % [pressed, skipped])


func _in_bounds(p: Vector3) -> bool:
	if p.y > 10.0:
		return true  # up the tower; the platform has its own rails
	for b in BOUNDS:
		if p.x >= b[0] - 0.5 and p.x <= b[1] + 0.5 and p.z >= b[2] - 0.5 and p.z <= b[3] + 0.5:
			return true
	return false


## Random walkers. Each walks for a while, picking a new direction every
## couple of seconds, and reports falling, leaving the map, or getting stuck
## somewhere no direction gets it out.
func _wander() -> void:
	var player: CharacterBody3D = game.player
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	Engine.time_scale = 2.5  # faster than this and the physics steps get too big to trust
	Engine.max_physics_steps_per_frame = 24
	var stuck_spots: Array = []
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	for start in STARTS:
		if only != "" and start[0] != only:
			continue
		var walked := 0.0
		for bot in 2:
			player.global_position = start[1]
			player.velocity = Vector3.ZERO
			await get_tree().physics_frame
			var stuck_tries := 0
			Input.action_press("move_forward")
			if bot == 1:
				Input.action_press("run")
			for leg in 14:
				player.rotation.y = rng.randf() * TAU
				var before := player.global_position
				for f in 90 + rng.randi() % 90:
					await get_tree().physics_frame
				var p := player.global_position
				walked += Vector2(p.x - before.x, p.z - before.z).length()
				if p.y < -1.0:
					_problem("%s: fell out of the world near %s" % [start[0], before])
					break
				if not _in_bounds(p):
					_problem("%s: walked out of bounds to %s (from %s)" % [start[0], p, before])
					break
				if p.distance_to(before) < 0.3:
					stuck_tries += 1
					if stuck_tries >= 6 and await _really_stuck(p):
						stuck_spots.append(p)
						_problem("%s: stuck at %s" % [start[0], p])
						break
				else:
					stuck_tries = 0
			Input.action_release("move_forward")
			Input.action_release("run")
		print("wander %s: %.0f m walked" % [start[0], walked])
	Engine.time_scale = 1.0


## Tries twelve directions at normal speed; stuck only if none of them work.
func _really_stuck(p: Vector3) -> bool:
	var player: CharacterBody3D = game.player
	var scale := Engine.time_scale
	Engine.time_scale = 1.0
	var best := 0.0
	for i in 12:
		player.global_position = p
		player.velocity = Vector3.ZERO
		player.rotation.y = i * TAU / 12.0
		for f in 40:
			await get_tree().physics_frame
		best = maxf(best, player.global_position.distance_to(p))
	player.global_position = p
	Engine.time_scale = scale
	if best < 0.5:
		print("  stuck state: frozen ", player.frozen, " paper ", game._paper_mode, " radio ", game._radio != null, " floor ", player.is_on_floor(), " moving ", Input.is_action_pressed("move_forward"))
	return best < 0.5
