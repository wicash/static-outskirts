## Pressing E on Biscuit. At first it's petting, which builds his trust (the
## lines in cat.gd). Once he trusts you and wears his collar, it asks him to
## come along or to stay.
extends "res://scripts/interactable.gd"

var cat: Node3D


func can_follow() -> bool:
	return cat.trust >= 3 and cat.collar_on()


func _process(_delta: float) -> void:
	if cat == null:
		return
	if cat.sleeping:
		prompt = "Stroke Biscuit"
	elif can_follow():
		prompt = "Tell Biscuit to stay" if cat.following else "Ask Biscuit to come along"
	elif times_used >= 3:
		prompt = "Pet Biscuit"


func interact() -> String:
	if cat.sleeping:
		return ["He purrs without waking up. One paw twitches. He's chasing something in a dream.",
			"You stroke his back. He stretches all four legs out, as long as a cat can go, then curls up again.",
			"Biscuit opens one eye, decides you're not breakfast, and closes it."][randi() % 3]
	if not can_follow():
		return super()
	cat.set_following(not cat.following)
	if cat.following:
		return ["\"Coming, Biscuit?\" He's already trotting after you, tail straight up like a flag.",
			"\"Come on then.\" He chirps, a funny little noise, and falls in at your heel."][randi() % 2]
	return ["\"Stay here, Biscuit. Look after the place.\" He sits down at once, as if it was his idea.",
		"\"Wait for me.\" He settles into a loaf and watches you go."][randi() % 2]
