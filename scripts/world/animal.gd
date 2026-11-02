extends KinematicBody
# Farm animal or wild creature: wanders around an anchor, can be fed and
# milked. Dogs/cats become companions, wild boars flee from the player.

var species = "chicken"
var def = {}
var fed = false
var milked = false
var growth = 1.0
var companion = false
var staying = false
var wild = false
var wild_done = false
var anchor = Vector3.ZERO
var move_target = Vector3.ZERO
var idle_t = 0.0
var sound_t = 5.0
var speed = 1.4

func setup(sp, anchor_pos, baby=false):
	species = sp
	def = ItemDB.animal(sp)
	anchor = anchor_pos
	translation = anchor + Vector3(rand_range(-2.0, 2.0), 0, rand_range(-2.0, 2.0))
	translation.y = TerrainGen.height(translation.x, translation.z)
	growth = 0.35 if baby else 1.0
	if sp == "cow" or sp == "buffalo":
		speed = 1.0
	elif sp == "dog" or sp == "cat":
		speed = 2.2
	elif sp == "pig":
		speed = 1.6
	var cs = CollisionShape.new()
	var cap = CapsuleShape.new()
	cap.radius = 0.4
	cap.height = 1.0
	cs.shape = cap
	cs.translation = Vector3(0, 0.5, 0)
	add_child(cs)
	add_child(Props.animal_mesh(sp))
	var sc = 0.35 + growth * 0.65
	scale = Vector3(sc, sc, sc)

func _ready():
	add_to_group("interactable")
	add_to_group("animal")

func _physics_process(delta):
	var player = _nearest_player()
	if wild and not wild_done:
		if player != null:
			var pd = translation.distance_to(player.translation)
			if pd < 7.0:
				var away = translation.direction_to(player.translation) * -1.0
				away.y = 0
				move_and_slide(away.normalized() * speed * 2.4, Vector3.UP)
				rotation.y = atan2(away.x, away.z)
				var ax = translation.x - anchor.x
				var az = translation.z - anchor.z
				if sqrt(ax * ax + az * az) > 45.0:
					wild_done = true
					Events.emit_signal("generic", "boar_chased", 1)
					Events.emit_signal("notify", "Boar Chased!", "The wild boar fled into the hills!")
					AudioSynth.play("accept")
				return
	_idle_or_wander(delta, player)

func _idle_or_wander(delta, player):
	idle_t -= delta
	if companion and not staying and player != null:
		var pd = translation.distance_to(player.translation)
		if pd > 5.0:
			var dir = player.translation.direction_to(translation) * -1.0
			dir.y = 0
			move_and_slide(dir.normalized() * speed * 1.6, Vector3.UP)
			rotation.y = atan2(dir.x, dir.z)
			_snap()
			return
	if idle_t <= 0.0:
		idle_t = rand_range(2.0, 6.0)
		var tx = anchor.x + rand_range(-8.0, 8.0)
		var tz = anchor.z + rand_range(-8.0, 8.0)
		if not TerrainGen.is_water(tx, tz):
			move_target = Vector3(tx, TerrainGen.height(tx, tz), tz)
	var dx = move_target.x - translation.x
	var dz = move_target.z - translation.z
	var d = sqrt(dx * dx + dz * dz)
	if d > 0.6:
		var dir = Vector3(dx / d, 0, dz / d)
		move_and_slide(dir * speed, Vector3.UP)
		rotation.y = atan2(dir.x, dir.z)
	_snap()
	# ambient sounds
	sound_t -= delta
	if player != null and sound_t <= 0.0:
		if translation.distance_to(player.translation) < 14.0:
			AudioSynth.play(str(def.get("sound", "chirp")), -6.0)
		sound_t = rand_range(6.0, 16.0)

func _snap():
	var th = TerrainGen.height(translation.x, translation.z)
	if translation.y < th - 1.0:
		translation.y = th
	elif translation.y > th + 2.5:
		translation.y = th

func _nearest_player():
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		return ps[0]
	return null

func get_prompt(player=null):
	var nm = str(def.get("name", species))
	if companion:
		return nm + " (companion)"
	return nm

func get_actions(player=null):
	var acts = ["Feed"]
	if (species == "cow" or species == "buffalo") and growth >= 1.0:
		acts.append("Milk")
	if companion:
		if staying:
			acts.append("Follow")
		else:
			acts.append("Stay")
	return acts

func action(label, player):
	if label == "Feed":
		feed()
	elif label == "Milk":
		milk()
	elif label == "Stay":
		staying = true
	elif label == "Follow":
		staying = false

func feed():
	if fed:
		Events.emit_signal("notify", "Not Hungry", "Already fed today.")
		return
	fed = true
	Events.emit_signal("animal_fed", species)
	AudioSynth.play(str(def.get("sound", "chirp")))
	Events.emit_signal("notify", "Fed", str(def.get("name", species)) + " is happy and fed.")

func milk():
	if not fed:
		Events.emit_signal("notify", "Feed First", "Feed her before milking.")
		return
	if milked:
		Events.emit_signal("notify", "Milked", "Already milked today.")
		return
	milked = true
	GameState.add_item("milk", 1)
	Events.emit_signal("animal_milked")
	AudioSynth.play("coin")
	Events.emit_signal("notify", "Fresh Milk", "Got 1 milk.")

func day_tick():
	fed = false
	milked = false
	growth = min(1.0, growth + 0.25)

func save_dict():
	return {"species": species, "x": translation.x, "y": translation.y, "z": translation.z, "fed": fed, "growth": growth, "companion": companion, "wild": wild}

func load_dict(d):
	species = str(d.get("species", species))
	def = ItemDB.animal(species)
	fed = bool(d.get("fed", false))
	growth = float(d.get("growth", 1.0))
	companion = bool(d.get("companion", false))
	wild = bool(d.get("wild", false))
	translation = Vector3(float(d.get("x", translation.x)), float(d.get("y", translation.y)), float(d.get("z", translation.z)))
