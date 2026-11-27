extends Control
# Splash screen: "G.I / MYANMAR OPEN WORLD 3D / POWERED BY I KO KO" in the
# Cyber Neon Green + Midnight Gold theme. Tap to skip.
# Godot 3.5's default font is a BitmapFont that cannot be resized, so the
# titles are Labels scaled with rect_scale instead of resized DynamicFonts.

const NEON = Color(0.0, 0.92, 0.55)
const GOLD = Color(0.95, 0.76, 0.25)
const BG = Color(0.015, 0.025, 0.05)
const DURATION = 2.8

var t = 0.0
var labels = []
var leaving = false

func _ready():
	set_anchors_preset(Control.PRESET_WIDE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_make_label("G.I", 6.0, GOLD, 0.30)
	_make_label("MYANMAR OPEN WORLD 3D", 2.6, NEON, 0.56)
	_make_label("POWERED BY I KO KO", 1.6, Color(0.82, 0.78, 0.62), 0.68)
	_layout()

func _make_label(text, s, color, y_frac):
	var l = Label.new()
	l.text = text
	l.add_color_override("font_color", color)
	l.add_color_override("font_color_shadow", Color(0, 0, 0, 0.85))
	l.add_constant_override("shadow_offset_x", 1)
	l.add_constant_override("shadow_offset_y", 1)
	l.rect_scale = Vector2(s, s)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_meta("y_frac", y_frac)
	l.set_meta("s", s)
	add_child(l)
	labels.append(l)

func _layout():
	var size = rect_size
	if size.x < 2.0:
		size = get_viewport_rect().size
	for l in labels:
		var s = float(l.get_meta("s"))
		var m = l.get_minimum_size() * s
		l.rect_position = Vector2((size.x - m.x) * 0.5, size.y * float(l.get_meta("y_frac")) - m.y * 0.5)

func _process(delta):
	t += delta
	modulate.a = clamp(t / 0.6, 0.0, 1.0)
	_layout()
	update()
	if t > DURATION:
		_go()

func _gui_input(event):
	if t < 0.4:
		return
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_go()

func _go():
	if leaving:
		return
	leaving = true
	set_process(false)
	get_tree().change_scene("res://scenes/main_menu.tscn")

func _draw():
	var size = rect_size
	if size.x < 2.0:
		size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var cx = size.x * 0.5
	var cy = size.y * 0.30
	var pulse = 0.92 + 0.08 * sin(t * 3.0)
	var r = size.y * 0.20 * pulse
	# Stupa-like diamond emblem: neon outline with a gold core.
	var outer = PoolVector2Array([
		Vector2(cx, cy - r),
		Vector2(cx + r * 0.72, cy),
		Vector2(cx, cy + r),
		Vector2(cx - r * 0.72, cy),
		Vector2(cx, cy - r)
	])
	draw_polyline(outer, NEON, 3.0)
	var inner = PoolVector2Array([
		Vector2(cx, cy - r * 0.78),
		Vector2(cx + r * 0.55, cy),
		Vector2(cx, cy + r * 0.78),
		Vector2(cx - r * 0.55, cy)
	])
	draw_colored_polygon(inner, Color(GOLD.r, GOLD.g, GOLD.b, 0.18))
	# Thin neon divider under the emblem.
	var w = size.x * 0.22 * clamp(t / 1.0, 0.0, 1.0)
	draw_line(Vector2(cx - w, size.y * 0.47), Vector2(cx + w, size.y * 0.47), GOLD, 2.0)
