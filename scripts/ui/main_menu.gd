extends Control
# Main menu: title, New Game (story picker), Continue, About, Quit.

const UiStyle = preload("res://scripts/ui/ui_theme.gd")

var story_box = null
var about_box = null
var _fonts = {}

func _ready():
	set_anchors_preset(Control.PRESET_WIDE)
	_label("G.I KO KO", 58, UiStyle.GOLD, 400, 60)
	_label("MYANMAR OPEN WORLD 3D", 26, Color(0.83, 0.68, 0.2), 445, 130)
	_label("Powered by I KO KO", 16, Color(0.6, 0.56, 0.5), 535, 165)
	_btn("New Game", 490, 240, 300, 56, "_new_game")
	var cont = _btn("Continue", 490, 306, 300, 56, "_continue")
	if not SaveMgr.has_save():
		cont.disabled = true
	_btn("About", 490, 372, 300, 56, "_about")
	_btn("Quit", 490, 438, 300, 56, "_quit")
	story_box = PanelContainer.new()
	story_box.add_style_override("panel", UiStyle.panel_style())
	story_box.rect_position = Vector2(330, 200)
	story_box.rect_min_size = Vector2(620, 420)
	story_box.visible = false
	add_child(story_box)
	about_box = PanelContainer.new()
	about_box.add_style_override("panel", UiStyle.panel_style())
	about_box.rect_position = Vector2(390, 220)
	about_box.rect_min_size = Vector2(500, 300)
	about_box.visible = false
	add_child(about_box)
	_build_about()

func _font(size):
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

func _label(text, size, color, x, y):
	var l = Label.new()
	l.text = text
	var f = _font(size)
	if f != null:
		l.add_font_override("font", f)
	l.add_color_override("font_color", color)
	l.rect_position = Vector2(x, y)
	add_child(l)
	return l

func _btn(text, x, y, w, h, method):
	var b = Button.new()
	b.text = text
	UiStyle.style_button(b)
	var f = _font(20)
	if f != null:
		b.add_font_override("font", f)
	b.rect_position = Vector2(x, y)
	b.rect_min_size = Vector2(w, h)
	b.connect("pressed", self, method)
	add_child(b)
	return b

func _new_game():
	AudioSynth.play("click")
	_build_story_picker()
	story_box.visible = true

func _build_story_picker():
	for c in story_box.get_children():
		story_box.remove_child(c)
		c.queue_free()
	var vb = VBoxContainer.new()
	story_box.add_child(vb)
	var t = Label.new()
	t.text = "Who are you in the valley of Myaing?"
	var tf = _font(24)
	if tf != null:
		t.add_font_override("font", tf)
	t.add_color_override("font_color", UiStyle.GOLD)
	vb.add_child(t)
	var desc = Label.new()
	desc.text = "Your choice sets your starting bonus. The world is the same - your path is yours."
	var df = _font(15)
	if df != null:
		desc.add_font_override("font", df)
	desc.add_color_override("font_color", Color(0.8, 0.8, 0.75))
	desc.autowrap = true
	vb.add_child(desc)
	for sid in ItemDB.STORIES.keys():
		var s = ItemDB.STORIES[sid]
		var hb = HBoxContainer.new()
		vb.add_child(hb)
		var l = Label.new()
		l.text = str(s["name"]) + " - " + str(s.get("desc", ""))
		var lf = _font(16)
		if lf != null:
			l.add_font_override("font", lf)
		l.add_color_override("font_color", UiStyle.TEXT)
		l.autowrap = true
		l.rect_min_size = Vector2(420, 0)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		var b = Button.new()
		b.text = "Choose"
		UiStyle.style_button(b)
		hb.add_child(b)
		b.connect("pressed", self, "_pick_story", [sid])
	var cancel = Button.new()
	cancel.text = "Back"
	UiStyle.style_button(cancel)
	vb.add_child(cancel)
	cancel.connect("pressed", self, "_close_story")

func _pick_story(sid):
	AudioSynth.play("accept")
	GameState.story_choice = sid
	GameState.pending_new_game = true
	GameState.pending_load = false
	get_tree().change_scene("res://scenes/main.tscn")

func _close_story():
	story_box.visible = false

func _continue():
	AudioSynth.play("click")
	GameState.pending_load = true
	GameState.pending_new_game = false
	get_tree().change_scene("res://scenes/main.tscn")

func _about():
	about_box.visible = not about_box.visible

func _build_about():
	for c in about_box.get_children():
		about_box.remove_child(c)
		c.queue_free()
	var vb = VBoxContainer.new()
	about_box.add_child(vb)
	var lines = [
		"G.I KO KO - MYANMAR OPEN WORLD 3D",
		"A farming, survival and exploration open world",
		"in a Myanmar river valley.",
		"",
		"Farm rice and peanuts, fish the lake, raise animals,",
		"race vehicles, dig for treasure, befriend the village,",
		"and follow 85+ missions and stories.",
		"",
		"Powered by I KO KO",
		"Made with Godot 3.5.2 (GLES2)"
	]
	for line in lines:
		var l = Label.new()
		l.text = line
		var f = _font(16)
		if f != null:
			l.add_font_override("font", f)
		l.add_color_override("font_color", UiStyle.TEXT)
		vb.add_child(l)
	var close = Button.new()
	close.text = "Close"
	UiStyle.style_button(close)
	vb.add_child(close)
	close.connect("pressed", self, "_about")

func _quit():
	get_tree().quit()
