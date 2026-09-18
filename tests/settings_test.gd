extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1; push_error(text)
func run() -> void:
	var settings=root.get_node("Settings")
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	await process_frame
	settings.open_menu()
	var elapsed: float=game.elapsed
	var position: Vector3=game.player.position
	Input.action_press("move_right")
	for i in range(8): await physics_frame
	check(is_equal_approx(elapsed,game.elapsed) and position==game.player.position,"pause freezes gameplay")
	game.ultimate.charge=200
	check(not game.ultimate.activate(),"ultimate blocked while paused")
	Input.action_release("move_right")
	Input.action_press("ultimate")
	settings.close_menu(); check(not paused,"combat resumes")
	check(not settings.allows_action("ultimate"),"held pause input is blocked")
	Input.action_release("ultimate"); check(settings.allows_action("ultimate"),"release restores input")
	game.experience=game.xp_needed; game.open_weapon_choice()
	settings.open_menu(); settings.close_menu()
	check(paused and game.choice_open,"nested pause preserves weapon choice")
	game.choose_weapon(0); check(not paused,"choice resumes")
	check(settings.rebind("ultimate",KEY_F),"rebind")
	check(not settings.rebind("move_up",KEY_F),"duplicates rejected")
	check(not settings.rebind("move_up",KEY_ESCAPE),"reserved key rejected")
	settings.music_volume=0.35; settings.sfx_volume=0.55; settings.effect_opacity=0.4; settings.camera_shake=false; settings.music_muted=true; settings.save_preferences()
	settings.music_volume=1; settings.camera_shake=true; settings.load_preferences()
	check(is_equal_approx(settings.music_volume,0.35) and not settings.camera_shake and settings.keys.ultimate==KEY_F,"settings persist")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"persisted mute")
	var pad:=InputEventJoypadButton.new(); pad.button_index=JOY_BUTTON_X; pad.pressed=true
	check(pad.is_action_pressed("ultimate"),"gamepad ultimate")
	var motion:=InputEventJoypadMotion.new(); motion.axis=JOY_AXIS_LEFT_X; motion.axis_value=1.0
	var before_move: float=game.player.position.x
	Input.parse_input_event(motion)
	for i in range(5): await physics_frame
	check(game.player.position.x>before_move,"gamepad stick moves player")
	motion.axis_value=0; Input.parse_input_event(motion)
	pad.button_index=JOY_BUTTON_START; settings._input(pad); check(paused,"gamepad pause"); settings._input(pad); check(not paused,"gamepad resume")
	var attack:=Node3D.new(); attack.add_to_group("friendly_effects"); game.actors.add_child(attack)
	var v=load("res://scripts/visuals.gd")
	var mesh=v.ellipsoid(attack,Color.WHITE,Vector3.ZERO,Vector3.ONE)
	var cv=load("res://scripts/combat_visuals.gd")
	var boundary=cv.friendly(attack,2)
	var warning=cv.warning(game.actors,2)
	var danger_mesh=warning.get_node("Countdown")
	for i in range(3): await process_frame
	check(is_equal_approx(mesh.material_override.albedo_color.a,0.4),"friendly opacity")
	check(is_equal_approx(boundary.material_override.albedo_color.a,1),"friendly boundary retained")
	check(is_equal_approx(danger_mesh.material_override.albedo_color.a,1),"enemy warning retained")
	mesh.material_override.albedo_color.a=0.5
	await process_frame; await process_frame
	check(is_equal_approx(mesh.material_override.albedo_color.a,0.2),"animated opacity does not compound")
	settings.effect_opacity=1; settings.music_volume=1; settings.sfx_volume=1; settings.music_muted=false; settings.camera_shake=true; settings.keys=settings.DEFAULT_KEYS.duplicate(); settings.install_inputs(); settings.save_preferences()
	game.experience=0; game.elapsed=600; game._start_final_boss()
	settings.open_menu()
	var cinematic_time: float=game.presentation.time
	for i in range(8): await process_frame
	check(is_equal_approx(game.presentation.time,cinematic_time),"cinematic pauses")
	settings.close_menu()
	game.free(); await process_frame
	print("SETTINGS TEST: ","PASS" if failures==0 else str(failures)+" failures")
	quit(failures)
