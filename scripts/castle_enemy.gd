extends "res://scripts/enemy.gd"
const C=preload("res://scripts/combat_visuals.gd")
var cooldown:=2.0
var warning_left:=0.0
var dash_left:=0.0
var rest:=0.0
var locked:=Vector3.ZERO
var marker: Node3D
func _ready() -> void:
	if kind==14: set_meta("gate_phasing",true)
	health_multiplier=sqrt(health_multiplier)
	super._ready()
	marker=C.warning(self,0.7,6 if kind==13 else 1.5)
	marker.hide()
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	age+=delta
	hurt_time=maxf(0,hurt_time-delta)
	var offset:=target.global_position-global_position
	var toward:=offset.normalized()
	if rest>0: rest-=delta; return
	if warning_left>0:
		warning_left=maxf(0,warning_left-delta)
		C.progress(marker,warning_left/(1.0 if kind==13 else 0.6))
		model.rotation.x=-0.15
		if warning_left<=0:
			marker.hide()
			dash_left=6.0/9 if kind==13 else 0.35
		return
	if dash_left>0:
		var step:=minf(delta,dash_left)
		set_meta("wall_dash",true)
		var original:=contact_damage
		if kind==13: contact_damage=roundi(16*damage_multiplier)
		_move_and_contact(step,locked*(9 if kind==13 else 1.5/0.35))
		contact_damage=original
		dash_left-=step
		if get_meta("wall_blocked",false): dash_left=0
		if kind==12: model.position.y=sin((1-dash_left/0.35)*PI)*0.6
		if dash_left<=0:
			set_meta("wall_dash",false)
			rest=1.2 if kind==13 else 0
			cooldown=4
		return
	var motion:=toward*speed
	if kind==10:
		motion=(toward+Vector3(-toward.z,0,toward.x)*sin(age*4+movement_phase)*0.5).normalized()*speed
	_move_and_contact(delta,motion)
	if kind==14:
		model.position.y=0.3+sin(age*3)*0.18
		model.rotation.z=sin(age*2)*0.08
		return
	if kind==10:
		model.position.y=0.35+sin(age*7)*0.15
		model.get_node("WingLeft").rotation.z=sin(age*12)*0.5
		model.get_node("WingRight").rotation.z=-sin(age*12)*0.5
		return
	model.rotation.y=lerp_angle(model.rotation.y,atan2(toward.x,toward.z),minf(1,delta*8))
	if model.has_node("Tail"): model.get_node("Tail").rotation.y=sin(age*7)*0.22
	for child in model.get_children():
		if str(child.name).begins_with("Paw_"): child.rotation.x=sin(age*10+child.position.z*6)*0.3
	cooldown-=delta
	if cooldown>0: return
	if kind==11 and offset.length()<=10 and get_tree().get_nodes_in_group("castle_bombs").size()<2 and get_tree().get_nodes_in_group("regular_projectiles").size()<32:
		var bomb=preload("res://scripts/castle_bomb.gd").new()
		bomb.target=target
		bomb.origin=global_position
		bomb.position=target.global_position
		bomb.damage=roundi(12*damage_multiplier)
		get_parent().add_child(bomb)
		cooldown=6
		get_tree().call_group("game_audio","play_effect","castle_throw")
	elif kind in [12,13] and offset.length()<=(6 if kind==13 else 5):
		locked=toward if kind==13 else Vector3(-toward.z,0,toward.x)*(1 if sin(movement_phase)>0 else -1)
		warning_left=1 if kind==13 else 0.6
		marker.rotation.y=atan2(locked.x,locked.z)
		marker.position=locked*(3 if kind==13 else 0.75)
		marker.show()

func danger_contains(point: Vector3) -> bool:
	return kind==13 and (warning_left>0 or dash_left>0) and Geometry3D.get_closest_point_to_segment(point,global_position,global_position+locked*6).distance_to(point)<1.4
