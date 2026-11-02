extends Spatial
# The family farm: 24 plots in a 6x4 grid. The whole farm is one interactable;
# the nearest plot receives the action.

const PlotScript = preload("res://scripts/world/plot.gd")

var plots = []

func _ready():
	add_to_group("interactable")
	add_to_group("farm")
	for j in range(4):
		for i in range(6):
			var p = PlotScript.new()
			p.index = plots.size()
			p.translation = Vector3((i - 2.5) * 2.4, 0, j * 2.4)
			add_child(p)
			plots.append(p)

func nearest_plot(player):
	if player == null:
		var ps = get_tree().get_nodes_in_group("player")
		if ps.size() > 0:
			player = ps[0]
	if player == null:
		return null
	var best = null
	var bd = 2.4
	for p in plots:
		var pp = p.global_transform.origin
		var d = Vector2(pp.x - player.translation.x, pp.z - player.translation.z).length()
		if d < bd:
			bd = d
			best = p
	return best

func get_prompt(player=null):
	var p = nearest_plot(player)
	if p == null:
		return "The Family Farm"
	return p.get_prompt()

func get_actions(player=null):
	var p = nearest_plot(player)
	if p == null:
		return []
	return p.get_actions(player)

func action(label, player):
	var p = nearest_plot(player)
	if p == null:
		return
	p.action(label, player)

func plant_seed(idx, crop_id):
	if idx < 0 or idx >= plots.size():
		return
	var p = plots[idx]
	if p.crop_id != "":
		Events.emit_signal("notify", "Plot Busy", "This plot already has a crop.")
		return
	if GameState.remove_item("seed_" + crop_id, 1):
		p.plant(crop_id)
	else:
		Events.emit_signal("notify", "No Seeds", "You have no " + ItemDB.display_name("seed_" + crop_id) + " left.")

func grow(delta_days):
	for p in plots:
		p.grow(delta_days)

func day_tick():
	for p in plots:
		p.day_tick()

func water_all():
	for p in plots:
		if p.crop_id != "":
			p.watered = true
			p._refresh()

func save_dict():
	var arr = []
	for p in plots:
		arr.append(p.save_dict())
	return arr

func load_dict(arr):
	for i in range(plots.size()):
		if i < arr.size():
			plots[i].load_dict(arr[i])
