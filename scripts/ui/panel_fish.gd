extends "res://scripts/ui/panel_base.gd"
# Fishing minigame panel: cast, wait for the bite (!), hook in time.

var state = "idle" # idle / casting / bite
var timer = 0.0
var bite_window = 0.9
var status_label = null
var cast_btn = null
var hook_btn = null
var meter = null
var meter_pos = 0.0
var meter_dir = 1.0

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(460, 320)
	rect_position = Vector2(-230, -160)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	vb.add_child(ui_title("Fishing"))
	status_label = ui_label("Cast your line into the water.", 17)
	status_label.autowrap = true
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(status_label)
	meter = Control.new()
	meter.rect_min_size = Vector2(0, 34)
	vb.add_child(meter)
	meter.connect("draw", self, "_draw_meter")
	cast_btn = ui_button("Cast")
	vb.add_child(cast_btn)
	cast_btn.connect("pressed", self, "_cast")
	hook_btn = ui_button("HOOK NOW!")
	hook_btn.visible = false
	vb.add_child(hook_btn)
	hook_btn.connect("pressed", self, "_hook")
	var close = ui_button("Stop Fishing")
	vb.add_child(close)
	close.connect("pressed", self, "close")

func close():
	state = "idle"
	.close()

func _cast():
	if state != "idle":
		return
	AudioSynth.play("splash")
	state = "casting"
	timer = rand_range(1.5, 4.0)
	status_label.text = "You cast the line... watch the float."
	cast_btn.visible = false

func _process(delta):
	if not visible:
		return
	meter_pos += meter_dir * delta * 1.4
	if meter_pos > 1.0:
		meter_pos = 1.0
		meter_dir = -1.0
	elif meter_pos < 0.0:
		meter_pos = 0.0
		meter_dir = 1.0
	if state == "casting":
		timer -= delta
		if timer <= 0.0:
			state = "bite"
			timer = bite_window
			hook_btn.visible = true
			AudioSynth.play("bite")
			status_label.text = "!!! Something is biting - HOOK NOW!"
	elif state == "bite":
		timer -= delta
		if timer <= 0.0:
			_missed()
	meter.update()

func _draw_meter():
	var w = meter.rect_size.x
	meter.draw_rect(Rect2(0, 8, w, 18), Color(0.1, 0.1, 0.08), true)
	if state == "bite":
		meter.draw_rect(Rect2(0, 8, w, 18), Color(0.5, 0.1, 0.05), true)
	meter.draw_circle(Vector2(w * 0.5, 17), 9.0, Color(0.9, 0.8, 0.4))
	var zone = 0.5 + (meter_pos - 0.5) * 0.0
	var px = w * (0.5 - zone * 0.18) + w * zone * 0.36 * meter_pos
	meter.draw_circle(Vector2(px, 17), 7.0, Color(0.2, 0.8, 1.0))

func _hook():
	if state != "bite":
		return
	hook_btn.visible = false
	state = "idle"
	cast_btn.visible = true
	var zone_pos = meter_pos
	if abs(zone_pos - 0.5) < 0.16:
		_success()
	else:
		_missed()

func _missed():
	state = "idle"
	hook_btn.visible = false
	cast_btn.visible = true
	AudioSynth.play("deny")
	status_label.text = "The fish got away... cast again!"

func _success():
	AudioSynth.play("harvest")
	var roll = randf()
	var total = 0.0
	for fid in ItemDB.FISH.keys():
		total += float(ItemDB.FISH[fid].get("rarity", 0.5))
	var pick = "shrimp"
	var acc = 0.0
	for fid in ItemDB.FISH.keys():
		var f = ItemDB.FISH[fid]
		acc += float(f.get("rarity", 0.5)) / total
		if roll <= acc:
			pick = fid
			break
	var f2 = ItemDB.FISH[pick]
	var weight = rand_range(float(f2.get("wmin", 0.3)), float(f2.get("wmax", 2.0)))
	GameState.add_item(pick, 1)
	Events.emit_signal("fish_caught", pick, weight)
	if weight >= 3.0:
		Events.emit_signal("generic", "big_fish", 1)
	Events.emit_signal("notify", "Caught a Fish!", str(f2["name"]) + ", " + str(stepify(weight, 0.1)) + " kg!")
	status_label.text = "You caught a " + str(f2["name"]) + " (" + str(stepify(weight, 0.1)) + " kg)! Cast again?"
