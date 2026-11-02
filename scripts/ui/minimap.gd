extends Control
# Minimap: cached terrain image with dots for the player, NPCs, animals,
# vehicles, the mission beacon and discovered locations.

const MAP_PX = 150.0
const WORLD_HALF = 336.0

var _tex = null
var _dirty = true
var _acc = 0.0

func _ready():
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rect_min_size = Vector2(MAP_PX + 10, MAP_PX + 10)
	rect_position = Vector2(-MAP_PX - 14, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	_acc += delta
	if _dirty or _acc >= 0.5:
		_dirty = false
		_acc = 0.0
		update()

func _draw():
	if _tex == null:
		_build_tex()
	draw_texture_rect(_tex, Rect2(Vector2(5, 5), Vector2(MAP_PX, MAP_PX)), false)
	draw_rect(Rect2(Vector2(5, 5), Vector2(MAP_PX, MAP_PX)), Color(0.83, 0.68, 0.2), false, 2.0)
	var world = _world()
	if world == null:
		return
	var p = _player()
	if p != null:
		var pp = _to_map(p.translation.x, p.translation.z)
		draw_circle(pp, 3.5, Color(0.3, 0.75, 0.35))
	# NPCs
	for nid in world.npcs.keys():
		var n = world.npcs[nid]
		if n != null and is_instance_valid(n):
			draw_circle(_to_map(n.translation.x, n.translation.z), 2.0, Color(0.9, 0.9, 0.9))
	# animals
	for a in world.animals:
		if a != null and is_instance_valid(a):
			draw_circle(_to_map(a.translation.x, a.translation.z), 1.5, Color(0.85, 0.6, 0.2))
	# vehicles
	for v in world.vehicles:
		if v != null and is_instance_valid(v) and not v.driver:
			draw_circle(_to_map(v.translation.x, v.translation.z), 2.0, Color(0.4, 0.6, 0.95))
	# mission beacon
	var mp = Missions.tracked_marker()
	if mp != null:
		var bp = _to_map(mp.x, mp.y)
		draw_circle(bp, 4.0, Color(1.0, 0.85, 0.3))
		draw_circle(bp, 7.0, Color(1.0, 0.85, 0.3, 0.4))

func _build_tex():
	var img = Image.new()
	var n = 64
	img.create(n, n, false, Image.FORMAT_RGBA8)
	img.lock()
	for j in range(n):
		for i in range(n):
			var wx = (float(i) / float(n - 1) - 0.5) * 2.0 * WORLD_HALF
			var wz = (float(j) / float(n - 1) - 0.5) * 2.0 * WORLD_HALF
			var h = TerrainGen.height(wx, wz)
			var c = TerrainGen.color_at(wx, wz, h)
			if h < TerrainGen.WATER_Y:
				c = Color(0.15, 0.3, 0.5)
			img.set_pixel(i, j, c)
	img.unlock()
	img.resize(int(MAP_PX), int(MAP_PX), Image.INTERPOLATE_BILINEAR)
	_tex = ImageTexture.new()
	_tex.create_from_image(img)

func _to_map(x, z):
	return Vector2(5.0 + (x / WORLD_HALF + 1.0) * 0.5 * MAP_PX, 5.0 + (z / WORLD_HALF + 1.0) * 0.5 * MAP_PX)

func _world():
	var ws = get_tree().get_nodes_in_group("world")
	if ws.size() > 0:
		return ws[0]
	return null

func _player():
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		return ps[0]
	return null
