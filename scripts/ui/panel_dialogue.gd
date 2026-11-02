extends "res://scripts/ui/panel_base.gd"
# Dialogue panel: talk to an NPC, continue lines, shop, deliver quest items.

const MD = preload("res://scripts/missions/mission_data.gd")

var npc = null
var name_label = null
var line_label = null
var hb = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(540, 300)
	rect_position = Vector2(-270, -150)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	name_label = ui_title("...")
	vb.add_child(name_label)
	line_label = ui_label("", 18)
	line_label.autowrap = true
	line_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(line_label)
	hb = HBoxContainer.new()
	vb.add_child(hb)

func open_dialogue(n):
	npc = n
	open()
	name_label.text = str(npc.def.get("name", npc.npc_id)) + " - " + str(npc.def.get("role", ""))
	line_label.text = npc.next_line()
	_refresh_buttons()

func _refresh_buttons():
	for c in hb.get_children():
		hb.remove_child(c)
		c.queue_free()
	var next = ui_button("Continue")
	hb.add_child(next)
	next.connect("pressed", self, "_next")
	if npc.shop_type() != "":
		var shop = ui_button("Shop")
		hb.add_child(shop)
		shop.connect("pressed", self, "_open_shop")
	var deliverables = _deliverables()
	if deliverables.size() > 0:
		var dlb = ui_button("Deliver Item")
		hb.add_child(dlb)
		dlb.connect("pressed", self, "_deliver")
	var leave = ui_button("Leave")
	hb.add_child(leave)
	leave.connect("pressed", self, "_leave")

func _next():
	AudioSynth.play("click")
	line_label.text = npc.next_line()
	_refresh_buttons()

func _open_shop():
	AudioSynth.play("click")
	get_tree().call_group("hud", "open_shop", npc.shop_type(), npc.is_trader)

func _deliverables():
	var out = []
	for mid in Missions.active.keys():
		var d = MD.DEFS.get(mid, null)
		if d == null:
			continue
		if str(d.get("giver", "")) != npc.npc_id:
			continue
		for o in d.get("objectives", []):
			if str(o.get("type", "")) == "item_delivered":
				var item_id = str(o.get("target", ""))
				if GameState.has_item(item_id):
					out.append(item_id)
	return out

func _deliver():
	var deliverables = _deliverables()
	if deliverables.size() == 0:
		line_label.text = "You have nothing they need right now."
		return
	var item_id = deliverables[0]
	if GameState.remove_item(item_id, 1):
		Events.emit_signal("item_delivered", item_id)
		Events.emit_signal("notify", "Delivered", "You gave 1 " + ItemDB.display_name(item_id) + " to " + str(npc.def.get("name", "")) + ".")
		AudioSynth.play("accept")
		line_label.text = "Oh! Thank you, this is exactly what I needed."
	_refresh_buttons()

func _leave():
	AudioSynth.play("click")
	npc.close_dialogue()
	close()
