extends Reference
# Mission database: 85+ missions across story, side quests, farm, delivery,
# errands, vehicles, survival, fishing, animals, races, dailies, weeklies,
# world events, achievements and special challenges.
#
# Objective "type" matches an Events signal name. "target" (optional) must
# match the signal's first argument. "amount" is the required count.
# "time" is only used by race objectives (finish under N seconds).

const DEFS = {
	# ---------------- main story ----------------
	"MS1": {"title": "A Fresh Start", "desc": "Grandpa U Ba waves you over. Meet him in Myaing Village.", "cat": "main", "giver": "u_ba", "marker": [-100, 40], "objectives": [{"type": "npc_talked", "target": "u_ba"}], "rewards": {"money": 100, "xp": 10, "items": {"cooked_rice": 2}}, "next": "MS2"},
	"MS2": {"title": "Clearing the Land", "desc": "Gather 5 wood and 3 stone around the valley for farm repairs.", "cat": "main", "giver": "", "marker": [-90, 20], "objectives": [{"type": "generic", "target": "wood", "amount": 5}, {"type": "generic", "target": "stone", "amount": 3}], "rewards": {"money": 150, "xp": 20}, "next": "MS3"},
	"MS3": {"title": "First Furrows", "desc": "Plow 3 plots on the family farm with the hoe.", "cat": "main", "giver": "", "marker": [0, 66], "objectives": [{"type": "field_plowed", "amount": 3}], "rewards": {"money": 150, "xp": 25}, "next": "MS4"},
	"MS4": {"title": "Rice of Life", "desc": "Plant 5 rice seeds. Rice is the soul of Myanmar.", "cat": "main", "giver": "", "marker": [0, 66], "objectives": [{"type": "crop_planted", "target": "rice", "amount": 5}], "rewards": {"money": 150, "xp": 25}, "next": "MS5"},
	"MS5": {"title": "Water from the River", "desc": "Water 5 planted plots. The Ayeyarwady never sleeps.", "cat": "main", "giver": "", "marker": [0, 66], "objectives": [{"type": "plot_watered", "amount": 5}], "rewards": {"money": 200, "xp": 30}, "next": "MS6"},
	"MS6": {"title": "The First Harvest", "desc": "Harvest 5 ripe rice crops.", "cat": "main", "giver": "", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "target": "rice", "amount": 5}], "rewards": {"money": 250, "xp": 40, "items": {"curry": 2}}, "next": "MS7"},
	"MS7": {"title": "Market Day", "desc": "Sell crops 3 times at the town market stalls.", "cat": "main", "giver": "", "marker": [160, 40], "objectives": [{"type": "crop_sold", "amount": 3}], "rewards": {"money": 300, "xp": 50}, "next": "MS8"},
	"MS8": {"title": "The Village Honors You", "desc": "Your name spreads through the valley. Reach level 5.", "cat": "main", "giver": "u_ba", "marker": [0, 60], "objectives": [{"type": "level_up", "amount": 5}], "rewards": {"money": 1000, "xp": 100}, "next": ""},
	# ---------------- side quests ----------------
	"S1": {"title": "The Lost Duckling", "desc": "A fisher's duckling wandered off near Inle Lake. Find it and pick it up gently.", "cat": "side", "giver": "lin", "marker": [-160, -100], "objectives": [{"type": "generic", "target": "duckling", "amount": 1}], "rewards": {"money": 200, "xp": 30, "items": {"water_bottle": 3}}},
	"S2": {"title": "A Gift for the Monk", "desc": "Deliver 5 rice to the Sayadaw at the Golden Hill Pagoda.", "cat": "side", "giver": "sayadaw", "marker": [120, 155], "objectives": [{"type": "item_delivered", "target": "rice", "amount": 5}], "rewards": {"money": 300, "xp": 40}},
	"S3": {"title": "The Fisher's Tale", "desc": "Talk to Ko Lin at the lake, then catch 3 fish.", "cat": "side", "giver": "lin", "marker": [-160, -104], "objectives": [{"type": "npc_talked", "target": "lin"}, {"type": "fish_caught", "amount": 3}], "rewards": {"money": 250, "xp": 35, "items": {"fish_grilled": 3}}},
	"S4": {"title": "Night Watch", "desc": "Villagers worry about spirits after dark. Stay outside near the village from 22:00 for a full minute.", "cat": "side", "giver": "", "marker": [-110, 30], "objectives": [{"type": "generic", "target": "night_out", "amount": 1}], "rewards": {"money": 250, "xp": 40}},
	"S5": {"title": "Cool and Clear", "desc": "Drink from the village well 3 times.", "cat": "side", "giver": "", "marker": [-96, 34], "objectives": [{"type": "player_drank", "amount": 3}], "rewards": {"money": 100, "xp": 15}},
	"S6": {"title": "A Friend in Need", "desc": "Buy any animal from U Phyu in town.", "cat": "side", "giver": "u_phyu", "marker": [163, 33], "objectives": [{"type": "animal_bought", "amount": 1}], "rewards": {"money": 200, "xp": 30}},
	# ---------------- farm ----------------
	"F1": {"title": "Peanut Butter Days", "desc": "Harvest 8 peanut crops.", "cat": "farm", "giver": "ko_tin", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "target": "peanut", "amount": 8}], "rewards": {"money": 200, "xp": 30}},
	"F2": {"title": "Corn Rows", "desc": "Harvest 8 corn crops.", "cat": "farm", "giver": "ko_tin", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "target": "corn", "amount": 8}], "rewards": {"money": 250, "xp": 30}},
	"F3": {"title": "Chili Business", "desc": "Sell 10 chili at the market.", "cat": "farm", "giver": "ma_su", "marker": [160, 40], "objectives": [{"type": "crop_sold", "target": "chili", "amount": 10}], "rewards": {"money": 300, "xp": 40}},
	"F4": {"title": "Golden Sesame", "desc": "Harvest 6 sesame crops.", "cat": "farm", "giver": "", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "target": "sesame", "amount": 6}], "rewards": {"money": 250, "xp": 30}},
	"F5": {"title": "Watermelon Season", "desc": "Harvest 4 watermelon.", "cat": "farm", "giver": "", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "target": "watermelon", "amount": 4}], "rewards": {"money": 300, "xp": 35}},
	"F6": {"title": "Master Farmer", "desc": "Harvest 50 crops of any kind.", "cat": "farm", "giver": "", "marker": [0, 66], "objectives": [{"type": "crop_harvested", "amount": 50}], "rewards": {"money": 800, "xp": 80}},
	# ---------------- delivery ----------------
	"D1": {"title": "Firewood for U Ba", "desc": "Deliver 5 wood to U Ba for the winter store.", "cat": "delivery", "giver": "u_ba", "marker": [-100, 40], "objectives": [{"type": "item_delivered", "target": "wood", "amount": 5}], "rewards": {"money": 120, "xp": 20}},
	"D2": {"title": "Tomatoes for Daw Hla", "desc": "Deliver 5 tomato for the village kitchen.", "cat": "delivery", "giver": "daw_hla", "marker": [-98, 34], "objectives": [{"type": "item_delivered", "target": "tomato", "amount": 5}], "rewards": {"money": 150, "xp": 20, "items": {"curry": 2}}},
	"D3": {"title": "Sesame for Ma Su", "desc": "Deliver 6 sesame to the trader.", "cat": "delivery", "giver": "ma_su", "marker": [-108, 36], "objectives": [{"type": "item_delivered", "target": "sesame", "amount": 6}], "rewards": {"money": 200, "xp": 25}},
	"D4": {"title": "Eggs for Ko Tin", "desc": "Deliver 6 eggs to the farmer.", "cat": "delivery", "giver": "ko_tin", "marker": [-130, 50], "objectives": [{"type": "item_delivered", "target": "egg", "amount": 6}], "rewards": {"money": 150, "xp": 20}},
	"D5": {"title": "Corn for the Livestock", "desc": "Deliver 8 corn to U Phyu for the animals.", "cat": "delivery", "giver": "u_phyu", "marker": [163, 33], "objectives": [{"type": "item_delivered", "target": "corn", "amount": 8}], "rewards": {"money": 220, "xp": 25}},
	# ---------------- errands ----------------
	"E1": {"title": "Greetings", "desc": "Meet the valley: talk to 5 different villagers.", "cat": "errand", "giver": "", "marker": [-110, 30], "objectives": [{"type": "npc_talked", "amount": 5}], "rewards": {"money": 150, "xp": 20}},
	"E2": {"title": "The Monk's Blessing", "desc": "Talk to the Sayadaw 3 times.", "cat": "errand", "giver": "", "marker": [120, 155], "objectives": [{"type": "npc_talked", "target": "sayadaw", "amount": 3}], "rewards": {"money": 150, "xp": 25}},
	"E3": {"title": "Roads of the Valley", "desc": "Discover 4 locations.", "cat": "errand", "giver": "", "marker": [0, 0], "objectives": [{"type": "location_discovered", "amount": 4}], "rewards": {"money": 200, "xp": 30}},
	"E4": {"title": "Weather Report", "desc": "Experience 3 weather changes.", "cat": "errand", "giver": "", "marker": [0, 0], "objectives": [{"type": "weather_changed", "amount": 3}], "rewards": {"money": 100, "xp": 15}},
	"E5": {"title": "Full Circle", "desc": "Discover all 12 locations of the valley.", "cat": "errand", "giver": "", "marker": [0, 0], "objectives": [{"type": "location_discovered", "amount": 12}], "rewards": {"money": 800, "xp": 80}},
	# ---------------- vehicles ----------------
	"V1": {"title": "Two Wheels", "desc": "Buy a bicycle from Ko Zaw.", "cat": "vehicle", "giver": "ko_zaw", "marker": [155, 34], "objectives": [{"type": "vehicle_bought", "target": "bicycle"}], "rewards": {"money": 100, "xp": 20}},
	"V2": {"title": "Need for Speed", "desc": "Buy a motorcycle.", "cat": "vehicle", "giver": "ko_zaw", "marker": [155, 34], "objectives": [{"type": "vehicle_bought", "target": "motorcycle"}], "rewards": {"money": 200, "xp": 30}},
	"V3": {"title": "Road Trip", "desc": "Drive a total of 1000 meters.", "cat": "vehicle", "giver": "", "marker": [0, 0], "objectives": [{"type": "distance_driven", "amount": 1000}], "rewards": {"money": 250, "xp": 35}},
	"V4": {"title": "Family Car", "desc": "Buy a car.", "cat": "vehicle", "giver": "ko_zaw", "marker": [155, 34], "objectives": [{"type": "vehicle_bought", "target": "car"}], "rewards": {"money": 400, "xp": 50}},
	"V5": {"title": "The Boatman", "desc": "Buy a boat and cross the waters.", "cat": "vehicle", "giver": "lin", "marker": [155, 34], "objectives": [{"type": "vehicle_bought", "target": "boat"}], "rewards": {"money": 200, "xp": 30}},
	# ---------------- survival ----------------
	"SV1": {"title": "Well Fed", "desc": "Eat 5 meals.", "cat": "survival", "giver": "", "marker": [0, 0], "objectives": [{"type": "player_ate", "amount": 5}], "rewards": {"money": 100, "xp": 15}},
	"SV2": {"title": "Fresh Water", "desc": "Drink 3 times (well water counts).", "cat": "survival", "giver": "", "marker": [8, 62], "objectives": [{"type": "player_drank", "amount": 3}], "rewards": {"money": 100, "xp": 15}},
	"SV3": {"title": "A Good Night's Rest", "desc": "Sleep 3 times.", "cat": "survival", "giver": "", "marker": [-14, 60], "objectives": [{"type": "player_slept", "amount": 3}], "rewards": {"money": 150, "xp": 20}},
	"SV4": {"title": "Storm Chaser", "desc": "Brave a full minute outside during a storm.", "cat": "survival", "giver": "", "marker": [0, 0], "objectives": [{"type": "generic", "target": "storm_out", "amount": 1}], "rewards": {"money": 300, "xp": 40}},
	# ---------------- fishing ----------------
	"FS1": {"title": "First Catch", "desc": "Catch 1 fish.", "cat": "fishing", "giver": "lin", "marker": [-160, -108], "objectives": [{"type": "fish_caught", "amount": 1}], "rewards": {"money": 100, "xp": 15}},
	"FS2": {"title": "The Dock Master", "desc": "Catch 10 fish.", "cat": "fishing", "giver": "", "marker": [-160, -108], "objectives": [{"type": "fish_caught", "amount": 10}], "rewards": {"money": 300, "xp": 40}},
	"FS3": {"title": "Monster Hunter", "desc": "Catch a fish weighing 3 kg or more.", "cat": "fishing", "giver": "lin", "marker": [-160, -108], "objectives": [{"type": "generic", "target": "big_fish", "amount": 1}], "rewards": {"money": 400, "xp": 50}},
	"FS4": {"title": "Golden Kya Legend", "desc": "Catch the legendary Golden Kya of Inle Lake.", "cat": "fishing", "giver": "lin", "marker": [-160, -130], "objectives": [{"type": "fish_caught", "target": "golden_kya"}], "rewards": {"money": 1500, "xp": 150}},
	# ---------------- animals ----------------
	"A1": {"title": "Egg Economy", "desc": "Collect 10 eggs from your birds.", "cat": "animal", "giver": "", "marker": [0, 54], "objectives": [{"type": "eggs_collected", "amount": 10}], "rewards": {"money": 200, "xp": 25}},
	"A2": {"title": "Milk Run", "desc": "Milk your cow or buffalo 5 times.", "cat": "animal", "giver": "", "marker": [0, 54], "objectives": [{"type": "animal_milked", "amount": 5}], "rewards": {"money": 250, "xp": 30}},
	"A3": {"title": "Feeding Time", "desc": "Feed your animals 10 times.", "cat": "animal", "giver": "", "marker": [0, 54], "objectives": [{"type": "animal_fed", "amount": 10}], "rewards": {"money": 150, "xp": 20}},
	"A4": {"title": "Loyal Friend", "desc": "Buy a dog or cat - a true companion.", "cat": "animal", "giver": "u_phyu", "marker": [163, 33], "objectives": [{"type": "companion_recruited", "amount": 1}], "rewards": {"money": 300, "xp": 40}},
	# ---------------- races ----------------
	"R1": {"title": "Village Loop", "desc": "Finish the Village Loop race at the race track.", "cat": "race", "giver": "", "marker": [-130, -5], "objectives": [{"type": "race_finished", "target": "village_loop"}], "rewards": {"money": 300, "xp": 40}},
	"R2": {"title": "Road Sprint", "desc": "Finish the Road Sprint race along the highway.", "cat": "race", "giver": "", "marker": [0, 55], "objectives": [{"type": "race_finished", "target": "road_sprint"}], "rewards": {"money": 400, "xp": 50}},
	"R3": {"title": "Pagoda Climb", "desc": "Finish the Pagoda Climb race up the golden hill.", "cat": "race", "giver": "", "marker": [110, 90], "objectives": [{"type": "race_finished", "target": "pagoda_climb"}], "rewards": {"money": 500, "xp": 60}},
	# ---------------- timed challenges (repeatable) ----------------
	"TC1": {"title": "Speed Run: Village", "desc": "Finish the Village Loop in under 75 seconds.", "cat": "timed", "giver": "", "marker": [-130, -5], "repeat": true, "objectives": [{"type": "race_finished", "target": "village_loop", "time": 75.0}], "rewards": {"money": 200, "xp": 20}},
	"TC2": {"title": "Speed Run: Highway", "desc": "Finish the Road Sprint in under 90 seconds.", "cat": "timed", "giver": "", "marker": [0, 55], "repeat": true, "objectives": [{"type": "race_finished", "target": "road_sprint", "time": 90.0}], "rewards": {"money": 300, "xp": 30}},
	"TC3": {"title": "Speed Run: Pagoda", "desc": "Finish the Pagoda Climb in under 120 seconds.", "cat": "timed", "giver": "", "marker": [110, 90], "repeat": true, "objectives": [{"type": "race_finished", "target": "pagoda_climb", "time": 120.0}], "rewards": {"money": 400, "xp": 40}},
	# ---------------- hidden quests ----------------
	"H1": {"title": "Treasure Hunter I", "desc": "Mounds of old gold lie buried in the valley. Dig up 1 treasure mound.", "cat": "hidden", "giver": "", "event": "treasure_hunter", "objectives": [{"type": "treasure_found", "amount": 1}], "rewards": {"money": 200, "xp": 30}, "next": "H2"},
	"H2": {"title": "Treasure Hunter II", "desc": "Dig up 5 treasure mounds.", "cat": "hidden", "giver": "", "objectives": [{"type": "treasure_found", "amount": 5}], "rewards": {"money": 500, "xp": 60}, "next": "H3"},
	"H3": {"title": "The Nat's Hoard", "desc": "Every mound in the valley - dig up 8 treasures.", "cat": "hidden", "giver": "", "objectives": [{"type": "treasure_found", "amount": 8}], "rewards": {"money": 1500, "xp": 150}},
	# ---------------- dailies ----------------
	"DA1": {"title": "Daily Chores: Plowing", "desc": "Plow 2 plots today.", "cat": "daily", "giver": "", "objectives": [{"type": "field_plowed", "amount": 2}], "rewards": {"money": 60, "xp": 10}},
	"DA2": {"title": "Daily Harvest", "desc": "Harvest 3 crops today.", "cat": "daily", "giver": "", "objectives": [{"type": "crop_harvested", "amount": 3}], "rewards": {"money": 80, "xp": 12}},
	"DA3": {"title": "Daily Water", "desc": "Water 4 plots today.", "cat": "daily", "giver": "", "objectives": [{"type": "plot_watered", "amount": 4}], "rewards": {"money": 60, "xp": 10}},
	"DA4": {"title": "Daily Catch", "desc": "Catch 2 fish today.", "cat": "daily", "giver": "", "objectives": [{"type": "fish_caught", "amount": 2}], "rewards": {"money": 80, "xp": 12}},
	"DA5": {"title": "Daily Rounds", "desc": "Talk to 2 villagers today.", "cat": "daily", "giver": "", "objectives": [{"type": "npc_talked", "amount": 2}], "rewards": {"money": 50, "xp": 8}},
	"DA6": {"title": "Daily Meal", "desc": "Eat a proper meal today.", "cat": "daily", "giver": "", "objectives": [{"type": "player_ate", "amount": 1}], "rewards": {"money": 40, "xp": 6}},
	"DA7": {"title": "Daily Drive", "desc": "Drive 300 meters today.", "cat": "daily", "giver": "", "objectives": [{"type": "distance_driven", "amount": 300}], "rewards": {"money": 70, "xp": 10}},
	"DA8": {"title": "Daily Eggs", "desc": "Collect 2 eggs today.", "cat": "daily", "giver": "", "objectives": [{"type": "eggs_collected", "amount": 2}], "rewards": {"money": 60, "xp": 10}},
	# ---------------- weeklies ----------------
	"WE1": {"title": "Weekly Trader", "desc": "Earn 1000 kyat this week.", "cat": "weekly", "giver": "", "objectives": [{"type": "money_earned", "amount": 1000}], "rewards": {"money": 300, "xp": 50}},
	"WE2": {"title": "Weekly Harvest", "desc": "Harvest 20 crops this week.", "cat": "weekly", "giver": "", "objectives": [{"type": "crop_harvested", "amount": 20}], "rewards": {"money": 400, "xp": 60}},
	"WE3": {"title": "Weekly Explorer", "desc": "Discover 2 locations this week.", "cat": "weekly", "giver": "", "objectives": [{"type": "location_discovered", "amount": 2}], "rewards": {"money": 300, "xp": 40}},
	"WE4": {"title": "Weekly Angler", "desc": "Catch 8 fish this week.", "cat": "weekly", "giver": "", "objectives": [{"type": "fish_caught", "amount": 8}], "rewards": {"money": 350, "xp": 50}},
	# ---------------- world events ----------------
	"EV1": {"title": "The Wandering Trader", "desc": "A trader from distant markets is here for one day. Buy something from her.", "cat": "event", "giver": "", "event": "trader", "objectives": [{"type": "generic", "target": "trader_buy", "amount": 1}], "rewards": {"money": 150, "xp": 25}},
	"EV2": {"title": "Boar Trouble", "desc": "A wild boar is trampling the fields! Get close and scare it away from the village.", "cat": "event", "giver": "", "event": "boar", "objectives": [{"type": "generic", "target": "boar_chased", "amount": 1}], "rewards": {"money": 200, "xp": 30}},
	"EV3": {"title": "Glint on the Road", "desc": "Someone dropped a pouch on the road today. Dig up today's treasure mound.", "cat": "event", "giver": "", "event": "mound", "objectives": [{"type": "treasure_found", "amount": 1}], "rewards": {"money": 150, "xp": 20}},
	"EV4": {"title": "Festival Day", "desc": "The valley celebrates! Sell 5 items at the festival prices.", "cat": "event", "giver": "", "event": "festival", "objectives": [{"type": "item_sold", "amount": 5}], "rewards": {"money": 250, "xp": 35}},
	# ---------------- achievements ----------------
	"AC1": {"title": "Green Thumb", "desc": "Harvest 100 crops.", "cat": "achv", "giver": "", "objectives": [{"type": "crop_harvested", "amount": 100}], "rewards": {"money": 1000, "xp": 100}},
	"AC2": {"title": "Merchant of the Valley", "desc": "Earn 50,000 kyat in total.", "cat": "achv", "giver": "", "objectives": [{"type": "money_earned", "amount": 50000}], "rewards": {"money": 2000, "xp": 200}},
	"AC3": {"title": "Road Warrior", "desc": "Drive 10,000 meters in total.", "cat": "achv", "giver": "", "objectives": [{"type": "distance_driven", "amount": 10000}], "rewards": {"money": 800, "xp": 80}},
	"AC4": {"title": "Angler Supreme", "desc": "Catch 50 fish.", "cat": "achv", "giver": "", "objectives": [{"type": "fish_caught", "amount": 50}], "rewards": {"money": 800, "xp": 80}},
	"AC5": {"title": "Landowner", "desc": "Build 5 buildings.", "cat": "achv", "giver": "", "objectives": [{"type": "building_built", "amount": 5}], "rewards": {"money": 1000, "xp": 100}},
	"AC6": {"title": "Zookeeper", "desc": "Buy 8 animals.", "cat": "achv", "giver": "", "objectives": [{"type": "animal_bought", "amount": 8}], "rewards": {"money": 800, "xp": 80}},
	"AC7": {"title": "Seasoned Farmer", "desc": "Live through 28 days.", "cat": "achv", "giver": "", "objectives": [{"type": "day_completed", "amount": 28}], "rewards": {"money": 1500, "xp": 150}},
	"AC8": {"title": "Conversationalist", "desc": "Talk to villagers 50 times.", "cat": "achv", "giver": "", "objectives": [{"type": "npc_talked", "amount": 50}], "rewards": {"money": 500, "xp": 60}},
	"AC9": {"title": "Treasure Lord", "desc": "Find 15 treasures.", "cat": "achv", "giver": "", "objectives": [{"type": "treasure_found", "amount": 15}], "rewards": {"money": 1500, "xp": 150}},
	"AC10": {"title": "Legend of the Valley", "desc": "Reach level 20.", "cat": "achv", "giver": "", "objectives": [{"type": "level_up", "amount": 20}], "rewards": {"money": 5000, "xp": 0}},
	# ---------------- special ----------------
	"SP1": {"title": "A New Home", "desc": "Place your first building from the Build menu.", "cat": "special", "giver": "", "marker": [0, 60], "objectives": [{"type": "building_built", "amount": 1}], "rewards": {"money": 300, "xp": 50}},
	"SP2": {"title": "The Golden Pickup", "desc": "Buy the mighty pickup truck.", "cat": "special", "giver": "", "marker": [155, 34], "objectives": [{"type": "vehicle_bought", "target": "pickup"}], "rewards": {"money": 500, "xp": 60}},
	"SP3": {"title": "Nat Mountain", "desc": "Discover the Nat Mountain Peak - the roof of the valley.", "cat": "special", "giver": "", "marker": [230, 150], "objectives": [{"type": "location_discovered", "target": "mountain_peak"}], "rewards": {"money": 500, "xp": 80}}
}
