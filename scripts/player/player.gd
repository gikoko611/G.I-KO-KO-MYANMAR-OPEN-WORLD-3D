extends KinematicBody
# The player: capsule body with SpringArm camera rig, virtual joystick
# movement, survival stats, swimming and interaction scanning.

const SPEED_WALK = 3.2
const SPEED_RUN = 5.6
const JUMP_SPEED = 4.6
const GRAVITY = 12.0
const SPAWN = Vector3(-14, 3.0, 64)

var health = 100.0
var stamina = 100.0
var hunger = 100.0
var thirst = 100.0
var driving = false
var inside_building = null
var current_target = null
var cam_yaw = 0.0
var cam_pitch = -12.0
var vel = Vector3.ZERO
var dead = false
var mesh_root = null
var cam_rig = null
var spring_arm = null
var step_acc = 0.0
var anim_phase = 0.0

func _ready():
	add_to_group("player")
	var cs = CollisionShape.new()
	var cap = CapsuleShape.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.translation = Vector3(0, 0.85, 0)
	add_child(cs)
	mesh_root = Props.player_mesh()
	add_child(mesh_root)
	cam_rig = Spatial.new()
	cam_rig.translation = Vector3(0, 1.55, 0)
	add_child(cam_rig)
	spring_arm = SpringArm.new()
	spring_arm.spring_length = 4.5
	spring_arm.add_excluded_object(get_rid())
	cam_rig.add_child(spring_arm)
	var cam = Camera.new()
	spring_arm.add_child(cam)
	translation = SPAWN
	translation.y = TerrainGen.height(SPAWN.x, SPAWN.z)

func _physics_process(delta):
	if dead:
		return
	var hud = _hud()
	if driving:
		var world = _world()
		if world != null and world.current_vehicle != null:
			translation = world.current_vehicle.translation
		_update_camera(hud)
		return
	var move = Vector2.ZERO
	var run = false
	if hud != null and not GameState.ui_busy():
		move = hud.move_vector
		run = hud.run_flag
	# movement relative to camera yaw
	var fwd = Vector3(-sin(deg2rad(cam_yaw)), 0, -cos(deg2rad(cam_yaw)))
	var right = Vector3(cos(deg2rad(cam_yaw)), 0, -sin(deg2rad(cam_yaw)))
	var dir = Vector3.ZERO
	if move.length() > 0.15:
		dir = (fwd * move.y + right * move.x).normalized()
	var max_speed = SPEED_RUN if run else SPEED_WALK
	vel.x = dir.x * max_speed
	vel.z = dir.z * max_speed
	# water / gravity
	var in_water = TerrainGen.is_water(translation.x, translation.z) and translation.y < TerrainGen.WATER_Y + 0.3
	if in_water:
		vel.y = 0.0
		translation.y = lerp(translation.y, TerrainGen.WATER_Y - 0.35, min(1.0, delta * 6.0))
		vel.x *= 0.55
		vel.z *= 0.55
		stamina = max(0.0, stamina - delta * 1.1)
	else:
		vel.y -= GRAVITY * delta
		if hud != null and hud.jump_pressed and translation.y <= TerrainGen.height(translation.x, translation.z) + 0.05:
			vel.y = JUMP_SPEED
			AudioSynth.play("jump")
		if hud != null:
			hud.jump_pressed = false
	move_and_slide(vel, Vector3.UP)
	# terrain guard
	var th = TerrainGen.height(translation.x, translation.z)
	if translation.y < th:
		translation.y = th
		vel.y = max(vel.y, 0.0)
	# facing + limb swing
	if dir.length() > 0.1:
		rotation.y = atan2(dir.x, dir.z)
		anim_phase += delta * (12.0 if run else 8.0)
		_swing_lims(sin(anim_phase))
		step_acc += max_speed * delta
		if step_acc > 1.7:
			step_acc = 0.0
			AudioSynth.play("step", -10.0)
	else:
		_swing_lims(0.0)
	# running costs stamina
	if run and dir.length() > 0.1:
		stamina = max(0.0, stamina - delta * 4.0)
	else:
		stamina = min(100.0, stamina + delta * 6.0)
	# survival decay (about a day and a half from full to empty)
	if inside_building == null:
		hunger = max(0.0, hunger - delta * 0.09)
		thirst = max(0.0, thirst - delta * 0.12)
	else:
		hunger = max(0.0, hunger - delta * 0.05)
		thirst = max(0.0, thirst - delta * 0.06)
	if hunger <= 0.0 or thirst <= 0.0:
		health = max(0.0, health - delta * 2.0)
	elif hunger > 40.0 and thirst > 40.0:
		health = min(100.0, health + delta * 0.5)
	if health <= 0.0:
		_die()
	_scan_interactables()
	_update_camera(hud)

