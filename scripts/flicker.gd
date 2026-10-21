## A streetlight that somehow still has power, flickering on and off.
extends OmniLight3D

var bulb: MeshInstance3D
var on_material: Material
var off_material: Material
var _timer := 0.0


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	var on := randf() < 0.7
	visible = on
	if bulb:
		bulb.material_override = on_material if on else off_material
	# Mostly on, with bursts of quick stutters.
	_timer = randf_range(0.6, 4.0) if on else randf_range(0.03, 0.25)
