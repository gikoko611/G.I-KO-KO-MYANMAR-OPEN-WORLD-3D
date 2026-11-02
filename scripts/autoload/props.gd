extends Node
# Procedural prop factory: every mesh in the game is built from primitives
# here at runtime. No external model or texture files are needed.

var _mats = {}
var _meshes = {}

# ------------------------------ materials -------------------------------

func mat(color, emissive=false):
	var key = color.to_html() + str(emissive)
	if _mats.has(key):
		return _mats[key]
	var m = SpatialMaterial.new()
	m.albedo_color = color
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy = 0.6
	_mats[key] = m
	return m

func tmat(color, opacity):
	var key = "t" + color.to_html() + str(opacity)
	if _mats.has(key):
		return _mats[key]
	var m = SpatialMaterial.new()
	m.albedo_color = Color(color.r, color.g, color.b, opacity)
	m.flags_transparent = true
	m.flags_unshaded = true
	_mats[key] = m
	return m

# --------------------------- primitive meshes ---------------------------

func box_mesh(w, h, d):
	var key = "b" + str(w) + "," + str(h) + "," + str(d)
	if _meshes.has(key):
		return _meshes[key]
	var m = CubeMesh.new()
	m.size = Vector3(w, h, d)
	_meshes[key] = m
	return m

func cyl_mesh(rt, rb, h):
	var key = "c" + str(rt) + "," + str(rb) + "," + str(h)
	if _meshes.has(key):
		return _meshes[key]
	var m = CylinderMesh.new()
	m.top_radius = rt
	m.bottom_radius = rb
	m.height = h
	m.radial_segments = 10
	_meshes[key] = m
	return m

func sphere_mesh(r):
	var key = "s" + str(r)
	if _meshes.has(key):
		return _meshes[key]
	var m = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 8
	_meshes[key] = m
	return m

func cone_mesh(r, h):
	var key = "k" + str(r) + "," + str(h)
	if _meshes.has(key):
		return _meshes[key]
	var m = CylinderMesh.new()
	m.top_radius = 0.02
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 8
	_meshes[key] = m
	return m

func plane_mesh(w, d):
	var key = "p" + str(w) + "," + str(d)
	if _meshes.has(key):
		return _meshes[key]
	var m = PlaneMesh.new()
	m.size = Vector2(w, d)
	_meshes[key] = m
	return m

func quad_mesh(w, h, material):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	st.add_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-w / 2.0, -h / 2.0, 0))
	st.add_uv(Vector2(1, 0))
	st.add_vertex(Vector3(w / 2.0, -h / 2.0, 0))
	st.add_uv(Vector2(1, 1))
	st.add_vertex(Vector3(w / 2.0, h / 2.0, 0))
	st.add_uv(Vector2(0, 0))
	st.add_vertex(Vector3(-w / 2.0, -h / 2.0, 0))
	st.add_uv(Vector2(1, 1))
	st.add_vertex(Vector3(w / 2.0, h / 2.0, 0))
	st.add_uv(Vector2(0, 1))
	st.add_vertex(Vector3(-w / 2.0, h / 2.0, 0))
	return st.commit()

# --------------------------- instance helpers ---------------------------

func box(w, h, d, color, emissive=false):
	var mi = MeshInstance.new()
	mi.mesh = box_mesh(w, h, d)
	mi.material_override = mat(color, emissive)
	return mi

func cyl(rt, rb, h, color, emissive=false):
	var mi = MeshInstance.new()
	mi.mesh = cyl_mesh(rt, rb, h)
	mi.material_override = mat(color, emissive)
	return mi

func sphere(r, color, emissive=false):
	var mi = MeshInstance.new()
	mi.mesh = sphere_mesh(r)
	mi.material_override = mat(color, emissive)
	return mi

func cone(r, h, color):
	var mi = MeshInstance.new()
	mi.mesh = cone_mesh(r, h)
	mi.material_override = mat(color)
	return mi

func part(parent, node, x, y, z, rx=0.0, ry=0.0, rz=0.0):
	node.translation = Vector3(x, y, z)
	node.rotation_degrees = Vector3(rx, ry, rz)
	parent.add_child(node)
	return node

# ----------------------------- vegetation -------------------------------

func tree_trunk_mesh():
	return cyl_mesh(0.24, 0.34, 4.0)

