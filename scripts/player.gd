## First/third person walker. V switches view, E interacts.
extends CharacterBody3D

signal focus_changed(prompt: String)
signal message(text: String)

const WALK_SPEED := 3.0
const RUN_SPEED := 5.2
const MOUSE_SENSITIVITY := 0.0025
const REACH := 2.6
const THIRD_PERSON_DISTANCE := 3.0

var third_person := false
## True while sitting at the radio or asleep: no walking or interacting.
var frozen := false
var torch: SpotLight3D
var _pitch := 0.0
var _focus: Node = null

var head: Node3D
var arm: SpringArm3D
var camera: Camera3D
var body: Node3D
var _step_audio: AudioStreamPlayer
var _step_distance := 0.0


func _ready() -> void:
	collision_mask = 1 | 2  # solid things and invisible blockers (kit.gd, blocker)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)

	head = Node3D.new()
	head.position.y = 1.38
	add_child(head)
	arm = SpringArm3D.new()
	arm.spring_length = 0.0
	arm.margin = 0.2
	arm.add_excluded_object(get_rid())
	head.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 200.0
	arm.add_child(camera)
	camera.make_current()

	# Sam's little keyring torch. F switches it on and off.
	torch = SpotLight3D.new()
	torch.light_color = Color(1.0, 0.92, 0.75)
	torch.light_energy = 4.0
	torch.spot_range = 16.0
	torch.spot_angle = 32.0
	torch.spot_attenuation = 0.4
	torch.visible = false
	head.add_child(torch)
	torch.position = Vector3(0.15, -0.15, 0)

	_step_audio = AudioStreamPlayer.new()
	_step_audio.stream = _make_step_sound()
	_step_audio.volume_db = -14.0
	add_child(_step_audio)


func set_body(node: Node3D) -> void:
	body = node
	add_child(body)
	body.visible = third_person


func look(relative: Vector2) -> void:
	rotation.y -= relative.x * MOUSE_SENSITIVITY
	_pitch = clampf(_pitch - relative.y * MOUSE_SENSITIVITY, -1.4, 1.3)
	head.rotation.x = _pitch


func toggle_view() -> void:
	third_person = not third_person
	arm.spring_length = THIRD_PERSON_DISTANCE if third_person else 0.0
	# Over-the-shoulder framing so the character doesn't cover the crosshair.
	camera.h_offset = 0.55 if third_person else 0.0
	camera.v_offset = 0.15 if third_person else 0.0
	if body:
		body.visible = third_person


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if frozen:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if body and body.has_method("animate"):
			body.animate(0.0, delta)
		return
	if Input.is_action_just_pressed("torch"):
		torch.visible = not torch.visible

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity.x = move_toward(velocity.x, dir.x * speed, speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, speed * 8.0 * delta)
	move_and_slide()
	var flat_speed := Vector2(velocity.x, velocity.z).length()
	if body and body.has_method("animate"):
		body.animate(flat_speed, delta)
	_footsteps(flat_speed, delta)

	_update_focus()
	if Input.is_action_just_pressed("interact") and _focus:
		var text: String = _focus.interact()
		if text != "":
			message.emit(text)
		focus_changed.emit(_focus.prompt)
	if Input.is_action_just_pressed("toggle_view"):
		toggle_view()


func _update_focus() -> void:
	var from := camera.global_position
	var forward := -camera.global_basis.z
	var length := REACH + (from.distance_to(head.global_position))
	var query := PhysicsRayQueryParameters3D.create(from, from + forward * length)
	query.exclude = [get_rid()]
	query.collision_mask = 1  # not blockers
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var found: Node = null
	if hit and hit.collider.has_method("interact"):
		if hit.position.distance_to(head.global_position) <= REACH:
			found = hit.collider
	if found != _focus:
		_focus = found
		focus_changed.emit(_focus.prompt if _focus else "")


func _footsteps(speed: float, delta: float) -> void:
	if not is_on_floor() or speed < 0.5:
		_step_distance = 0.0
		return
	_step_distance += speed * delta
	if _step_distance > (0.9 if speed > 4.0 else 0.7):
		_step_distance = 0.0
		_step_audio.pitch_scale = randf_range(0.8, 1.15)
		_step_audio.play()


## A short crunchy thump, generated so the project needs no sound files yet.
func _make_step_sound() -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * 0.12)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	for i in frames:
		var t := float(i) / frames
		lp = lerpf(lp, randf_range(-1.0, 1.0), 0.25)
		var thump := sin(t * 90.0) * (1.0 - t) * 0.6
		var v := (lp * 0.7 + thump) * pow(1.0 - t, 3.0)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
