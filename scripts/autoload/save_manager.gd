extends Node
# Save manager: JSON save game and settings under user://, with corruption
# quarantine so a broken save never crashes the game.

const SAVE_PATH = "user://savegame.json"
const SETTINGS_PATH = "user://settings.json"

func _ready():
	_load_settings()

func has_save():
	var f = File.new()
	return f.file_exists(SAVE_PATH)

func save_game(manual=true):
	var data = {
		"version": 1,
		"game": GameState.save_dict(),
		"missions": Missions.save_dict(),
		"world": {},
		"player": {}
	}
	var worlds = get_tree().get_nodes_in_group("world")
	if worlds.size() > 0:
		data["world"] = worlds[0].save_dict()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		data["player"] = players[0].save_dict()
	var f = File.new()
	if f.open(SAVE_PATH, File.WRITE) != OK:
		Events.emit_signal("notify", "Save Failed", "Could not write the save file.")
		return false
	f.store_string(to_json(data))
	f.close()
	if manual:
		Events.emit_signal("notify", "Game Saved", "Day " + str(GameState.day) + " - your progress is safe.")
		AudioSynth.play("accept")
	return true

func load_game():
	var f = File.new()
	if not f.file_exists(SAVE_PATH):
		Events.emit_signal("notify", "No Save Found", "Start a New Game first.")
		return false
	if f.open(SAVE_PATH, File.READ) != OK:
		return false
	var txt = f.get_as_text()
	f.close()
	var data = parse_json(txt)
	if typeof(data) != TYPE_DICTIONARY:
		_quarantine(txt)
		Events.emit_signal("notify", "Save Corrupted", "The save file was damaged and moved aside.")
		return false
	GameState.load_dict(data.get("game", {}))
	Missions.load_dict(data.get("missions", {}))
	var worlds = get_tree().get_nodes_in_group("world")
	if worlds.size() > 0 and data.has("world"):
		worlds[0].load_dict(data["world"])
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and data.has("player"):
		players[0].load_dict(data["player"])
	Events.emit_signal("notify", "Game Loaded", "Welcome back!")
	return true

func delete_save():
	var dir = Directory.new()
	if dir.open("user://") == OK:
		dir.remove("savegame.json")

func _quarantine(txt):
	var f = File.new()
	if f.open("user://savegame.corrupt.json", File.WRITE) == OK:
		f.store_string(txt)
		f.close()
	var dir = Directory.new()
	if dir.open("user://") == OK:
		dir.remove("savegame.json")

func _load_settings():
	var f = File.new()
	if not f.file_exists(SETTINGS_PATH):
		return
	if f.open(SETTINGS_PATH, File.READ) != OK:
		return
	var d = parse_json(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return
	GameState.graphics = int(d.get("graphics", 1))
	var vols = d.get("volumes", {})
	for b in ["Music", "SFX", "Ambience"]:
		if vols.has(b):
			GameState.volumes[b] = float(vols[b])

func save_settings():
	var f = File.new()
	if f.open(SETTINGS_PATH, File.WRITE) != OK:
		return
	f.store_string(to_json({"graphics": GameState.graphics, "volumes": GameState.volumes}))
	f.close()
