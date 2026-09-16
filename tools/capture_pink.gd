extends SceneTree
const Roster=preload("res://scripts/character_roster.gd")
func _initialize() -> void: call_deferred("run")
func snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	var title=load("res://scenes/title.tscn").instantiate()
	root.add_child(title)
	current_scene=title
	await snap("character-classic")
	title.select_character("pink")
	await snap("character-pink")
	title.free()
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for i in range(5):
		var enemy=game.spawn_enemy(i%4)
		enemy.position=Vector3(i*1.6-3,0,3)
		enemy.set_physics_process(false)
	for i in range(3):
		var heart=preload("res://scripts/heart_projectile.gd").new()
		heart.position=Vector3(-2+i*2,1,1)
		heart.direction=Vector3.BACK
		game.actors.add_child(heart)
		heart.set_physics_process(false)
	await snap("heart-wave")
	for id in game.Catalog.ITEMS: game.armory.acquire(id)
	game._update_hud()
	await snap("pink-inventory")
	game.final_boss_defeated=true
	game._physics_process(0)
	await snap("pink-victory")
	game.queue_free()
	await process_frame
	quit()
