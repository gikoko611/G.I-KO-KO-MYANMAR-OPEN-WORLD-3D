extends Spatial
# One farm plot: empty -> plowed -> planted -> ripe. Visualized with simple
# meshes, grown by the farm.

var index = 0
var plowed = false
var crop_id = ""
var growth = 0.0
var watered = false
var fertilized = false
var soil = null
var plant_node = null

func _ready():
	soil = MeshInstance.new()
	soil.mesh = Props.box_mesh(2.2, 0.25, 2.2)
	add_child(soil)
	_refresh()

func _refresh():
	if soil == null:
		return
	if plowed:
		soil.material_override = Props.mat(Color(0.3, 0.2, 0.1))
	else:
		soil.material_override = Props.mat(Color(0.42, 0.34, 0.2))
	if plant_node != null:
		plant_node.queue_free()
		plant_node = null
	if crop_id != "":
		plant_node = MeshInstance.new()
		plant_node.mesh = Props.cone_mesh(0.5, 1.2)
		var c = Color(0.25, 0.55, 0.15)
		if growth >= 1.0:
			c = Color(0.85, 0.75, 0.2)
		elif fertilized:
			c = c.lightened(0.1)
		plant_node.material_override = Props.mat(c)
		var sc = 0.25 + growth * 0.75
		plant_node.scale = Vector3(sc, sc, sc)
		add_child(plant_node)

func get_prompt(player=null):
	if crop_id != "":
		var cname = str(ItemDB.crop(crop_id).get("name", crop_id))
		if growth >= 1.0:
			return "Ripe " + cname + " - harvest!"
		return "Growing " + cname + " (" + str(int(growth * 100)) + "%)"
	if plowed:
		return "Plowed plot"
	return "Empty plot"

func get_actions(player=null):
	var acts = []
	if not plowed:
		acts.append("Plow")
	elif crop_id == "":
		acts.append("Plant")
	if crop_id != "":
		if not watered:
			acts.append("Water")
		if not fertilized:
			acts.append("Fertilize K15")
		if growth >= 1.0:
			acts.append("Harvest")
	return acts

func action(label, player):
	if label == "Plow":
		plowed = true
		Events.emit_signal("field_plowed")
		GameState.add_xp(2)
		AudioSynth.play("plow")
		_refresh()
	elif label == "Plant":
		get_tree().call_group("hud", "open_seed_picker", index)
	elif label == "Water":
		water()
	elif label == "Fertilize K15":
		if GameState.spend_money(15):
			fertilized = true
			Events.emit_signal("crop_fertilized")
			AudioSynth.play("water")
			_refresh()
	elif label == "Harvest":
		_harvest()

func plant(cid):
	crop_id = cid
	growth = 0.0
	watered = false
	fertilized = false
	Events.emit_signal("crop_planted", cid)
	AudioSynth.play("plant")
	_refresh()

func water():
	if crop_id == "":
		return
	watered = true
	Events.emit_signal("plot_watered")
	AudioSynth.play("water")
	_refresh()

func _harvest():
	if crop_id == "":
		return
	var c = ItemDB.crop(crop_id)
	var yield_n = 2 + (1 if fertilized else 0)
	GameState.add_item(crop_id, yield_n)
	Events.emit_signal("crop_harvested", crop_id)
	GameState.add_xp(int(c.get("xp", 5)))
	AudioSynth.play("harvest")
	crop_id = ""
	growth = 0.0
	watered = false
	fertilized = false
	_refresh()

func grow(delta_days):
	if crop_id == "":
		return
	var c = ItemDB.crop(crop_id)
	var rate = 1.0 / max(0.1, float(c.get("grow", 1.0)))
	var seasons = c.get("seasons", [0, 1, 2, 3])
	if seasons.find(ItemDB.season(GameState.day)) == -1:
		rate *= 0.35
	if not watered:
		rate *= 0.5
	if fertilized:
		rate *= 1.5
	var before = growth
	growth = min(1.0, growth + delta_days * rate)
	if int(before * 4.0) != int(growth * 4.0):
		_refresh()

func day_tick():
	watered = false
	_refresh()

func save_dict():
	return {"plowed": plowed, "crop": crop_id, "growth": growth, "watered": watered, "fert": fertilized}

func load_dict(d):
	plowed = bool(d.get("plowed", false))
	crop_id = str(d.get("crop", ""))
	growth = float(d.get("growth", 0.0))
	watered = bool(d.get("watered", false))
	fertilized = bool(d.get("fert", false))
	_refresh()