func tree_canopy_mesh():
	return cone_mesh(1.7, 2.4)

func palm_trunk_mesh():
	return cyl_mesh(0.16, 0.22, 5.0)

func bamboo_mesh():
	return cyl_mesh(0.09, 0.09, 5.0)

func rock():
	var mi = MeshInstance.new()
	mi.mesh = sphere_mesh(1.0)
	mi.material_override = mat(Color(0.55, 0.55, 0.58))
	mi.scale = Vector3(1.0, 0.7, 0.9)
	return mi

func grass_tuft():
	var mi = MeshInstance.new()
	mi.mesh = cone_mesh(0.12, 0.5)
	mi.material_override = mat(Color(0.3, 0.55, 0.2))
	return mi

# ------------------------------ structures ------------------------------

func hut(w, d, wall_color, roof_color):
	var s = Spatial.new()
	part(s, box(w, 2.6, d, wall_color), 0, 1.3, 0)
	part(s, box(w + 0.8, 0.3, d + 0.8, roof_color), 0, 2.75, 0)
	part(s, box(w * 0.5, 0.2, d * 0.5, roof_color), 0, 2.95, 0)
	part(s, box(0.9, 1.6, 0.12, Color(0.3, 0.2, 0.12)), 0, 0.8, d / 2.0 + 0.05)
	part(s, box(0.7, 0.6, 0.08, Color(0.25, 0.35, 0.45)), w / 2.0 + 0.05, 1.5, 0)
	return s

func pagoda():
	var s = Spatial.new()
	var gold = Color(0.9, 0.75, 0.25)
	part(s, box(7.0, 0.8, 7.0, Color(0.75, 0.7, 0.6)), 0, 0.4, 0)
	var tiers = [[6.0, 1.8, 1.7], [4.6, 1.6, 3.5], [3.4, 1.4, 5.2]]
	for t in tiers:
		part(s, box(t[0], t[1], t[0], Color(0.85, 0.75, 0.55)), 0, t[2], 0)
		part(s, box(t[0] + 1.4, 0.25, t[0] + 1.4, gold, true), 0, t[2] + t[1] / 2.0 + 0.12, 0)
	part(s, cyl(0.12, 0.18, 2.4, gold, true), 0, 7.2, 0)
	part(s, sphere(0.35, gold, true), 0, 8.5, 0)
	for c in [[-3, -3], [3, -3], [-3, 3], [3, 3]]:
		part(s, cone(0.25, 1.0, gold), c[0], 1.3, c[1])
	return s

func shrine():
	var s = Spatial.new()
	var gold = Color(0.9, 0.75, 0.25)
	part(s, box(2.4, 0.5, 2.4, Color(0.6, 0.6, 0.58)), 0, 0.25, 0)
	part(s, box(1.2, 1.8, 1.2, Color(0.55, 0.5, 0.45)), 0, 1.4, 0)
	part(s, box(2.0, 0.2, 2.0, gold), 0, 2.4, 0)
	part(s, cone(0.5, 1.2, gold), 0, 3.1, 0)
	part(s, sphere(0.25, gold, true), 0, 3.9, 0)
	for b in [[-1.4, -1.4], [1.4, -1.4], [-1.4, 1.4], [1.4, 1.4]]:
		part(s, cyl(0.06, 0.06, 0.5, gold, true), b[0], 0.6, b[1])
	return s

func stall(color):
	var s = Spatial.new()
	for p in [[-1.8, -1.2], [1.8, -1.2], [-1.8, 1.2], [1.8, 1.2]]:
		part(s, box(0.14, 2.4, 0.14, Color(0.5, 0.35, 0.2)), p[0], 1.2, p[1])
	part(s, box(4.2, 0.14, 2.8, Color(0.62, 0.45, 0.25)), 0, 1.0, 0)
	part(s, box(4.6, 0.1, 3.2, color), 0, 2.5, 0)
	part(s, sphere(0.3, Color(0.85, 0.3, 0.2)), -1.2, 1.25, 0)
	part(s, sphere(0.25, Color(0.9, 0.7, 0.2)), 0.2, 1.22, 0.3)
	part(s, box(0.5, 0.3, 0.5, Color(0.5, 0.6, 0.3)), 1.3, 1.25, -0.3)
	return s

