extends SceneTree
const C=preload("res://scripts/weapon_catalog.gd")
const E=preload("res://scripts/evolution_catalog.gd")
const S=preload("res://scripts/stage_catalog.gd")
const A=preload("res://scripts/beach_fusion_attack.gd")
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok: failures+=1; push_error(label)
func setup(stage: String="beach") -> void:
	if is_instance_valid(game): game.free()
	paused=false; S.selected_id=stage
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_process(false); game.set_physics_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	game.player.position=Vector3.ZERO
func clear() -> void:
	for node in game.actors.get_children():
		if node!=game.player: node.free()
func enemy(point: Vector3,kind:=15) -> Node3D:
	var e=game.spawn_enemy(kind); e.position=point; e.health=1000; e.max_health=1000; return e
func attack(id: String,rank:=1,point:=Vector3.ZERO) -> Node3D:
	var a:=A.new(); a.mode=id; a.stats=C.stats(id,rank); a.position=point; game.armory.attach(a,id); return a
func run() -> void:
	for id in ["pearl_wave","bubble_aquarium","crab_udon"]:
		for x in range(1,6):
			for y in range(1,6):
				var levels: Dictionary={}; levels[E.RECIPES[id].sources[0]]=x; levels[E.RECIPES[id].sources[1]]=y
				check(E.inherited_level(id,levels)==x+y-1,"25 inherited levels "+id)
				for stage in S.STAGES: check((id in E.available(levels,{},S.weapon_pool(stage)))==(stage=="beach"),"stage restriction "+id)
		check(C.max_rank(id)==9 and C.min_rank(id)==1,"fusion caps")
	setup()
	for id in ["pearl_wave","bubble_aquarium","crab_udon"]:
		setup(); enemy(Vector3(0,0,5))
		for source in E.RECIPES[id].sources: game.armory.acquire(source); game.armory.levels[source]=3; game.armory.fire(source)
		check(game.armory.evolve(id,id) and game.armory.levels[id]==5,"evolve and inherit "+id)
		for source in E.RECIPES[id].sources:
			check(not game.armory.levels.has(source) and game.armory.consumed.has(source),"consumed")
			for node in get_nodes_in_group("weapon_attacks"): check(node.get_meta("weapon_id","")!=source,"no old source attacks")
		var wait: float=game.armory.cooldowns[id]; game.armory.acquire(id); check(game.armory.cooldowns[id]==wait,"upgrade preserves clock")
	setup(); var e=enemy(Vector3(0,0,7)); var outside=enemy(Vector3(4,0,7)); var mole=enemy(Vector3(0,0,5),8); mole.targetable=false
	var a=attack("pearl_wave"); a._physics_process(1.1); a._physics_process(0.1)
	check(e.health==984 and outside.health==1000 and mole.health==1000,"wave fixed width swept once excludes underground")
	check(a.stats.width==6 and a.wave.stats.width==3,"full width versus half width")
	clear(); e=enemy(Vector3.ZERO); a=attack("bubble_aquarium"); a._physics_process(3.0)
	check(a.pulses==6 and a.bubbles.size()==6 and e.health==988,"six pulses no extra direct hits")
	check(not a.dome.visible,"dome ends at 3 seconds")
	clear(); e=enemy(Vector3(3.1,0,0)); a=attack("bubble_aquarium"); a._physics_process(0.5)
	var bubble: Node3D=a.bubbles[0]; bubble.bubbles[0].node.global_position=e.position
	var hp: int=e.health; bubble.pop(bubble.bubbles[0]); bubble.pop(bubble.bubbles[0]); check(e.health==hp-4,"single bubble pop no direct double damage")
	clear(); e=enemy(Vector3(7,0,0)); var left=enemy(Vector3(-6,0,0)); a=attack("crab_udon"); a._physics_process(0.35)
	check(e.health==998 and left.health==998,"noodle outward hits")
	game.player.position=Vector3(15,0,15); a._physics_process(0.9)
	check(is_equal_approx(e.position.x,3) and is_equal_approx(left.position.x,-3),"four metre cap and fixed three metre safe distance")
	check(e.health==982 and left.health==982 and a.snapped,"single finishing snap")
	a._physics_process(0.2); check(e.health==982,"no repeat snap")
	clear(); e=enemy(Vector3(7,0,0)); e.apply_control("freeze",1); a=attack("crab_udon"); a._physics_process(1.25); check(e.position.x<3.01,"frozen can be pulled")
	clear(); e=enemy(Vector3(7,0,0)); e.apply_control("knockback",4,Vector3.RIGHT); a=attack("crab_udon"); a._physics_process(1.25); check(e.position.x==7,"knockback takes precedence")
	clear(); e=enemy(Vector3(6,0,0)); a=attack("crab_udon"); a._physics_process(0.35); e.targetable=false; a._physics_process(0.9); check(a.lanes[1].claw.position.x==3,"invalid catch uses fallback")
	clear(); var boss=preload("res://scripts/beach_miniboss.gd").new(); game.actors.add_child(boss); boss.position=Vector3(4,0,0); boss.health=1000
	a=attack("crab_udon"); a._physics_process(1.25); check(boss.position.x==4 and boss.health==982,"boss damage without capture")
	setup("castle"); e=enemy(Vector3(10,0,0)); a=attack("crab_udon",1,Vector3(4,0,0)); a._physics_process(1.25); check(e.health==1000,"wall blocks noodles and snap")
	clear(); e=enemy(Vector3(10,0,0)); a=attack("bubble_aquarium",1,Vector3(6,0,0)); a._physics_process(3); check(e.health==1000,"wall blocks dome and bubbles")
	setup()
	game.armory.acquire("pearl_wave"); game.armory.acquire("bubble_aquarium")
	for source in ["crab_claw","udon"]: game.armory.acquire(source)
	check(game.armory.available_evolutions().is_empty(),"two slot limit includes sea fusions")
	setup(); e=enemy(Vector3(0,0,3)); e.health=1
	var kills: int=game.kills; var xp: int=game.experience; var charge: float=game.ultimate.charge
	a=attack("pearl_wave"); a._physics_process(0.6)
	check(game.kills==kills+1 and game.experience>xp and game.ultimate.charge>charge,"wave child awards XP kills and ultimate")
	check(game.contributions.entries.has("weapon:pearl_wave"),"nested wave damage attribution")
	setup(); game.armory.acquire("bubble_aquarium"); check(not game.armory.fire("bubble_aquarium"),"aquarium waits for target")
	e=enemy(Vector3(0,0,4)); check(game.armory.fire("bubble_aquarium"),"aquarium targets nearest")
	clear(); e=enemy(Vector3.ZERO); e.hit_radius=4
	a=attack("crab_udon"); a._physics_process(1.25); check(e.health==982,"left and right share both hit histories")
	clear(); a=attack("bubble_aquarium"); var values=a.stats.duplicate(); a._physics_process(0.5)
	game.beach.command(); game.beach.tick(2)
	var drifting: Node3D=a.bubbles[0].bubbles[0].node; drifting.global_position=Vector3(0,0,8)
	var start: Vector3=drifting.global_position; var flow: Vector3=game.beach.flow(start)
	a._physics_process(0.1)
	check(drifting.global_position.distance_to(start+Vector3.BACK*0.15+flow*0.1)<0.01,"bubble inherits tide")
	check(a.stats==values,"attack keeps its stats")
	clear(); a=attack("bubble_aquarium"); a._physics_process(6.5); check(a.is_queued_for_deletion(),"last bubble expires with parent")
	clear(); a=attack("crab_udon"); a._physics_process(0.2)
	game.actors.process_mode=Node.PROCESS_MODE_INHERIT
	var moving_age: float=a.age; await physics_frame; await physics_frame
	check(a.age>moving_age,"animation runs before pause")
	var age: float=a.age
	paused=true; await process_frame; await process_frame; check(a.age==age,"tree pause")
	paused=false; game.actors.process_mode=Node.PROCESS_MODE_DISABLED; game.player.health=0; game._physics_process(0.01); await process_frame
	check(get_nodes_in_group("weapon_attacks").is_empty(),"death clears attacks")
	game.free(); await process_frame
	var sandbox=load("res://scenes/sandbox.tscn").instantiate(); root.add_child(sandbox); current_scene=sandbox; sandbox.set_physics_process(false)
	sandbox.menu.open_menu()
	for id in ["pearl_wave","bubble_aquarium","crab_udon"]: sandbox.set_weapon(id,9); check(sandbox.armory.levels[id]==9,"sandbox direct Lv9")
	sandbox.free(); paused=false; await process_frame
	print("BEACH FUSION TEST: %d failures"%failures); quit(1 if failures else 0)
