extends Panel
# Base panel: styled background, shared font/label/button helpers and the
# ui_open counter that pauses the world while a panel is shown.

const UiStyle = preload("res://scripts/ui/ui_theme.gd")

var _fonts = {}

func _ready():
	add_stylebox_override("panel", UiStyle.panel_style())
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func ui_font(size):
	if _fonts.has(size):
		return _fonts[size]
	var base = get_font("font")
	if base == null:
		return null
	var df = base.duplicate()
	if df != null and df is DynamicFont:
		df.size = size
		_fonts[size] = df
		return df
	return null

func ui_label(text, size=17, color=UiStyle.TEXT):
	var l = Label.new()
	l.text = text
	var f = ui_font(size)
	if f != null:
		l.add_font_override("font", f)
	l.add_color_override("font_color", color)
	return l

func ui_title(text):
	return ui_label(text, 24, UiStyle.GOLD)

func ui_button(text):
	var b = Button.new()
	b.text = text
	UiStyle.style_button(b)
	var f = ui_font(17)
	if f != null:
		b.add_font_override("font", f)
	return b

func open():
	if visible:
		return
	visible = true
	GameState.ui_open += 1
	AudioSynth.play("click")

func close():
	if not visible:
		return
	visible = false
	GameState.ui_open = max(0, GameState.ui_open - 1)
	AudioSynth.play("click")

func toggle():
	if visible:
		close()
	else:
		open()
