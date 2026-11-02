extends Control
# Main HUD: virtual joystick (left), camera drag (right), status bars,
# buttons, minimap, notifications, context actions, driving, placement,
# race info and lazy-loaded panels.

const UiStyle = preload("res://scripts/ui/ui_theme.gd")
const PanelInventoryScript = preload("res://scripts/ui/panel_inventory.gd")
const PanelShopScript = preload("res://scripts/ui/panel_shop.gd")
const PanelMissionsScript = preload("res://scripts/ui/panel_missions.gd")
const PanelMapScript = preload("res://scripts/ui/panel_map.gd")
const PanelDialogueScript = preload("res://scripts/ui/panel_dialogue.gd")
const PanelPauseScript = preload("res://scripts/ui/panel_pause.gd")
const PanelBuildScript = preload("res://scripts/ui/panel_build.gd")
const PanelFishScript = preload("res://scripts/ui/panel_fish.gd")
const MinimapScript = preload("res://scripts/ui/minimap.gd")

# ---- input state read by the player each frame ----
var move_vector = Vector2.ZERO
var run_flag = false
var jump_pressed = false
var cam_yaw = 0.0
var cam_pitch = -12.0

# ---- touch state ----
var joy_touch = -1
var cam_touch = -1
var joy_origin = Vector2.ZERO
var joy_vec = Vector2.ZERO
var cam_last = Vector2.ZERO
var mouse_down = false
var mouse_zone = "" # "" / "joy" / "cam"

# ---- widgets ----
var joy_draw = null
var bars = {}
var money_label = null
var time_label = null
var race_label = null
var prompt_label = null
var notif_box = null
var context_box = null
var drive_box = null
var brake_held = false
var jump_btn = null
var sprint_btn = null
var exit_btn = null
var brake_btn = null
var place_box = null
var panels = {}
var seed_panel = null
var ctx_timer = 0.0
var ctx_target = null
var _fonts = {}

func _ready():
	add_to_group("hud")
	set_anchors_preset(Control.PRESET_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_left()
	_build_notifs()
	_build_bars()
	_build_top_right()
	_build_bottom_right()
	_build_context()
	_build_drive()
	_build_placement()
	joy_draw = Control.new()
	joy_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_draw.set_anchors_preset(Control.PRESET_WIDE)
	add_child(joy_draw)
	joy_draw.connect("draw", self, "_draw_joy")
	Events.connect("notify", self, "_on_notify")

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

func _button(text, x, y, w, h, size=17):
	var b = Button.new()
	b.text = text
	UiStyle.style_button(b)
	var f = _font(size)
	if f != null:
		b.add_font_override("font", f)
	b.rect_position = Vector2(x, y)
	b.rect_min_size = Vector2(w, h)
	add_child(b)
	return b

func _bar(color, x, y):
	var bg = ProgressBar.new()
	bg.min_value = 0.0
	bg.max_value = 100.0
	bg.value = 100.0
	bg.rect_position = Vector2(x, y)
	bg.rect_min_size = Vector2(240, 16)
	bg.add_style_override("bg", UiStyle.bar_style(UiStyle.BAR_BG))
	bg.add_style_override("fg", UiStyle.bar_style(color))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	return bg

func _panel(key, script):
	if panels.has(key):
		return panels[key]
	var p = script.new()
	add_child(p)
	panels[key] = p
	return p

func _player():
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		return ps[0]
	return null

func _world():
	var ws = get_tree().get_nodes_in_group("world")
	if ws.size() > 0:
		return ws[0]
	return null

# ------------------------------ widgets ---------------------------------

func _build_top_left():
	money_label = _label("K 0", 24, UiStyle.GOLD, 20, 12)
	time_label = _label("Day 1  07:00\nSummer, Sunny", 18, UiStyle.TEXT, 20, 44)
	race_label = _label("", 20, Color(0.95, 0.5, 0.3), 20, 92)
	race_label.visible = false

func _build_notifs():
	notif_box = VBoxContainer.new()
	notif_box.rect_position = Vector2(440, 12)
	notif_box.rect_min_size = Vector2(400, 0)
	notif_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notif_box)

func _build_bars():
	bars["health"] = _bar(Color(0.75, 0.25, 0.2), 20, 560)
	bars["stamina"] = _bar(Color(0.9, 0.8, 0.3), 20, 582)
	bars["hunger"] = _bar(Color(0.85, 0.55, 0.2), 20, 604)
	bars["thirst"] = _bar(Color(0.3, 0.6, 0.9), 20, 626)

