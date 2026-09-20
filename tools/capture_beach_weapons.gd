extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene:=Node3D.new(); root.add_child(scene); current_scene=scene
	var models=preload("res://scripts/beach_models.gd")
	models.arena(scene)
	var camera:=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=20; camera.position=Vector3(0,19,17); scene.add_child(camera); camera.look_at(Vector3.ZERO); camera.current=true
	var ids=["shell_wave","bubble","crab_claw"]
	for i in range(3):
		var stand:=Node3D.new(); stand.position=Vector3((i-1)*6,1,-3); stand.scale=Vector3.ONE*2.3; scene.add_child(stand); models.weapon(stand,ids[i])
		var label=preload("res://scripts/combat_visuals.gd").symbol(scene,preload("res://scripts/weapon_catalog.gd").ITEMS[ids[i]].name,Color("244756")); label.position=Vector3((i-1)*6,0,-1); label.font_size=34; label.outline_size=0
		var attack=preload("res://scripts/beach_attack.gd").new(); attack.mode=ids[i]; attack.stats=preload("res://scripts/weapon_catalog.gd").stats(ids[i],1); attack.position=Vector3((i-1)*6,0,2); scene.add_child(attack); attack.set_physics_process(false)
		attack._physics_process(0.20 if i==2 else 0.40)
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/beach-weapon-models.png")
	scene.free(); await process_frame; quit()
