extends Spatial
# A freshly laid egg pickup.

func setup(pos):
	translation = pos
	add_child(Props.egg())

func _ready():
	add_to_group("interactable")
	add_to_group("egg")

func get_prompt(player=null):
	return "Fresh egg"

func get_actions(player=null):
	if visible:
		return ["Pick Up"]
	return []

func action(label, player):
	if not visible:
		return
	GameState.add_item("egg", 1)
	Events.emit_signal("eggs_collected", 1)
	AudioSynth.play("coin")
	Events.emit_signal("notify", "Egg Collected", "One fresh egg added to your bag.")
	queue_free()