func _build_top_right():
	var mm = MinimapScript.new()
	add_child(mm)
	var names = [["Missions", "_open_missions"], ["Map", "_open_map"], ["Bag", "_open_bag"], ["Build", "_open_build"], ["Menu", "toggle_pause"]]
	var bx = 1280 - 24 - names.size() * 102
	for i in range(names.size()):
		var b = _button(names[i][0], bx + i * 102, 184, 96, 44, 15)
		b.connect("pressed", self, names[i][1])

func _build_bottom_right():
	jump_btn = _button("Jump", 1280 - 24 - 96, 720 - 24 - 96, 96, 96, 20)
	jump_btn.connect("pressed", self, "_jump")
	sprint_btn = _button("Walk", 1280 - 24 - 96 - 106, 720 - 24 - 96, 96, 96, 20)
	sprint_btn.connect("pressed", self, "_toggle_run")

func _build_context():
	prompt_label = _label("", 18, UiStyle.GOLD, 340, 690)
	context_box = VBoxContainer.new()
	context_box.rect_position = Vector2(1280 - 24 - 160, 330)
	context_box.rect_min_size = Vector2(160, 0)
	add_child(context_box)

func _build_drive():
	drive_box = VBoxContainer.new()
	drive_box.rect_position = Vector2(540, 600)
	add_child(drive_box)
	exit_btn = _button("Exit Vehicle", 540, 600, 200, 56, 18)
	exit_btn.visible = false
	exit_btn.connect("pressed", self, "_exit_vehicle")
	brake_btn = _button("BRAKE", 540, 664, 200, 40, 18)
	brake_btn.visible = false
	brake_btn.connect("pressed", self, "_brake_on")
	brake_btn.connect("button_up", self, "_brake_off")

func _build_placement():
	place_box = VBoxContainer.new()
	place_box.rect_position = Vector2(540, 560)
	add_child(place_box)
	confirm_btn = _button("Confirm Build", 540, 560, 200, 48, 18)
	confirm_btn.visible = false
	confirm_btn.connect("pressed", self, "_confirm_place")
	cancel_btn = _button("Cancel Build", 540, 616, 200, 48, 18)
	cancel_btn.visible = false
	cancel_btn.connect("pressed", self, "_cancel_place")

# ------------------------------ input -----------------------------------

func _input(event):
	if GameState.ui_busy():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 576 and joy_touch == -1:
				joy_touch = event.index
				joy_origin = event.position
				joy_vec = Vector2.ZERO
			elif cam_touch == -1:
				cam_touch = event.index
				cam_last = event.position
		else:
			if event.index == joy_touch:
				joy_touch = -1
				joy_vec = Vector2.ZERO
				move_vector = Vector2.ZERO
			if event.index == cam_touch:
				cam_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joy_touch:
			var d = event.position - joy_origin
			if d.length() > 60.0:
				d = d.normalized() * 60.0
			joy_vec = d / 60.0
			move_vector = Vector2(joy_vec.x, -joy_vec.y)
		elif event.index == cam_touch:
			var dx = event.position.x - cam_last.x
			var dy = event.position.y - cam_last.y
			cam_last = event.position
			cam_yaw -= dx * 0.2
			cam_pitch = clamp(cam_pitch - dy * 0.15, -55.0, 30.0)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed and not mouse_down:
			mouse_down = true
			if event.position.x < 576:
				mouse_zone = "joy"
				joy_origin = event.position
				joy_vec = Vector2.ZERO
			else:
				mouse_zone = "cam"
				cam_last = event.position
		elif not event.pressed and mouse_down:
			mouse_down = false
			mouse_zone = ""
			joy_vec = Vector2.ZERO
			move_vector = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_down:
		if mouse_zone == "joy":
			var d = event.position - joy_origin
			if d.length() > 60.0:
				d = d.normalized() * 60.0
			joy_vec = d / 60.0
			move_vector = Vector2(joy_vec.x, -joy_vec.y)
		elif mouse_zone == "cam":
			var dx = event.position.x - cam_last.x
			var dy = event.position.y - cam_last.y
			cam_last = event.position
			cam_yaw -= dx * 0.2
			cam_pitch = clamp(cam_pitch - dy * 0.15, -55.0, 30.0)

