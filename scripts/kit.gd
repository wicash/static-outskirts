## Building blocks for the placeholder world: materials and simple shapes.
## Every prop in the game is made from these, so the whole look stays consistent.
extends RefCounted

const PS1 := preload("res://shaders/ps1.gdshader")
const PS1_GLASS := preload("res://shaders/ps1_glass.gdshader")
const Interactable := preload("res://scripts/interactable.gd")

enum Pattern { PLAIN, SIDING, BRICK, PLANKS, TILES, SHINGLES, WALLPAPER, ASPHALT, CONCRETE }

const FOG := Color(0.55, 0.52, 0.47)

# A shared palette so places feel related.
const WOOD := Color(0.45, 0.32, 0.22)
const WOOD_DARK := Color(0.3, 0.21, 0.15)
const WOOD_LIGHT := Color(0.62, 0.48, 0.33)
const METAL := Color(0.42, 0.43, 0.45)
const RUST := Color(0.45, 0.28, 0.18)
const CONCRETE := Color(0.55, 0.54, 0.5)
const ASPHALT := Color(0.24, 0.24, 0.25)
const GLASS := Color(0.16, 0.19, 0.22)
const DAYLIGHT := Color(0.62, 0.62, 0.6)
const WARM_LIGHT := Color(1.0, 0.75, 0.45)
const SOOT := Color(0.12, 0.11, 0.1)
const PAPER := Color(0.88, 0.86, 0.78)
const FABRIC_RED := Color(0.55, 0.22, 0.2)
const FABRIC_BLUE := Color(0.3, 0.38, 0.5)
const FABRIC_GREEN := Color(0.35, 0.42, 0.3)
const FABRIC_MUSTARD := Color(0.68, 0.55, 0.25)
const DEAD_GRASS := Color(0.42, 0.41, 0.32)
const PLANT := Color(0.3, 0.45, 0.25)

var grain: NoiseTexture2D
var rng := RandomNumberGenerator.new()
var _materials := {}


func _init() -> void:
	rng.seed = 1983
	grain = NoiseTexture2D.new()
	grain.width = 64
	grain.height = 64
	grain.seamless = true
	var noise := FastNoiseLite.new()
	noise.frequency = 0.2
	noise.fractal_octaves = 3
	grain.noise = noise


func mat(color: Color, pattern := Pattern.PLAIN, glow := 0.0, fog_end := 70.0) -> ShaderMaterial:
	var key := "%s/%d/%s/%s" % [color.to_html(), pattern, glow, fog_end]
	if _materials.has(key):
		return _materials[key]
	var m := ShaderMaterial.new()
	m.shader = PS1
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("pattern", pattern)
	m.set_shader_parameter("emission", glow)
	m.set_shader_parameter("fog_end", fog_end)
	_materials[key] = m
	return m


## The material every tree shares: colours come from the tree mesh, and it sways.
func tree_mat() -> ShaderMaterial:
	if _materials.has("tree"):
		return _materials["tree"]
	var m := ShaderMaterial.new()
	m.shader = PS1
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("vertex_tint", true)
	m.set_shader_parameter("sway", 1.0)
	m.set_shader_parameter("fog_end", 70.0)
	_materials["tree"] = m
	return m


## See-through glass. `dirt` 0 = clean, 1 = covered in ash.
func glass_mat(dirt := 0.35, tint := Color(0.55, 0.62, 0.66, 0.28)) -> ShaderMaterial:
	var key := "glass/%s/%s" % [dirt, tint.to_html()]
	if _materials.has(key):
		return _materials[key]
	var m := ShaderMaterial.new()
	m.shader = PS1_GLASS
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("dirt", dirt)
	m.set_shader_parameter("tint", tint)
	_materials[key] = m
	return m


