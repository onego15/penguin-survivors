extends SceneTree
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func run() -> void:
	preload("res://scripts/character_roster.gd").selected_id="pink"
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.camera.size=12
	game.armory.acquire("udon")
	game.armory.levels.udon=3
	game.armory.cooldowns.udon=999
	game.armory.cooldowns.heart=999
	game.armory.tick(0)
	game.player.body.rotation.y=-0.3
	for i in range(3):
		var enemy=game.spawn_enemy(i)
		enemy.position=Vector3(-2+i*1.5,0,4+i*0.4)
		enemy.health=1000
		enemy.max_health=1000
		enemy.set_physics_process(false)
	game.armory.fire("udon")
	for attack in get_nodes_in_group("weapon_attacks"):
		attack.set_physics_process(false)
		attack._physics_process(0.32)
	game._update_hud()
	await snap("udon-attack")
	game.armory.levels.lightning=2
	game.armory.levels.spear=4
	var ids: Array[String]=["udon","lightning","spear"]
	game.choice_ui.show_choices(ids,game.armory.levels,12)
	await snap("weapon-upgrade-values")
	game.free()
	preload("res://scripts/stage_catalog.gd").selected_id="castle"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position=Vector3(3,0,8)
	game.elapsed=302
	game.director.advance()
	game.director.notice="ゴースト / 閉じた門を通過。城壁は通れません"
	game.director.notification_until=310
	game.obstacles.gates[3].state="closed"
	game.obstacles.gates[3].mesh.show()
	game.obstacles.gates[3].label.text="鍵 閉鎖中"
	game.camera.size=16
	game._update_camera()
	for i in range(3):
		var ghost=game.spawn_enemy(14)
		ghost.position=Vector3(6.5+i*1.5,0,8+i*0.3)
		ghost._physics_process(0)
		ghost.set_physics_process(false)
	game._update_hud()
	await snap("castle-ghost")
	for id in game.Catalog.ITEMS: game.armory.acquire(id)
	game._update_hud()
	await snap("twenty-weapons-equipped")
	var victory=load("res://scripts/victory_screen.gd").new()
	victory.results={"character_id":"pink","elapsed":650,"level":20,"kills":999,"weapons":{}}
	for id in game.Catalog.ITEMS: victory.results.weapons[id]=5
	game.add_child(victory)
	await snap("twenty-weapons-clear")
	game.free()
	await process_frame
	quit()
