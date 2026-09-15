extends RefCounted
const Minion=preload("res://scripts/boss_minion.gd")
var game: Node3D
var phase:=0
var clock:=0.0
var next_minions:=14.0
var support_due:=8.0
var support_used:=false
func clear_minions() -> void:
	for enemy in game.get_tree().get_nodes_in_group("final_minions"):
		enemy.dead=true
		enemy.remove_from_group("enemies")
		enemy.remove_from_group("all_enemies")
		enemy.remove_from_group("final_minions")
		enemy.queue_free()
func begin_phase(value: int) -> void:
	clear_minions()
	phase=value
	clock=0
	next_minions=14
	support_due=8
	support_used=false
func stop() -> void:
	phase=0
	clear_minions()
func busy() -> bool:
	return not is_instance_valid(game.active_boss) or game.active_boss.dead or game.active_boss.warning_left>0 or game.active_boss.dash_left>0
func tick(delta: float) -> void:
	if phase==0 or game.run_state!="combat" or game.player.health<=0 or game.final_boss_defeated or game.get_tree().paused: return
	clock+=delta
	if busy(): return
	if not support_used and clock>=support_due and not is_instance_valid(game.support.active):
		var point: Vector3=game.support.find_safe_position()
		if point==Vector3.INF: support_due=clock+2
		else:
			game.support.spawn_friend(game.support.draw_kind(),point)
			support_used=true
	if clock<next_minions: return
	var slots:=4-game.get_tree().get_nodes_in_group("final_minions").size()
	if slots<=0:
		next_minions=clock+(20 if phase==2 else 24)
		return
	var heading: float=game.rng.randf_range(0,TAU)
	var points: Array[Vector3]=[]
	for attempt in range(64):
		var angle: float=heading+game.rng.randf_range(-PI/3,PI/3)
		var candidate: Vector3=game.player.global_position+Vector3(cos(angle),0,sin(angle))*game.rng.randf_range(12,16)
		if absf(candidate.x)>23 or absf(candidate.z)>23: continue
		if not points.is_empty() and candidate.distance_to(points[0])<2: continue
		points.append(candidate)
		if points.size()==mini(2,slots): break
	if points.is_empty():
		next_minions=clock+2
		return
	for point in points:
		var enemy:=Minion.new()
		enemy.second_phase=phase==2
		enemy.side=-1 if game.rng.randf()<0.5 else 1
		enemy.position=point
		enemy.target=game.player
		enemy.rewarded.connect(game._on_enemy_defeated)
		game.actors.add_child(enemy)
	next_minions=clock+(20 if phase==2 else 24)
