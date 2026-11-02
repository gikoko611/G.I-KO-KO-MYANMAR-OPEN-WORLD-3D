extends Spatial
# The open world: environment, day/night cycle, weather, chunk streaming,
# village / town / farm layout, NPCs, animals, vehicles, buildings, races,
# world events, discoveries and save/load.

const ChunkScript = preload("res://scripts/world/chunk.gd")
const FarmScript = preload("res://scripts/world/farm.gd")
const NpcScript = preload("res://scripts/world/npc.gd")
const AnimalScript = preload("res://scripts/world/animal.gd")
const VehicleScript = preload("res://scripts/world/vehicle.gd")
const BuildingScript = preload("res://scripts/world/building.gd")
const GatherableScript = preload("res://scripts/world/gatherable.gd")
const TreasureScript = preload("res://scripts/world/treasure.gd")
const EggScript = preload("res://scripts/world/egg_pickup.gd")
const DucklingScript = preload("res://scripts/world/duckling.gd")
const RaceStartScript = preload("res://scripts/world/race_start.gd")
const WellScript = preload("res://scripts/world/well.gd")

const DAY_LENGTH = 720.0
const CHUNK_MIN = -7
const CHUNK_MAX = 6

var env = null
var sun = null
var sky = null
var water_plane = null
var rain = null
var farm = null
var player = null
var current_vehicle = null
var placement_building = null
var beacon_node = null
var trader_npc = null
var boar = null
var duckling = null
var animals = []
var buildings = []
var vehicles = []
var npcs = {}
var chunks = {}
var chunk_queue = []
var treasures = []
var gatherables = []
var race_starts = {}
var race_flags = {}
var race_active = false
var race_id = ""
var race_cp = 0
var race_time = 0.0
var music_state = ""
var amb_timer = 0.0
var save_timer = 60.0
var disc_timer = 0.5
var night_acc = 0.0
var night_done = false
var storm_acc = 0.0
var storm_done = false
var duckling_rescued = false

func _ready():
	add_to_group("world")
	_setup_environment()
	_setup_layout()
	Events.connect("vehicle_bought", self, "_on_vehicle_bought")
	Events.connect("animal_bought", self, "_on_animal_bought")
	Events.connect("settings_changed", self, "_on_settings_changed")

func _process(delta):
	var p = _get_player()
	_update_chunks(p)
	if GameState.ui_busy():
		return
	# day cycle
	GameState.time += delta * 24.0 / DAY_LENGTH
	if GameState.time >= 24.0:
		GameState.time -= 24.0
		GameState.day += 1
		_new_day()
	if p == null:
		return
	_update_sun()
	_update_weather_visuals(p)
	_update_music_ambience(delta, p)
	if farm != null:
		farm.grow(delta / DAY_LENGTH)
	_check_discoveries(p, delta)
	_check_survival(p, delta)
	_update_race(delta, p)
	_update_beacon()
	_update_placement(p)
	save_timer -= delta
	if save_timer <= 0.0:
		save_timer = 90.0
		SaveMgr.save_game(false)

# ------------------------------ environment ------------------------------

func _setup_environment():
	sky = ProceduralSky.new()
	sky.sky_top_color = Color(0.25, 0.55, 0.9)
	sky.sky_horizon_color = Color(0.65, 0.8, 0.95)
	sky.sky_curve = 0.12
	sky.ground_bottom_color = Color(0.2, 0.25, 0.2)
	sky.ground_horizon_color = Color(0.5, 0.55, 0.45)
	sky.ground_curve = 0.05
	sky.sun_curve_size = 0.08
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_depth_begin = 35.0
	env.fog_depth_end = 110.0
	var wen = WorldEnvironment.new()
	wen.environment = env
	add_child(wen)
	sun = DirectionalLight.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = GameState.shadows_enabled()
	add_child(sun)
	water_plane = MeshInstance.new()
	water_plane.mesh = Props.plane_mesh(680, 680)
	water_plane.material_override = Props.tmat(Color(0.12, 0.35, 0.5), 0.55)
	water_plane.translation = Vector3(0, TerrainGen.WATER_Y, 0)
	add_child(water_plane)
	rain = CPUParticles.new()
	rain.amount = GameState.rain_amount()
	rain.lifetime = 1.1
	rain.direction = Vector3(0, -1, 0.15)
	rain.spread = 12.0
	rain.gravity = Vector3(0, -18, 0)
	rain.initial_velocity = 14.0
	rain.emission_shape = CPUParticles.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(30, 8, 30)
	rain.mesh = Props.quad_mesh(0.03, 0.55, Props.tmat(Color(0.6, 0.75, 0.9), 0.6))
	rain.visible = false
	rain.emitting = false
	add_child(rain)

