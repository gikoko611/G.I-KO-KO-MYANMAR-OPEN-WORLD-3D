extends "res://scripts/ui/panel_base.gd"
# Inventory panel: grid of owned items with Use / Eat / Drink / Drop actions.

var list_box = null
var desc_label = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(560, 460)
	rect_position = Vector2(-280, -230)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	var title = ui_title("Inventory")
	vb.add_child(title)
	var cap_label = ui_label("", 15)
	vb.add_child(cap_label)
	cap_label.name = "CapLabel"
	list_box = VBoxContainer.new()
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)
	vb.add_child(scroll)
	desc_label = ui_label("Select an item.", 15, Color(0.7, 0.7, 0.65))
	desc_label.autowrap = true
	desc_label.rect_min_size = Vector2(500, 44)
	vb.add_child(desc_label)
	var close = ui_button("Close")
	vb.add_child(close)
	close.connect("pressed", self, "close")

func open():
	.open()
	_refresh()

func _process(_delta):
	if visible:
		var cl = get_node_or_null("VBoxContainer/CapLabel")
		if cl != null:
			cl.text = "Space: " + str(GameState.inventory.total()) + " / " + str(GameState.inventory.capacity)

func _refresh():
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var keys = GameState.inventory.keys()
	keys.sort()
	if keys.size() == 0:
		list_box.add_child(ui_label("Your bag is empty.", 16, Color(0.7, 0.7, 0.65)))
		return
	for id in keys:
		var row = HBoxContainer.new()
		list_box.add_child(row)
		var nm = ui_label(ItemDB.display_name(id) + " x" + str(GameState.inventory.count(id)), 17)
		nm.rect_min_size = Vector2(220, 0)
		row.add_child(nm)
		var kind = ItemDB.kind_of(id)
		if kind == "food":
			var eat = ui_button("Eat")
			row.add_child(eat)
			eat.connect("pressed", self, "_use_item", [id, "eat"])
		elif kind == "drink":
			var drink = ui_button("Drink")
			row.add_child(drink)
			drink.connect("pressed", self, "_use_item", [id, "drink"])
		elif id.begins_with("seed_"):
			var hint = ui_label("Plant at the farm", 14, Color(0.6, 0.6, 0.55))
			row.add_child(hint)
		var drop = ui_button("Drop")
		row.add_child(drop)
		drop.connect("pressed", self, "_use_item", [id, "drop"])
		var info = ui_button("?")
		row.add_child(info)
		info.connect("pressed", self, "_show_desc", [id])

func _use_item(id, mode):
	if mode == "eat":
		var ps = get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			ps[0].eat(id)
	elif mode == "drink":
		var ps2 = get_tree().get_nodes_in_group("player")
		if ps2.size() > 0:
			ps2[0].drink_item(id)
	elif mode == "drop":
		GameState.remove_item(id, 1)
		Events.emit_signal("notify", "Dropped", "You dropped 1 " + ItemDB.display_name(id) + ".")
	_refresh()

func _show_desc(id):
	var d = ItemDB.item(id)
	desc_label.text = ItemDB.display_name(id) + ": " + str(d.get("desc", ""))