func well():
	var s = Spatial.new()
	part(s, cyl(1.1, 1.2, 1.0, Color(0.6, 0.6, 0.58)), 0, 0.5, 0)
	part(s, cyl(0.9, 0.9, 0.1, Color(0.1, 0.15, 0.2)), 0, 0.98, 0)
	for p in [[-0.9, 0], [0.9, 0]]:
		part(s, box(0.14, 2.2, 0.14, Color(0.5, 0.35, 0.2)), p[0], 1.9, p[1])
	part(s, box(2.4, 0.12, 1.0, Color(0.45, 0.2, 0.15)), 0, 3.0, 0)
	part(s, cyl(0.05, 0.05, 1.0, Color(0.3, 0.3, 0.3)), 0, 2.5, 0)
	part(s, box(0.3, 0.3, 0.3, Color(0.55, 0.4, 0.3)), 0, 2.0, 0)
	return s

func bridge():
	var s = Spatial.new()
	for i in range(9):
		part(s, box(3.4, 0.22, 1.55, Color(0.5, 0.38, 0.24)), 0, 0, -8.0 + i * 2.0)
	for side in [-1.6, 1.6]:
		for i in range(5):
			part(s, box(0.18, 1.0, 0.18, Color(0.45, 0.32, 0.2)), side, 0.6, -7.0 + i * 4.0)
		part(s, box(0.16, 0.14, 17.0, Color(0.45, 0.32, 0.2)), side, 1.05, 0)
	return s

func dock():
	var s = Spatial.new()
	for i in range(6):
		part(s, box(2.2, 0.18, 1.9, Color(0.52, 0.4, 0.26)), 0, 0, -i * 2.0)
	for p in [[-1.0, 0.0], [1.0, 0.0], [-1.0, -10.0], [1.0, -10.0]]:
		part(s, cyl(0.12, 0.12, 2.0, Color(0.42, 0.32, 0.2)), p[0], -0.9, p[1])
	return s

func waterfall():
	var s = Spatial.new()
	part(s, box(10.0, 7.0, 3.0, Color(0.45, 0.45, 0.48)), 0, 3.5, 1.5)
	var water = MeshInstance.new()
	water.mesh = box_mesh(4.0, 6.5, 0.6)
	water.material_override = tmat(Color(0.65, 0.85, 0.95), 0.65)
	part(s, water, 0, 3.4, 0)
	var pool = MeshInstance.new()
	pool.mesh = plane_mesh(9.0, 9.0)
	pool.material_override = tmat(Color(0.4, 0.65, 0.8), 0.7)
	part(s, pool, 0, 0.15, -3.0)
	var mist = CPUParticles.new()
	mist.amount = 24
	mist.lifetime = 1.2
	mist.direction = Vector3(0, 1, 0)
	mist.spread = 30.0
	mist.gravity = Vector3(0, -2.0, 0)
	mist.initial_velocity = 1.5
	mist.scale_amount = 0.6
	mist.mesh = quad_mesh(0.6, 0.6, tmat(Color(0.9, 0.95, 1.0), 0.35))
	mist.emission_shape = CPUParticles.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 1.5
	part(s, mist, 0, 1.0, -2.0)
	return s

func sign(color):
	var s = Spatial.new()
	part(s, cyl(0.08, 0.1, 1.6, Color(0.5, 0.38, 0.24)), 0, 0.8, 0)
	part(s, box(1.4, 0.7, 0.08, color), 0, 1.5, 0)
	return s

func fence(length, color):
	var s = Spatial.new()
	var n = int(length / 2.0)
	for i in range(n + 1):
		part(s, box(0.14, 1.1, 0.14, color), -length / 2.0 + i * 2.0, 0.55, 0)
	part(s, box(length, 0.1, 0.08, color), 0, 0.85, 0)
	part(s, box(length, 0.1, 0.08, color), 0, 0.45, 0)
	return s

func treasure_mound():
	var s = Spatial.new()
	var mound = MeshInstance.new()
	mound.mesh = sphere_mesh(1.0)
	mound.material_override = mat(Color(0.42, 0.32, 0.2))
	mound.scale = Vector3(1.2, 0.55, 1.2)
	part(s, mound, 0, 0.35, 0)
	part(s, sphere(0.16, Color(0.9, 0.75, 0.2), true), 0.3, 0.85, 0.2)
	part(s, cyl(0.05, 0.05, 0.8, Color(0.5, 0.4, 0.25)), -0.4, 0.6, -0.3)
	return s