func _update_sun():
	var t = GameState.time
	var ang = (t - 6.0) / 12.0 * PI
	sun.rotation_degrees = Vector3(-30.0 - sin(ang) * 45.0, -140.0 + t * 8.0, 0)
	var night = t < 5.5 or t > 19.0
	if night:
		sun.light_energy = 0.08
		sun.light_color = Color(0.5, 0.55, 0.75)
		env.ambient_light_energy = 0.22
		env.fog_color = Color(0.07, 0.09, 0.14)
	else:
		sun.light_energy = clamp(0.5 + sin(ang) * 0.6, 0.4, 1.1)
		sun.light_color = Color(1.0, 0.95, 0.85)
		env.ambient_light_energy = 0.7
		env.fog_color = Color(0.75, 0.82, 0.9)

func _update_weather_visuals(p):
	var wet = GameState.weather == "rain" or GameState.weather == "storm"
	rain.visible = wet
	rain.emitting = wet
	rain.amount = GameState.rain_amount()
	rain.translation = Vector3(p.translation.x, p.translation.y + 14.0, p.translation.z)
	if GameState.weather == "fog":
		env.fog_depth_begin = 12.0
		env.fog_depth_end = 55.0
	elif GameState.weather == "storm":
		env.fog_depth_begin = 20.0
		env.fog_depth_end = 90.0
	else:
		var fd = GameState.fog_density()
		env.fog_depth_begin = 35.0 / fd
		env.fog_depth_end = 110.0 / fd
	AudioSynth.set_rain(wet)

func _update_music_ambience(delta, p):
	amb_timer -= delta
	if amb_timer > 0.0:
		return
	amb_timer = 1.5
	var t = GameState.time
	if t >= 6.0 and t < 19.0:
		if music_state != "day":
			music_state = "day"
			AudioSynth.play_music("music_day")
	else:
		if music_state != "night":
			music_state = "night"
			AudioSynth.play_music("music_night")
	var want = "village"
	var px = p.translation.x
	var pz = p.translation.z
	var fx = px - 60.0
	var fz = pz + 140.0
	if sqrt(fx * fx + fz * fz) < 70.0:
		want = "forest"
	if TerrainGen.is_water(px, pz + 8.0) or TerrainGen.is_water(px, pz - 8.0) or TerrainGen.is_water(px + 8.0, pz) or TerrainGen.is_water(px - 8.0, pz):
		want = "river"
	AudioSynth.play_ambience(want)

# -------------------------------- layout ---------------------------------

