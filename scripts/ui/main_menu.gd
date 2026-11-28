extends Control
# Main menu with three save slots. New Game chooses an empty/overwrite slot;
# Continue loads a selected occupied slot. All controls are touch sized.

const UiStyle = preload("res://scripts/ui/ui_theme.gd")

var story_box = null
var about_box = null
var slot_box = null
var slot_mode = "load"
var selected_slot = 1
var _fonts = {}

func _ready():
	set_anchors_preset(Control.PRESET_WIDE)
	_label("G.I KO KO", 58, UiStyle.GOLD, 400, 50)
	_label("MYANMAR OPEN WORLD 3D", 26, Color(0.83, 0.68, 0.2), 445, 120)
	_label("Powered by I KO KO", 16, Color(0.6, 0.56, 0.5), 535, 155)
	_btn("New Game", 490, 220, 300, 56, "_new_game")
	var cont = _btn("Continue", 490, 286, 300, 56, "_continue")
	cont.disabled = not SaveMgr.has_any_save()
	_btn("About", 490, 352, 300, 56, "_about")
	_btn("Quit", 490, 418, 300, 56, "_quit")
	slot_box = PanelContainer.new()
	slot_box.add_style_override("panel", UiStyle.panel_style())
	slot_box.rect_position = Vector2(350, 155)
	slot_box.rect_min_size = Vector2(580, 440)
	slot_box.visible = false
	add_child(slot_box)
	story_box = PanelContainer.new()
	story_box.add_style_override("panel", UiStyle.panel_style())
	story_box.rect_position = Vector2(330, 155)
	story_box.rect_min_size = Vector2(620, 470)
	story_box.visible = false
	add_child(story_box)
	about_box = PanelContainer.new()
	about_box.add_style_override("panel", UiStyle.panel_style())
	about_box.rect_position = Vector2(390, 200)
	about_box.rect_min_size = Vector2(500, 340)
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

func _panel_button(text):
	var b = Button.new()
	b.text = text
	b.rect_min_size = Vector2(520, 70)
	UiStyle.style_button(b)
	var f = _font(18)
	if f != null:
		b.add_font_override("font", f)
	return b

func _clear(container):
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()

func _new_game():
	AudioSynth.play("click")
	_open_slots("new")

func _continue():
	AudioSynth.play("click")
	_open_slots("load")

func _open_slots(mode):
	slot_mode = mode
	about_box.visible = false
	story_box.visible = false
	_build_slot_picker()
	slot_box.visible = true

func _build_slot_picker():
	_clear(slot_box)
	var vb = VBoxContainer.new()
	slot_box.add_child(vb)
	var title = Label.new()
	title.text = "Choose a slot to " + ("start" if slot_mode == "new" else "continue")
	var tf = _font(24)
	if tf != null:
		title.add_font_override("font", tf)
	title.add_color_override("font_color", UiStyle.GOLD)
	vb.add_child(title)
	for slot in range(1, SaveMgr.SLOT_COUNT + 1):
		var summary = SaveMgr.slot_summary(slot)
		var text = "Slot " + str(slot) + "  -  " + str(summary.get("label", "Empty slot"))
		var b = _panel_button(text)
		b.disabled = slot_mode == "load" and not summary.get("exists", false)
		vb.add_child(b)
		b.connect("pressed", self, "_slot_chosen", [slot])
	var note = Label.new()
	# This text must match _pick_story(): the old save in a used slot is
	# deleted at the moment the story is chosen, not later.
	note.text = ("WARNING: a used slot is erased as soon as you pick your story. Empty slots are safe." if slot_mode == "new" else "Each slot keeps an automatic backup if its newest file is damaged.")
	note.autowrap = true
	note.rect_min_size = Vector2(520, 44)
	var nf = _font(14)
	if nf != null:
		note.add_font_override("font", nf)
	note.add_color_override("font_color", (UiStyle.RED if slot_mode == "new" else Color(0.8, 0.8, 0.75)))
	vb.add_child(note)
	var back = _panel_button("Back")
	back.rect_min_size = Vector2(520, 54)
	vb.add_child(back)
	back.connect("pressed", self, "_close_slots")

func _slot_chosen(slot):
	selected_slot = int(slot)
	AudioSynth.play("accept")
	if slot_mode == "load":
		SaveMgr.set_current_slot(selected_slot)
		SaveMgr.save_settings()
		GameState.pending_load = true
		GameState.pending_new_game = false
		get_tree().change_scene("res://scenes/main.tscn")
	else:
		# Nothing is changed on disk yet; the slot is only committed in
		# _pick_story() so Back leaves every save untouched.
		_build_story_picker()
		slot_box.visible = false
		story_box.visible = true

func _close_slots():
	slot_box.visible = false

func _build_story_picker():
	_clear(story_box)
	var vb = VBoxContainer.new()
	story_box.add_child(vb)
	var t = Label.new()
	t.text = "Who are you in the valley of Myaing?  Slot " + str(selected_slot)
	var tf = _font(24)
	if tf != null:
		t.add_font_override("font", tf)
	t.add_color_override("font_color", UiStyle.GOLD)
	vb.add_child(t)
	var desc = Label.new()
	desc.text = "Your choice sets your starting bonus. The world is the same - your path is yours."
	if SaveMgr.has_save(selected_slot):
		desc.text += " Choosing a story now erases the game saved in slot " + str(selected_slot) + "."
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
	cancel.text = "Back to slots"
	UiStyle.style_button(cancel)
	vb.add_child(cancel)
	cancel.connect("pressed", self, "_close_story")

func _pick_story(sid):
	AudioSynth.play("accept")
	SaveMgr.set_current_slot(selected_slot)
	SaveMgr.delete_save(selected_slot)
	SaveMgr.save_settings()
	GameState.story_choice = sid
	GameState.pending_new_game = true
	GameState.pending_load = false
	get_tree().change_scene("res://scenes/main.tscn")

func _close_story():
	story_box.visible = false
	_open_slots("new")

func _about():
	slot_box.visible = false
	story_box.visible = false
	about_box.visible = not about_box.visible

func _build_about():
	_clear(about_box)
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
		"Three local save slots with automatic backups.",
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