func egg():
	var mi = MeshInstance.new()
	mi.mesh = sphere_mesh(0.14)
	mi.material_override = mat(Color(0.98, 0.95, 0.85))
	mi.scale = Vector3(0.85, 1.1, 0.85)
	return mi

func checkpoint_flag(color):
	var s = Spatial.new()
	part(s, cyl(0.05, 0.06, 3.2, Color(0.9, 0.9, 0.9)), 0, 1.6, 0)
	var flag = box(0.9, 0.55, 0.04, color, true)
	part(s, flag, 0.45, 2.8, 0)
	return s

func beacon():
	var s = Spatial.new()
	part(s, cyl(0.1, 0.14, 9.0, Color(0.9, 0.75, 0.2), true), 0, 4.5, 0)
	part(s, sphere(0.45, Color(1.0, 0.85, 0.3), true), 0, 9.2, 0)
	return s

# ------------------------------- people ---------------------------------

func human(shirt=null, pants=null, skin=null, hat=null):
	if shirt == null:
		shirt = Color(0.4, 0.5, 0.7)
	if pants == null:
		pants = Color(0.25, 0.3, 0.45)
	if skin == null:
		skin = Color(0.85, 0.68, 0.5)
	var s = Spatial.new()
	part(s, sphere(0.22, skin), 0, 1.62, 0)
	part(s, box(0.46, 0.55, 0.26, shirt), 0, 1.1, 0)
	var larm = box(0.14, 0.5, 0.14, shirt)
	larm.name = "LArm"
	part(s, larm, -0.3, 1.1, 0)
	var rarm = box(0.14, 0.5, 0.14, shirt)
	rarm.name = "RArm"
	part(s, rarm, 0.3, 1.1, 0)
	var lleg = box(0.16, 0.55, 0.16, pants)
	lleg.name = "LLeg"
	part(s, lleg, -0.13, 0.28, 0)
	var rleg = box(0.16, 0.55, 0.16, pants)
	rleg.name = "RLeg"
	part(s, rleg, 0.13, 0.28, 0)
	if hat != null:
		part(s, box(0.28, 0.14, 0.28, hat), 0, 1.82, 0)
	return s

func player_mesh():
	return human(Color(0.2, 0.45, 0.75), Color(0.2, 0.25, 0.35), Color(0.85, 0.68, 0.5), Color(0.9, 0.75, 0.25))

# ------------------------------- animals --------------------------------

func quadruped(body_size, body_color, head_size, leg_h, extras):
	var s = Spatial.new()
	var y = leg_h + body_size.y / 2.0
	part(s, box(body_size.x, body_size.y, body_size.z, body_color), 0, y, 0)
	var head = sphere(head_size, body_color)
	part(s, head, 0, y + body_size.y * 0.25, body_size.z / 2.0 + head_size * 0.6)
	for p in [[-body_size.x / 2.0 + 0.08, body_size.z / 2.0 - 0.15], [body_size.x / 2.0 - 0.08, body_size.z / 2.0 - 0.15], [-body_size.x / 2.0 + 0.08, -body_size.z / 2.0 + 0.15], [body_size.x / 2.0 - 0.08, -body_size.z / 2.0 + 0.15]]:
		part(s, box(0.12, leg_h, 0.12, body_color.darkened(0.2)), p[0], leg_h / 2.0, p[1])
	if extras != null:
		if extras.get("tail", false):
			part(s, box(0.08, 0.08, 0.5, body_color.darkened(0.15)), 0, y + 0.05, -body_size.z / 2.0 - 0.25)
		if extras.get("horns", false):
			part(s, box(0.06, 0.25, 0.06, Color(0.75, 0.7, 0.5)), -head_size * 0.7, y + body_size.y * 0.25 + head_size * 0.8, body_size.z / 2.0 + head_size * 0.4)
			part(s, box(0.06, 0.25, 0.06, Color(0.75, 0.7, 0.5)), head_size * 0.7, y + body_size.y * 0.25 + head_size * 0.8, body_size.z / 2.0 + head_size * 0.4)
		if extras.get("beak", false):
			part(s, cone(0.07, 0.22, Color(0.9, 0.6, 0.1)), 0, y + body_size.y * 0.25, body_size.z / 2.0 + head_size * 1.3, 90, 0, 0)
		if extras.get("crest", false):
			part(s, box(0.1, 0.14, 0.24, Color(0.85, 0.2, 0.15)), 0, y + body_size.y * 0.25 + head_size * 0.9, body_size.z / 2.0 + head_size * 0.3)
	return s

