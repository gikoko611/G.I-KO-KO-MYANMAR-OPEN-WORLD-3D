extends Node
# Global game state: money, xp, level, time, weather, inventory, settings and
# pending menu actions. Everything gameplay-related reads from here.

const InvList = preload("res://scripts/inventory/inv_list.gd")

var money = 500
var xp = 0
var level = 1
var day = 1
var time = 7.0
var weather = "sunny"
var festival = false
var story_stage = 1
var story_choice = ""
var companion = false
var discovered = {}
var inventory = null
var pending_new_game = false
var pending_load = false
var ui_open = 0

# graphics preset: 0 low, 1 medium, 2 high
var graphics = 1
var volumes = {"Music": 0.7, "SFX": 0.9, "Ambience": 0.5}

func _ready():
	inventory = InvList.new()

func ui_busy():
	return ui_open > 0

func season():
	return ItemDB.season(day)

func season_name():
	var names = ["Summer", "Rainy", "Cool", "Cold"]
	return names[season()]

func add_money(n):
	money += int(n)
	if n > 0:
		Events.emit_signal("money_earned", int(n))

func spend_money(n):
	if money < n:
		Events.emit_signal("notify", "Not Enough Money", "You need K " + str(n) + " but only have K " + str(money) + ".")
		return false
	money -= int(n)
	Events.emit_signal("money_spent", int(n))
	return true

func add_xp(n):
	xp += int(n)
	while xp >= xp_next():
		xp -= xp_next()
		level += 1
		Events.emit_signal("level_up", level)
		Events.emit_signal("notify", "Level Up!", "You reached level " + str(level) + "!")

func xp_next():
	return 100 * level

func has_item(id, n=1):
	return inventory.has(id, n)

func add_item(id, n=1):
	return inventory.add(id, n)

func remove_item(id, n=1):
	return inventory.remove(id, n)

func view_radius():
	return [2, 3, 4][graphics]

func prop_density():
	return [0.5, 0.8, 1.1][graphics]

func rain_amount():
	return [250, 450, 700][graphics]

func fog_density():
	return [0.6, 0.8, 1.0][graphics]

func shadows_enabled():
	return graphics == 2

func set_graphics(g):
	graphics = clamp(int(g), 0, 2)
	Events.emit_signal("settings_changed")

func set_volume(bus, v):
	if volumes.has(bus):
		volumes[bus] = clamp(v, 0.0, 1.0)
		AudioSynth.set_bus_volume(bus, volumes[bus])

func apply_settings():
	AudioSynth.set_bus_volume("Music", volumes["Music"])
	AudioSynth.set_bus_volume("SFX", volumes["SFX"])
	AudioSynth.set_bus_volume("Ambience", volumes["Ambience"])
	Events.emit_signal("settings_changed")

func apply_story_choice(id):
	story_choice = id
	Events.emit_signal("story_choice_made", id)
	if id == "family":
		money += 300
		add_item("cooked_rice", 2)
	elif id == "independent":
		Events.emit_signal("vehicle_bought", "bicycle")
	elif id == "farmer":
		add_item("seed_rice", 6)
		add_item("seed_peanut", 4)

func reset_all():
	money = 500
	xp = 0
	level = 1
	day = 1
	time = 7.0
	weather = "sunny"
	festival = false
	story_stage = 1
	story_choice = ""
	companion = false
	discovered = {"farm": true}
	ui_open = 0
	inventory = InvList.new()
	inventory.capacity = 60
	inventory.add("seed_rice", 4)
	inventory.add("seed_peanut", 3)
	inventory.add("water_bottle", 2)
	inventory.add("cooked_rice", 2)

func save_dict():
	return {
		"money": money,
		"xp": xp,
		"level": level,
		"day": day,
		"time": time,
		"weather": weather,
		"story_stage": story_stage,
		"story_choice": story_choice,
		"companion": companion,
		"discovered": discovered,
		"inventory": inventory.save_dict(),
		"graphics": graphics,
		"volumes": volumes
	}

func load_dict(d):
	money = int(d.get("money", 500))
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	day = int(d.get("day", 1))
	time = float(d.get("time", 7.0))
	weather = str(d.get("weather", "sunny"))
	story_stage = int(d.get("story_stage", 1))
	story_choice = str(d.get("story_choice", ""))
	companion = bool(d.get("companion", false))
	discovered = {}
	var disc = d.get("discovered", {})
	for k in disc.keys():
		discovered[k] = bool(disc[k])
	graphics = int(d.get("graphics", 1))
	var vols = d.get("volumes", {})
	for b in ["Music", "SFX", "Ambience"]:
		if vols.has(b):
			volumes[b] = float(vols[b])
	inventory = InvList.new()
	inventory.capacity = 60
	inventory.load_dict(d.get("inventory", {}))
	ui_open = 0
