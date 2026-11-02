extends Node
# Mission manager: accepts, tracks, completes and pays out every mission.
# Objectives are bumped directly by Events signals.

const MD = preload("res://scripts/missions/mission_data.gd")

const BOARD_CATS = ["main", "side", "farm", "delivery", "errand", "vehicle", "survival", "fishing", "animal", "race", "timed", "special"]

# signals whose single argument is the amount to add
const AMOUNT_SIGS = ["distance_driven", "money_earned", "level_up", "eggs_collected", "day_completed", "week_completed"]

var active = {}
var completed = {}

func _ready():
	Events.connect("crop_planted", self, "_e1", ["crop_planted"])
	Events.connect("field_plowed", self, "_e0", ["field_plowed"])
	Events.connect("plot_watered", self, "_e0", ["plot_watered"])
	Events.connect("crop_fertilized", self, "_e0", ["crop_fertilized"])
	Events.connect("crop_harvested", self, "_e1", ["crop_harvested"])
	Events.connect("crop_sold", self, "_e2", ["crop_sold"])
	Events.connect("item_sold", self, "_e2", ["item_sold"])
	Events.connect("seed_bought", self, "_e1", ["seed_bought"])
	Events.connect("item_bought", self, "_e1", ["item_bought"])
	Events.connect("money_earned", self, "_e1", ["money_earned"])
	Events.connect("item_delivered", self, "_e1", ["item_delivered"])
	Events.connect("fish_caught", self, "_e2", ["fish_caught"])
	Events.connect("treasure_found", self, "_e0", ["treasure_found"])
	Events.connect("animal_bought", self, "_e1", ["animal_bought"])
	Events.connect("animal_fed", self, "_e1", ["animal_fed"])
	Events.connect("eggs_collected", self, "_e1", ["eggs_collected"])
	Events.connect("animal_milked", self, "_e0", ["animal_milked"])
	Events.connect("vehicle_bought", self, "_e1", ["vehicle_bought"])
	Events.connect("vehicle_entered", self, "_e1", ["vehicle_entered"])
	Events.connect("distance_driven", self, "_e1", ["distance_driven"])
	Events.connect("race_finished", self, "_e2", ["race_finished"])
	Events.connect("location_discovered", self, "_e1", ["location_discovered"])
	Events.connect("npc_talked", self, "_e1", ["npc_talked"])
	Events.connect("player_ate", self, "_e1", ["player_ate"])
	Events.connect("player_drank", self, "_e0", ["player_drank"])
	Events.connect("player_slept", self, "_e0", ["player_slept"])
	Events.connect("day_completed", self, "_e1", ["day_completed"])
	Events.connect("week_completed", self, "_e1", ["week_completed"])
	Events.connect("level_up", self, "_e1", ["level_up"])
	Events.connect("building_built", self, "_e1", ["building_built"])
	Events.connect("building_upgraded", self, "_e1", ["building_upgraded"])
	Events.connect("companion_recruited", self, "_e0", ["companion_recruited"])
	Events.connect("weather_changed", self, "_e1", ["weather_changed"])
	Events.connect("generic", self, "_e2", ["generic"])

# ------------------------------ event intake -----------------------------

func _e0(sig):
	_bump(sig, "", 1)
	if sig == "treasure_found":
		# hidden chain opens with the first treasure
		accept_event("treasure_hunter")

func _e1(a, sig):
	var amount = 1
	if AMOUNT_SIGS.find(sig) != -1:
		amount = max(1, int(a))
	_bump(sig, str(a), amount)
	if sig == "day_completed":
		_rollover(int(a))

func _e2(a, b, sig):
	if sig == "race_finished":
		_race(str(a), float(b))
	elif sig == "crop_sold" or sig == "item_sold":
		_bump(sig, str(a), max(1, int(b)))
	elif sig == "generic":
		_bump("generic", str(a), max(1, int(b)))
	else:
		_bump(sig, str(a), 1)

func _bump(sig, target, amount):
	for mid in active.keys():
		var def = MD.DEFS.get(mid, null)
		if def == null:
			continue
		var st = active[mid]
		var objs = def["objectives"]
		for i in range(objs.size()):
			var o = objs[i]
			if str(o["type"]) != sig:
				continue
			var need = int(o.get("amount", 1))
			if st["progress"][i] >= need:
				continue
			if o.has("target") and str(o["target"]) != target:
				continue
			st["progress"][i] += amount
		_check_complete(mid)

