extends Spatial
# Exit door inside a building interior: teleports the player back outside.

var building = null

func _ready():
	add_to_group("interactable")
	var door = Props.box(1.6, 2.2, 0.2, Color(0.35, 0.25, 0.15))
	door.translation = Vector3(0, 1.1, 0)
	add_child(door)

func get_prompt(player=null):
	return "Exit"

func get_actions(player=null):
	return ["Exit"]

func action(label, player):
	if label == "Exit" and building != null:
		player.exit_building(building)
