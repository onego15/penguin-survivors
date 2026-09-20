extends RefCounted
## Snapshot the finite pre-boss roster; presentation and HP use the same totals.
var game: Node3D
var started:=false
var locked:=false
var targets: Array=[]
var miniboss: Node3D
var frozen: Dictionary={}
func begin() -> void:
	if started: return
	started=true
	for enemy in game.get_tree().get_nodes_in_group("all_enemies"):
		if enemy.dead or enemy.is_in_group("final_bosses") or enemy.is_in_group("final_minions"): continue
		if enemy.is_miniboss: miniboss=enemy
		else: targets.append(enemy)
	if game.obstacles!=null: game.obstacles.open_all()
func alive(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.dead and not enemy.is_queued_for_deletion()
func snapshot() -> Dictionary:
	if locked: return frozen.duplicate(true)
	var remaining:=0
	for enemy in targets:
		if alive(enemy): remaining+=1
	var ratio:=clampf(float(miniboss.health)/miniboss.max_health,0,1) if alive(miniboss) else 0.0
	var result:=totals(targets.size(),remaining,ratio)
	result["started"]=started
	return result
static func totals(initial: int, remaining: int, ratio: float) -> Dictionary:
	var normal:=30.0*remaining/initial if initial>0 else 0.0
	var boss:=20.0*ratio
	return {"initial":initial,"remaining":remaining,"boss_ratio":ratio,"normal_bonus":normal,"boss_bonus":boss,"bonus":clampi(ceili(normal+boss-0.000000001),0,50)}
func finish() -> void:
	if locked: return
	begin()
	frozen=snapshot()
	frozen["locked"]=true
	locked=true
func apply(boss: Node3D) -> void:
	if boss.get_meta("cleanup_hp_applied",false): return
	boss.health=maxi(1,ceili(float(boss.max_health*(100+int(snapshot().bonus)))/100.0))
	boss.max_health=boss.health
	boss.set_meta("cleanup_hp_applied",true)
func guidance() -> String:
	var data:=snapshot()
	if data.remaining==0:
		return "通常敵掃討完了／中ボスのHPを削ろう" if data.boss_ratio>0 else "掃討完了！ 加算なし"
	for enemy in targets:
		if alive(enemy) and enemy.targetable: return "敵を倒して強化を減らそう"
	return "潜行中：出現を待とう" if not alive(miniboss) else "中ボスのHPを削ろう"
func offscreen_target():
	var candidates:=targets.duplicate()
	if alive(miniboss): candidates.append(miniboss)
	var selected: Node3D
	var distance:=INF
	for enemy in candidates:
		if not alive(enemy) or not enemy.targetable: continue
		var point: Vector2=game.camera.unproject_position(enemy.global_position)
		if game.get_viewport().get_visible_rect().grow(-30).has_point(point) and not game.camera.is_position_behind(enemy.global_position): continue
		var value: float=enemy.global_position.distance_squared_to(game.player.global_position)
		if value<distance: selected=enemy; distance=value
	return selected
