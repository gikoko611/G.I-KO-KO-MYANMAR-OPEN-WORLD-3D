extends Reference
# Shared UI style: G.I KO KO "Cyber Neon Green + Midnight Gold".
# Dark midnight glass panels, emerald highlights, gold accents.

const GOLD = Color(0.95, 0.76, 0.25)
const NEON = Color(0.0, 0.92, 0.55)
const TEXT = Color(0.94, 0.96, 0.92)
const BG = Color(0.02, 0.04, 0.07, 0.94)
const PANEL = Color(0.03, 0.07, 0.09, 0.90)
const BTN = Color(0.05, 0.13, 0.12, 0.94)
const BTN_HOVER = Color(0.04, 0.28, 0.20, 0.96)
const GREEN = Color(0.0, 0.85, 0.5)
const RED = Color(0.9, 0.3, 0.25)
const BAR_BG = Color(0.02, 0.05, 0.06, 0.85)

static func panel_style(bg=PANEL, radius=12):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = NEON.darkened(0.35)
	sb.set_border_width_all(2)
	sb.border_blend = true
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb

static func bar_style(fg):
	var sb = StyleBoxFlat.new()
	sb.bg_color = fg
	sb.set_corner_radius_all(3)
	return sb

static func button_styles():
	var n = StyleBoxFlat.new()
	n.bg_color = BTN
	n.set_corner_radius_all(8)
	n.border_color = GOLD.darkened(0.3)
	n.set_border_width_all(1)
	n.content_margin_left = 10.0
	n.content_margin_right = 10.0
	n.content_margin_top = 6.0
	n.content_margin_bottom = 6.0
	var h = n.duplicate()
	h.bg_color = BTN_HOVER
	h.border_color = NEON
	var p = n.duplicate()
	p.bg_color = GOLD.darkened(0.1)
	p.border_color = GOLD
	return [n, h, p]

static func style_button(b):
	var st = button_styles()
	b.add_style_override("normal", st[0])
	b.add_style_override("hover", st[1])
	b.add_style_override("pressed", st[2])
	b.add_style_override("focus", st[1])
	b.add_color_override("font_color", TEXT)
	b.add_color_override("font_color_hover", Color(0.85, 1.0, 0.92))
	b.add_color_override("font_color_pressed", Color(0.05, 0.05, 0.05))
	# Touch-friendly minimum size for Android fingers.
	if b.rect_min_size.y < 48:
		b.rect_min_size.y = 48
	return b