func _race(rid, secs):
	for mid in active.keys():
		var def = MD.DEFS.get(mid, null)
		if def == null:
			continue
		var st = active[mid]
		var objs = def["objectives"]
		for i in range(objs.size()):
			var o = objs[i]
			if str(o["type"]) != "race_finished":
				continue
			if str(o.get("target", "")) != rid:
				continue
			if o.has("time"):
				if secs <= float(o["time"]):
					st["progress"][i] += 1
			else:
				st["progress"][i] += 1
		_check_complete(mid)

# ------------------------------ lifecycle --------------------------------

func _check_complete(mid):
	var def = MD.DEFS.get(mid, null)
	if def == null:
		return
	var st = active.get(mid, null)
	if st == null:
		return
	var objs = def["objectives"]
	for i in range(objs.size()):
		if st["progress"][i] < int(objs[i].get("amount", 1)):
			return
	complete(mid)

func complete(mid):
	var def = MD.DEFS.get(mid, null)
	if def == null:
		return
	active.erase(mid)
	completed[mid] = true
	var rw = def.get("rewards", {})
	var money = int(rw.get("money", 0))
	var xp = int(rw.get("xp", 0))
	if money > 0:
		GameState.add_money(money)
	if xp > 0:
		GameState.add_xp(xp)
	var items = rw.get("items", {})
	for k in items.keys():
		GameState.add_item(k, int(items[k]))
	Events.emit_signal("notify", "Mission Complete!", def["title"] + "\nRewards: K " + str(money) + (", " + str(xp) + " XP" if xp > 0 else ""))
	AudioSynth.play("complete")
	Events.emit_signal("mission_completed", mid)
	if bool(def.get("repeat", false)):
		accept(mid, true)
	elif def.get("next", "") != "" and MD.DEFS.has(def["next"]):
		accept(def["next"])
		Events.emit_signal("notify", "New Mission", MD.DEFS[def["next"]]["title"])
		AudioSynth.play("notify")

func accept(mid, silent=false):
	if active.has(mid) or completed.has(mid):
		return
	var def = MD.DEFS.get(mid, null)
	if def == null:
		return
	var prog = []
	for o in def["objectives"]:
		prog.append(0)
	active[mid] = {"progress": prog}
	if not silent:
		Events.emit_signal("notify", "Mission Accepted", def["title"])
		AudioSynth.play("accept")
		Events.emit_signal("mission_accepted", mid)

func cancel(mid):
	if not active.has(mid):
		return
	var def = MD.DEFS.get(mid, null)
	if def != null and def["cat"] == "achv":
		return
	active.erase(mid)
	Events.emit_signal("notify", "Mission Cancelled", MD.DEFS.get(mid, {"title": mid})["title"])
	Events.emit_signal("mission_failed", mid)

func accept_event(tag):
	for mid in MD.DEFS.keys():
		var def = MD.DEFS[mid]
		if def.get("event", "") != tag:
			continue
		if active.has(mid) or completed.has(mid):
			continue
		accept(mid)
		Events.emit_signal("notify", "New Quest!", def["title"] + "\n" + def["desc"])

func reset_all():
	active = {}
	completed = {}
	for mid in MD.DEFS.keys():
		if MD.DEFS[mid]["cat"] == "achv":
			accept(mid, true)

# ------------------------------ daily rollover ---------------------------

func _rollover(day):
	# auto missions expire with the day
	for mid in active.keys():
		var def = MD.DEFS.get(mid, null)
		if def == null:
			continue
		if def["cat"] == "daily" or def["cat"] == "weekly" or def["cat"] == "event":
			active.erase(mid)
	# dailies and weeklies can be earned again
	for mid in completed.keys():
		var def = MD.DEFS.get(mid, null)
		if def == null:
			continue
		if def["cat"] == "daily" or def["cat"] == "weekly":
			completed.erase(mid)
	# pick today's dailies (seeded - same for everyone)
	var dailies = []
	var weeklies = []
	for mid in MD.DEFS.keys():
		if MD.DEFS[mid]["cat"] == "daily":
			dailies.append(mid)
		elif MD.DEFS[mid]["cat"] == "weekly":
			weeklies.append(mid)
	seed(day * 7919)
	dailies.shuffle()
	var picks = min(2, dailies.size())
	for i in range(picks):
		accept(dailies[i], true)
	var week = int(day / 7)
	seed(day * 104729 + week * 31)
	weeklies.shuffle()
	if weeklies.size() > 0:
		accept(weeklies[0], true)
	if day % 7 == 0 and day > 0:
		Events.emit_signal("week_completed", week)

