extends Node
# Three-slot JSON save manager under user://.
# Each slot uses a temp file plus a backup so a power loss or Android kill
# cannot overwrite the last valid save. Legacy savegame.json is treated as
# slot 1 and migrated after the first successful slot-1 save.

const SLOT_COUNT = 3
const SAVE_VERSION = 3
const LEGACY_PATH = "user://savegame.json"
const LEGACY_TEMP = "user://savegame.tmp"
const LEGACY_BACKUP = "user://savegame.bak"
const SETTINGS_PATH = "user://settings.json"
const SETTINGS_TEMP = "user://settings.tmp"
const SETTINGS_BACKUP = "user://settings.bak"

var current_slot = 1

func _ready():
	_load_settings()

func set_current_slot(slot):
	current_slot = _valid_slot(slot)

func get_current_slot():
	return current_slot

func has_save(slot=-1):
	var s = current_slot if int(slot) == -1 else _valid_slot(slot)
	var f = File.new()
	if f.file_exists(_slot_path(s)) or f.file_exists(_slot_backup(s)):
		return true
	return s == 1 and (f.file_exists(LEGACY_PATH) or f.file_exists(LEGACY_BACKUP))

func has_any_save():
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false

func slot_summary(slot):
	var s = _valid_slot(slot)
	var data = _read_slot(s)
	if data.empty():
		return {"slot": s, "exists": false, "label": "Empty slot"}
	var game = data.get("game", {})
	if typeof(game) != TYPE_DICTIONARY:
		game = {}
	return {
		"slot": s,
		"exists": true,
		"day": int(game.get("day", 1)),
		"level": int(game.get("level", 1)),
		"money": int(game.get("money", 0)),
		"story_choice": str(game.get("story_choice", "")),
		"label": "Day " + str(int(game.get("day", 1))) + "  Level " + str(int(game.get("level", 1))) + "  K " + str(int(game.get("money", 0)))
	}

func save_game(manual=true, slot=-1):
	var s = current_slot if int(slot) == -1 else _valid_slot(slot)
	current_slot = s
	var data = {
		"version": SAVE_VERSION,
		"slot": s,
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
	if not _write_atomic(_slot_path(s), _slot_temp(s), _slot_backup(s), to_json(data)):
		Events.emit_signal("notify", "Save Failed", "Could not write slot " + str(s) + ". Free some phone storage and try again.")
		return false
	if s == 1:
		_remove_legacy_files()
	if manual:
		Events.emit_signal("notify", "Game Saved", "Slot " + str(s) + " - Day " + str(GameState.day) + ".")
		AudioSynth.play("accept")
	return true

func load_game(slot=-1):
	var s = current_slot if int(slot) == -1 else _valid_slot(slot)
	current_slot = s
	var data = _read_dict(_slot_path(s))
	var from_backup = false
	var from_legacy = false
	if data.empty():
		var f = File.new()
		if f.file_exists(_slot_path(s)):
			_quarantine(_slot_path(s), s)
		data = _read_dict(_slot_backup(s))
		from_backup = not data.empty()
	if data.empty() and s == 1:
		data = _read_dict(LEGACY_PATH)
		if data.empty():
			data = _read_dict(LEGACY_BACKUP)
		from_legacy = not data.empty()
	if data.empty():
		Events.emit_signal("notify", "No Save Found", "Slot " + str(s) + " is empty.")
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
		Events.emit_signal("notify", "Backup Loaded", "Slot " + str(s) + " was damaged, so its previous save was restored.")
	elif from_legacy:
		Events.emit_signal("notify", "Old Save Loaded", "Your original save is now open in slot 1. It will migrate on the next save.")
	else:
		Events.emit_signal("notify", "Game Loaded", "Slot " + str(s) + " loaded.")
	return true

func delete_save(slot=-1):
	var s = current_slot if int(slot) == -1 else _valid_slot(slot)
	var dir = Directory.new()
	if dir.open("user://") == OK:
		for p in [_slot_path(s), _slot_temp(s), _slot_backup(s), _slot_corrupt(s)]:
			_remove_if_present(dir, p)
		if s == 1:
			_remove_legacy_files()
	return true

# ---------------------------------------------------------------- helpers

func _valid_slot(slot):
	return int(clamp(int(slot), 1, SLOT_COUNT))

func _slot_path(slot):
	return "user://savegame_slot_" + str(_valid_slot(slot)) + ".json"

func _slot_temp(slot):
	return "user://savegame_slot_" + str(_valid_slot(slot)) + ".tmp"

func _slot_backup(slot):
	return "user://savegame_slot_" + str(_valid_slot(slot)) + ".bak"

func _slot_corrupt(slot):
	return "user://savegame_slot_" + str(_valid_slot(slot)) + ".corrupt.json"

func _read_slot(slot):
	var s = _valid_slot(slot)
	var data = _read_dict(_slot_path(s))
	if data.empty():
		data = _read_dict(_slot_backup(s))
	if data.empty() and s == 1:
		data = _read_dict(LEGACY_PATH)
		if data.empty():
			data = _read_dict(LEGACY_BACKUP)
	return data

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

func _quarantine(path, slot):
	var dir = Directory.new()
	if dir.open("user://") != OK:
		return
	var target = _slot_corrupt(slot)
	_remove_if_present(dir, target)
	dir.rename(path, target)

func _remove_if_present(dir, path):
	if dir.file_exists(path):
		dir.remove(path)

func _remove_legacy_files():
	var dir = Directory.new()
	if dir.open("user://") != OK:
		return
	for p in [LEGACY_PATH, LEGACY_TEMP, LEGACY_BACKUP, "user://savegame.corrupt.json"]:
		_remove_if_present(dir, p)

func _load_settings():
	var d = _read_dict(SETTINGS_PATH)
	if d.empty():
		d = _read_dict(SETTINGS_BACKUP)
	if d.empty():
		return
	GameState.graphics = int(clamp(int(d.get("graphics", 0)), 0, 2))
	current_slot = _valid_slot(d.get("current_slot", 1))
	var vols = d.get("volumes", {})
	if typeof(vols) == TYPE_DICTIONARY:
		for b in ["Music", "SFX", "Ambience"]:
			if vols.has(b):
				GameState.volumes[b] = clamp(float(vols[b]), 0.0, 1.0)

func save_settings():
	var payload = to_json({"graphics": GameState.graphics, "volumes": GameState.volumes, "current_slot": current_slot})
	_write_atomic(SETTINGS_PATH, SETTINGS_TEMP, SETTINGS_BACKUP, payload)
