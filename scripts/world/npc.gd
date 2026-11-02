extends KinematicBody
# Villager: walks a daily schedule between home and work, can be talked to.

var npc_id = ""
var def = {}
var is_trader = false
var dlg_open = false
var line_idx = 0
var home = Vector3.ZERO
var work = Vector3.ZERO
var move_target = Vector3.ZERO
var speed = 1.7
var mesh_root = null

func setup(id, trader=false):
	npc_id = id
	is_trader = trader
	def = ItemDB.npc(id)
	var hp = ItemDB.npc_pos(id, "home")
	var wp = ItemDB.npc_pos(id, "work")
	home = Vector3(hp[0], TerrainGen.height(hp[0], hp[1]), hp[1])
	work = Vector3(wp[0], TerrainGen.height(wp[0], wp[1]), wp[1])
	translation = home
	move_target = work
	var cs = CollisionShape.new()
	var cap = CapsuleShape.new()
	cap.radius = 0.32
	cap.height = 1.7
	cs.shape = cap
	cs.translation = Vector3(0, 0.85, 0)
	add_child(cs)
	mesh_root = Props.human(def.get("color", Color(0.4, 0.5, 0.7)), Color(0.25, 0.3, 0.45))
	add_child(mesh_root)

func _ready():
	add_to_group("interactable")
	add_to_group("npc")

func _physics_process(_delta):
	if dlg_open:
		return
	var t = GameState.time
	var want = home
	if t >= 6.0 and t < 18.0:
		want = work
	var dx = want.x - translation.x
	var dz = want.z - translation.z
	var d = sqrt(dx * dx + dz * dz)
	if d > 2.0:
		var dir = Vector3(dx / d, 0, dz / d)
		move_and_slide(dir * speed, Vector3.UP)
		var ang = atan2(dir.x, dir.z)
		var cur = mesh_root.rotation.y
		while ang - cur > PI:
			ang -= TAU
		while ang - cur < -PI:
			ang += TAU
		mesh_root.rotation.y = cur + (ang - cur) * 0.15
	# terrain fall guard
	var th = TerrainGen.height(translation.x, translation.z)
	if translation.y < th - 1.5:
		translation.y = th
	elif translation.y > th + 3.0:
		translation.y = th

func get_prompt(player=null):
	return "Talk to " + str(def.get("name", npc_id))

func get_actions(player=null):
	return ["Talk"]

func action(label, player):
	if label == "Talk":
		dlg_open = true
		Events.emit_signal("npc_talked", npc_id)
		get_tree().call_group("hud", "open_dialogue", self)

func next_line():
	var lines = def.get("lines", ["Hello!"])
	if lines.size() == 0:
		return "Hello!"
	var l = str(lines[line_idx % lines.size()])
	line_idx += 1
	return l

func shop_type():
	return str(def.get("shop", ""))

func close_dialogue():
	dlg_open = false

func save_dict():
	return {"id": npc_id, "x": translation.x, "z": translation.z}

func load_dict(d):
	translation.x = float(d.get("x", translation.x))
	translation.z = float(d.get("z", translation.z))
	translation.y = TerrainGen.height(translation.x, translation.z)