func _setup_layout():
	# farm + house
	farm = FarmScript.new()
	farm.translation = Vector3(0, TerrainGen.height(0, 55), 55)
	add_child(farm)
	var house = BuildingScript.new()
	house.setup("house")
	add_child(house)
	house.translation = Vector3(-14, TerrainGen.height(-14, 60), 60)
	house.place()
	buildings.append(house)
	# wells
	var well1 = WellScript.new()
	add_child(well1)
	well1.translation = Vector3(8, TerrainGen.height(8, 62), 62)
	var well2 = WellScript.new()
	add_child(well2)
	well2.translation = Vector3(-96, TerrainGen.height(-96, 34), 34)
	# fences around the farm
	var f1 = Props.fence(18.0, Color(0.5, 0.38, 0.24))
	f1.translation = Vector3(0, TerrainGen.height(0, 51), 51)
	add_child(f1)
	var f2 = Props.fence(18.0, Color(0.5, 0.38, 0.24))
	f2.translation = Vector3(0, TerrainGen.height(0, 66), 66)
	add_child(f2)
	# village huts
	for hxz in [[-118, 22], [-104, 18], [-98, 34], [-116, 40], [-100, 46], [-122, 32], [-108, 24], [-96, 26]]:
		var h = Props.hut(4.5, 4.0, Color(0.75, 0.65, 0.5), Color(0.5, 0.3, 0.2))
		h.translation = Vector3(hxz[0], TerrainGen.height(hxz[0], hxz[1]), hxz[1])
		add_child(h)
	# town stalls and huts
	for sxz in [[150, 20], [155, 34], [145, 48], [168, 30], [172, 48], [163, 22]]:
		var s = Props.stall(Color(0.83, 0.68, 0.2))
		s.translation = Vector3(sxz[0], TerrainGen.height(sxz[0], sxz[1]), sxz[1])
		add_child(s)
	for txz in [[158, 52], [170, 38], [148, 28], [175, 45]]:
		var th = Props.hut(5.0, 4.5, Color(0.8, 0.72, 0.55), Color(0.45, 0.28, 0.18))
		th.translation = Vector3(txz[0], TerrainGen.height(txz[0], txz[1]), txz[1])
		add_child(th)
	# pagoda and shrine
	var pag = Props.pagoda()
	pag.translation = Vector3(120, TerrainGen.height(120, 158), 158)
	add_child(pag)
	var sh = Props.shrine()
	sh.translation = Vector3(60, TerrainGen.height(60, -140), -140)
	add_child(sh)
	# bridge, dock, waterfall
	var br = Props.bridge()
	br.translation = Vector3(-160, TerrainGen.height(-160, -83) + 0.05, -83)
	add_child(br)
	var dk = Props.dock()
	dk.translation = Vector3(-160, TerrainGen.height(-160, -108), -108)
	add_child(dk)
	var wf = Props.waterfall()
	wf.translation = Vector3(40, TerrainGen.height(40, 105) - 0.4, 105)
	add_child(wf)
	# NPCs
	for nid in ItemDB.NPCS.keys():
		if nid == "thiri":
			continue
		var n = NpcScript.new()
		add_child(n)
		n.setup(nid)
		npcs[nid] = n
	# default animals
	var chick = AnimalScript.new()
	add_child(chick)
	chick.setup("chicken", Vector3(4, TerrainGen.height(4, 52), 52))
	animals.append(chick)
	var duck = AnimalScript.new()
	add_child(duck)
	duck.setup("duck", Vector3(7, TerrainGen.height(7, 53), 53))
	animals.append(duck)
	# default boat near the bridge
	var boat = VehicleScript.new()
	add_child(boat)
	boat.setup("boat")
	boat.translation = Vector3(-150, TerrainGen.WATER_Y + 0.25, -83.4)
	vehicles.append(boat)
	# duckling at the lake shore
	if not Missions.completed.has("S1") and not duckling_rescued:
		duckling = DucklingScript.new()
		add_child(duckling)
		duckling.setup(Vector3(-158, TerrainGen.height(-158, -102), -102))
	# races: start signs + checkpoint flags
	for rid in ItemDB.RACES.keys():
		var rd = ItemDB.RACES[rid]
		var rs = RaceStartScript.new()
		add_child(rs)
		rs.setup(rid)
		rs.translation = Vector3(rd["start"][0], TerrainGen.height(rd["start"][0], rd["start"][1]), rd["start"][1])
		race_starts[rid] = rs
		var flags = []
		for cp in rd["checkpoints"]:
			var fl = Props.checkpoint_flag(Color(0.85, 0.2, 0.2))
			fl.translation = Vector3(cp[0], TerrainGen.height(cp[0], cp[1]), cp[1])
			fl.visible = false
			add_child(fl)
			flags.append(fl)
		race_flags[rid] = flags
	# treasure mounds
	var spots = []
	for s in ItemDB.TREASURE_SPOTS:
		spots.append(s)
	spots.append([60, -146])
	spots.append([44, 99])
	spots.append([-160, -130])
	for sxz in spots:
		var t = TreasureScript.new()
		add_child(t)
		t.setup(Vector3(sxz[0], TerrainGen.height(sxz[0], sxz[1]), sxz[1]))
		treasures.append(t)
	# seeded gatherables
	seed(1337)
	var placed_count = 0
	var tries = 0
	while placed_count < 46 and tries < 500:
		tries += 1
		var x = rand_range(-260.0, 260.0)
		var z = rand_range(-260.0, 260.0)
		if TerrainGen.is_water(x, z):
			continue
		if TerrainGen.in_flat_region(x, z, 8.0):
			continue
		if TerrainGen.road_dist(x, z) < 7.0:
			continue
		var kind = "wood"
		var in_forest = false
		var fx = x - 60.0
		var fz = z + 140.0
		if sqrt(fx * fx + fz * fz) < 55.0:
			kind = "wood"
			in_forest = true
		elif randf() < 0.35:
			kind = "stone"
		var g = GatherableScript.new()
		add_child(g)
		g.setup(kind, Vector3(x, TerrainGen.height(x, z), z), in_forest)
		gatherables.append(g)
		placed_count += 1

