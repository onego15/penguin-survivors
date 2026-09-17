extends SceneTree
const Catalog=preload("res://scripts/weapon_catalog.gd")
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1; print("FAIL: ",label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original=JSON.parse_string(FileAccess.get_file_as_string("res://tests/weapon_style_stats.json"))
	check(original.size()==23,"23 weapons")
	for id in original:
		for rank in range(1,6):
			var stats=Catalog.stats(id,rank)
			for key in original[id][rank-1]: check(is_equal_approx(float(stats[key]),float(original[id][rank-1][key])),"unchanged %s Lv%d %s"%[id,rank,key])
	var stages=load("res://scripts/stage_catalog.gd")
	for stage in ["snowfield","castle"]: check(stages.weapon_pool(stage).size()==16 and "beam" in stages.weapon_pool(stage),"stage pool")
	var game=load("res://scenes/sandbox.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.set_physics_process(false); game.player.set_physics_process(false)
	game.settings.weapons={"frost":1,"fan":1,"rear_fan":1,"nova":1,"lightning":1,"orbit":1,"mine":1}
	game.rebuild_player(); game.player.set_physics_process(false)
	game.armory.tick(0)
	var before: Vector3=game.armory.mounts.nova.position
	game.armory.tick(0.2)
	var after: Vector3=game.armory.mounts.nova.position
	check(is_equal_approx(before.x,after.x) and is_equal_approx(before.z,after.z),"decorations do not orbit")
	check(game.armory.mounts.nova.get_node("Motif").has_node("Tube2"),"three chime tubes")
	check(not game.armory.mounts.lightning.get_node("Motif").has_node("Tube2"),"bell distinct from chime")
	var feathers:=0; var confetti:=0
	for attack in get_nodes_in_group("weapon_attacks"):
		if "visual_kind" in attack:
			if attack.visual_kind=="feather": feathers+=1
			if attack.visual_kind=="confetti": confetti+=1
		if "mode" in attack and attack.mode=="mine":
			var point: Vector3=attack.global_position
			attack._physics_process(0.15)
			check(attack.global_position==point and attack.cosmetic.position.z!=0,"acorn rolls cosmetically only")
	check(feathers==5 and confetti==5,"unchanged shots with distinct visuals")
	var t: float=game.armory.orbit_attack.age
	paused=true; await create_timer(0.05,true).timeout
	check(game.armory.orbit_attack.age==t,"pause freezes visuals")
	paused=false
	game.settings.weapons={}; game.rebuild_player(); await process_frame
	check(get_nodes_in_group("weapon_attacks").is_empty(),"unequip clears effects")
	game.free(); await process_frame
	print("WEAPON STYLE TEST: ",failures," failures")
	quit(failures)
