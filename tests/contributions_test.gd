extends SceneTree
const Ledger=preload("res://scripts/contributions.gd")
var game: Node3D
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)
func enemy(hp:=20):
	var e=game.spawn_enemy(0); e.health=hp; e.max_health=hp; e.position=Vector3(0,0,4); return e
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game
	game.set_physics_process(false); game.set_process(false); game.actors.process_mode=Node.PROCESS_MODE_DISABLED
	var attack:=Node3D.new(); attack.set_meta("weapon_id","frost"); game.actors.add_child(attack)
	var e=enemy(5); Ledger.hit(attack,e,100); Ledger.hit(attack,e,100)
	check(game.contributions.entries["weapon:frost"].damage==5 and game.contributions.entries["weapon:frost"].kills==1,"overkill and duplicate death excluded")
	var guard=load("res://scripts/miniboss.gd").new(); guard.target=game.player; game.actors.add_child(guard); guard.kind=3; guard.guard_left=2; guard.health=100
	Ledger.hit(attack,guard,20)
	check(game.contributions.entries["weapon:frost"].damage==15,"armour records reduced damage")
	guard.free()
	var hidden=enemy(); hidden.targetable=false; Ledger.hit(attack,hidden,20)
	check(game.contributions.entries["weapon:frost"].damage==15,"untargetable does not count")
	game.armory.acquire("frost"); game.armory.evolve("pop_branch","pop_cannon")
	check(game.contributions.entries.has("weapon:frost") and game.contributions.entries.has("weapon:pop_cannon"),"consumed source retained separately")
	var parent:=Node3D.new(); parent.set_meta("weapon_id","blizzard_fan"); game.actors.add_child(parent)
	var child:=Node3D.new(); parent.add_child(child); var frozen=enemy()
	Ledger.control(child,frozen,"freeze",1.2,Vector3.ZERO); Ledger.control(child,frozen,"freeze",1.2,Vector3.ZERO)
	frozen.control_step(0.4)
	check(game.contributions.entries["weapon:blizzard_fan"].freeze==1 and is_equal_approx(game.contributions.entries["weapon:blizzard_fan"].freeze_seconds,0.4),"control success only and elapsed duration")
	Ledger.control(child,frozen,"knockback",3,Vector3.BACK); Ledger.control(child,frozen,"knockback",3,Vector3.BACK)
	check(game.contributions.entries["weapon:blizzard_fan"].knockback==1,"rejected control not counted")
	var before: float=game.contributions.entries["weapon:blizzard_fan"].freeze_seconds
	paused=true; await process_frame; await process_frame; paused=false
	check(game.contributions.entries["weapon:blizzard_fan"].freeze_seconds==before,"pause adds no duration")
	frozen.is_miniboss=true; var n: float=game.contributions.entries["weapon:blizzard_fan"].freeze
	Ledger.control(child,frozen,"freeze",4,Vector3.ZERO); check(game.contributions.entries["weapon:blizzard_fan"].freeze==n,"boss resistance")
	var friend=game.support.spawn_friend(0,Vector3.ZERO); game.player.health=98; friend.recruit()
	check(game.contributions.entries["support:0"].healing==2,"healing capped to actual")
	friend._heal(); check(game.contributions.entries["support:0"].healing==2,"full health no healing")
	game.player.support_damage_multiplier=0.7; game.player.invulnerability=0; game.player.take_damage(11); game.player.take_damage(11)
	check(game.contributions.entries["support:1"].prevented==3,"rounded reduction and invulnerability priority")
	game.player.invulnerability=0; game.player.health=1; game.player.take_damage(40)
	check(game.contributions.entries["support:1"].prevented==3,"lethal overkill is not saved HP")
	friend._heal(); check(game.contributions.entries["support:0"].healing==2,"no revival healing")
	hidden.position=Vector3(20,0,20)
	friend._shoot()
	var shot: Node3D
	for actor in game.actors.get_children():
		if actor.get_meta("contribution_id","")=="support:2": shot=actor
	friend.free()
	check(is_instance_valid(shot),"support shot created")
	if is_instance_valid(shot): shot._physics_process(0.5)
	check(game.contributions.entries.has("support:2") and game.contributions.entries["support:2"].damage>0,"departed support projectile attribution")
	game.player.health=80
	game.ultimate.definition=preload("res://scripts/character_roster.gd").ULTIMATES.bloom; game.player.character_id="pink"; game.ultimate.charge=200
	var target=enemy(10); game.ultimate.activate()
	check(game.contributions.entries["ultimate:bloom"].healing==20 and game.contributions.entries["ultimate:bloom"].kills>=1,"ultimate damage kill and heal attributed")
	var snap: Dictionary=game.contributions.snapshot(game.armory.levels); game.contributions.add("weapon:frost","damage",7)
	check(snap["weapon:frost"].damage==15,"snapshot independent")
	game.player.health=0; game._physics_process(0)
	check(game.game_over and is_instance_valid(game.defeat_results),"death shows contributions")
	var report=game.defeat_results.report
	check(report.listing.text.contains("進化・合体前") and report.listing.text.contains("ラブリー"),"report sources and consumed labels")
	report.order.select(2); report.refresh(); check(report.listing.text.contains("凍結 1回"),"control order renders")
	game.free(); await process_frame
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); current_scene=game; game.set_physics_process(false)
	check(game.contributions.entries.size()==1 and game.contributions.entries["weapon:frost"].damage==0,"new run resets ledger")
	game.free(); await process_frame
	print("CONTRIBUTIONS TEST: %d failures"%failures); quit(1 if failures else 0)
