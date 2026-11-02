extends KinematicBody
# The lost duckling: pick it up gently and it follows you forever.

var rescued = false
var quack_t = 3.0

func setup(pos):
	translation = pos
	var cs = CollisionShape.new()
	var sb = SphereShape.new()
	sb.radius = 0.25
	cs.shape = sb
	cs.translation = Vector3(0, 0.25, 0)
	add_child(cs)
	add_child(Props.animal_mesh("duck"))
	scale = Vector3(0.5, 0.5, 0.5)

func _ready():
	add_to_group("interactable")

func _physics_process(delta):
	quack_t -= delta
	if quack_t <= 0.0:
		quack_t = rand_range(4.0, 10.0)
		var ps = get_tree().get_nodes_in_group("player")
		if ps.size() > 0 and ps[0].translation.distance_to(translation) < 12.0:
			AudioSynth.play("chirp", -8.0)
	if not rescued:
		return
	var ps = get_tree().get_nodes_in_group("player")
	if ps.size() == 0:
		return
	var p = ps[0]
	var d = translation.distance_to(p.translation)
	if d > 1.8:
		var dir = translation.direction_to(p.translation)
		dir.y = 0
		move_and_slide(dir.normalized() * 2.4, Vector3.UP)
	var th = TerrainGen.height(translation.x, translation.z)
	if translation.y < th - 0.5:
		translation.y = th

func get_prompt(player=null):
	if rescued:
		return "Your duckling"
	return "A lost duckling!"

func get_actions(player=null):
	if rescued:
		return []
	return ["Pick up gently"]

func action(label, player):
	if rescued:
		return
	rescued = true
	Events.emit_signal("generic", "duckling", 1)
	AudioSynth.play("chirp")
	Events.emit_signal("notify", "Rescued!", "The duckling waddles happily behind you now.")