# ----------------------------- chunk streaming ---------------------------

func _chunk_key(cx, cz):
	return str(cx) + "," + str(cz)

func _build_chunk(cx, cz):
	var key = _chunk_key(cx, cz)
	if chunks.has(key):
		return
	var c = ChunkScript.new()
	add_child(c)
	c.translation = Vector3(cx * TerrainGen.CHUNK, 0, cz * TerrainGen.CHUNK)
	c.setup(cx, cz)
	chunks[key] = c

func _update_chunks(p):
	if p == null:
		return
	var cc = int(floor(p.translation.x / TerrainGen.CHUNK))
	var cr = int(floor(p.translation.z / TerrainGen.CHUNK))
	var rad = GameState.view_radius()
	var want = {}
	for dz in range(-rad, rad + 1):
		for dx in range(-rad, rad + 1):
			var cx = cc + dx
			var cz = cr + dz
			if cx < CHUNK_MIN or cx > CHUNK_MAX or cz < CHUNK_MIN or cz > CHUNK_MAX:
				continue
			var key = _chunk_key(cx, cz)
			want[key] = [cx, cz]
			if not chunks.has(key) and chunk_queue.find(key) == -1:
				chunk_queue.append(key)
	for key in chunks.keys():
		if not want.has(key):
			var c = chunks[key]
			chunks.erase(key)
			c.queue_free()
	var keep = []
	for key in chunk_queue:
		if want.has(key):
			keep.append(key)
	chunk_queue = keep
	if chunk_queue.size() > 0:
		var key = chunk_queue[0]
		chunk_queue.pop_front()
		var coords = want[key]
		_build_chunk(coords[0], coords[1])

func prewarm(px, pz):
	var cc = int(floor(px / TerrainGen.CHUNK))
	var cr = int(floor(pz / TerrainGen.CHUNK))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var cx = cc + dx
			var cz = cr + dz
			if cx >= CHUNK_MIN and cx <= CHUNK_MAX and cz >= CHUNK_MIN and cz <= CHUNK_MAX:
				_build_chunk(cx, cz)

# ------------------------------- day cycle -------------------------------

func _new_day():
	# clear expired world events
	if trader_npc != null and is_instance_valid(trader_npc):
		trader_npc.queue_free()
		trader_npc = null
	if boar != null and is_instance_valid(boar):
		boar.queue_free()
		boar = null
	# weather roll
	var roll = randi() % 100
	var w = "sunny"
	if roll < 40:
		w = "sunny"
	elif roll < 60:
		w = "cloudy"
	elif roll < 80:
		w = "rain"
	elif roll < 90:
		w = "fog"
	else:
		w = "storm"
	GameState.weather = w
	Events.emit_signal("weather_changed", w)
	GameState.festival = false
	# eggs first (fed is still true from yesterday)
	_spawn_eggs()
	for a in animals:
		a.day_tick()
	if farm != null:
		farm.day_tick()
		if w == "rain" or w == "storm" or _has_building("water_tower"):
			farm.water_all()
	# building income + storm damage
	var income = 0
	for b in buildings:
		if b.type == "market_shop":
			income += b.level * 40
		elif b.type == "guest_house":
			income += b.level * 25
		if w == "storm":
			b.condition = max(10.0, b.condition - 6.0)
	if income > 0:
		GameState.add_money(income)
		Events.emit_signal("notify", "Morning Income", "Your properties earned K " + str(income) + " overnight.")
	# respawns
	for g in gatherables:
		g.try_respawn(GameState.day)
	for t in treasures:
		t.try_respawn(GameState.day)
	# world event (40% chance)
	if randi() % 100 < 40:
		_spawn_world_event()
	night_done = false
	night_acc = 0.0
	storm_done = false
	storm_acc = 0.0
	Events.emit_signal("day_completed", GameState.day)
	SaveMgr.save_game(false)

