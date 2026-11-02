extends Spatial
# A buried treasure mound: dig it up for a valuable chest.

var respawn_day = 0

func setup(pos):
	translation = pos
	add_child(Props.treasure_mound())

func _ready():
	add_to_group("interactable")
	add_to_group("treasure")

func get_prompt(player=null):
	if visible:
		return "Treasure mound"
	return ""

func get_actions(player=null):
	if visible:
		return ["Dig"]
	return []

func action(label, player):
	if not visible:
		return
	GameState.add_item("treasure_chest", 1)
	Events.emit_signal("treasure_found")
	GameState.add_xp(15)
	AudioSynth.play("dig")
	AudioSynth.play("coin")
	Events.emit_signal("notify", "Treasure!", "You dug up a treasure chest! (sell it at the market)")
	visible = false
	respawn_day = GameState.day + 7

func try_respawn(day):
	if respawn_day > 0 and day >= respawn_day:
		visible = true
		respawn_day = 0