func animal_mesh(id):
	if id == "chicken":
		return quadruped(Vector3(0.5, 0.4, 0.6), Color(0.95, 0.93, 0.85), 0.22, 0.35, {"beak": true, "crest": true})
	if id == "duck":
		return quadruped(Vector3(0.55, 0.38, 0.65), Color(0.9, 0.9, 0.4), 0.2, 0.3, {"beak": true})
	if id == "cow":
		return quadruped(Vector3(1.1, 0.8, 1.8), Color(0.85, 0.83, 0.78), 0.42, 0.9, {"horns": true, "tail": true})
	if id == "goat":
		return quadruped(Vector3(0.7, 0.55, 1.1), Color(0.8, 0.75, 0.65), 0.3, 0.55, {"horns": true, "tail": true})
	if id == "buffalo":
		return quadruped(Vector3(1.2, 0.85, 1.9), Color(0.35, 0.3, 0.28), 0.46, 0.9, {"horns": true, "tail": true})
	if id == "pig":
		return quadruped(Vector3(0.9, 0.65, 1.3), Color(0.95, 0.7, 0.7), 0.35, 0.55, {"tail": true})
	if id == "dog":
		return quadruped(Vector3(0.45, 0.4, 0.9), Color(0.6, 0.45, 0.3), 0.26, 0.4, {"tail": true})
	if id == "cat":
		return quadruped(Vector3(0.35, 0.3, 0.7), Color(0.4, 0.35, 0.3), 0.2, 0.32, {"tail": true})
	return quadruped(Vector3(0.6, 0.5, 1.0), Color(0.7, 0.7, 0.7), 0.28, 0.5, {})

# ------------------------------- vehicles -------------------------------

func _wheel(parent, x, y, z, r, w):
	var wheel = cyl(r, r, w, Color(0.15, 0.15, 0.15))
	wheel.name = "Wheel"
	part(parent, wheel, x, y, z, 0, 0, 90)
	return wheel