func _spawn_eggs():
	var laid = 0
	for a in animals:
		if laid >= 3:
			break
		if (a.species == "chicken" or a.species == "duck") and a.growth >= 1.0 and a.fed:
			var e = EggScript.new()
			add_child(e)
			var ex = a.translation.x + rand_range(-1.5, 1.5)
			var ez = a.translation.z + rand_range(-1.5, 1.5)
			e.setup(Vector3(ex, TerrainGen.height(ex, ez) + 0.15, ez))
			laid += 1
	if laid > 0:
		Events.emit_signal("notify", "Fresh Eggs", "Your birds laid " + str(laid) + " egg(s) this morning.")

func _spawn_world_event():
	var roll = randi() % 4
	if roll == 0:
		if trader_npc == null:
			trader_npc = NpcScript.new()
			add_child(trader_npc)
			trader_npc.setup("thiri", true)
			trader_npc.translation = Vector3(-40, TerrainGen.height(-40, 20), 20)
		Events.emit_signal("notify", "World Event", "A wandering trader set up on the road - one day only!")
		Missions.accept_event("trader")
	elif roll == 1:
		if boar == null or not is_instance_valid(boar):
			boar = AnimalScript.new()
			add_child(boar)
			boar.setup("pig", Vector3(-70, TerrainGen.height(-70, 10), 10))
			boar.wild = true
			boar.speed = 3.2
		Events.emit_signal("notify", "World Event", "A wild boar is trampling fields near the village - chase it away!")
		Missions.accept_event("boar")
	elif roll == 2:
		var t = TreasureScript.new()
		add_child(t)
		var tx = rand_range(-100.0, 100.0)
		var tz = rand_range(-60.0, 60.0)
		t.setup(Vector3(tx, TerrainGen.height(tx, tz), tz))
		treasures.append(t)
		Events.emit_signal("notify", "World Event", "A glint on the road... today's treasure mound awaits!")
		Missions.accept_event("mound")
	else:
		GameState.festival = true
		Events.emit_signal("notify", "World Event", "Festival day! Better prices at every shop!")
		Missions.accept_event("festival")

# ------------------------------ discoveries ------------------------------

func _check_discoveries(p, delta):
	disc_timer -= delta
	if disc_timer > 0.0:
		return
	disc_timer = 0.5
	for loc in ItemDB.LOCATIONS:
		var lid = str(loc["id"])
		if GameState.discovered.has(lid):
			continue
		var radius = 25.0
		if bool(loc["hidden"]):
			radius = 15.0
		var dx = p.translation.x - float(loc["pos"][0])
		var dz = p.translation.z - float(loc["pos"][1])
		if sqrt(dx * dx + dz * dz) < radius:
			GameState.discovered[lid] = true
			Events.emit_signal("location_discovered", lid)
			GameState.add_xp(10)
			var reward = int(loc["reward"])
			if reward > 0:
				GameState.add_money(reward)
			Events.emit_signal("notify", "Discovered!", str(loc["name"]) + " (+" + str(reward) + " kyat)")
			AudioSynth.play("complete")

