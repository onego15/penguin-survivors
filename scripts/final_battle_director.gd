extends RefCounted
const Minion=preload("res://scripts/boss_minion.gd")
var game: Node3D
var total_spawned:=0
var phase:=0
var clock:=0.0
var next_minions:=6.0
var support_due:=8.0
var support_count:=0
var had_support:=false
var next_tie_leopard:=false
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
	next_minions=6
	support_due=8
	support_count=0
	had_support=is_instance_valid(game.support.active)
	next_tie_leopard=false
func stop() -> void:
	phase=0
	clear_minions()
func busy() -> bool:
	return not is_instance_valid(game.active_boss) or game.active_boss.dead or game.active_boss.warning_left>0 or game.active_boss.dash_left>0
func tick(delta: float) -> void:
	if phase==0 or game.run_state!="combat" or game.player.health<=0 or game.final_boss_defeated or game.get_tree().paused: return
	clock+=delta
	var present:=is_instance_valid(game.support.active)
	if had_support and not present: support_due=maxf(support_due,clock+3)
	had_support=present
	if busy(): return
	if support_count<(2 if phase==2 else 1) and clock>=support_due and not is_instance_valid(game.support.active):
		var point: Vector3=game.support.find_safe_position()
		if point==Vector3.INF: support_due=clock+2
		else:
			game.support.spawn_friend(game.support.draw_kind(),point)
			support_count+=1
			had_support=true
	if clock<next_minions: return
	var slots:=int(game.Tiers.data(game.difficulty_id).minion_caps[phase-1])-game.get_tree().get_nodes_in_group("final_minions").size()
	if slots<=0:
		next_minions=clock+int(game.Tiers.data(game.difficulty_id).intervals[phase-1])
		return
	var heading: float=game.rng.randf_range(0,TAU)
	var points: Array[Vector3]=[]
	for attempt in range(64):
		var angle: float=heading+game.rng.randf_range(-PI/3,PI/3)
		var candidate: Vector3=game.player.global_position+Vector3(cos(angle),0,sin(angle))*game.rng.randf_range(12,16)
		if absf(candidate.x)>23 or absf(candidate.z)>23: continue
		var obstacle=preload("res://scripts/castle_obstacles.gd").world(game)
		if obstacle!=null and not obstacle.reachable(game.player.global_position,candidate,0.8): continue
		var crowded:=false
		for existing in points:
			if candidate.distance_to(existing)<2: crowded=true
		if crowded: continue
		points.append(candidate)
		if points.size()==mini(4 if phase==2 else 2,slots): break
	if points.is_empty():
		next_minions=clock+2
		return
	for point in points:
		var enemy:=Minion.new()
		enemy.second_phase=choose_leopard(points.size())
		enemy.side=-1 if game.rng.randf()<0.5 else 1
		enemy.position=point
		enemy.target=game.player
		enemy.rewarded.connect(game._on_enemy_defeated)
		game.Tiers.prepare(enemy,game.difficulty_id)
		game.actors.add_child(enemy)
		game.Tiers.apply_hp(enemy)
		total_spawned+=1
	next_minions=clock+int(game.Tiers.data(game.difficulty_id).intervals[phase-1])

func choose_leopard(batch_size: int) -> bool:
	if phase!=2: return false
	if batch_size==4:
		var alternating:=next_tie_leopard
		next_tie_leopard=not next_tie_leopard
		return alternating
	var seals:=0
	var leopards:=0
	for enemy in game.get_tree().get_nodes_in_group("final_minions"):
		if enemy.dead: continue
		if enemy.second_phase: leopards+=1
		else: seals+=1
	if seals!=leopards: return leopards<seals
	var result:=next_tie_leopard
	next_tie_leopard=not next_tie_leopard
	return result