func _swing_lims(s):
	var la = mesh_root.get_node_or_null("LArm")
	var ra = mesh_root.get_node_or_null("RArm")
	var ll = mesh_root.get_node_or_null("LLeg")
	var rl = mesh_root.get_node_or_null("RLeg")
	if la != null:
		la.rotation_degrees.x = s * 40.0
	if ra != null:
		ra.rotation_degrees.x = -s * 40.0
	if ll != null:
		ll.rotation_degrees.x = -s * 40.0
	if rl != null:
		rl.rotation_degrees.x = s * 40.0

func _update_camera(hud):
	if hud != null:
		cam_yaw = hud.cam_yaw
		cam_pitch = hud.cam_pitch
	cam_rig.rotation_degrees.y = cam_yaw
	spring_arm.rotation_degrees.x = cam_pitch

func _scan_interactables():
	current_target = null
	if driving or GameState.ui_busy():
		return
	var best = null
	var bd = 3.4
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n is Spatial:
			continue
		if not n.visible:
			continue
		if "driver" in n and n.driver:
			continue
		var d = translation.distance_to(n.global_transform.origin)
		if d < bd:
			bd = d
			best = n
	current_target = best

# ------------------------------ survival ---------------------------------

func eat(item_id):
	var d = ItemDB.item(item_id)
	var food = float(d.get("food", 10))
	hunger = min(100.0, hunger + food)
	health = min(100.0, health + food * 0.3)
	GameState.remove_item(item_id, 1)
	Events.emit_signal("player_ate", item_id)
	AudioSynth.play("eat")
	Events.emit_signal("notify", "Yummy!", "You ate " + ItemDB.display_name(item_id) + ".")

func drink_item(item_id):
	thirst = min(100.0, thirst + 40.0)
	GameState.remove_item(item_id, 1)
	Events.emit_signal("player_drank")
	AudioSynth.play("water")
	Events.emit_signal("notify", "Refreshing", "Thirst quenched.")

func try_sleep(save_too=false):
	if inside_building == null:
		Events.emit_signal("notify", "No Bed", "Sleep inside a house.")
		AudioSynth.play("deny")
		return
	if not (GameState.time >= 20.0 or GameState.time < 5.0):
		Events.emit_signal("notify", "Not Tired", "Come back after 20:00.")
		AudioSynth.play("deny")
		return
	Events.emit_signal("player_slept")
	health = 100.0
	stamina = 100.0
	hunger = max(hunger, 60.0)
	thirst = max(thirst, 60.0)
	get_tree().call_group("world", "sleep_to_morning")
	if save_too:
		SaveMgr.save_game(false)
	AudioSynth.play("accept")

func enter_building(b):
	inside_building = b
	b.build_interior()
	var ip = b.interior_pos()
	translation = Vector3(ip.x, ip.y + 0.2, ip.z + 1.2)
	vel = Vector3.ZERO
	AudioSynth.play("accept")

func exit_building(b):
	inside_building = null
	var op = b.outside_pos()
	translation = Vector3(op.x, TerrainGen.height(op.x, op.z) + 0.2, op.z)
	vel = Vector3.ZERO
	AudioSynth.play("accept")

func _die():
	if dead:
		return
	dead = true
	Events.emit_signal("player_died")
	Events.emit_signal("notify", "You Collapsed", "A kind villager carried you home...")
	var loss = min(GameState.money, 100)
	GameState.money -= loss
	yield(get_tree().create_timer(2.0), "timeout")
	dead = false
	health = 60.0
	stamina = 60.0
	hunger = 60.0
	thirst = 60.0
	translation = SPAWN
	translation.y = TerrainGen.height(SPAWN.x, SPAWN.z)

func _hud():
	var hs = get_tree().get_nodes_in_group("hud")
	if hs.size() > 0:
		return hs[0]
	return null

func _world():
	var ws = get_tree().get_nodes_in_group("world")
	if ws.size() > 0:
		return ws[0]
	return null

# ------------------------------ persistence ------------------------------

func save_dict():
	return {"x": translation.x, "y": translation.y, "z": translation.z, "health": health, "stamina": stamina, "hunger": hunger, "thirst": thirst, "yaw": cam_yaw, "pitch": cam_pitch}

func load_dict(d):
	translation = Vector3(float(d.get("x", SPAWN.x)), float(d.get("y", SPAWN.y)), float(d.get("z", SPAWN.z)))
	health = float(d.get("health", 100.0))
	stamina = float(d.get("stamina", 100.0))
	hunger = float(d.get("hunger", 100.0))
	thirst = float(d.get("thirst", 100.0))
	cam_yaw = float(d.get("yaw", 0.0))
	cam_pitch = float(d.get("pitch", -12.0))
	driving = false
	inside_building = null
