extends Node
# Static game database: crops, items, fish, vehicles, buildings, animals,
# NPCs, locations, races and story backgrounds. All data, no logic.

const CROPS = {
	"rice": {"name": "Rice", "seed": 12, "sell": 38, "grow": 1.0, "xp": 5, "seasons": [0, 1, 2, 3]},
	"peanut": {"name": "Peanut", "seed": 10, "sell": 30, "grow": 1.2, "xp": 5, "seasons": [0, 1, 2]},
	"sesame": {"name": "Sesame", "seed": 15, "sell": 42, "grow": 1.4, "xp": 6, "seasons": [0, 3]},
	"corn": {"name": "Corn", "seed": 14, "sell": 46, "grow": 1.6, "xp": 7, "seasons": [1, 2, 3]},
	"tomato": {"name": "Tomato", "seed": 18, "sell": 52, "grow": 1.5, "xp": 8, "seasons": [1, 2]},
	"chili": {"name": "Chili", "seed": 20, "sell": 60, "grow": 1.8, "xp": 9, "seasons": [1, 2, 3]},
	"cucumber": {"name": "Cucumber", "seed": 16, "sell": 40, "grow": 1.3, "xp": 6, "seasons": [1, 2]},
	"eggplant": {"name": "Eggplant", "seed": 17, "sell": 48, "grow": 1.7, "xp": 8, "seasons": [2, 3]},
	"watermelon": {"name": "Watermelon", "seed": 22, "sell": 70, "grow": 2.0, "xp": 10, "seasons": [2, 3]},
	"mango": {"name": "Mango", "seed": 30, "sell": 95, "grow": 2.4, "xp": 12, "seasons": [2, 3]},
	"banana": {"name": "Banana", "seed": 26, "sell": 78, "grow": 2.2, "xp": 11, "seasons": [0, 1, 2, 3]},
	"thanatkha": {"name": "Thanatkha", "seed": 24, "sell": 68, "grow": 2.0, "xp": 10, "seasons": [0, 1, 2, 3]}
}

const ITEMS = {
	"wood": {"name": "Wood", "sell": 4, "buy": 10, "kind": "material", "desc": "Chopped logs from the forest."},
	"stone": {"name": "Stone", "sell": 5, "buy": 12, "kind": "material", "desc": "Quarried rock for building."},
	"water_bottle": {"name": "Water Bottle", "sell": 3, "buy": 8, "kind": "drink", "desc": "Clean drinking water."},
	"cooked_rice": {"name": "Cooked Rice", "sell": 10, "buy": 22, "kind": "food", "desc": "Warm and filling.", "food": 30},
	"fish_grilled": {"name": "Grilled Fish", "sell": 14, "buy": 30, "kind": "food", "desc": "Smoky lake fish.", "food": 35},
	"curry": {"name": "Curry", "sell": 20, "buy": 45, "kind": "food", "desc": "Hearty village curry.", "food": 55},
	"tea_leaf": {"name": "Tea Leaf", "sell": 12, "buy": 25, "kind": "food", "desc": "Fermented pickled tea.", "food": 10},
	"fishing_rod": {"name": "Fishing Rod", "sell": 0, "buy": 60, "kind": "tool", "desc": "Cast from the dock or shore."},
	"treasure_chest": {"name": "Treasure Chest", "sell": 150, "buy": 0, "kind": "treasure", "desc": "An ancient chest of gold!"},
	"truffle": {"name": "Truffle", "sell": 45, "buy": 0, "kind": "food", "desc": "A rare forest find.", "food": 20},
	"milk": {"name": "Milk", "sell": 18, "buy": 0, "kind": "food", "desc": "Fresh from the cow.", "food": 12},
	"egg": {"name": "Egg", "sell": 8, "buy": 0, "kind": "food", "desc": "Farm-fresh egg.", "food": 8}
}

