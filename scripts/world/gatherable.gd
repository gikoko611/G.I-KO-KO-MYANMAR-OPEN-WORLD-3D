extends Spatial
# A gatherable wood log or stone pile. Respawns after two days.

var kind = "wood"
var respawn_day = 0
var forest = false

func setup(k, pos, in_forest=false):
	kind = k
	forest = in_forest
	translation = pos
	if k == "wood":
		var log = Props.cyl(0.28, 0.28, 2.2, Color(0.42, 0.3, 0.18))
		log.rotation_degrees = Vector3(0, rand_range(0.0, 360.0), 90)
		log.translation = Vector3(0, 0.3, 0)
		add_child(log)
	else:
		var rock = Props.rock()
		rock.translation = Vector3(0, 0.3, 0)
		add_child(rock)

func _ready():
	add_to_group("interactable")
	add_to_group("gatherable")

func get_prompt(player=null):
	if kind == "wood":
		return "Fallen log"
	return "Stone pile"

func get_actions(player=null):
	if visible:
		if kind == "wood":
			return ["Chop"]
		return ["Mine"]
	return []

func action(label, player):
	if not visible:
		return
	if label == "Chop":
		var n = 3
		GameState.add_item("wood", n)
		Events.emit_signal("generic", "wood", n)
		GameState.add_xp(2)
		AudioSynth.play("chop")
		if forest and randf() < 0.12:
			GameState.add_item("truffle", 1)
			Events.emit_signal("notify", "Rare Find!", "You found a truffle under the log!")
	elif label == "Mine":
		var n2 = 2
		GameState.add_item("stone", n2)
		Events.emit_signal("generic", "stone", n2)
		GameState.add_xp(2)
		AudioSynth.play("dig")
	visible = false
	respawn_day = GameState.day + 2

func try_respawn(day):
	if respawn_day > 0 and day >= respawn_day:
		visible = true
		respawn_day = 0