func vehicle_mesh(id):
	var s = Spatial.new()
	var d = ItemDB.vehicle(id)
	var c = d.get("color", Color(0.5, 0.5, 0.5))
	if id == "bicycle":
		part(s, cyl(0.04, 0.04, 1.4, c), 0, 0.75, 0, 0, 0, 90)
		part(s, box(0.08, 0.6, 0.08, c), 0, 0.85, 0.5)
		part(s, box(0.7, 0.08, 0.12, c), 0, 1.1, 0.42)
		part(s, box(0.4, 0.06, 0.3, Color(0.2, 0.2, 0.25)), 0, 1.1, -0.1)
		_wheel(s, 0, 0.42, 0.75, 0.42, 0.07)
		_wheel(s, 0, 0.42, -0.55, 0.42, 0.07)
	elif id == "motorcycle":
		part(s, box(0.3, 0.35, 1.8, c), 0, 0.7, 0)
		part(s, box(0.25, 0.5, 0.25, Color(0.2, 0.2, 0.2)), 0, 0.9, 0.8)
		part(s, box(0.4, 0.06, 0.35, Color(0.2, 0.2, 0.25)), 0, 1.1, -0.5)
		_wheel(s, 0, 0.35, 0.85, 0.35, 0.12)
		_wheel(s, 0, 0.35, -0.85, 0.35, 0.12)
	elif id == "car":
		part(s, box(1.7, 0.5, 3.6, c), 0, 0.65, 0)
		part(s, box(1.5, 0.45, 1.8, Color(0.4, 0.55, 0.6)), 0, 1.1, -0.2)
		part(s, box(1.55, 0.06, 0.9, Color(0.5, 0.65, 0.7)), 0, 1.1, -1.15)
		_wheel(s, -0.85, 0.35, 1.2, 0.35, 0.25)
		_wheel(s, 0.85, 0.35, 1.2, 0.35, 0.25)
		_wheel(s, -0.85, 0.35, -1.2, 0.35, 0.25)
		_wheel(s, 0.85, 0.35, -1.2, 0.35, 0.25)
	elif id == "pickup":
		part(s, box(1.9, 0.55, 4.6, c), 0, 0.75, 0)
		part(s, box(1.7, 0.6, 1.6, c.darkened(0.15)), 0, 1.3, 0.9)
		part(s, box(1.7, 0.25, 2.2, Color(0.35, 0.3, 0.25)), 0, 0.85, -1.4)
		_wheel(s, -0.95, 0.45, 1.6, 0.45, 0.3)
		_wheel(s, 0.95, 0.45, 1.6, 0.45, 0.3)
		_wheel(s, -0.95, 0.45, -1.5, 0.45, 0.3)
		_wheel(s, 0.95, 0.45, -1.5, 0.45, 0.3)
	elif id == "farm_truck":
		part(s, box(2.0, 0.7, 4.8, c), 0, 0.8, 0)
		part(s, box(1.8, 0.8, 1.8, c.darkened(0.2)), 0, 1.5, 1.2)
		part(s, box(1.8, 0.5, 2.4, Color(0.4, 0.35, 0.25)), 0, 1.0, -1.5)
		_wheel(s, -1.0, 0.5, 1.7, 0.5, 0.32)
		_wheel(s, 1.0, 0.5, 1.7, 0.5, 0.32)
		_wheel(s, -1.0, 0.5, -1.6, 0.5, 0.32)
		_wheel(s, 1.0, 0.5, -1.6, 0.5, 0.32)
	elif id == "tractor":
		part(s, box(1.3, 0.8, 2.6, c), 0, 0.95, -0.2)
		part(s, box(0.9, 0.5, 0.9, c.darkened(0.15)), 0, 1.6, 0.5)
		part(s, cyl(0.05, 0.05, 1.6, Color(0.3, 0.3, 0.3)), 0, 1.8, 0.2, 0, 0, 90)
		part(s, box(0.9, 0.06, 0.5, Color(0.2, 0.2, 0.2)), -0.6, 2.1, 0.9)
		part(s, box(0.9, 0.06, 0.5, Color(0.2, 0.2, 0.2)), 0.6, 2.1, 0.9)
		_wheel(s, -0.8, 0.3, 1.0, 0.3, 0.22)
		_wheel(s, 0.8, 0.3, 1.0, 0.3, 0.22)
		_wheel(s, -0.85, 0.65, -1.0, 0.65, 0.4)
		_wheel(s, 0.85, 0.65, -1.0, 0.65, 0.4)
	elif id == "boat":
		part(s, box(1.8, 0.5, 3.8, Color(0.45, 0.3, 0.15)), 0, 0.5, 0)
		part(s, box(1.3, 0.4, 3.0, Color(0.6, 0.42, 0.2)), 0, 0.75, 0)
		part(s, box(1.6, 0.1, 0.9, Color(0.55, 0.4, 0.25)), 0, 0.85, 0.6)
		part(s, cyl(0.05, 0.05, 2.2, Color(0.4, 0.28, 0.15)), 0, 1.4, -0.8)
	return s

# ------------------------------ buildings -------------------------------

func building_mesh(id):
	var s = Spatial.new()
	var d = ItemDB.building(id)
	var c = d.get("color", Color(0.8, 0.7, 0.5))
	if id == "water_tower":
		for p in [[-1.2, -1.2], [1.2, -1.2], [-1.2, 1.2], [1.2, 1.2]]:
			part(s, cyl(0.1, 0.12, 4.0, Color(0.45, 0.35, 0.25)), p[0], 2.0, p[1])
		part(s, cyl(1.4, 1.5, 2.2, c), 0, 5.0, 0)
		part(s, cone(1.5, 0.9, Color(0.4, 0.5, 0.55)), 0, 6.5, 0)
	else:
		part(s, box(5.0, 2.8, 4.0, c), 0, 1.4, 0)
		part(s, box(5.8, 0.3, 4.8, Color(0.5, 0.3, 0.2)), 0, 2.95, 0)
		part(s, box(1.0, 1.7, 0.12, Color(0.3, 0.2, 0.12)), 0, 0.85, 2.0)
		if id == "market_shop" or id == "workshop" or id == "garage":
			part(s, box(2.2, 1.2, 0.1, Color(0.6, 0.75, 0.8)), 1.2, 1.5, 2.0)
		if id == "animal_barn":
			part(s, box(1.6, 1.6, 0.1, Color(0.3, 0.2, 0.12)), 2.0, 0.8, 3.0)
		if id == "warehouse" or id == "rice_storage":
			part(s, box(1.4, 1.4, 0.1, Color(0.4, 0.3, 0.2)), -1.5, 0.7, 2.0)
		if id == "house" or id == "farmhouse" or id == "guest_house":
			part(s, box(0.7, 0.6, 0.08, Color(0.25, 0.35, 0.45)), -1.3, 1.5, 2.0)
	return s