const FISH = {
	"carp": {"name": "Carp", "sell": 20, "rarity": 0.45, "wmin": 0.5, "wmax": 2.0},
	"tilapia": {"name": "Tilapia", "sell": 16, "rarity": 0.55, "wmin": 0.4, "wmax": 1.5},
	"catfish": {"name": "Catfish", "sell": 28, "rarity": 0.25, "wmin": 1.0, "wmax": 4.0},
	"snakehead": {"name": "Snakehead", "sell": 35, "rarity": 0.18, "wmin": 0.8, "wmax": 3.5},
	"perch": {"name": "Perch", "sell": 24, "rarity": 0.35, "wmin": 0.3, "wmax": 1.2},
	"eel": {"name": "Eel", "sell": 40, "rarity": 0.12, "wmin": 0.5, "wmax": 2.5},
	"shrimp": {"name": "Shrimp", "sell": 12, "rarity": 0.60, "wmin": 0.05, "wmax": 0.3},
	"golden_kya": {"name": "Golden Kya", "sell": 120, "rarity": 0.03, "wmin": 1.0, "wmax": 2.0}
}

const VEHICLES = {
	"bicycle": {"name": "Bicycle", "cost": 250, "color": Color(0.25, 0.5, 0.9), "speed": 6.0, "accel": 4.0, "water": false},
	"motorcycle": {"name": "Motorcycle", "cost": 1200, "color": Color(0.85, 0.2, 0.2), "speed": 14.0, "accel": 7.0, "water": false},
	"car": {"name": "Car", "cost": 4500, "color": Color(0.3, 0.55, 0.3), "speed": 18.0, "accel": 8.0, "water": false},
	"pickup": {"name": "Pickup Truck", "cost": 8000, "color": Color(0.55, 0.4, 0.2), "speed": 16.0, "accel": 6.0, "water": false},
	"farm_truck": {"name": "Farm Truck", "cost": 6000, "color": Color(0.5, 0.5, 0.55), "speed": 12.0, "accel": 5.0, "water": false},
	"tractor": {"name": "Tractor", "cost": 3500, "color": Color(0.75, 0.55, 0.1), "speed": 8.0, "accel": 3.0, "water": false},
	"boat": {"name": "Boat", "cost": 900, "color": Color(0.4, 0.6, 0.8), "speed": 7.0, "accel": 3.0, "water": true}
}

const BUILDINGS = {
	"house": {"name": "House", "cost": 0, "cap": 20, "color": Color(0.85, 0.72, 0.5), "interior": "house"},
	"farmhouse": {"name": "Farmhouse", "cost": 2500, "cap": 40, "color": Color(0.8, 0.65, 0.4), "interior": "farmhouse", "mats": {"wood": 40, "stone": 20}},
	"animal_barn": {"name": "Animal Barn", "cost": 1800, "cap": 30, "color": Color(0.7, 0.5, 0.35), "interior": "animal_barn", "mats": {"wood": 30, "stone": 10}},
	"warehouse": {"name": "Warehouse", "cost": 2200, "cap": 80, "color": Color(0.55, 0.55, 0.6), "interior": "warehouse", "mats": {"wood": 25, "stone": 35}},
	"market_shop": {"name": "Market Shop", "cost": 3200, "cap": 10, "color": Color(0.83, 0.68, 0.2), "interior": "market_shop", "mats": {"wood": 35, "stone": 25}},
	"workshop": {"name": "Workshop", "cost": 2800, "cap": 10, "color": Color(0.5, 0.5, 0.55), "interior": "workshop", "mats": {"wood": 30, "stone": 30}},
	"water_tower": {"name": "Water Tower", "cost": 1500, "cap": 0, "color": Color(0.4, 0.55, 0.6), "interior": "", "mats": {"wood": 15, "stone": 45}},
	"guest_house": {"name": "Guest House", "cost": 5000, "cap": 20, "color": Color(0.75, 0.6, 0.55), "interior": "guest_house", "mats": {"wood": 60, "stone": 30}},
	"garage": {"name": "Garage", "cost": 4000, "cap": 10, "color": Color(0.45, 0.45, 0.5), "interior": "garage", "mats": {"wood": 20, "stone": 40}},
	"rice_storage": {"name": "Rice Storage", "cost": 2600, "cap": 120, "color": Color(0.78, 0.7, 0.5), "interior": "rice_storage", "mats": {"wood": 45, "stone": 20}}
}

