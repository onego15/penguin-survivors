extends Node
const Friend = preload("res://scripts/support_friend.gd")
var game: Node3D
var active: Node3D
var next_at := 0.0
var bag: Array[int] = []
var last_kind := -1
func _ready() -> void:
	next_at=game.elapsed+game.rng.randf_range(75,95)
func draw_kind() -> int:
	if bag.is_empty():
		bag.assign([0,1,2])
		for i in range(2,0,-1):
			var j: int=game.rng.randi_range(0,i)
			var value:=bag[i]
			bag[i]=bag[j]
			bag[j]=value
		if bag.back()==last_kind:
			var value:=bag[0]
			bag[0]=bag[2]
			bag[2]=value
	last_kind=bag.pop_back()
	return last_kind
func tick(delta: float) -> void:
	if game.game_over or game.victory or game.player.health<=0:
		clear()
		return
	if is_instance_valid(active):
		active.tick(delta)
		if active.done:
			active.queue_free()
			active=null
			next_at=game.elapsed+game.rng.randf_range(110,140)
		return
	if game.final_boss_spawned or game.elapsed>=570 or game.elapsed<next_at or game.elapsed-game.last_event_at<10:
		return
	var point := find_safe_position()
	if point==Vector3.INF:
		next_at=game.elapsed+2
		return
	spawn_friend(draw_kind(),point)
func spawn_friend(kind: int, point: Vector3) -> Node3D:
	if is_instance_valid(active): return active
	active=Friend.new()
	active.game=game
	active.kind=kind
	active.position=point
	add_child(active)
	game.sound.play_effect("support_arrive")
	return active
func position_safe(point: Vector3) -> bool:
	if absf(point.x)>22 or absf(point.z)>22: return false
	var distance := point.distance_to(game.player.global_position)
	if distance<6 or distance>9: return false
	var camera: Camera3D=game.camera
	var rect := camera.get_viewport().get_visible_rect().grow(-35)
	if camera.is_position_behind(point) or not rect.has_point(camera.unproject_position(point)): return false
	for enemy in get_tree().get_nodes_in_group("all_enemies"):
		if enemy.dead: continue
		if enemy.global_position.distance_to(point)<3+enemy.hit_radius: return false
		if enemy.has_method("danger_contains") and enemy.danger_contains(point): return false
		if enemy.kind==2 and enemy.charge_state!=0:
			if Geometry3D.get_closest_point_to_segment(point,enemy.global_position,enemy.global_position+enemy.charge_direction*10).distance_to(point)<3: return false
		if enemy.is_in_group("final_bosses") or enemy.is_miniboss:
			if point.distance_to(enemy.global_position)<12: return false
	for cloud in get_tree().get_nodes_in_group("enemy_clouds"):
		if cloud.danger_contains(point): return false
	for bolt in get_tree().get_nodes_in_group("hostile_projectiles"):
		var ground: Vector3=bolt.global_position-Vector3.UP
		if Geometry3D.get_closest_point_to_segment(point,ground,ground+bolt.direction*bolt.speed).distance_to(point)<2: return false
	return true
func find_safe_position() -> Vector3:
	for attempt in range(96):
		var angle: float=game.rng.randf_range(0,TAU)
		var point: Vector3=game.player.global_position+Vector3(cos(angle),0,sin(angle))*game.rng.randf_range(6,9)
		if position_safe(point): return point
	return Vector3.INF
func begin_final() -> void:
	if is_instance_valid(active) and active.state=="waiting": clear()
func clear() -> void:
	game.player.support_damage_multiplier=1.0
	if is_instance_valid(active):
		active.queue_free()
		active=null
func status_text() -> String:
	if not is_instance_valid(active): return ""
	if active.state=="leaving": return "%s：またね！" % Friend.NAMES[active.kind]
	return "%s %s / %s %d秒" % [Friend.ICONS[active.kind],Friend.NAMES[active.kind],"近づくと「%s」" % Friend.EFFECTS[active.kind] if active.state=="waiting" else Friend.EFFECTS[active.kind],ceili(active.remaining)]