# ------------------------------ queries ----------------------------------

func on_board():
	var list = []
	for mid in MD.DEFS.keys():
		var def = MD.DEFS[mid]
		if BOARD_CATS.find(def["cat"]) == -1:
			continue
		if active.has(mid) or completed.has(mid):
			continue
		list.append(mid)
	return list

func get_active():
	var list = []
	for mid in MD.DEFS.keys():
		if active.has(mid) and MD.DEFS[mid]["cat"] != "achv":
			list.append(mid)
	return list

func get_dailies():
	var list = []
	for mid in MD.DEFS.keys():
		if active.has(mid) and (MD.DEFS[mid]["cat"] == "daily" or MD.DEFS[mid]["cat"] == "weekly" or MD.DEFS[mid]["cat"] == "event"):
			list.append(mid)
	return list

func get_achievements():
	var list = []
	for mid in MD.DEFS.keys():
		if MD.DEFS[mid]["cat"] == "achv":
			list.append(mid)
	return list

func get_completed():
	var list = []
	for mid in MD.DEFS.keys():
		if completed.has(mid):
			list.append(mid)
	return list

func progress(mid):
	var st = active.get(mid, null)
	if st == null:
		return []
	return st["progress"]

func is_complete(mid):
	return completed.has(mid)

func obj_text(o):
	var names = {
		"npc_talked": "Talk",
		"generic": "Do",
		"field_plowed": "Plow plots",
		"crop_planted": "Plant",
		"plot_watered": "Water plots",
		"crop_fertilized": "Fertilize plots",
		"crop_harvested": "Harvest",
		"crop_sold": "Sell",
		"item_sold": "Sell",
		"seed_bought": "Buy seeds",
		"item_bought": "Buy",
		"money_earned": "Earn K",
		"item_delivered": "Deliver",
		"fish_caught": "Catch fish",
		"treasure_found": "Find treasures",
		"animal_bought": "Buy animals",
		"animal_fed": "Feed animals",
		"eggs_collected": "Collect eggs",
		"animal_milked": "Milk animals",
		"vehicle_bought": "Buy vehicle",
		"vehicle_entered": "Drive",
		"distance_driven": "Drive m",
		"race_finished": "Finish race",
		"location_discovered": "Discover",
		"player_ate": "Eat meals",
		"player_drank": "Drink",
		"player_slept": "Sleep",
		"day_completed": "Reach day",
		"week_completed": "Reach week",
		"level_up": "Reach level",
		"building_built": "Build buildings",
		"building_upgraded": "Upgrade buildings",
		"companion_recruited": "Recruit companion",
		"weather_changed": "See weather change"
	}
	var base = str(names.get(str(o["type"]), str(o["type"])))
	if o.has("target") and str(o["target"]) != "":
		base += " " + str(o["target"]).replace("_", " ")
	return base

func progress_text(mid):
	var def = MD.DEFS.get(mid, null)
	if def == null:
		return mid
	var txt = def["title"] + "\n"
	var st = active.get(mid, null)
	var objs = def["objectives"]
	for i in range(objs.size()):
		var o = objs[i]
		var need = int(o.get("amount", 1))
		var have = 0
		if st != null:
			have = int(st["progress"][i])
		txt += obj_text(o) + ": " + str(min(have, need)) + "/" + str(need) + "\n"
	return txt

func tracked_marker():
	for mid in MD.DEFS.keys():
		if not active.has(mid):
			continue
		var def = MD.DEFS[mid]
		if def.has("marker") and not completed.has(mid):
			return Vector2(def["marker"][0], def["marker"][1])
	return null

# ------------------------------ persistence ------------------------------

func save_dict():
	var act = {}
	for mid in active.keys():
		act[mid] = active[mid]["progress"]
	return {"active": act, "completed": completed.keys()}

func load_dict(d):
	active = {}
	completed = {}
	var act = d.get("active", {})
	for mid in act.keys():
		if not MD.DEFS.has(mid):
			continue
		var prog = []
		var objs = MD.DEFS[mid]["objectives"]
		var saved = act[mid]
		for i in range(objs.size()):
			var v = 0
			if i < saved.size():
				v = int(saved[i])
			prog.append(v)
		active[mid] = {"progress": prog}
	var done = d.get("completed", [])
	for mid in done:
		if MD.DEFS.has(mid):
			completed[mid] = true
	# always keep achievements tracked
	for mid in MD.DEFS.keys():
		if MD.DEFS[mid]["cat"] == "achv" and not active.has(mid) and not completed.has(mid):
			accept(mid, true)