func _check_survival(p, delta):
	var t = GameState.time
	if (t >= 22.0) and not night_done and p.inside_building == null:
		var dx = p.translation.x + 110.0
		var dz = p.translation.z - 30.0
		if sqrt(dx * dx + dz * dz) < 60.0:
			night_acc += delta
			if night_acc >= 60.0:
				night_done = true
				night_acc = 0.0
				Events.emit_signal("generic", "night_out", 1)
	else:
		if t < 22.0:
			night_acc = 0.0
	if GameState.weather == "storm" and p.inside_building == null and not storm_done:
		storm_acc += delta
		if storm_acc >= 60.0:
			storm_done = true
			storm_acc = 0.0
			Events.emit_signal("generic", "storm_out", 1)

# --------------------------------- races ---------------------------------

func start_race(rid):
	if race_active:
		Events.emit_signal("notify", "Race Running", "Finish or wait out the current race.")
		return
	if current_vehicle == null:
		Events.emit_signal("notify", "Need a Vehicle", "Bring any vehicle to the start flag to race!")
		AudioSynth.play("deny")
		return
	var rd = ItemDB.RACES.get(rid, {})
	race_active = true
	race_id = rid
	race_cp = 0
	race_time = 0.0
	for fl in race_flags.get(rid, []):
		fl.visible = true
	AudioSynth.play("race_start")
	Events.emit_signal("notify", "Race Started!", str(rd.get("name", rid)) + " - pass every red flag!")

func _update_race(delta, p):
	if not race_active:
		return
	race_time += delta
	var rd = ItemDB.RACES.get(race_id, {})
	var cps = rd.get("checkpoints", [])
	if race_cp < cps.size():
		var cp = cps[race_cp]
		var dx = p.translation.x - float(cp[0])
		var dz = p.translation.z - float(cp[1])
		if sqrt(dx * dx + dz * dz) < 14.0:
			race_cp += 1
			AudioSynth.play("accept")
			if race_cp >= cps.size():
				_finish_race()
				return
	if race_time > 300.0:
		_end_race()
		Events.emit_signal("notify", "Race Abandoned", "Too slow - the race ended.")

func _finish_race():
	var rd = ItemDB.RACES.get(race_id, {})
	var secs = stepify(race_time, 0.1)
	_end_race()
	Events.emit_signal("race_finished", race_id, secs)
	if secs <= float(rd.get("time_target", 999.0)):
		GameState.add_money(int(rd.get("reward", 0)))
		GameState.add_xp(20)
		Events.emit_signal("notify", "Race Won!", str(rd.get("name", race_id)) + " finished in " + str(secs) + "s! +" + str(rd.get("reward", 0)) + " kyat")
		AudioSynth.play("complete")
	else:
		Events.emit_signal("notify", "Race Finished", "Time " + str(secs) + "s (target " + str(rd.get("time_target", 0)) + "s). Try again!")

func _end_race():
	race_active = false
	for fl in race_flags.get(race_id, []):
		fl.visible = false

# -------------------------------- vehicles -------------------------------

func enter_vehicle(v):
	var p = _get_player()
	if p == null or current_vehicle != null:
		return
	current_vehicle = v
	v.driver = true
	p.driving = true
	p.translation = v.translation
	p.visible = false
	Events.emit_signal("vehicle_entered", v.id)
	AudioSynth.play("accept")
	Events.emit_signal("notify", "Driving", str(ItemDB.vehicle(v.id).get("name", v.id)) + " - use the joystick to drive!")

func exit_vehicle():
	var p = _get_player()
	if current_vehicle == null or p == null:
		return
	var v = current_vehicle
	v.driver = false
	v.drive_input = Vector2.ZERO
	v.brake = false
	v.speed = 0.0
	var side = v.transform.basis.x.normalized() * 2.5
	var px = v.translation + side
	p.translation = Vector3(px.x, TerrainGen.height(px.x, px.z) + 0.1, px.z)
	p.visible = true
	p.driving = false
	current_vehicle = null
	AudioSynth.set_engine(false, 0.0)

func _nearest_vehicle(radius):
	var p = _get_player()
	if p == null:
		return null
	var best = null
	var bd = radius
	for v in vehicles:
		if v.driver:
			continue
		var d = v.translation.distance_to(p.translation)
		if d < bd:
			bd = d
			best = v
	return best

