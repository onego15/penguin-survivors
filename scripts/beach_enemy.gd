extends "res://scripts/enemy.gd"
const C=preload("res://scripts/combat_visuals.gd")
var anchor:=Vector3.ZERO
var destination:=Vector3.ZERO
var leg:=0
var clockwise:=1.0
var cooldown:=2.0
var warning_left:=0.0
var warning_duration:=1.0
var rest:=0.0
var locked:=Vector3.BACK
var marker: Node3D
var hazard: Node3D
var shortened:=false
func _ready() -> void:
	if not is_miniboss: health_multiplier=sqrt(health_multiplier)
	super._ready()
	anchor=Vector3(clampf(position.x,-16,16),0,clampf(position.z,-18,18))
	clockwise=1.0 if sin(movement_phase)>=0 else -1.0
	choose_destination()
	if kind==18 and is_instance_valid(target): start_attack()
func choose_destination() -> void:
	leg+=1
	var size:=2.5 if shortened else (6.0 if kind in [15,18] else 3.0)
	var angle:=leg*TAU/3+movement_phase
	if kind==15: destination=anchor+Vector3(size*(1 if leg%2==0 else -1),0,0)
	elif kind==18: destination=Vector3(clampf(anchor.x+cos(angle)*size*(1 if shortened else 2),-22,22),0,clampf(anchor.z+sin(angle)*size*(1 if shortened else 2),-22,22))
	else: destination=anchor+Vector3(cos(angle),0,sin(angle))*size
	destination.x=clampf(destination.x,-23,23); destination.z=clampf(destination.z,-23,23)
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	if control_step(delta): return
	age+=delta; hurt_time=maxf(0,hurt_time-delta)
	var game=target.get_parent().get_parent()
	if not shortened and "sweep" in game and game.sweep.started:
		shortened=true; anchor=position; choose_destination()
	if rest>0: rest=maxf(0,rest-delta); return
	if warning_left>0:
		warning_left=maxf(0,warning_left-delta)
		if is_instance_valid(marker): C.progress(marker,warning_left/warning_duration)
		model.scale=Vector3.ONE*visual_scale*(1+0.15*(1-warning_left/warning_duration) if kind==20 else 1.0)
		model.rotation.x=-0.12*sin((1-warning_left/warning_duration)*PI)
		if warning_left<=0: release_attack()
		return
	cooldown-=delta
	var offset:=destination-position; offset.y=0
	if kind==17:
		var a:=age/3*clockwise+movement_phase
		destination=anchor+Vector3(cos(a),0,sin(a))*(2.0 if shortened else 3.0)
	if offset.length()<0.25:
		choose_destination()
		rest=0.5 if kind==15 else (1.0 if kind==18 else 0.15)
		if kind==18: start_attack()
		return
	if cooldown<=0 and kind!=18 and (kind!=15 or is_miniboss) and target.position.distance_to(position)<=10:
		if kind in [16,19,20] and get_tree().get_nodes_in_group("regular_projectiles").size()>=32: return
		if kind==17 and get_tree().get_nodes_in_group("jelly_warnings").size()>=2: return
		start_attack(); return
	_move_and_contact(delta,offset.normalized()*minf(speed,offset.length()/maxf(delta,0.001)))
	if kind in [17,18]: model.position.y=0.35+sin(age*4)*0.12
	for child in model.get_children():
		if str(child.name).begins_with("Fin") or str(child.name).begins_with("Tentacle"): child.rotation.z=sin(age*5+child.get_index())*0.2
func start_attack() -> void:
	locked=(destination-position).normalized() if kind==18 else (target.position-position).normalized()
	locked.y=0
	warning_duration=1.5 if is_miniboss and kind==17 else (1.2 if is_miniboss or kind==17 else (1.4 if kind==20 else 1.0))
	warning_left=warning_duration
	if is_instance_valid(marker): marker.free()
	if kind in [15,17]:
		hazard=preload("res://scripts/beach_hazard.gd").new(); hazard.position=position; hazard.target=target
		hazard.radius=4 if is_miniboss else 2.5; hazard.delay=warning_duration
		hazard.half_angle=PI/3 if kind==15 else PI; hazard.direction=locked
		hazard.damage=18 if kind==15 else (16 if is_miniboss else roundi(8*damage_multiplier)); hazard.effect="shock" if kind==17 else ""
		preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,hazard)
		get_parent().add_child(hazard)
		if kind==17: hazard.add_to_group("jelly_warnings")
	else:
		marker=C.warning(self,hit_radius,position.distance_to(destination)) if kind==18 else C.sector_warning(self,4,PI if kind==20 else (0.4 if is_miniboss else 0.08))
		marker.position=locked*position.distance_to(destination)/2 if kind==18 else Vector3.UP*0.09
		marker.rotation.y=atan2(locked.x,locked.z)
	get_tree().call_group("game_audio","play_effect","sea_cast")
func release_attack() -> void:
	if is_instance_valid(marker): marker.hide()
	cooldown=4 if is_miniboss else (6 if kind in [17,20] else 5)
	rest=1.5 if is_miniboss else 0.0
	if kind in [15,17,18]: return
	var count:=6 if kind==20 else (3 if is_miniboss else 1)
	for i in range(count):
		if get_tree().get_nodes_in_group("regular_projectiles").size()>=32: break
		var shot=preload("res://scripts/boss_projectile.gd").new()
		shot.regular=true; shot.target=target; shot.position=position+Vector3.UP
		shot.direction=locked.rotated(Vector3.UP,i*TAU/count if kind==20 else (i-(count-1)/2.0)*0.35)
		shot.speed=3 if kind==20 else 5; shot.lifetime=4 if kind==20 else 2.4
		shot.damage=10 if is_miniboss else roundi(8*damage_multiplier); shot.status_effect="ink" if kind==19 else "sand"
		preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,shot); get_parent().add_child(shot)
func cancel_control_action() -> void:
	super.cancel_control_action()
	warning_left=0; rest=0; cooldown=maxf(cooldown,1)
	if is_instance_valid(marker): marker.hide()
	if is_instance_valid(hazard) and not hazard.fired: hazard.queue_free()
func _exit_tree() -> void:
	if is_instance_valid(hazard) and not hazard.fired: hazard.queue_free()
func danger_contains(point: Vector3) -> bool:
	return is_instance_valid(hazard) and hazard.danger_contains(point)