## A pane of glass (a thin box).
func pane(parent: Node, size: Vector3, pos: Vector3, rot := Vector3.ZERO, dirt := 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = glass_mat(dirt)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


## A flat four-cornered surface (car windows and other slanted shapes).
func quad(parent: Node, a: Vector3, b: Vector3, c: Vector3, d: Vector3, material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	parent.add_child(mi)
	return mi


## Words in the world (number plates, writing in dust).
func words(parent: Node, text: String, pos: Vector3, rot: Vector3, size := 0.004, color := Color(0.15, 0.15, 0.15)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = size
	l.font_size = 32
	l.outline_size = 0
	l.modulate = color
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.double_sided = false
	l.position = pos
	l.rotation_degrees = rot
	parent.add_child(l)
	return l


## A ring (steering wheels, tyres seen side-on).
func ring(parent: Node, inner: float, outer: float, pos: Vector3, color: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 10
	tm.ring_segments = 5
	mi.mesh = tm
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


## An empty node to group parts, placed and turned (degrees around Y).
func group(parent: Node, pos := Vector3.ZERO, turn := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = turn
	parent.add_child(n)
	return n


## A block. Options: solid (collision), rot (degrees), pattern, glow.
func box(parent: Node, size: Vector3, pos: Vector3, color: Color, opts := {}) -> Node3D:
	var bm := BoxMesh.new()
	bm.size = size
	# Extra vertices on big surfaces so the per-vertex fog and lighting stay smooth.
	bm.subdivide_width = mini(int(size.x / 2.0), 40)
	bm.subdivide_height = mini(int(size.y / 2.0), 40)
	bm.subdivide_depth = mini(int(size.z / 2.0), 40)
	return _place(parent, bm, size, pos, color, opts)


## A low-poly cylinder (or cone, with top radius 0).
func cyl(parent: Node, radius: float, height: float, pos: Vector3, color: Color, opts := {}) -> Node3D:
	var cm := CylinderMesh.new()
	cm.top_radius = opts.get("top", radius)
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = opts.get("sides", 7)
	cm.rings = 1
	return _place(parent, cm, Vector3(radius * 2, height, radius * 2), pos, color, opts)


## A low-poly ball, squashed by `size`.
func ball(parent: Node, size: Vector3, pos: Vector3, color: Color, opts := {}) -> Node3D:
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = opts.get("sides", 7)
	sm.rings = opts.get("rings", 4)
	var node := _place(parent, sm, size, pos, color, opts)
	if node is MeshInstance3D:
		node.scale = size
	return node


## A triangular prism (roofs, ramps). The ridge runs along Z.
func prism(parent: Node, size: Vector3, pos: Vector3, color: Color, opts := {}) -> Node3D:
	var pm := PrismMesh.new()
	pm.size = size
	return _place(parent, pm, size, pos, color, opts)


func _place(parent: Node, mesh: Mesh, size: Vector3, pos: Vector3, color: Color, opts: Dictionary) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, opts.get("pattern", Pattern.PLAIN), opts.get("glow", 0.0), opts.get("fog_end", 70.0))
	var node: Node3D = mi
	if opts.get("solid", false):
		var body := StaticBody3D.new()
		add_shape(body, size)
		body.add_child(mi)
		node = body
	node.position = pos
	node.rotation_degrees = opts.get("rot", Vector3.ZERO)
	parent.add_child(node)
	return node


## A straight bar from a to b (beams, branches, roof slabs when thick).
func beam(parent: Node, a: Vector3, b: Vector3, thick: float, color: Color, opts := {}) -> Node3D:
	var d := b - a
	var node := box(parent, Vector3(d.length(), thick, opts.get("depth", thick)), (a + b) / 2.0, color, opts)
	var x := d.normalized()
	var up: Vector3 = opts.get("up", Vector3.UP)
	if absf(x.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var z := x.cross(up).normalized()
	node.basis = Basis(x, z.cross(x), z)
	return node


func add_shape(body: Node, size: Vector3, offset := Vector3.ZERO) -> void:
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	shape.position = offset
	body.add_child(shape)


## An invisible solid block (to stop the player walking through a prop).
func blocker(parent: Node, size: Vector3, pos: Vector3, turn := 0.0) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees.y = turn
	# Layer 2: Sam bumps into blockers, but her "what am I looking at" ray
	# goes through them, so a bed's blocker doesn't hide the bed.
	body.collision_layer = 2
	add_shape(body, size)
	parent.add_child(body)


## Something you can press E on. `size` is the area you can aim at;
## add visible parts as children of the returned node.
func thing(parent: Node, size: Vector3, pos: Vector3, prompt: String, lines: Array, script: Script = Interactable) -> StaticBody3D:
	var body: StaticBody3D = script.new()
	body.position = pos
	body.prompt = prompt
	body.lines = PackedStringArray(lines)
	add_shape(body, size)
	parent.add_child(body)
	return body


## A place to search (cupboard, drawer, glovebox). Gives its loot once.
func search(parent: Node, size: Vector3, pos: Vector3, prompt: String, found: String, loot: Array, journal := "") -> StaticBody3D:
	var t := thing(parent, size, pos, prompt, [found, "Nothing else in here."])
	t.gives = loot
	t.journal = journal
	t.empty_prompt = prompt + " (searched)"
	return t


## A block you can press E on.
func thing_box(parent: Node, size: Vector3, pos: Vector3, color: Color, prompt: String, lines: Array, opts := {}) -> StaticBody3D:
	var t := thing(parent, size, pos, prompt, lines, opts.get("script", Interactable))
	box(t, size, Vector3.ZERO, color, {"pattern": opts.get("pattern", Pattern.PLAIN), "glow": opts.get("glow", 0.0)})
	t.rotation_degrees = opts.get("rot", Vector3.ZERO)
	return t


## Many copies of one small mesh, cheaply (grass, debris).
func scatter(parent: Node, mesh: Mesh, color: Color, transforms: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat(color)
	parent.add_child(mmi)
