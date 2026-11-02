extends StaticBody
# Placeable building with actions and a lazy interior room (a sky platform
# with floor collision and an exit door).

const ExitDoorScript = preload("res://scripts/world/exit_door.gd")

var type = "house"
var level = 1
var condition = 100.0
var placed = false
var is_ghost = false
var interior_node = null
var door_node = null

func setup(bid):
	type = bid
	var cs = CollisionShape.new()
	var sb = BoxShape.new()
	sb.extents = Vector3(2.8, 1.8, 2.2)
	cs.shape = sb
	cs.translation = Vector3(0, 1.8, 0)
	add_child(cs)
	add_child(Props.building_mesh(bid))

func _ready():
	add_to_group("building")
	if not placed:
		make_ghost()

func make_ghost():
	is_ghost = true
	placed = false
	set_collision_layer(0)
	set_collision_mask(0)
	if is_in_group("interactable"):
		remove_from_group("interactable")

func place():
	is_ghost = false
	placed = true
	set_collision_layer(1)
	set_collision_mask(1)
	add_to_group("interactable")

func get_prompt(player=null):
	var nm = str(ItemDB.building(type).get("name", type))
	return nm + " Lv" + str(level)

func get_actions(player=null):
	if not placed:
		return []
	var acts = []
	var d = ItemDB.building(type)
	if str(d.get("interior", "")) != "":
		acts.append("Enter")
	if type == "house" or type == "farmhouse" or type == "guest_house":
		acts.append("Sleep & Save")
	if type == "animal_barn":
		acts.append("Feed All")
	if type == "workshop" or type == "garage":
		acts.append("Repair Vehicle")
	if type == "garage":
		acts.append("Refuel K50")
	if int(d.get("cap", 0)) > 0 and level < 3:
		acts.append("Upgrade")
	if condition < 99.0:
		acts.append("Repair K50")
	return acts

func action(label, player):
	if not placed:
		return
	if label == "Enter":
		player.enter_building(self)
	elif label == "Sleep & Save":
		player.enter_building(self)
		player.try_sleep(true)
	elif label == "Feed All":
		get_tree().call_group("world", "feed_all_animals")
	elif label == "Repair Vehicle":
		get_tree().call_group("world", "repair_vehicle")
	elif label == "Refuel K50":
		get_tree().call_group("world", "refuel_vehicle", 25.0)
	elif label.begins_with("Upgrade"):
		_upgrade()
	elif label.begins_with("Repair"):
		if GameState.spend_money(50):
			condition = 100.0
			AudioSynth.play("accept")
			Events.emit_signal("notify", "Repaired", "The building is sturdy again.")

func _upgrade():
	var d = ItemDB.building(type)
	var cost = int(d.get("cost", 0)) * level + 500
	if GameState.spend_money(cost):
		level += 1
		condition = 100.0
		Events.emit_signal("building_upgraded", type)
		AudioSynth.play("complete")
		Events.emit_signal("notify", "Upgraded!", str(d.get("name", type)) + " is now level " + str(level) + ".")
		get_tree().call_group("world", "_recalc_inventory_capacity")

func interior_pos():
	return translation + Vector3(0, 200.0, 0)

func outside_pos():
	return translation + Vector3(0, 0, 4.5)

func build_interior():
	if interior_node != null:
		return
	var kind = str(ItemDB.building(type).get("interior", type))
	interior_node = Props.interior(kind)
	interior_node.translation = interior_pos()
	var parent = get_parent()
	if parent != null:
		parent.add_child(interior_node)
		var floor_body = StaticBody.new()
		var fcs = CollisionShape.new()
		var fbox = BoxShape.new()
		fbox.extents = Vector3(5.0, 0.3, 5.0)
		fcs.shape = fbox
		fcs.translation = Vector3(0, -0.3, 0)
		floor_body.add_child(fcs)
		floor_body.translation = interior_pos()
		parent.add_child(floor_body)
		var light = OmniLight.new()
		light.omni_range = 10.0
		light.omni_energy = 0.9
		light.translation = interior_pos() + Vector3(0, 2.6, 0)
		parent.add_child(light)
		door_node = ExitDoorScript.new()
		door_node.building = self
		door_node.translation = interior_pos() + Vector3(0, 0, 4.2)
		parent.add_child(door_node)

func save_dict():
	return {"type": type, "x": translation.x, "y": translation.y, "z": translation.z, "rot": rotation.y, "level": level, "condition": condition}

func load_dict(d):
	setup(str(d.get("type", "house")))
	translation = Vector3(float(d.get("x", 0)), float(d.get("y", 0)), float(d.get("z", 0)))
	rotation.y = float(d.get("rot", 0.0))
	level = int(d.get("level", 1))
	condition = float(d.get("condition", 100.0))
	placed = true
