extends "res://scripts/ui/panel_base.gd"
# Shop panel: buy and sell by shop type (seed / vehicle / animal / general /
# market / fuel). Festival gives -10% buy and +10% sell prices.

var shop_type = "general"
var is_trader = false
var list_box = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(600, 480)
	rect_position = Vector2(-300, -240)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	var title = ui_title("Shop")
	title.name = "ShopTitle"
	vb.add_child(title)
	list_box = VBoxContainer.new()
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)
	vb.add_child(scroll)
	var money_label = ui_label("", 16, Color(0.9, 0.8, 0.4))
	money_label.name = "MoneyLabel"
	vb.add_child(money_label)
	var close = ui_button("Leave")
	vb.add_child(close)
	close.connect("pressed", self, "close")

func open_shop(stype, trader=false):
	shop_type = stype
	is_trader = trader
	open()
	_refresh()

func open():
	.open()

func _process(_delta):
	if not visible:
		return
	var ml = get_node_or_null("VBoxContainer/MoneyLabel")
	if ml != null:
		ml.text = "Your money: K " + str(GameState.money) + ("  (FESTIVAL PRICES!)" if GameState.festival else "")

func _refresh():
	for c in list_box.get_children():
		list_box.remove_child(c)
		c.queue_free()
	var t = get_node_or_null("VBoxContainer/ShopTitle")
	if t != null:
		t.text = "Shop - " + shop_type + (" (Wandering Trader)" if is_trader else "")
	if shop_type == "seed":
		for cid in ItemDB.CROPS.keys():
			var c = ItemDB.CROPS[cid]
			var price = _buy_price(int(c["seed"]))
			_add_row("Seeds: " + str(c["name"]) + " (grows " + str(c["grow"]) + "d)", "K " + str(price), cid, "seed")
	elif shop_type == "vehicle":
		for vid in ItemDB.VEHICLES.keys():
			var v = ItemDB.VEHICLES[vid]
			_add_row(str(v["name"]) + " - top speed " + str(v["speed"]) + " m/s", "K " + str(v["cost"]), vid, "vehicle")
	elif shop_type == "animal":
		for aid in ItemDB.ANIMALS.keys():
			var a = ItemDB.ANIMALS[aid]
			_add_row(str(a["name"]), "K " + str(a["cost"]), aid, "animal")
	elif shop_type == "general":
		for gid in ["water_bottle", "cooked_rice", "fish_grilled", "curry", "tea_leaf", "fishing_rod"]:
			var it = ItemDB.item(gid)
			_add_row(str(it["name"]) + " - " + str(it.get("desc", "")), "K " + str(_buy_price(int(it.get("buy", 0)))), gid, "item")
	elif shop_type == "market":
		var keys = GameState.inventory.keys()
		keys.sort()
		if keys.size() == 0:
			list_box.add_child(ui_label("Nothing to sell. Harvest, gather or fish first!", 16, Color(0.7, 0.7, 0.65)))
		for id in keys:
			var price = _sell_price(ItemDB.sell_price(id))
			_add_sell_row(ItemDB.display_name(id) + " x" + str(GameState.inventory.count(id)), "K " + str(price), id)
	elif shop_type == "fuel":
		_add_row("Fuel +25 (fills nearest vehicle)", "K 50", "fuel", "fuel")

func _add_row(label_text, price_text, id, kind):
	var row = HBoxContainer.new()
	list_box.add_child(row)
	var nm = ui_label(label_text, 16)
	nm.rect_min_size = Vector2(380, 0)
	nm.autowrap = true
	row.add_child(nm)
	row.add_child(ui_label(price_text, 16, Color(0.9, 0.8, 0.4)))
	var b = ui_button("Buy")
	row.add_child(b)
	b.connect("pressed", self, "_buy", [id, kind])

func _add_sell_row(label_text, price_text, id):
	var row = HBoxContainer.new()
	list_box.add_child(row)
	var nm = ui_label(label_text, 16)
	nm.rect_min_size = Vector2(380, 0)
	row.add_child(nm)
	row.add_child(ui_label(price_text, 16, Color(0.9, 0.8, 0.4)))
	var b = ui_button("Sell 1")
	row.add_child(b)
	b.connect("pressed", self, "_sell", [id])
	var b_all = ui_button("Sell All")
	row.add_child(b_all)
	b_all.connect("pressed", self, "_sell_all", [id])

func _buy_price(base):
	var p = base
	if GameState.festival:
		p = int(ceil(base * 0.9))
	return p

func _sell_price(base):
	var p = base
	if GameState.festival:
		p = int(ceil(base * 1.1))
	return p

func _buy(id, kind):
	AudioSynth.play("click")
	if kind == "seed":
		var price = _buy_price(int(ItemDB.CROPS[id]["seed"]))
		if not GameState.spend_money(price):
			return
		GameState.add_item("seed_" + id, 1)
		Events.emit_signal("seed_bought", id)
		Events.emit_signal("notify", "Bought", "1 " + ItemDB.display_name("seed_" + id) + " for K " + str(price) + ".")
	elif kind == "vehicle":
		var price2 = int(ItemDB.VEHICLES[id]["cost"])
		if not GameState.spend_money(price2):
			return
		Events.emit_signal("vehicle_bought", id)
		AudioSynth.play("coin")
	elif kind == "animal":
		var price3 = int(ItemDB.ANIMALS[id]["cost"])
		if not GameState.spend_money(price3):
			return
		Events.emit_signal("animal_bought", id)
		AudioSynth.play("chirp")
	elif kind == "fuel":
		if not GameState.spend_money(50):
			return
		get_tree().call_group("world", "refuel_vehicle", 25.0)
	elif kind == "item":
		var price4 = _buy_price(int(ItemDB.item(id).get("buy", 0)))
		if not GameState.spend_money(price4):
			return
		GameState.add_item(id, 1)
		Events.emit_signal("item_bought", id)
		Events.emit_signal("notify", "Bought", ItemDB.display_name(id) + " for K " + str(price4) + ".")
	if is_trader:
		Events.emit_signal("generic", "trader_buy", 1)
	_refresh()

func _sell(id):
	var price = _sell_price(ItemDB.sell_price(id))
	if GameState.remove_item(id, 1):
		GameState.add_money(price)
		_emit_sold(id, 1)
		AudioSynth.play("coin")
	_refresh()

func _sell_all(id):
	var count = GameState.inventory.count(id)
	if count <= 0:
		return
	var price = _sell_price(ItemDB.sell_price(id)) * count
	if GameState.remove_item(id, count):
		GameState.add_money(price)
		_emit_sold(id, count)
		AudioSynth.play("coin")
	_refresh()

func _emit_sold(id, n):
	if ItemDB.CROPS.has(id):
		Events.emit_signal("crop_sold", id, n)
	else:
		Events.emit_signal("item_sold", id, n)
