extends Spatial
# A drinking well: free water that restores thirst (mission SV2/S5).

func _ready():
	add_to_group("interactable")
	add_child(Props.well())

func get_prompt(player=null):
	return "Drink from the well"

func get_actions(player=null):
	return ["Drink"]

func action(label, player):
	if label == "Drink":
		player.thirst = min(100.0, player.thirst + 35.0)
		Events.emit_signal("player_drank")
		AudioSynth.play("water")
		Events.emit_signal("notify", "Refreshed", "Cool, clean well water.")
