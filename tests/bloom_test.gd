extends SceneTree
const Roster=preload("res://scripts/character_roster.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func run() -> void:
	for character in ["pink","classic"]:
		Roster.selected_id=character
		var game=load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_physics_process(false)
		game.actors.process_mode=Node.PROCESS_MODE_DISABLED
		game.player.health=70
		var enemy=game.spawn_enemy(0)
		enemy.health=200
		enemy.position=Vector3(3,0,0)
		var u=game.ultimate
		u.reward(200)
		u.activate()
		check(enemy.health==(120 if character=="pink" else 100),character+" damage remains a single hit")
		check(game.player.health==(90 if character=="pink" else 70),character+" healing")
		if character=="pink":
			var effect=get_nodes_in_group("ultimate_effects")[0]
			check(effect.healed==20 and effect.heal_label.text=="HP +20","Actual healing text")
			var count: int=effect.get_child_count()
			effect.animate(1,2.2)
			check(count==effect.get_child_count() and enemy.health==120,"Animation creates no nodes and deals no extra damage")
			game.player.health=95
			u.reward(200)
			u.activate()
			check(game.player.health==100 and get_nodes_in_group("ultimate_effects")[-1].healed==5,"Healing caps at 100 and displays five")
			u.reward(200)
			u.activate()
			check(get_nodes_in_group("ultimate_effects")[-1].heal_label==null,"Full HP has no healing label")
			u.reward(200)
			check(not u.activate() and u.charge==0,"Three-use limit")
			game.player.health=0
			u.uses=0
			u.charge=200
			check(not u.activate() and game.player.health==0,"No revival")
			u._process(0)
			var hidden:=true
			for fx in get_nodes_in_group("ultimate_effects"): hidden=hidden and not fx.visible
			check(hidden,"Death immediately hides effects and labels")
			game.player.health=60
			game._start_final_boss()
			game._finish_presentation()
			var boss=game.active_boss
			boss.position=Vector3(4,0,0)
			boss.health=750
			u.charge=200
			check(u.activate() and boss.health==670 and game.run_state=="phase_transition" and game.player.health==80,"Bloom heals before triggering boss phase transition")
			var fx=get_nodes_in_group("ultimate_effects")[-1]
			check(not fx.can_process(),"Boss presentation freezes bloom and recovery label")
			game._finish_presentation()
			paused=true
			check(not fx.can_process() and not u.activate(),"Weapon pause freezes bloom and blocks activation")
			paused=false
			boss.health=40
			u.reward(200)
			u.activate()
			u._process(0)
			check(game.final_boss_defeated and not fx.visible,"Victory clears bloom effects")
		game.queue_free()
		await process_frame
	Roster.selected_id="classic"
	print("BLOOM TEST: %d failure(s)" % failures)
	quit(1 if failures else 0)
