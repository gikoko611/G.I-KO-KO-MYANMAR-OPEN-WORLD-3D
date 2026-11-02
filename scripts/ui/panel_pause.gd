extends "res://scripts/ui/panel_base.gd"
# Pause panel: resume, save, load, settings (graphics + volumes), quit.

var settings_box = null
var graphics_label = null

func _ready():
	set_anchors_preset(Control.PRESET_CENTER)
	rect_min_size = Vector2(460, 420)
	rect_position = Vector2(-230, -210)
	var vb = VBoxContainer.new()
	add_child(vb)
	vb.set_anchors_preset(Control.PRESET_WIDE)
	vb.add_child(ui_title("Paused"))
	var resume = ui_button("Resume")
	vb.add_child(resume)
	resume.connect("pressed", self, "close")
	var save_btn = ui_button("Save Game")
	vb.add_child(save_btn)
	save_btn.connect("pressed", self, "_save")
	var load_btn = ui_button("Load Last Save")
	vb.add_child(load_btn)
	load_btn.connect("pressed", self, "_load")
	var settings_btn = ui_button("Settings")
	vb.add_child(settings_btn)
	settings_btn.connect("pressed", self, "_toggle_settings")
	var quit = ui_button("Save & Quit to Menu")
	vb.add_child(quit)
	quit.connect("pressed", self, "_quit")
	settings_box = VBoxContainer.new()
	settings_box.visible = false
	vb.add_child(settings_box)
	graphics_label = ui_label("", 15, Color(0.8, 0.8, 0.75))
	settings_box.add_child(graphics_label)
	var ghb = HBoxContainer.new()
	settings_box.add_child(ghb)
	var g_names = ["Low", "Medium", "High"]
	for i in range(3):
		var gb = ui_button(g_names[i])
		ghb.add_child(gb)
		gb.connect("pressed", self, "_set_graphics", [i])
	settings_box.add_child(ui_label("Music volume", 15, Color(0.8, 0.8, 0.75)))
	var mslider = HSlider.new()
	mslider.min_value = 0.0
	mslider.max_value = 1.0
	mslider.step = 0.05
	mslider.value = GameState.volumes.get("Music", 0.8)
	settings_box.add_child(mslider)
	mslider.connect("value_changed", self, "_set_vol", ["Music"])
	settings_box.add_child(ui_label("Effects volume", 15, Color(0.8, 0.8, 0.75)))
	var sslider = HSlider.new()
	sslider.min_value = 0.0
	sslider.max_value = 1.0
	sslider.step = 0.05
	sslider.value = GameState.volumes.get("SFX", 0.9)
	settings_box.add_child(sslider)
	sslider.connect("value_changed", self, "_set_vol", ["SFX"])
	settings_box.add_child(ui_label("Ambience volume", 15, Color(0.8, 0.8, 0.75)))
	var aslider = HSlider.new()
	aslider.min_value = 0.0
	aslider.max_value = 1.0
	aslider.step = 0.05
	aslider.value = GameState.volumes.get("Ambience", 0.7)
	settings_box.add_child(aslider)
	aslider.connect("value_changed", self, "_set_vol", ["Ambience"])

func open():
	.open()
	settings_box.visible = false

func _save():
	AudioSynth.play("accept")
	SaveMgr.save_game(true)
	SaveMgr.save_settings()

func _load():
	AudioSynth.play("click")
	close()
	SaveMgr.load_game()

func _toggle_settings():
	AudioSynth.play("click")
	settings_box.visible = not settings_box.visible
	graphics_label.text = "Graphics quality: " + ["Low", "Medium", "High"][GameState.graphics] + " (designed for Redmi 9A on Low)"

func _set_graphics(i):
	GameState.set_graphics(i)
	GameState.apply_settings()
	SaveMgr.save_settings()
	graphics_label.text = "Graphics quality: " + ["Low", "Medium", "High"][GameState.graphics] + " (designed for Redmi 9A on Low)"

func _set_vol(v, bus):
	GameState.set_volume(bus, v)
	GameState.apply_settings()

func _quit():
	AudioSynth.play("click")
	SaveMgr.save_game(false)
	SaveMgr.save_settings()
	get_tree().change_scene("res://scenes/main_menu.tscn")