func _draw_joy():
	if joy_touch != -1 or (mouse_down and mouse_zone == "joy"):
		joy_draw.draw_circle(joy_origin, 64.0, Color(1, 1, 1, 0.08))
		joy_draw.draw_circle(joy_origin, 64.0, Color(0.83, 0.68, 0.2, 0.5), false, 2.0)
		joy_draw.draw_circle(joy_origin + joy_vec * 60.0, 26.0, Color(0.83, 0.68, 0.2, 0.8))

func _jump():
	jump_pressed = true

func _toggle_run():
	run_flag = not run_flag
	sprint_btn.text = ("Sprint" if run_flag else "Walk")
	sprint_btn.modulate = (Color(1, 0.9, 0.5) if run_flag else Color(1, 1, 1))

# ------------------------------ context ---------------------------------

func _process(delta):
	var p = _player()
	joy_draw.update()
	if p == null:
		return
	bars["health"].value = p.health
	bars["stamina"].value = p.stamina
	bars["hunger"].value = p.hunger
	bars["thirst"].value = p.thirst
	money_label.text = "K " + str(GameState.money)
	var hh = int(GameState.time)
	var mm = int((GameState.time - hh) * 60.0)
	time_label.text = "Day " + str(GameState.day) + "  " + str(hh).pad_zeros(2) + ":" + str(mm).pad_zeros(2) + "\n" + GameState.season_name() + ", " + GameState.weather.capitalize() + ("  FESTIVAL!" if GameState.festival else "")
	_update_race_label()
	_update_drive_ui(p)
	_update_placement_ui()
	ctx_timer -= delta
	if ctx_timer <= 0.0:
		ctx_timer = 0.15
		_update_context(p)

func _update_race_label():
	var w = _world()
	if w != null and w.race_active:
		race_label.visible = true
		var total = 0
		var rdef = ItemDB.RACES.get(w.race_id, {})
		total = rdef.get("checkpoints", []).size()
		race_label.text = "RACE! Checkpoint " + str(w.race_cp + 1) + "/" + str(total) + "  Time " + str(stepify(w.race_time, 0.1)) + "s"
	else:
		race_label.visible = false

func _update_drive_ui(p):
	var driving = p.driving
	exit_btn.visible = driving
	brake_btn.visible = driving
	if not driving:
		brake_held = false
		return
	var w = _world()
	if w != null and w.current_vehicle != null:
		w.current_vehicle.brake = brake_held

var confirm_btn = null
var cancel_btn = null

func _update_placement_ui():
	var w = _world()
	var placing = w != null and w.placement_building != null
	if confirm_btn != null:
		confirm_btn.visible = placing
	if cancel_btn != null:
		cancel_btn.visible = placing

func _can_fish(p):
	if not GameState.has_item("fishing_rod"):
		return false
	var fwd = Vector3(-sin(deg2rad(p.cam_yaw)), 0, -cos(deg2rad(p.cam_yaw)))
	var px = p.translation.x + fwd.x * 2.5
	var pz = p.translation.z + fwd.z * 2.5
	return TerrainGen.is_water(px, pz)

func _update_context(p):
	for c in context_box.get_children():
		context_box.remove_child(c)
		c.queue_free()
	var target = p.current_target
	if target != null:
		var prompt = str(target.get_prompt(p))
		prompt_label.text = prompt
		var actions = target.get_actions(p)
		for a in actions:
			var b = _button(str(a), 0, 0, 160, 54, 16)
			context_box.add_child(b)
			b.connect("pressed", self, "_do_action", [target, str(a)])
	else:
		prompt_label.text = ""
		if _can_fish(p):
			var fish = _button("Fish", 0, 0, 160, 54, 16)
			context_box.add_child(fish)
			fish.connect("pressed", self, "_open_fish")
		if GameState.companion:
			var pet = _button("Companion: Stay/Follow", 0, 0, 160, 44, 13)
			context_box.add_child(pet)
			pet.connect("pressed", self, "_companion_cmd")

func _do_action(target, label):
	var p = _player()
	if p == null:
		return
	AudioSynth.play("click")
	target.action(label, p)

# ------------------------------ actions ---------------------------------

func _open_missions():
	_panel("missions", PanelMissionsScript).open()

func _open_map():
	_panel("map", PanelMapScript).open()

func _open_bag():
	_panel("inventory", PanelInventoryScript).open()

func _open_build():
	_panel("build", PanelBuildScript).open()

func _open_fish():
	_panel("fish", PanelFishScript).open()

func toggle_pause():
	_panel("pause", PanelPauseScript).toggle()

