extends MeshInstance
# One streamed terrain chunk: heightmap mesh with vertex colors, trimesh
# collision and MultiMesh-scattered props.

func setup(cx, cz):
	var origin = Vector3(cx * TerrainGen.CHUNK, 0, cz * TerrainGen.CHUNK)
	_build_mesh(origin)
	_build_collision()
	_scatter(origin)

func _build_mesh(origin):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g = TerrainGen.GRID
	var step = TerrainGen.CHUNK / g
	for j in range(g + 1):
		for i in range(g + 1):
			var lx = i * step
			var lz = j * step
			var wx = origin.x + lx
			var wz = origin.z + lz
			var h = TerrainGen.height(wx, wz)
			st.add_color(TerrainGen.color_at(wx, wz, h))
			st.add_vertex(Vector3(lx, h, lz))
	for j in range(g):
		for i in range(g):
			var a = j * (g + 1) + i
			var b = a + 1
			var c = a + g + 1
			var d = c + 1
			st.add_index(a)
			st.add_index(c)
			st.add_index(b)
			st.add_index(b)
			st.add_index(c)
			st.add_index(d)
	st.generate_normals()
	mesh = st.commit()

func _build_collision():
	var shape = mesh.create_trimesh_shape()
	if shape == null:
		return
	var cs = CollisionShape.new()
	cs.shape = shape
	var body = StaticBody.new()
	body.add_child(cs)
	add_child(body)

func _scatter(origin):
	seed(int(origin.x) * 731 + int(origin.z) * 911 + 17)
	var density = clamp(GameState.prop_density(), 0.15, 1.0)
	var buckets = {"tree": [], "palm": [], "rock": [], "grass": []}
	for j in range(8):
		for i in range(8):
			if randf() > density:
				continue
			var wx = origin.x + (i + randf()) * 6.0
			var wz = origin.z + (j + randf()) * 6.0
			var pt = TerrainGen.prop_at(wx, wz)
			if pt == "" or not buckets.has(pt):
				continue
			var h = TerrainGen.height(wx, wz)
			buckets[pt].append([wx - origin.x, h, wz - origin.z])
	# trees: trunk + canopy
	var trunk_m = Props.tree_trunk_mesh()
	var canopy_m = Props.tree_canopy_mesh()
	_trunk_canopy(trunk_m, canopy_m, buckets["tree"], Color(0.4, 0.28, 0.16), Color(0.16, 0.42, 0.14), 3.6)
	_trunk_canopy(Props.palm_trunk_mesh(), cone_mesh_palm(), buckets["palm"], Color(0.45, 0.35, 0.2), Color(0.2, 0.5, 0.18), 4.6)
	# rocks
	var rocks = []
	for p in buckets["rock"]:
		var sc = rand_range(0.5, 1.4)
		rocks.append(Transform(Basis(Vector3(sc, sc * 0.7, sc)), Vector3(p[0], p[1] + sc * 0.35, p[2])))
	_multimesh(Props.sphere_mesh(1.0), Props.mat(Color(0.55, 0.55, 0.58)), rocks)
	# grass
	var grass = []
	for p in buckets["grass"]:
		grass.append(Transform(Basis(), Vector3(p[0], p[1] + 0.25, p[2])))
	_multimesh(Props.cone_mesh(0.14, 0.55), Props.mat(Color(0.3, 0.55, 0.2)), grass)

func cone_mesh_palm():
	return Props.cone_mesh(1.3, 1.6)

func _trunk_canopy(trunk_m, canopy_m, spots, trunk_c, canopy_c, canopy_y):
	var trunks = []
	var canopies = []
	for p in spots:
		var sc = rand_range(0.8, 1.25)
		trunks.append(Transform(Basis(Vector3(sc, sc, sc)), Vector3(p[0], p[1] + 2.0 * sc, p[2])))
		canopies.append(Transform(Basis(Vector3(sc, sc, sc)), Vector3(p[0], p[1] + canopy_y, p[2])))
	_multimesh(trunk_m, Props.mat(trunk_c), trunks)
	_multimesh(canopy_m, Props.mat(canopy_c), canopies)

func _multimesh(mesh, material, transforms):
	if transforms.size() == 0:
		return
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var mmi = MultiMeshInstance.new()
	mmi.multimesh = mm
	mmi.material_override = material
	add_child(mmi)
