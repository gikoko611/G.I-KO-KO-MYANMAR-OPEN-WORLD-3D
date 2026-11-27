extends Node
# Save manager: JSON save game and settings under user://.
# Writes are crash-safe: data goes to a .tmp file first, is verified, the old
# save is kept as .bak, and only then the new file replaces it. If the main
# save is damaged, loading falls back to the backup automatically.

const SAVE_PATH = "user://savegame.json"
const SAVE_TEMP = "user://savegame.tmp"
const SAVE_BACKUP = "user://savegame.bak"
const SETTINGS_PATH = "user://settings.json"
const SETTINGS_TEMP = "user://settings.tmp"
const SETTINGS_BACKUP = "user://settings.bak"
const SAVE_VERSION = 2

func _ready():
	_load_settings()

func has_save():
	var f = File.new()
	return f.file_exists(SAVE_PATH) or f.file_exists(SAVE_BACKUP)

func save_game(manual=true):
	var data = {
		"version": SAVE_VERSION,
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
	if not _write_atomic(SAVE_PATH, SAVE_TEMP, SAVE_BACKUP, to_json(data)):
		Events.emit_signal("notify", "Save Failed", "Could not write the save file. Free some phone storage and try again.")
		return false
	if manual:
		Events.emit_signal("notify", "Game Saved", "Day " + str(GameState.day) + " - your progress is safe.")
		AudioSynth.play("accept")
	return true

func load_game():
	var data = _read_dict(SAVE_PATH)
	var from_backup = false
	if data.empty():
		var f = File.new()
		if f.file_exists(SAVE_PATH):
			_quarantine(SAVE_PATH)
		data = _read_dict(SAVE_BACKUP)
		from_backup = not data.empty()
	if data.empty():
		Events.emit_signal("notify", "No Save Found", "Start a New Game first.")
		return false
	GameState.load_dict(data.get("game", {}))
	Missions.load_dict(data.get("missions", {}))
	var worlds = get_tree().get_nodes_in_group("world")
	if worlds.size() > 0 and data.has("world"):
		worlds[0].load_dict(data["world"])
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and data.has("player"):
		players[0].load_dict(data["player"])
	if from_backup:
		Events.emit_signal("notify", "Backup Loaded", "The latest save was damaged, so the previous save was restored.")
	else:
		Events.emit_signal("notify", "Game Loaded", "Welcome back!")
	return true

func delete_save():
	var dir = Directory.new()
	if dir.open("user://") == OK:
		for p in [SAVE_PATH, SAVE_TEMP, SAVE_BACKUP]:
			if dir.file_exists(p):
				dir.remove(p)

# ---------------------------------------------------------------- helpers

func _read_dict(path):
	var f = File.new()
	if not f.file_exists(path):
		return {}
	if f.open(path, File.READ) != OK:
		return {}
	var txt = f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return {}
	var parsed = parse_json(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _write_atomic(path, temp_path, backup_path, text):
	var dir = Directory.new()
	if dir.open("user://") != OK:
		return false
	var f = File.new()
	if f.open(temp_path, File.WRITE) != OK:
		return false
	f.store_string(text)
	f.close()
	# Verify the temp file before touching the real save.
	if _read_dict(temp_path).empty():
		dir.remove(temp_path)
		return false
	if dir.file_exists(path):
		if dir.file_exists(backup_path):
			dir.remove(backup_path)
		if dir.rename(path, backup_path) != OK:
			dir.remove(temp_path)
			return false
	if dir.rename(temp_path, path) != OK:
		if not dir.file_exists(path) and dir.file_exists(backup_path):
			dir.copy(backup_path, path)
		dir.remove(temp_path)
		return false
	return true

func _quarantine(path):
	var dir = Directory.new()
	if dir.open("user://") != OK:
		return
	var target = "user://savegame.corrupt.json"
	if dir.file_exists(target):
		dir.remove(target)
	dir.rename(path, target)

func _load_settings():
	var d = _read_dict(SETTINGS_PATH)
	if d.empty():
		d = _read_dict(SETTINGS_BACKUP)
	if d.empty():
		# First launch: keep the LOW preset from GameState (Redmi 9A default).
		return
	GameState.graphics = int(clamp(int(d.get("graphics", 0)), 0, 2))
	var vols = d.get("volumes", {})
	if typeof(vols) == TYPE_DICTIONARY:
		for b in ["Music", "SFX", "Ambience"]:
			if vols.has(b):
				GameState.volumes[b] = clamp(float(vols[b]), 0.0, 1.0)

func save_settings():
	var payload = to_json({"graphics": GameState.graphics, "volumes": GameState.volumes})
	_write_atomic(SETTINGS_PATH, SETTINGS_TEMP, SETTINGS_BACKUP, payload)
