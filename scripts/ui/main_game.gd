extends Node
# Main game scene: creates the world, the player and the HUD, then applies
# a pending new game or load. Handles the Android back button.

const WorldScript = preload("res://scripts/world/world.gd")
const PlayerScript = preload("res://scripts/player/player.gd")
const HudScript = preload("res://scripts/ui/hud.gd")

func _ready():
	if GameState.pending_new_game:
		GameState.reset_all()
		Missions.reset_all()
	var world = WorldScript.new()
	add_child(world)
	var player = PlayerScript.new()
	add_child(player)
	if GameState.pending_new_game:
		GameState.apply_story_choice(GameState.story_choice)
	world.prewarm(player.translation.x, player.translation.z)
	var hud = HudScript.new()
	add_child(hud)
	GameState.apply_settings()
	if GameState.pending_load:
		SaveMgr.load_game()
	GameState.pending_new_game = false
	GameState.pending_load = false

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		var hs = get_tree().get_nodes_in_group("hud")
		if hs.size() > 0:
			hs[0].toggle_pause()
