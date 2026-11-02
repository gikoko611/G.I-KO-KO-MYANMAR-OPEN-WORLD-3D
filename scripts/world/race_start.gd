extends Spatial
# Race start flag: begin a race with any vehicle.

var race_id = ""

func setup(rid):
	race_id = rid
	var d = ItemDB.RACES.get(rid, {})
	add_child(Props.sign(Color(0.83, 0.68, 0.2)))
	var flag = Props.checkpoint_flag(Color(0.83, 0.68, 0.2))
	flag.translation = Vector3(2.0, 0, 0)
	add_child(flag)

func _ready():
	add_to_group("interactable")

func get_prompt(player=null):
	var d = ItemDB.RACES.get(race_id, {})
	return "Race: " + str(d.get("name", race_id))

func get_actions(player=null):
	return ["Start Race"]

func action(label, player):
	if label == "Start Race":
		get_tree().call_group("world", "start_race", race_id)
