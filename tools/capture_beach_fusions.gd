extends SceneTree
const A=preload("res://scripts/beach_fusion_attack.gd")
const C=preload("res://scripts/weapon_catalog.gd")
var game: Node3D
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/sea-fusion-"+name+".png")
func spawn_attack(id: String,point: Vector3,direction: Vector3,time: float) -> Node3D:
	var a:=A.new(); a.mode=id; a.stats=C.stats(id,5); a.position=point; a.direction=direction; game.armory.attach(a,id); a._physics_process(time); return a
func run() -> void:
	for id in ["pearl_wave","bubble_aquarium","crab_udon","overlap"]:
		game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"; root.add_child(game); current_scene=game
		game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.player.position=Vector3(0,0,3); game._update_camera()
		for i in range(6):
			var enemy=game.spawn_enemy(15+i); enemy.position=Vector3(-6+(i%3)*6,0,-4+(i/3)*5); enemy.health=1000; enemy.max_health=1000; enemy.health_bar.hide(); enemy.cancel_control_action()
		if id=="overlap":
			for weapon in ["pearl_wave","bubble_aquarium","crab_udon"]: game.armory.acquire(weapon); game.armory.levels[weapon]=5
			spawn_attack("pearl_wave",Vector3(-3,0,3),Vector3.FORWARD,0.85)
			spawn_attack("bubble_aquarium",Vector3(4,0,-3),Vector3.FORWARD,1.8)
			spawn_attack("crab_udon",Vector3(0,0,3),Vector3.FORWARD,0.6)
			var boss=preload("res://scripts/octo.gd").new(); boss.target=game.player; boss.position=Vector3(0,0,-8); game.actors.add_child(boss); boss.initialize_training_phase(true); boss.tentacles()
		else:
			game.armory.acquire(id); game.armory.levels[id]=5
			spawn_attack(id,Vector3(0,0,-3) if id=="bubble_aquarium" else game.player.position,Vector3.FORWARD,1.8 if id=="bubble_aquarium" else 0.85 if id=="pearl_wave" else 0.6)
		for weapon in game.armory.levels: game.armory.cooldowns[weapon]=100
		game.armory.tick(0); game._update_hud()
		if id=="overlap": game.inventory_label.text=game.inventory_label.text.replace("装備武器 / 進化 3 / 2","表示検証：3合体同時\n本編の上限は2枠")
		await snap(id); game.free(); await process_frame
	game=load("res://scenes/main.tscn").instantiate(); game.stage_id="beach"; root.add_child(game); current_scene=game; game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	for id in ["shell_wave","orbit","bubble","storm","crab_claw","udon"]: game.armory.acquire(id)
	game.experience=game.xp_needed; game.open_weapon_choice(); await snap("choice"); paused=false; game.free(); await process_frame; quit()
