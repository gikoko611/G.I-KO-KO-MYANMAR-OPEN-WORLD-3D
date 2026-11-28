extends CanvasLayer
# Touch-first crouch and first/third-person camera controls.
# Kept separate from the main HUD so these controls can be disabled or moved
# without coupling gameplay code to the UI. Compatible with Godot 3.5.2.

const UiStyle = preload("res://scripts/ui/ui_theme.gd")

var player = null
var crouched = false
var first_person = false
var crouch_button = null
var camera_button = null
var normal_capsule_height = 1.7
var normal_shape_y = 0.85
var normal_rig_y = 1.55
var normal_spring_length = 4.5

func setup(p):
	player = p

func _ready():
	layer = 4
	_build_controls()
	call_deferred("_capture_player_defaults")

func _build_controls():
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	crouch_button = Button.new()
	crouch_button.text = "Crouch"
	crouch_button.rect_position = Vector2(1280 - 24 - 96 - 106, 720 - 24 - 96 - 58)
	crouch_button.rect_min_size = Vector2(96, 50)
	UiStyle.style_button(crouch_button)
	root.add_child(crouch_button)
	crouch_button.connect("pressed", self, "_toggle_crouch")

	camera_button = Button.new()
	camera_button.text = "1st Person"
	camera_button.rect_position = Vector2(1280 - 24 - 118, 720 - 24 - 96 - 58)
	camera_button.rect_min_size = Vector2(118, 50)
	UiStyle.style_button(camera_button)
	root.add_child(camera_button)
	camera_button.connect("pressed", self, "_toggle_camera")

func _capture_player_defaults():
	if player == null or not is_instance_valid(player):
		return
	var shape = _collision_shape()
	if shape != null and shape.shape is CapsuleShape:
		normal_capsule_height = shape.shape.height
		normal_shape_y = shape.translation.y
	if player.cam_rig != null:
		normal_rig_y = player.cam_rig.translation.y
	if player.spring_arm != null:
		normal_spring_length = player.spring_arm.spring_length

func _collision_shape():
	if player == null or not is_instance_valid(player):
		return null
	for child in player.get_children():
		if child is CollisionShape:
			return child
	return null

func _toggle_crouch():
	if player == null or not is_instance_valid(player) or player.driving:
		return
	crouched = not crouched
	var shape = _collision_shape()
	if shape != null and shape.shape is CapsuleShape:
		# Use a duplicate so changing the runtime shape cannot alter a cached resource.
		shape.shape = shape.shape.duplicate()
		shape.shape.height = 1.05 if crouched else normal_capsule_height
		shape.translation.y = 0.55 if crouched else normal_shape_y
	if player.cam_rig != null:
		player.cam_rig.translation.y = 1.02 if crouched else normal_rig_y
	if player.mesh_root != null and not first_person:
		player.mesh_root.scale.y = 0.72 if crouched else 1.0
	crouch_button.text = "Stand" if crouched else "Crouch"
	AudioSynth.play("click")

func _toggle_camera():
	if player == null or not is_instance_valid(player):
		return
	first_person = not first_person
	if player.spring_arm != null:
		player.spring_arm.spring_length = 0.08 if first_person else normal_spring_length
	if player.mesh_root != null:
		player.mesh_root.visible = not first_person and not player.driving
	camera_button.text = "3rd Person" if first_person else "1st Person"
	AudioSynth.play("click")

func _process(_delta):
	if player == null or not is_instance_valid(player):
		return
	# Hide player geometry in first person and keep controls out of the way while driving.
	if player.mesh_root != null:
		player.mesh_root.visible = not first_person and not player.driving
	if crouch_button != null:
		crouch_button.visible = not player.driving and not GameState.ui_busy()
	if camera_button != null:
		camera_button.visible = not GameState.ui_busy()