func repair_vehicle():
	var v = _nearest_vehicle(18.0)
	if v == null:
		Events.emit_signal("notify", "No Vehicle", "Park a vehicle near the workshop first.")
		AudioSynth.play("deny")
		return
	v.repair()

func refuel_vehicle(rate):
	var cost = int(rate * 2)
	var v = _nearest_vehicle(18.0)
	if v == null:
		Events.emit_signal("notify", "No Vehicle", "Park a vehicle here first.")
		AudioSynth.play("deny")
		return
	if v.fuel >= 99.5:
		Events.emit_signal("notify", "Tank Full", "No fuel needed right now.")
		return
	if GameState.spend_money(cost):
		v.refuel(rate)
		AudioSynth.play("coin")
		Events.emit_signal("notify", "Refueled", "+" + str(int(rate)) + " fuel for K " + str(cost) + ".")

func _on_vehicle_bought(vehicle_id):
	var v = VehicleScript.new()
	add_child(v)
	v.setup(vehicle_id)
	var x = 8.0
	var z = 50.0
	if vehicle_id == "boat":
		x = -150.0
		z = -83.4
	v.translation = Vector3(x, TerrainGen.height(x, z) + 0.3, z)
	if vehicle_id == "boat":
		v.translation.y = TerrainGen.WATER_Y + 0.25
	vehicles.append(v)
	Events.emit_signal("notify", "New Vehicle", str(ItemDB.vehicle(vehicle_id).get("name", vehicle_id)) + " delivered to your farm!")

func _on_animal_bought(animal_id):
	var a = AnimalScript.new()
	add_child(a)
	a.setup(animal_id, Vector3(4, TerrainGen.height(4, 52), 52))
	animals.append(a)
	if animal_id == "dog" or animal_id == "cat":
		a.companion = true
		GameState.companion = true
		Events.emit_signal("companion_recruited")
		Events.emit_signal("notify", "New Best Friend", str(ItemDB.animal(animal_id).get("name", animal_id)) + " will follow you everywhere!")
	else:
		Events.emit_signal("notify", "New Animal", str(ItemDB.animal(animal_id).get("name", animal_id)) + " settles in near the farm.")

func companion_command():
	for a in animals:
		if a.companion:
			a.staying = not a.staying
			Events.emit_signal("notify", "Companion", "Stay here." if a.staying else "Follow me!")
			return
	Events.emit_signal("notify", "No Companion", "Buy a dog or cat from U Phyu first.")

func feed_all_animals():
	var fed_count = 0
	for a in animals:
		if a.visible and not a.fed:
			a.feed()
			fed_count += 1
	if fed_count == 0:
		Events.emit_signal("notify", "All Fed", "Every animal is already fed today.")
	else:
		Events.emit_signal("notify", "Feeding Time", "Fed " + str(fed_count) + " animal(s) from the barn.")

# ------------------------------- buildings -------------------------------

func start_placement(id):
	cancel_placement()
	var b = BuildingScript.new()
	add_child(b)
	b.setup(id)
	b.translation = Vector3(0, 200.0, 0)
	b.make_ghost()
	placement_building = b
	Events.emit_signal("notify", "Placing", str(ItemDB.building(id).get("name", id)) + " - walk to choose a spot, then Confirm.")

func _update_placement(p):
	if placement_building == null:
		return
	if not is_instance_valid(placement_building):
		placement_building = null
		return
	if p.driving or p.inside_building != null:
		return
	var fwd = -p.transform.basis.z
	var pos = p.translation + fwd * 7.0
	pos.y = TerrainGen.height(pos.x, pos.z)
	placement_building.translation = pos
	placement_building.rotation.y = p.rotation.y

func confirm_placement():
	if placement_building == null:
		return
	var d = ItemDB.building(placement_building.type)
	var ok = true
	var mats = d.get("mats", {})
	for k in mats.keys():
		if not GameState.has_item(k, int(mats[k])):
			ok = false
	if not ok:
		Events.emit_signal("notify", "Missing Materials", "Check the build menu for material costs.")
		AudioSynth.play("deny")
		return
	if not GameState.spend_money(int(d.get("cost", 0))):
		return
	for k in mats.keys():
		GameState.remove_item(k, int(mats[k]))
	placement_building.place()
	buildings.append(placement_building)
	Events.emit_signal("building_built", placement_building.type)
	GameState.add_xp(15)
	AudioSynth.play("chop")
	Events.emit_signal("notify", "Built!", str(d.get("name", placement_building.type)) + " construction complete.")
	placement_building = null
	_recalc_inventory_capacity()

