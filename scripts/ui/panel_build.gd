extends "res://scripts/ui/panel_base.gd"
# Build panel: pick a building, then the world enters placement mode.

var list_box = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(600, 480)
	rect_position = Vector2(-300, -240)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	vb.add_child(ui_title("Build"))
	var hint = ui_label("Pick a building, then walk to a good spot and press Confirm. You need money and materials.", 15, Color(0.8, 0.8, 0.75))
	hint.autowrap = true
	vb.add_child(hint)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_box = VBoxContainer.new()
	scroll.add_child(list_box)
	vb.add_child(scroll)
	var close = ui_button("Close")
	vb.add_child(close)
	close.connect("pressed", self, "close")

func open():
	.open()
	_refresh()

func _refresh():
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	for bid in ItemDB.BUILDINGS.keys():
		if bid == "house":
			continue
		var b = ItemDB.building(bid)
		var row = HBoxContainer.new()
		list_box.add_child(row)
		var mats = b.get("mats", {})
		var mats_str = ""
		for m in mats.keys():
			mats_str += str(mats[m]) + " " + ItemDB.display_name(m) + ", "
		if mats_str != "":
			mats_str = mats_str.substr(0, mats_str.length() - 2)
		var nm = ui_label(str(b["name"]) + "  (storage cap +" + str(b.get("cap", 0)) + ")\nCost K " + str(b["cost"]) + (", Materials: " + mats_str if mats_str != "" else ""), 16)
		nm.rect_min_size = Vector2(430, 0)
		nm.autowrap = true
		row.add_child(nm)
		var place = ui_button("Place")
		row.add_child(place)
		place.connect("pressed", self, "_place", [bid])

func _place(bid):
	AudioSynth.play("click")
	get_tree().call_group("world", "start_placement", bid)
	close()
