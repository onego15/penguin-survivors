extends SceneTree
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+label)
	if not ok: failures+=1
func enemy_at(point: Vector3) -> Node3D:
	var e=game.spawn_enemy(0)
	e.set_physics_process(false)
	e.position=point
	e.health=100
	return e
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.armory.acquire("boomerang")
	var endpoint=enemy_at(Vector3(0,0,9.1))
	game.armory.fire("boomerang")
	var fish=get_nodes_in_group("weapon_attacks")[0]
	fish.set_physics_process(false)
	var outbound=enemy_at(Vector3(-1.6,0,4.55))
	var inbound=enemy_at(Vector3(1.6,0,4.55))
	var center=enemy_at(Vector3(0,0,4.55))
	fish._physics_process(0.325)
	check(fish.position.distance_to(Vector3(-1.6,1,4.55))<0.001,"Quarter ellipse has 1.6m lateral reach")
	game.player.position=Vector3(4,0,0)
	fish._physics_process(0.325)
	check(fish.position.distance_to(Vector3(0,1,9.1))<0.001,"Half ellipse reaches 9.1m and ignores subsequent player movement")
	fish._physics_process(0.65)
	check(fish.position.distance_to(Vector3.UP)<0.001,"Full ellipse returns to its fixed launch point after 1.3 seconds")
	check(outbound.health==98 and inbound.health==98 and endpoint.health==96 and center.health==100,"Swept curved path hits each leg and misses the empty center even at low FPS")
	fish._physics_process(0.3)
	check(fish.is_queued_for_deletion() and fish.position.distance_to(game.player.position+Vector3.UP)<=0.3,"After the ellipse the fish returns to the moving player at 14m/s")
	for actor in game.actors.get_children():
		if actor!=game.player: actor.free()
	game.player.position=Vector3.ZERO
	game.armory.acquire("ember")
	game.armory.fire("ember")
	var meteor=get_nodes_in_group("weapon_attacks")[0]
	meteor.set_physics_process(false)
	check(meteor.position.distance_to(game.player.facing_direction()*8)<0.001,"Fireball locks eight metres ahead")
	var point: Vector3=meteor.position
	var victim=enemy_at(point)
	game.player.position=Vector3(8,0,8)
	meteor._physics_process(0.69)
	check(victim.health==100 and meteor.position==point,"Fireball has no early damage and does not follow")
	meteor._physics_process(0.01)
	check(victim.health==94,"Fireball retains six damage at 0.7 seconds")
	game.level=99
	game.kills=99999
	game.experience=12345
	game.xp_needed=23456
	game._update_hud()
	await process_frame
	var panel=game.hud_layer.get_node("StatusPanel")
	check(panel.position==Vector2(16,16) and panel.size==Vector2(300,108),"Compact status panel is 300x108 at 16px inset")
	print("HUD BOUNDS ",game.hud.get_rect()," ",game.detail_hud.get_rect()," ",game.xp_bar.get_rect())
	check(game.hud.position.x+game.hud.size.x<=316 and game.detail_hud.position.x+game.detail_hud.size.x<=316 and game.xp_bar.position.y+game.xp_bar.size.y<=124,"Status text and XP bar remain within the compact panel")
	var lightning=preload("res://scripts/weapon_detail.gd").new()
	lightning.mode="lightning"
	game.actors.add_child(lightning)
	lightning.animate(0.15,0.3)
	var count:=lightning.get_child_count()
	for i in range(100): lightning.animate(i*0.003,0.3)
	check(lightning.get_child_count()==count,"Lightning reuses its geometry during decay")
	game.queue_free()
	await create_timer(0.3).timeout
	print("ELLIPSE/HUD TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