func cancel_placement():
	if placement_building != null and is_instance_valid(placement_building):
		placement_building.queue_free()
	placement_building = null

func _has_building(btype):
	for b in buildings:
		if b.type == btype:
			return true
	return false

func _recalc_inventory_capacity():
	var cap = 60
	for b in buildings:
		cap += int(ItemDB.building(b.type).get("cap", 0)) * b.level
	GameState.inventory.capacity = cap

func _on_settings_changed():
	if sun != null:
		sun.shadow_enabled = GameState.shadows_enabled()
	if rain != null:
		rain.amount = GameState.rain_amount()

# --------------------------------- misc ----------------------------------

func sleep_to_morning():
	var was = GameState.time
	GameState.time = 7.0
	if was >= 12.0:
		GameState.day += 1
		_new_day()
	Events.emit_signal("notify", "Good Morning!", "Day " + str(GameState.day) + " - a fresh start.")

func _update_beacon():
	var mp = Missions.tracked_marker()
	if mp == null:
		if beacon_node != null:
			beacon_node.visible = false
		return
	if beacon_node == null:
		beacon_node = Props.beacon()
		add_child(beacon_node)
	beacon_node.visible = true
	beacon_node.translation = Vector3(mp.x, TerrainGen.height(mp.x, mp.y), mp.y)

func _get_player():
	if player != null and is_instance_valid(player):
		return player
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		player = ps[0]
		return player
	return null

# ------------------------------ persistence ------------------------------

func save_dict():
	var bs = []
	for b in buildings:
		bs.append(b.save_dict())
	var vs = []
	for v in vehicles:
		vs.append(v.save_dict())
	var as_ = []
	for a in animals:
		as_.append(a.save_dict())
	var ts = []
	for t in treasures:
		ts.append(not t.visible)
	var duck = false
	if duckling != null and is_instance_valid(duckling) and duckling.rescued:
		duck = true
	return {"farm": farm.save_dict(), "buildings": bs, "vehicles": vs, "animals": as_, "treasures_dug": ts, "duckling": duck}

func load_dict(d):
	if d.has("farm") and farm != null:
		farm.load_dict(d["farm"])
	for b in buildings:
		b.queue_free()
	buildings = []
	for v in vehicles:
		v.queue_free()
	vehicles = []
	for a in animals:
		a.queue_free()
	animals = []
	if d.has("buildings"):
		for bd in d["buildings"]:
			var b = BuildingScript.new()
			add_child(b)
			b.load_dict(bd)
			buildings.append(b)
	if d.has("vehicles"):
		for vd in d["vehicles"]:
			var v = VehicleScript.new()
			add_child(v)
			v.load_dict(vd)
			vehicles.append(v)
	if d.has("animals"):
		for ad in d["animals"]:
			var a = AnimalScript.new()
			add_child(a)
			a.setup(str(ad.get("species", "chicken")), Vector3(0, 0, 0))
			a.load_dict(ad)
			animals.append(a)
	if d.has("treasures_dug"):
		var ts = d["treasures_dug"]
		for i in range(min(treasures.size(), ts.size())):
			treasures[i].visible = not bool(ts[i])
	duckling_rescued = bool(d.get("duckling", false))
	if duckling_rescued:
		if duckling == null or not is_instance_valid(duckling):
			duckling = DucklingScript.new()
			add_child(duckling)
			var ps = get_tree().get_nodes_in_group("player")
			var dp = Vector3(0, 3, 60)
			if ps.size() > 0:
				dp = ps[0].translation
			duckling.setup(Vector3(dp.x, TerrainGen.height(dp.x, dp.z), dp.z))
			duckling.rescued = true
	elif duckling != null and is_instance_valid(duckling):
		duckling.queue_free()
		duckling = null
	_recalc_inventory_capacity()
