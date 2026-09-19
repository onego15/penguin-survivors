extends "res://scripts/enemy.gd"
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
const ROSTER=[
	{"kind":10,"name":"翼伯・ヴェスパー","speed":2.2,"hint":"氷の扇を横へ避ける"},
	{"kind":11,"name":"氷玉師・ラスカル","speed":2.0,"hint":"二つの着弾予告から離れる"},
	{"kind":12,"name":"白影・シルク","speed":2.6,"hint":"飛び込みの進路から横へ避ける"},
	{"kind":13,"name":"城門守・カプリコーン","speed":2.2,"hint":"長い突進を壁に誘導する"},
]
var encounter:=0
var boss_name:=""
var warning_left:=0.0
var cooldown:=3.0
var rest:=0.0
var dash_left:=0.0
var locked:=Vector3.ZERO
var landing:=Vector3.ZERO
var launch:=Vector3.ZERO
var warning: Node3D
var flash: Node3D
var flash_left:=0.0
var dive_hit := false
func _ready() -> void:
	is_miniboss=true
	var entry: Dictionary=ROSTER[clampi(encounter,0,3)]
	kind=entry.kind
	boss_name=entry.name
	speed=entry.speed
	visual_scale=1.9
	super._ready()
	add_to_group("minibosses")
	health=100+encounter*80
	max_health=health
	contact_damage=18+encounter*2
	hit_radius=1.25
	health_bar.position.y=3.5
	for i in range(5):
		var p:=Vector3(cos(i*TAU/5)*0.3,1.55,0.4+sin(i*TAU/5)*0.3)
		Visuals.rod(model,Color("e2c27e"),p,p+Vector3.UP*0.4,0.1,0)
	Visuals.ellipsoid(model,Color("4c3975"),Vector3(0,0.8,-0.35),Vector3(0.65,0.62,0.2))
	Visuals.ring(model,Color("e2c27e"),Vector3(0,0.78,0),0.67,0.04)
	warning=preload("res://scripts/enemy_telegraph.gd").fan(self,7,0.2) if kind==10 else C.warning(self,hit_radius,8)
	warning.hide()
	flash=C.danger(self,2.6)
	flash.hide()
func status_label() -> String:
	return " / "+ROSTER[encounter].hint
func start_attack() -> void:
	locked=(target.global_position-global_position).normalized()
	launch=global_position
	warning_left=1.2 if kind!=13 else 1.1
	if kind==11:
		var count:=get_tree().get_nodes_in_group("castle_bombs").size()
		var side:=Vector3(-locked.z,0,locked.x)
		for offset in [-2.0,2.0]:
			if count>=2: break
			var point: Vector3=target.global_position+side*offset
			if not O.placement(self,point,0.1): continue
			var bomb=preload("res://scripts/castle_bomb.gd").new()
			bomb.position=point
			bomb.origin=global_position
			bomb.target=target
			bomb.damage=18
			preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,bomb)
			get_parent().add_child(bomb)
			count+=1
		warning_left=0
		cooldown=6
		rest=1.5
		get_tree().call_group("game_audio","play_effect","castle_throw")
		return
	if kind==12:
		dive_hit=false
		landing=preload("res://scripts/enemy_telegraph.gd").endpoint(self,locked,minf(8,global_position.distance_to(target.global_position)))
		var obstacle=O.world(self)
		if obstacle!=null: landing=obstacle.sweep(launch,landing,hit_radius).point
		warning.free()
		warning=preload("res://scripts/enemy_telegraph.gd").lane(self,landing)
	else:
		warning.position=Vector3.UP*0.09 if kind==10 else locked*4
		warning.rotation.y=atan2(locked.x,locked.z)
	warning.show()
	get_tree().call_group("game_audio","play_effect","noctis_cast")
func release() -> void:
	warning.hide()
	if kind==10:
		for i in range(7):
			var bolt=preload("res://scripts/boss_projectile.gd").new()
			bolt.position=global_position+Vector3.UP
			bolt.direction=locked.rotated(Vector3.UP,(i-3)*0.2)
			bolt.target=target
			bolt.speed=6
			bolt.damage=14
			preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,bolt)
			get_parent().add_child(bolt)
		rest=1.5
		cooldown=5
	elif kind==12: dash_left=0.65
	elif kind==13: dash_left=8.0/9.0
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	age+=delta
	if kind==11: preload("res://scripts/enemy_presentation.gd").throw_pose(model,cooldown)
	hurt_time=maxf(0,hurt_time-delta)
	if flash_left>0:
		flash_left-=delta
		if flash_left<=0: flash.hide()
	if kind==10:
		model.get_node("WingLeft").rotation.z=sin(age*9)*0.45
		model.get_node("WingRight").rotation.z=-sin(age*9)*0.45
	if rest>0: rest-=delta; return
	if warning_left>0:
		warning_left=maxf(0,warning_left-delta)
		C.progress(warning,warning_left/(1.1 if kind==13 else 1.2))
		model.rotation.x=-0.12
		if warning_left<=0: release()
		return
	if dash_left>0:
		var step:=minf(delta,dash_left)
		dash_left-=step
		if kind==12:
			var previous := global_position
			var desired := launch.lerp(landing,1-dash_left/0.65)
			var obstacles=O.world(self)
			global_position=obstacles.move_actor(self,desired,hit_radius,false) if obstacles!=null else desired
			if get_meta("wall_blocked",false): dash_left=0
			model.position.y=sin((1-dash_left/0.65)*PI)*0.45
			model.rotation.x=0.32
			model.scale=Vector3(1,0.82,1.12)*visual_scale
			var nearest:=Geometry3D.get_closest_point_to_segment(target.global_position,previous,global_position)
			if not dive_hit and nearest.distance_to(target.global_position)<=hit_radius+0.42 and O.visible_between(self,nearest,target.global_position):
				dive_hit=true
				target.take_damage(20,preload("res://scripts/difficulty_tiers.gd").source(self))
		else:
			set_meta("wall_dash",true)
			_move_and_contact(step,locked*9)
			if get_meta("wall_blocked",false): dash_left=0
		if dash_left<=0:
			set_meta("wall_dash",false)
			model.position.y=0
			model.rotation.x=0
			model.scale=Vector3.ONE*visual_scale
			rest=2.0 if kind==13 and get_meta("wall_blocked",false) else 1.5
			cooldown=4
		return
	cooldown-=delta
	var offset:=target.global_position-global_position
	if cooldown<=0 and offset.length()<14: start_attack(); return
	_move_and_contact(delta,offset.normalized()*speed)
func danger_contains(point: Vector3) -> bool:
	if kind==12 and (warning_left>0 or dash_left>0): return Geometry3D.get_closest_point_to_segment(point,launch,landing).distance_to(point)<hit_radius+0.42
	if kind==13 and (warning_left>0 or dash_left>0): return Geometry3D.get_closest_point_to_segment(point,position,position+locked*8).distance_to(point)<1.8
	return false