func interior(kind):
	var s = Spatial.new()
	var wall_c = Color(0.75, 0.68, 0.55)
	var floor_m = MeshInstance.new()
	floor_m.mesh = plane_mesh(9.0, 9.0)
	floor_m.material_override = mat(Color(0.45, 0.36, 0.26))
	part(s, floor_m, 0, 0, 0)
	part(s, box(9.0, 3.0, 0.3, wall_c), 0, 1.5, -4.5)
	part(s, box(0.3, 3.0, 9.0, wall_c), -4.5, 1.5, 0)
	part(s, box(0.3, 3.0, 9.0, wall_c), 4.5, 1.5, 0)
	part(s, box(3.2, 3.0, 0.3, wall_c), -2.9, 1.5, 4.5)
	part(s, box(3.2, 3.0, 0.3, wall_c), 2.9, 1.5, 4.5)
	part(s, box(9.0, 0.3, 9.0, Color(0.5, 0.4, 0.3)), 0, 3.1, 0)
	if kind == "house" or kind == "farmhouse" or kind == "guest_house":
		part(s, box(2.0, 0.5, 3.2, Color(0.62, 0.5, 0.38)), -2.5, 0.25, -2.0)
		part(s, box(1.8, 0.25, 1.4, Color(0.92, 0.9, 0.85)), -2.5, 0.62, -2.4)
		part(s, box(1.6, 0.12, 2.8, Color(0.7, 0.2, 0.2)), 2.0, 0.75, -3.0)
		part(s, box(1.8, 0.75, 1.0, Color(0.5, 0.38, 0.25)), 2.5, 0.38, 1.5)
	elif kind == "animal_barn":
		part(s, box(7.0, 0.5, 2.5, Color(0.5, 0.4, 0.25)), 0, 0.25, -2.5)
		part(s, box(2.0, 1.2, 3.5, Color(0.62, 0.45, 0.2)), -3.0, 0.6, 1.5)
		part(s, box(2.0, 1.2, 3.5, Color(0.62, 0.45, 0.2)), 3.0, 0.6, 1.5)
	elif kind == "workshop":
		part(s, box(3.0, 0.9, 1.4, Color(0.45, 0.45, 0.5)), 0, 0.45, -3.0)
		part(s, cyl(0.2, 0.2, 0.9, Color(0.3, 0.3, 0.35)), 0, 1.4, -3.0)
		part(s, box(0.6, 0.6, 0.6, Color(0.75, 0.4, 0.1)), 2.5, 0.3, 1.0)
	elif kind == "market_shop":
		part(s, box(4.5, 1.0, 1.0, Color(0.62, 0.45, 0.25)), 0, 0.5, -2.5)
		part(s, box(0.8, 0.8, 0.8, Color(0.83, 0.68, 0.2)), -1.2, 1.35, -2.5)
		part(s, box(0.8, 0.8, 0.8, Color(0.85, 0.3, 0.2)), 1.2, 1.35, -2.5)
	elif kind == "garage":
		part(s, box(3.0, 0.4, 6.0, Color(0.35, 0.35, 0.38)), 0, 0.2, 0)
		part(s, cyl(0.3, 0.3, 1.2, Color(0.3, 0.3, 0.35)), 0, 0.6, -3.0)
	elif kind == "rice_storage" or kind == "warehouse":
		for p in [[-2.0, -2.0], [-2.0, 0.2], [0.2, -2.0], [0.2, 0.2], [2.2, -2.0], [2.2, 0.2]]:
			part(s, box(1.2, 1.0, 1.2, Color(0.75, 0.65, 0.45)), p[0], 0.5, p[1])
			part(s, box(1.2, 1.0, 1.2, Color(0.75, 0.65, 0.45)), p[0], 1.5, p[1])
	return s
