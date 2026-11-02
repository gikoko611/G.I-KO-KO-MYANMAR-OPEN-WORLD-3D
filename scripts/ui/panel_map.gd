extends "res://scripts/ui/panel_base.gd"
# World map panel: cached terrain image with location and player markers.

var map_rect = Rect2(0, 0, 520, 520)
var world_size = 680.0
var tex = null
var center_label = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(560, 600)
	rect_position = Vector2(-280, -300)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	vb.add_child(ui_title("Map of the Valley"))
	var mp = Control.new()
	mp.name = "MapDraw"
	mp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mp.connect("draw", self, "_draw_map")
	vb.add_child(mp)
	center_label = ui_label("", 15, Color(0.8, 0.8, 0.75))
	vb.add_child(center_label)
	var close = ui_button("Close")
	vb.add_child(close)
	close.connect("pressed", self, "close")
	_build_texture()

func _build_texture():
	var res = 64
	var img = Image.new()
	img.create(res, res, false, Image.FORMAT_RGBA8)
	img.lock()
	for py in range(res):
		for px in range(res):
			var wx = (float(px) / float(res) - 0.5) * world_size
			var wz = (float(py) / float(res) - 0.5) * world_size
			var c = Color(0.2, 0.16, 0.1)
			if TerrainGen.in_flat_region(wx, wz, 8.0):
				c = Color(0.35, 0.3, 0.2)
			if not TerrainGen.is_water(wx, wz):
				var h = TerrainGen.height(wx, wz)
				if h < 1.2:
					c = Color(0.75, 0.68, 0.4)
				elif h < 4.5:
					c = Color(0.3, 0.45, 0.2)
				elif h < 12.0:
					c = Color(0.25, 0.35, 0.16)
				else:
					c = Color(0.45, 0.42, 0.38)
			img.set_pixel(px, py, c)
	img.unlock()
	var upscaled = Image.new()
	upscaled.create(256, 256, false, Image.FORMAT_RGBA8)
	upscaled.blit_texture(img, Rect2(0, 0, res, res), Rect2(0, 0, 256, 256))
	tex = ImageTexture.new()
	tex.create_from_image(upscaled, 0)

func _map_pos(world_x, world_z):
	var w = map_rect.size.x
	var px = map_rect.position.x + (world_x / world_size + 0.5) * w
	var py = map_rect.position.y + (world_z / world_size + 0.5) * w
	return Vector2(px, py)

func _draw_map():
	var mp = get_node_or_null("VBoxContainer/MapDraw")
	if mp == null:
		return
	var origin = Vector2(20, (mp.rect_size.x - map_rect.size.x) * 0.5)
	if mp.rect_size.y < map_rect.size.y:
		origin.y = 10
	var r = Rect2(origin, map_rect.size)
	mp.draw_rect(Rect2(Vector2(10, 10), mp.rect_size - Vector2(20, 20)), Color(0.05, 0.05, 0.04), true)
	if tex != null:
		mp.draw_texture_rect(tex, r, false, Color(1, 1, 1), false)
	mp.draw_rect(r, Color(0.9, 0.8, 0.4), false, 2.0)
	var origin_backup = map_rect.position
	map_rect.position = origin
	for loc in ItemDB.LOCATIONS:
		var lid = loc["id"]
		var known = GameState.discovered.has(lid)
		if not known:
			continue
		var p = _map_pos(float(loc["pos"][0]), float(loc["pos"][1]))
		mp.draw_circle(p, 6.0, Color(0.1, 0.1, 0.1))
		mp.draw_circle(p, 4.5, Color(0.95, 0.85, 0.4))
		mp.draw_string(ui_font(13), p + Vector2(8, -4), str(loc["name"]))
	var marker = Missions.tracked_marker()
	if marker != Vector3.ZERO:
		var mp2 = _map_pos(marker.x, marker.z)
		mp.draw_circle(mp2, 8.0, Color(0.9, 0.3, 0.2))
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		var pp = _map_pos(ps[0].global_transform.origin.x, ps[0].global_transform.origin.z)
		mp.draw_circle(pp, 7.0, Color(0.2, 0.6, 1.0))
		mp.draw_circle(pp, 4.0, Color(1, 1, 1))
	map_rect.position = origin_backup

var _acc = 0.0

func _process(delta):
	if not visible:
		return
	_acc += delta
	if _acc < 0.5:
		return
	_acc = 0.0
	var mp = get_node_or_null("VBoxContainer/MapDraw")
	if mp != null:
		mp.update()
	if center_label != null:
		var ps = get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			center_label.text = "You are near: " + _nearest_location(ps[0].global_transform.origin)
		else:
			center_label.text = ""

func _nearest_location(pos):
	var best = ""
	var best_d = 1e9
	for loc in ItemDB.LOCATIONS:
		var lp = Vector2(float(loc["pos"][0]), float(loc["pos"][1]))
		var d = lp.distance_to(Vector2(pos.x, pos.z))
		if d < best_d:
			best_d = d
			best = str(loc["name"])
	return best + " (" + str(int(best_d)) + "m)"
