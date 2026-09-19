extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
func label(text: String, at: Vector3) -> void:
	var node:=Label3D.new(); node.text=text; node.position=at; node.no_depth_test=true; node.font_size=44; node.pixel_size=0.018; node.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	game.actors.add_child(node)
func unit(spec: Dictionary, at: Vector3) -> Node3D:
	var e=game.create_enemy(spec,at,0); e.set_physics_process(false); e.model.rotation.y=0
	return e
func run() -> void:
	game=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.settings.weapons={}; game.rebuild_player(); game.player.hide(); game.player.set_physics_process(false)
	game.camera.size=22; game.camera.position=Vector3(0,25,28); game.camera.look_at(Vector3.ZERO)
	for i in range(15):
		var at:=Vector3((i%5-2)*5.0,0,(floori(i/5.0)-1)*6.0)
		unit({"type":"normal","index":i},at)
		label(game.Enemy.NAMES[i],at+Vector3(0,0,1.8))
	await snap("enemy-refresh-normal")
	game.clear_enemies()
	for child in game.actors.get_children():
		if child is Label3D: child.free()
	game.camera.size=24
	for i in range(8):
		var at:=Vector3((i%4-1.5)*6.5,0,(floori(i/4.0)-0.5)*8)
		var boss=unit({"type":"mid","index":i},at)
		label(boss.boss_name.replace("・","\n"),at+Vector3(0,0,2.9))
	await snap("enemy-refresh-minibosses")
	game.clear_enemies()
	for child in game.actors.get_children():
		if child is Label3D: child.free()
	game.player.show(); game.camera.size=20; game._update_camera()
	var turtle=unit({"type":"normal","index":3},Vector3(-3,0,1)); turtle._physics_process(4.8)
	var boar=unit({"type":"normal","index":2},Vector3(4,0,-4)); boar.state_time=2; boar.speed=2.9; boar._physics_process(0)
	var hedgehog=unit({"type":"normal","index":7},Vector3(-4,0,-5)); hedgehog.cooldown=0; hedgehog._physics_process(0); hedgehog._physics_process(0.6)
	await snap("enemy-refresh-warnings")
	game.clear_enemies()
	var silk=unit({"type":"mid","index":6},Vector3(0,0,-7)); silk.start_attack()
	await snap("enemy-refresh-silk-warning")
	silk._physics_process(1.2); silk._physics_process(0.28)
	await snap("enemy-refresh-silk-dive")
	game.clear_enemies()
	for phase in [0,1]:
		var e=unit({"type":"minion","index":phase},Vector3(-3 if phase==0 else 3,0,0)); e._physics_process(0.05)
		label("氷アザラシ" if phase==0 else "氷ユキヒョウ",e.position+Vector3(0,0,1.8))
	await snap("enemy-refresh-minions")
	game.free(); await process_frame; quit()