const ANIMALS = {
	"chicken": {"name": "Chicken", "cost": 200, "sound": "cluck"},
	"duck": {"name": "Duck", "cost": 250, "sound": "chirp"},
	"cow": {"name": "Cow", "cost": 1500, "sound": "moo"},
	"buffalo": {"name": "Buffalo", "cost": 2500, "sound": "moo"},
	"goat": {"name": "Goat", "cost": 700, "sound": "chirp"},
	"pig": {"name": "Pig", "cost": 900, "sound": "moo"},
	"dog": {"name": "Dog", "cost": 500, "sound": "bark"},
	"cat": {"name": "Cat", "cost": 400, "sound": "chirp"}
}

const NPCS = {
	"u_ba": {"name": "U Ba", "role": "Village Elder", "shop": "", "color": Color(0.85, 0.55, 0.2), "home": [-110, 28], "work": [-100, 40], "lines": ["Welcome to our village!", "The river gives, the river takes.", "Hard work is honest work."]},
	"ko_tin": {"name": "Ko Tin", "role": "Farmer", "shop": "seed", "color": Color(0.3, 0.55, 0.2), "home": [-125, 45], "work": [-130, 50], "lines": ["The soil is rich this season.", "Rice feeds the whole nation.", "Buy seeds from me, plant them well."]},
	"daw_hla": {"name": "Daw Hla", "role": "Cook", "shop": "general", "color": Color(0.75, 0.2, 0.2), "home": [-95, 20], "work": [-98, 34], "lines": ["Fresh curry, still hot!", "My soup heals any tiredness.", "Come eat before you work."]},
	"ma_su": {"name": "Ma Su", "role": "Trader", "shop": "market", "color": Color(0.2, 0.45, 0.75), "home": [-105, 42], "work": [-108, 36], "lines": ["Best prices on this side of the river!", "I sell a little of everything.", "Bring me crops and I pay fair."]},
	"sayadaw": {"name": "Sayadaw", "role": "Monk", "shop": "", "color": Color(0.9, 0.8, 0.1), "home": [120, 156], "work": [120, 150], "lines": ["Peace comes from within.", "Generosity is the first virtue.", "May your harvest be bountiful."]},
	"lin": {"name": "Ko Lin", "role": "Fisher", "shop": "general", "color": Color(0.2, 0.5, 0.6), "home": [-160, -100], "work": [-158, -104], "lines": ["The lake is quiet this morning.", "Patience is a fisher's weapon.", "Even the Golden Kya bites, sometimes."]},
	"thiri": {"name": "Thiri", "role": "Wandering Trader", "shop": "market", "color": Color(0.6, 0.3, 0.6), "home": [0, 0], "work": [0, 0], "lines": ["One day only! Special stock!", "Rare goods from distant markets!", "You will not see these prices again."]},
	"ko_zaw": {"name": "Ko Zaw", "role": "Mechanic", "shop": "vehicle", "color": Color(0.35, 0.35, 0.35), "home": [150, 30], "work": [155, 34], "lines": ["An engine is like a heart.", "Drive safe, the roads are rough.", "Bring me your broken machines."]},
	"u_phyu": {"name": "U Phyu", "role": "Livestock Keeper", "shop": "animal", "color": Color(0.6, 0.5, 0.3), "home": [168, 26], "work": [163, 33], "lines": ["Animals know a kind hand.", "Feed them well and they feed you.", "A buffalo is a farmer's treasure."]},
	"daw_mya": {"name": "Daw Mya", "role": "Shopkeeper", "shop": "seed", "color": Color(0.8, 0.6, 0.75), "home": [172, 48], "work": [145, 48], "lines": ["Seeds today, harvest tomorrow.", "Mango saplings just arrived!", "Every seed is a promise."]},
	"ko_mg": {"name": "Ko Mg", "role": "Fuel Vendor", "shop": "fuel", "color": Color(0.7, 0.4, 0.1), "home": [163, 22], "work": [150, 20], "lines": ["Fuel for the long roads!", "Never run dry in the hills.", "My prices are honest."]}
}

