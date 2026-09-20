extends Node3D
const V=preload("res://scripts/visuals.gd")
var game: Node3D
var clock:=0.0
var state:="idle"
var left:=0.0
var direction:=1.0
var next_at:=60.0
var commanded:=false
var arrows: Array[Node3D]=[]
var pools: Array[Node3D]=[]
var pool_wait: Array[float]=[0.0,0.0]
var labels: Array[Label3D]=[]
func _ready() -> void:
	add_to_group("beach_fields")
	for z in [-8.0,8.0]:
		var mesh:=BoxMesh.new(); mesh.size=Vector3(48,0.018,4)
		V.mesh(self,mesh,Color("7bbebd"),Vector3(0,-0.052,z))
		for i in range(28):
			var x: float=-23+i*1.7
			V.rod(self,Color("a6d7d0"),Vector3(x,-0.038,z+sin(i*2.4)*1.6),Vector3(x+0.6,-0.038,z+sin(i*2.4)*1.6+0.07),0.013)
		for x in range(-20,21,4):
			var arrow:=V.pivot(self,"CurrentArrow",Vector3(x,0.025,z)); arrows.append(arrow)
			for side in [-1,1]: V.rod(arrow,Color("e9f4ed"),Vector3(-0.45,0,side*0.3),Vector3(0.4,0,0),0.025)
	for point in [Vector3(-14,0,-16),Vector3(14,0,16)]:
		var pool:=V.pivot(self,"CleansingSpring",point); pools.append(pool)
		V.ring(pool,Color("e5c8a2"),Vector3(0,0.08,0),1.5,0.13)
		V.ellipsoid(pool,Color("88d8bb"),Vector3(0,0.03,0),Vector3(1.4,0.05,1.4))
		V.ellipsoid(pool,Color("b2f1dd"),Vector3(0,0.65,0),Vector3(0.13,0.22,0.13))
		var label:=preload("res://scripts/combat_visuals.gd").symbol(pool,"状態異常を解除",Color("a1ffcf")); label.font_size=28; label.position.y=1.3; labels.append(label)
	refresh()
func flow(point: Vector3) -> Vector3:
	if state!="flow" or absf(point.x)>24: return Vector3.ZERO
	for z in [-8.0,8.0]:
		if absf(point.z-z)<=2: return Vector3(1.2*direction*(-1 if z<0 else 1),0,0)
	return Vector3.ZERO
func stop_flow() -> void:
	state="idle"; left=0; commanded=false; next_at=clock+20; refresh()
func command() -> void:
	direction=-direction; state="warning"; left=2; commanded=true; refresh()
	get_tree().call_group("game_audio","play_effect","tide")
func tick(delta: float) -> void:
	if game.run_state!="combat" or game.choice_open or game.get_tree().paused or game.player.health<=0: return
	clock+=delta
	for i in range(2):
		pool_wait[i]=maxf(0,pool_wait[i]-delta)
		labels[i].text="状態異常を解除" if pool_wait[i]<=0 else "%d秒"%ceili(pool_wait[i])
		if pool_wait[i]<=0 and game.player.position.distance_to(pools[i].position)<=1.5 and game.player.statuses.cleanse():
			pool_wait[i]=15; get_tree().call_group("game_audio","play_effect","cleanse")
	var training: bool=game.is_in_group("sandbox")
	var boss_alive: bool=is_instance_valid(game.active_boss) and not game.active_boss.dead
	if not training and not game.final_boss_spawned and (game.elapsed>=570 or game.elapsed<game.recovery_until or boss_alive): stop_flow(); return
	if not game.final_boss_spawned and game.elapsed>=60 and clock>=next_at and state=="idle": command(); commanded=false
	if state!="idle":
		left-=delta
		if left<=0:
			if state=="warning": state="flow"; left=6
			else: state="idle"; next_at=clock+12; commanded=false
	refresh()
	move_by_flow(game.player,delta)
	for enemy in get_tree().get_nodes_in_group("all_enemies"):
		if enemy.dead or enemy.is_miniboss or enemy.is_in_group("final_bosses") or enemy.kind in [17,18]: continue
		if not enemy.is_physics_processing() or (is_instance_valid(enemy.control) and (enemy.control.frozen>0 or enemy.control.knock_left>0)): continue
		move_by_flow(enemy,delta)
func move_by_flow(actor: Node3D, delta: float) -> void:
	actor.position+=flow(actor.position)*delta
	actor.position.x=clampf(actor.position.x,-23.5,23.5)
	actor.position.z=clampf(actor.position.z,-23.5,23.5)
func refresh() -> void:
	for arrow in arrows:
		arrow.visible=state!="idle"
		arrow.rotation.y=0 if direction*(-1 if arrow.position.z<0 else 1)>0 else PI
		arrow.scale=Vector3.ONE*(0.75+0.2*sin(clock*12) if state=="warning" else 1.0)
