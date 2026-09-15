extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")
func snap(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+label+".png")
func attack(mode: String, point: Vector3) -> Node3D:
	var a=load("res://scripts/advanced_attack.gd" if mode=="whip" else "res://scripts/weapon_attack.gd").new()
	a.mode=mode
	a.player=game.player
	a.position=point
	a.direction=Vector3.RIGHT
	a.damage=0
	return a
func attach(a: Node3D) -> void:
	game.actors.add_child(a)
	a.set_physics_process(false)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.elapsed=430
	game.director.advance()
	game.next_boss_at=480
	game.level=12
	game.xp_needed=game.Difficulty.xp_for_level(12)
	for id in ["spear","ember","lightning","whip","rear_bomb","boomerang"]: game.armory.acquire(id)
	var deer=game.spawn_enemy(9)
	deer.set_physics_process(false)
	deer.position=Vector3(-6,0,-4)
	deer.cooldown=0
	deer._physics_process(0)
	var spear=attack("bolt",Vector3(-7,1,3))
	spear.visual_kind="lance"
	spear.piercing=true
	spear.speed=26
	attach(spear)
	for i in range(10): spear._physics_process(0.01)
	var meteor=attack("meteor",Vector3(4,0,-2))
	meteor.lifetime=0.7
	meteor.area_radius=3.2
	attach(meteor)
	meteor._physics_process(0.45)
	var bolt=attack("lightning",Vector3(6,0,4))
	bolt.lifetime=0.55
	bolt.area_radius=3
	attach(bolt)
	bolt._physics_process(0.3)
	var whip=attack("whip",Vector3.UP)
	whip.direction=Vector3.BACK
	attach(whip)
	whip._physics_process(0.175)
	game._update_hud()
	await snap("weapon-revision")
	for node in game.actors.get_children():
		if node!=game.player: node.free()
	var firework=attack("rear_bomb",Vector3(-4,0,3))
	firework.launch_origin=Vector3.UP
	firework.area_radius=3
	firework.lifetime=0.65
	attach(firework)
	for i in range(10): firework._physics_process(0.035)
	await snap("firework-flight")
	firework._physics_process(0.3)
	for effect in get_nodes_in_group("weapon_impact_details"):
		effect.set_physics_process(false)
		effect.animate(0.36,0.8)
	var fish=attack("boomerang",Vector3.UP)
	fish.direction=Vector3.RIGHT
	fish.piercing=true
	fish.lifetime=2.4
	attach(fish)
	for i in range(24): fish._physics_process(1.0/60)
	await snap("firework-ellipse")
	game.queue_free()
	await create_timer(0.3).timeout
	quit()