const LOCATIONS = [
	{"id": "farm", "name": "The Family Farm", "pos": [0, 60], "hidden": false, "reward": 0},
	{"id": "village", "name": "Myaing Village", "pos": [-110, 30], "hidden": false, "reward": 0},
	{"id": "town", "name": "Yangon Market Town", "pos": [160, 40], "hidden": false, "reward": 0},
	{"id": "pagoda", "name": "Golden Hill Pagoda", "pos": [120, 158], "hidden": false, "reward": 50},
	{"id": "river_bridge", "name": "Old River Bridge", "pos": [-160, -84], "hidden": false, "reward": 50},
	{"id": "lake", "name": "Inle Lake", "pos": [-160, -130], "hidden": false, "reward": 100},
	{"id": "paddies", "name": "Rice Paddies", "pos": [-60, -95], "hidden": false, "reward": 50},
	{"id": "waterfall", "name": "Hidden Waterfall", "pos": [40, 105], "hidden": true, "reward": 150},
	{"id": "shrine", "name": "Forest Shrine", "pos": [60, -140], "hidden": true, "reward": 150},
	{"id": "lake_island", "name": "Island of the Golden Kya", "pos": [-160, -130], "hidden": true, "reward": 200},
	{"id": "mountain_peak", "name": "Nat Mountain Peak", "pos": [230, 150], "hidden": true, "reward": 300},
	{"id": "race_track", "name": "Village Race Track", "pos": [-85, -5], "hidden": false, "reward": 50}
]

const RACES = {
	"village_loop": {"name": "Village Loop", "start": [-130, -5], "checkpoints": [[-130, -5], [-150, 20], [-120, 55], [-75, 45], [-70, 15]], "reward": 400, "time_target": 75.0},
	"road_sprint": {"name": "Road Sprint", "start": [0, 55], "checkpoints": [[60, 45], [110, 40], [160, 40], [160, 10]], "reward": 600, "time_target": 90.0},
	"pagoda_climb": {"name": "Pagoda Climb", "start": [110, 90], "checkpoints": [[118, 120], [112, 150], [120, 158]], "reward": 800, "time_target": 120.0}
}

const TREASURE_SPOTS = [
	[45, 150],
	[200, 90],
	[-190, 30],
	[90, -120],
	[-40, 160]
]

const STORIES = {
	"family": {"name": "Family Duty", "desc": "Your parents are aging. Restore the family farm, feed the village, and make them proud. The whole village helps a hard-working farmer.", "bonus": "money"},
	"independent": {"name": "Fresh Start", "desc": "You came to this valley with nothing but a bicycle and big dreams. Nobody gives you anything - you build your fortune yourself.", "bonus": "vehicle"},
	"farmer": {"name": "Golden Harvest", "desc": "Farming flows in your blood. Crops grow faster in your hands and the land rewards your patience.", "bonus": "farming"}
}

func crop(id):
	return CROPS.get(id, {})

func item(id):
	if ITEMS.has(id):
		return ITEMS[id]
	if id.begins_with("seed_"):
		var cid = id.substr(5)
		if CROPS.has(cid):
			return {"name": "Seeds: " + CROPS[cid]["name"], "sell": int(CROPS[cid]["seed"] / 2), "buy": CROPS[cid]["seed"], "kind": "seed", "crop": cid, "desc": "Plant these in a plowed plot."}
	if FISH.has(id):
		return {"name": FISH[id]["name"], "sell": FISH[id]["sell"], "buy": 0, "kind": "fish", "desc": "Fresh catch from the lake.", "weight": true}
	return {"name": id, "sell": 0, "buy": 0, "kind": "material", "desc": ""}

func display_name(id):
	if id.begins_with("seed_"):
		return item(id)["name"]
	return item(id)["name"]

func sell_price(id):
	return int(item(id).get("sell", 0))

func kind_of(id):
	return str(item(id).get("kind", "material"))

func fish(id):
	return FISH.get(id, {})

func vehicle(id):
	return VEHICLES.get(id, {})

func building(id):
	return BUILDINGS.get(id, {})

func animal(id):
	return ANIMALS.get(id, {})

func npc(id):
	return NPCS.get(id, {})

func npc_pos(id, key):
	var d = NPCS.get(id, {})
	if d.has(key):
		return d[key]
	return [0, 0]

func season(day):
	# 0 summer, 1 rainy, 2 cool, 3 cold (7 days each, 28-day year)
	return int(day / 7) % 4
