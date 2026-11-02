extends "res://scripts/ui/panel_base.gd"
# Missions panel with tabs: Board / Active / Daily & Weekly / Done / Awards.

const MD = preload("res://scripts/missions/mission_data.gd")

var tabs = {}
var tab_btns = {}
var current_tab = "board"
var list_box = null
var tab_bar = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(640, 500)
	rect_position = Vector2(-320, -250)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	var title = ui_title("Missions & Quests")
	vb.add_child(title)
	tab_bar = HBoxContainer.new()
	vb.add_child(tab_bar)
	_make_tab("board", "Board")
	_make_tab("active", "Active")
	_make_tab("daily", "Daily/Weekly")
	_make_tab("done", "Done")
	_make_tab("awards", "Awards")
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_box = VBoxContainer.new()
	scroll.add_child(list_box)
	vb.add_child(scroll)
	var close = ui_button("Close")
	vb.add_child(close)
	close.connect("pressed", self, "close")

func _make_tab(key, label):
	var b = ui_button(label)
	tab_bar.add_child(b)
	tab_btns[key] = b
	b.connect("pressed", self, "_set_tab", [key])

func _set_tab(key):
	current_tab = key
	_refresh()

func open():
	.open()
	_set_tab(current_tab)

func _refresh():
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var mids = []
	if current_tab == "board":
		mids = Missions.on_board()
		_add_header("Available missions - press Accept to start.")
	elif current_tab == "active":
		mids = Missions.get_active()
		_add_header("Your current missions.")
	elif current_tab == "daily":
		mids = Missions.get_dailies()
		_add_header("Daily and weekly missions - reset automatically.")
	elif current_tab == "done":
		mids = Missions.get_completed()
		_add_header("Completed missions.")
	elif current_tab == "awards":
		mids = Missions.get_achievements()
		_add_header("Achievements.")
	if mids.size() == 0:
		list_box.add_child(ui_label("Nothing here yet.", 16, Color(0.7, 0.7, 0.65)))
	for mid in mids:
		_add_mission(mid)

func _add_header(text):
	var l = ui_label(text, 15, Color(0.75, 0.7, 0.55))
	l.autowrap = true
	list_box.add_child(l)

func _add_mission(mid):
	var d = MD.DEFS[mid]
	var panel = PanelContainer.new()
	panel.add_style_override("panel", UiStyle.panel_style(Color(0.12, 0.11, 0.08, 0.9), 1))
	list_box.add_child(panel)
	var vb = VBoxContainer.new()
	panel.add_child(vb)
	var title_line = "[" + str(d.get("cat", "mission")).to_upper() + "] " + str(d["title"])
	var rewards = d.get("rewards", {})
	var money = int(rewards.get("money", 0))
	var xp = int(rewards.get("xp", 0))
	var item_str = ""
	var rw_items = rewards.get("items", {})
	for iid in rw_items.keys():
		item_str += ", " + str(rw_items[iid]) + "x " + ItemDB.display_name(iid)
	var head = ui_label(title_line + "   (K " + str(money) + ", " + str(xp) + " XP" + item_str + ")", 18, Color(0.95, 0.85, 0.5))
	head.autowrap = true
	vb.add_child(head)
	var desc = ui_label(str(d.get("desc", "")), 15, Color(0.8, 0.8, 0.75))
	desc.autowrap = true
	vb.add_child(desc)
	var body_text = ""
	if Missions.active.has(mid):
		body_text = Missions.progress_text(mid)
		if body_text != "":
			body_text = "Progress:\n" + body_text
	elif Missions.completed.has(mid):
		body_text = "COMPLETED"
	if body_text != "":
		var body = ui_label(body_text, 15, Color(0.6, 0.9, 0.6))
		body.autowrap = true
		vb.add_child(body)
	var hb = HBoxContainer.new()
	vb.add_child(hb)
	if Missions.active.has(mid):
		var cancel = ui_button("Cancel")
		hb.add_child(cancel)
		cancel.connect("pressed", self, "_cancel_mission", [mid])
	elif not Missions.completed.has(mid):
		var accept = ui_button("Accept")
		hb.add_child(accept)
		accept.connect("pressed", self, "_accept_mission", [mid])

func _accept_mission(mid):
	AudioSynth.play("accept")
	Missions.accept(mid)
	_refresh()

func _cancel_mission(mid):
	AudioSynth.play("deny")
	Missions.cancel(mid)
	_refresh()
