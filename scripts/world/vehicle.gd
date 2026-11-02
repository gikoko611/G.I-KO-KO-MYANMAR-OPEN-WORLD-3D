extends KinematicBody
# Drivable vehicle: arcade kinematic physics, fuel and health, boat mode
# restricted to water. Wheels are children of the procedural mesh named
# "Wheel*" and spin while driving.

var id = "bicycle"
var def = {}
var driver = false
var speed = 0.0
var fuel = 100.0
var health = 100.0
var dist_total = 0.0
var drive_input = Vector2.ZERO
var brake = false
var is_boat = false
var wheels = []
var dist_acc = 0.0

func setup(vid):
	id = vid
	def = ItemDB.vehicle(vid)
	is_boat = bool(def.get("water", false))
	var cs = CollisionShape.new()
	var sb = BoxShape.new()
	sb.extents = Vector3(1.2, 0.6, 1.8)
	cs.shape = sb
	cs.translation = Vector3(0, 0.7, 0)
	add_child(cs)
	add_child(Props.vehicle_mesh(vid))
	var mesh_root = get_child(get_child_count() - 1)
	for c in mesh_root.get_children():
		if c.name.begins_with("Wheel"):
			wheels.append(c)

func _ready():
	add_to_group("interactable")
	add_to_group("vehicle")

func _physics_process(delta):
	var max_speed = max(0.5, float(def.get("speed", 8.0)))
	var accel = float(def.get("accel", 4.0))
	if driver:
		if fuel <= 0.0:
			drive_input.y = 0.0
			Events.emit_signal("notify", "Out of Fuel", "Refuel at the garage or fuel stall.")
			AudioSynth.play("deny")
		if brake:
			speed = lerp(speed, 0.0, min(1.0, delta * 4.0))
		else:
			speed += drive_input.y * accel * delta
			speed = clamp(speed, -max_speed * 0.4, max_speed)
			fuel = max(0.0, fuel - abs(drive_input.y) * delta * 0.25)
		# steering scales with speed
		var sfactor = clamp(abs(speed) / max_speed, 0.0, 1.0)
		if abs(speed) > 0.3:
			rotate_y(-drive_input.x * delta * 1.8 * (0.2 + sfactor) * sign(speed))
		if is_boat:
			var fwd = -transform.basis.z
			var next = translation + fwd * speed * delta
			if TerrainGen.is_water(next.x, next.z):
				translation = next
				translation.y = TerrainGen.WATER_Y + 0.25
			else:
				speed = lerp(speed, 0.0, delta * 5.0)
		else:
			var vel = -transform.basis.z * speed
			vel.y -= 9.8 * delta
			move_and_slide(vel, Vector3.UP)
			var th = TerrainGen.height(translation.x, translation.z)
			if translation.y < th:
				translation.y = th
			if TerrainGen.is_water(translation.x, translation.z):
				speed *= max(0.0, 1.0 - delta * 2.0)
		dist_acc += abs(speed) * delta
		if dist_acc >= 10.0:
			Events.emit_signal("distance_driven", int(dist_acc))
			dist_total += dist_acc
			dist_acc = 0.0
		AudioSynth.set_engine(true, clamp(abs(speed) / max_speed, 0.05, 1.0))
		for w in wheels:
			w.rotation_degrees.x += speed * delta * 45.0
	else:
		if speed != 0.0:
			speed = 0.0
			AudioSynth.set_engine(false, 0.0)

func refuel(amount):
	fuel = min(100.0, fuel + amount)

func repair():
	if health >= 100.0:
		Events.emit_signal("notify", "Like New", "This vehicle needs no repairs.")
		return
	health = 100.0
	AudioSynth.play("accept")
	Events.emit_signal("notify", "Repaired", str(def.get("name", id)) + " is fully repaired.")

func get_prompt(player=null):
	var nm = str(def.get("name", id))
	if driver:
		return nm + " (driving)"
	return nm + " - fuel " + str(int(fuel)) + "%"

func get_actions(player=null):
	if driver:
		return []
	return ["Drive"]

func action(label, player):
	if label == "Drive":
		get_tree().call_group("world", "enter_vehicle", self)

func save_dict():
	return {"id": id, "x": translation.x, "y": translation.y, "z": translation.z, "rot": rotation.y, "fuel": fuel, "health": health}

func load_dict(d):
	setup(str(d.get("id", id)))
	fuel = float(d.get("fuel", 100.0))
	health = float(d.get("health", 100.0))
	translation = Vector3(float(d.get("x", 0)), float(d.get("y", 0)), float(d.get("z", 0)))
	rotation.y = float(d.get("rot", 0.0))