func open_dialogue(npc):
	_panel("dialogue", PanelDialogueScript).open_dialogue(npc)

func open_shop(shop_type, trader=false):
	_panel("shop", PanelShopScript).open_shop(shop_type, trader)

func open_seed_picker(plot_idx):
	if seed_panel != null:
		seed_panel.queue_free()
		seed_panel = null
		GameState.ui_open = max(0, GameState.ui_open - 1)
	seed_panel = Panel.new()
	seed_panel.add_style_override("panel", UiStyle.panel_style())
	seed_panel.rect_position = Vector2(400, 160)
	seed_panel.rect_min_size = Vector2(480, 340)
	add_child(seed_panel)
	var vb = VBoxContainer.new()
	seed_panel.add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	var t = Label.new()
	t.text = "Choose a seed for this plot"
	var tf = _font(20)
	if tf != null:
		t.add_font_override("font", tf)
	t.add_color_override("font_color", UiStyle.GOLD)
	vb.add_child(t)
	var keys = GameState.inventory.keys()
	var seed_count = 0
	for id in keys:
		if not id.begins_with("seed_"):
			continue
		seed_count += 1
		var row = HBoxContainer.new()
		vb.add_child(row)
		var l = Label.new()
		l.text = ItemDB.display_name(id) + " x" + str(GameState.inventory.count(id))
		var lf = _font(17)
		if lf != null:
			l.add_font_override("font", lf)
		l.add_color_override("font_color", UiStyle.TEXT)
		row.add_child(l)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b = Button.new()
		b.text = "Plant"
		UiStyle.style_button(b)
		row.add_child(b)
		b.connect("pressed", self, "_plant_seed", [plot_idx, id.substr(5)])
	if seed_count == 0:
		var none = Label.new()
		none.text = "No seeds in your bag. Buy some at the seed shop!"
		var nf = _font(16)
		if nf != null:
			none.add_font_override("font", nf)
		none.add_color_override("font_color", UiStyle.TEXT)
		none.autowrap = true
		vb.add_child(none)
	var cancel = Button.new()
	cancel.text = "Cancel"
	UiStyle.style_button(cancel)
	vb.add_child(cancel)
	cancel.connect("pressed", self, "_close_seed_picker")
	GameState.ui_open += 1

func _plant_seed(plot_idx, crop_id):
	var farms = get_tree().get_nodes_in_group("farm")
	if farms.size() > 0:
		farms[0].plant_seed(plot_idx, crop_id)
	_close_seed_picker()

func _close_seed_picker():
	if seed_panel != null:
		seed_panel.queue_free()
		seed_panel = null
		GameState.ui_open = max(0, GameState.ui_open - 1)

func _exit_vehicle():
	var w = _world()
	if w != null:
		w.exit_vehicle()
	_toggle_run_off()

func _toggle_run_off():
	if run_flag:
		run_flag = false
		sprint_btn.text = "Walk"
		sprint_btn.modulate = Color(1, 1, 1)

func _brake_on():
	brake_held = true

func _brake_off():
	brake_held = false

func _confirm_place():
	var w = _world()
	if w != null:
		w.confirm_placement()

func _cancel_place():
	var w = _world()
	if w != null:
		w.cancel_placement()

func _companion_cmd():
	var w = _world()
	if w != null:
		w.companion_command()

# ------------------------------ notifications ---------------------------

func _on_notify(title, text):
	var box = PanelContainer.new()
	box.add_style_override("panel", UiStyle.panel_style(Color(0.08, 0.09, 0.12, 0.92), 8))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notif_box.add_child(box)
	var vb = VBoxContainer.new()
	box.add_child(vb)
	var t = Label.new()
	t.text = str(title)
	var tf = _font(18)
	if tf != null:
		t.add_font_override("font", tf)
	t.add_color_override("font_color", UiStyle.GOLD)
	vb.add_child(t)
	var l = Label.new()
	l.text = str(text)
	var lf = _font(16)
	if lf != null:
		l.add_font_override("font", lf)
	l.add_color_override("font_color", UiStyle.TEXT)
	l.autowrap = true
	l.rect_min_size = Vector2(360, 0)
	vb.add_child(l)
	var timer = Timer.new()
	timer.wait_time = 3.5
	timer.one_shot = true
	box.add_child(timer)
	timer.connect("timeout", self, "_kill_notif", [box])
	timer.start()

func _kill_notif(box):
	if box != null and is_instance_valid(box):
		notif_box.remove_child(box)
		box.queue_free()
