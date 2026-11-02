extends Reference
# Shared UI style constants and stylebox factories for the whole game.

const GOLD = Color(0.83, 0.68, 0.2)
const TEXT = Color(0.95, 0.93, 0.85)
const BG = Color(0.07, 0.09, 0.14, 0.94)
const PANEL = Color(0.1, 0.13, 0.2, 0.96)
const BTN = Color(0.16, 0.2, 0.3, 0.95)
const BTN_HOVER = Color(0.24, 0.29, 0.42, 0.95)
const GREEN = Color(0.3, 0.75, 0.35)
const RED = Color(0.85, 0.3, 0.25)
const BAR_BG = Color(0.08, 0.08, 0.1, 0.85)

static func panel_style(bg=PANEL, radius=10):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = GOLD.darkened(0.25)
	sb.set_border_width_all(1)
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
	n.set_corner_radius_all(6)
	n.content_margin_left = 8.0
	n.content_margin_right = 8.0
	var h = n.duplicate()
	h.bg_color = BTN_HOVER
	var p = n.duplicate()
	p.bg_color = GOLD.darkened(0.15)
	return [n, h, p]

static func style_button(b):
	var st = button_styles()
	b.add_style_override("normal", st[0])
	b.add_style_override("hover", st[1])
	b.add_style_override("pressed", st[2])
	b.add_color_override("font_color", TEXT)
	b.add_color_override("font_color_hover", Color(1.0, 1.0, 0.9))
	b.add_color_override("font_color_pressed", Color(0.1, 0.1, 0.1))
	return b
