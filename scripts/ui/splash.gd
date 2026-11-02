extends Control
# Splash screen: gold emblem, game title, credit line, then main menu.

var t = 0.0
var title_font = null

func _ready():
	set_anchors_preset(Control.PRESET_WIDE)

func _process(delta):
	t += delta
	if t > 2.6:
		set_process(false)
		get_tree().change_scene("res://scenes/main_menu.tscn")
	update()

func _draw():
	var cx = rect_size.x * 0.5
	var cy = rect_size.y * 0.5
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.05, 0.04, 0.03))
	var pulse = 0.8 + 0.2 * sin(t * 3.0)
	var r = 90.0 * pulse
	var diamond = PoolVector2Array([
		Vector2(cx, cy - r),
		Vector2(cx + r * 0.7, cy),
		Vector2(cx, cy + r),
		Vector2(cx - r * 0.7, cy)
	])
	draw_colored_polygon(diamond, Color(0.83, 0.68, 0.2))
	var diamond2 = PoolVector2Array([
		Vector2(cx, cy - r * 0.55),
		Vector2(cx + r * 0.38, cy),
		Vector2(cx, cy + r * 0.55),
		Vector2(cx - r * 0.38, cy)
	])
	draw_colored_polygon(diamond2, Color(0.98, 0.88, 0.45))
	var f = get_font("font")
	if f != null:
		var big = f.duplicate()
		if big != null and big is DynamicFont:
			big.size = 54
			draw_string(big, Vector2(cx - 200, cy + 170), "G.I KO KO", Color(0.95, 0.9, 0.75))
			var mid = f.duplicate()
			if mid != null and mid is DynamicFont:
				mid.size = 26
				draw_string(mid, Vector2(cx - 235, cy + 210), "MYANMAR OPEN WORLD 3D", Color(0.83, 0.68, 0.2))
				var small = f.duplicate()
				if small != null and small is DynamicFont:
					small.size = 18
					draw_string(small, Vector2(cx - 95, cy + 260), "Powered by I KO KO", Color(0.7, 0.65, 0.55))
