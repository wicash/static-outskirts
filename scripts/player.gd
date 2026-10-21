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
var _pitch := 0.0
var _focus: Node = null

var head: Node3D
var arm: SpringArm3D
var camera: Camera3D
var body: Node3D


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)

	head = Node3D.new()
	head.position.y = 1.55
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

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity.x = move_toward(velocity.x, dir.x * speed, speed * 8.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, speed * 8.0 * delta)
	move_and_slide()

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
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var found: Node = null
	if hit and hit.collider.has_method("interact"):
		if hit.position.distance_to(head.global_position) <= REACH:
			found = hit.collider
	if found != _focus:
		_focus = found
		focus_changed.emit(_focus.prompt if _focus else "")
