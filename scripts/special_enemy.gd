extends "res://scripts/enemy.gd"
const Bolt = preload("res://scripts/boss_projectile.gd")
const Cloud = preload("res://scripts/enemy_cloud.gd")
var cooldown := 2.0
var special_state := "move"
var timer := 0.0
var locked := Vector3.BACK
var landing := Vector3.ZERO
const C = preload("res://scripts/combat_visuals.gd")
var flank_side := 1.0
var warning_duration := 1.0
var digging: Node3D
var warning: Node3D
var rng: RandomNumberGenerator
func _ready() -> void:
	health_multiplier = sqrt(health_multiplier)
	super._ready()
	cooldown += fposmod(movement_phase, 1.0)
	rng=get_parent().get_parent().rng
	flank_side = -1.0 if sin(movement_phase)<0 else 1.0
	warning = C.warning(self,1.5 if kind==Kind.MOLE else (0.23 if kind==Kind.OWL else 2.0),12.0 if kind==Kind.OWL else 0.0)
	if kind==Kind.MOLE:
		digging=C.soil(self)
		digging.hide()
	warning.hide()
	if kind == Kind.DEER:
		warning.free()
		warning=C.warning(self,1.2,14.0)
		warning.hide()
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	if control_step(delta): return
	age += delta
	hurt_time = maxf(0,hurt_time-delta)
	var offset := target.global_position-global_position
	offset.y=0
	var distance := offset.length()
	var toward := offset.normalized() if distance>0.01 else Vector3.BACK
	if special_state == "warn":
		timer -= delta
		C.progress(warning,timer/warning_duration)
		if kind==Kind.MOLE: digging.scale.y=1.0+0.3*sin(age*20)
		if kind==Kind.DEER: model.get_node("Head").rotation.x=0.4
		if timer <= 0: _release()
		return
	if special_state == "dig":
		timer=maxf(0,timer-delta)
		model.position.y=-(1-timer/0.4)*1.2
		model.rotation.x=sin(age*35)*0.12
		for part in model.get_children():
			if str(part.name).begins_with("DigHand"):
				part.rotation.x=sin(age*35)*0.6
		if timer<=0:
			landing=sample_landing(target.global_position)
			targetable=false
			remove_from_group("enemies")
			model.hide()
			health_bar.hide()
			_begin_warning(1.2)
			warning.global_position=landing+Vector3(0,0.06,0)
			digging.global_position=landing
		return
	if special_state == "recover":
		timer-=delta
		if kind==Kind.DEER:
			var progress:=clampf((1.2-timer)/0.3,0,1)
			model.get_node("Head").rotation.y=sin(progress*TAU)*0.8
			model.get_node("Head").rotation.x=lerpf(0.4,0,progress)
			if timer<=0: special_state="move"
			return
		model.position.y=sin(clampf((2-timer)/0.3,0,1)*PI)*0.55
		if timer<1.7 and is_instance_valid(digging): digging.hide()
		if timer<=0: special_state="move"
		return
	var motion: Vector3 = toward * speed * STATS[kind].speed
	if kind == Kind.OWL:
		motion = toward * speed * (1 if distance>9 else (-1 if distance<7 else 0))
	elif kind == Kind.WOLF:
		var side := Vector3(-toward.z,0,toward.x)*flank_side
		motion = (toward*0.75+side*0.85).normalized()*speed*1.3 if distance<=5 else toward*speed*1.3
		var next := position+motion*delta
		if (absf(next.x)>23 and signf(motion.x)==signf(position.x)) or (absf(next.z)>23 and signf(motion.z)==signf(position.z)):
			flank_side *= -1
			motion=(toward*0.75-side*0.85).normalized()*speed*1.3
	_move_and_contact(delta,motion)
	if kind == Kind.OWL:
		model.position.y = 0.2 + sin(age*4)*0.08
		model.get_node("WingLeft").rotation.z=sin(age*8)*0.25
		model.get_node("WingRight").rotation.z=-sin(age*8)*0.25
	if kind==Kind.WOLF:
		model.rotation.z=flank_side*0.13
		for part in model.get_children():
			if str(part.name).begins_with("Paw"): part.rotation.x=sin(age*13+part.position.z*4)*0.45
		model.get_node("Tail").rotation.y=sin(age*9)*0.25
		return
	cooldown-=delta
	if cooldown>0: return
	locked=toward
	# Limit simultaneous committed attacks, so a large pack still leaves a dodge route.
	if kind == Kind.MOLE:
		var committed := 0
		for other in get_tree().get_nodes_in_group("all_enemies"):
			if other!=self and not other.dead and other.kind==kind and other.get("special_state") in ["dig","warn"]: committed+=1
		if committed >= 1:
			cooldown=0.4+fposmod(movement_phase,0.3)
			return
	if kind == Kind.SKUNK:
		if get_tree().get_nodes_in_group("enemy_clouds").size()<6:
			var cloud := Cloud.new()
			cloud.target=target
			cloud.position=position
			cloud.damage=roundi(8*damage_multiplier)
			preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,cloud)
			get_parent().add_child(cloud)
		cooldown=4
	elif kind == Kind.OWL and distance<=12:
		_begin_warning(0.9)
	elif kind == Kind.HEDGEHOG and distance<=12:
		_begin_warning(1.0)
	elif kind == Kind.DEER and distance<=12:
		if get_tree().get_nodes_in_group("regular_projectiles").size()>=32: return
		for other in get_tree().get_nodes_in_group("all_enemies"):
			if other!=self and not other.dead and other.kind==Kind.DEER and other.get("special_state")=="warn": return
		_begin_warning(1.2)
	elif kind == Kind.MOLE:
		special_state="dig"
		timer=0.4
		digging.position=Vector3.ZERO
		digging.show()
func _begin_warning(duration: float) -> void:
	special_state="warn"
	timer=duration
	warning_duration=duration
	C.progress(warning,1.0)
	warning.show()
	if kind == Kind.DEER:
		warning.position=locked*7+Vector3.UP*0.06
		warning.rotation.y=atan2(locked.x,locked.z)
		model.rotation.y=warning.rotation.y
	if kind == Kind.OWL:
		warning.position=locked*(6 if kind==Kind.OWL else 2.5)+Vector3(0,0.06,0)
		warning.rotation.y=atan2(locked.x,locked.z)
		model.rotation.y=warning.rotation.y
func _release() -> void:
	warning.hide()
	special_state="move"
	if kind == Kind.OWL:
		_fire(locked)
		cooldown=4
	elif kind == Kind.HEDGEHOG:
		# Reserve all eight slots, otherwise defer the complete burst.
		if get_tree().get_nodes_in_group("regular_projectiles").size()<=24:
			for i in range(8): _fire(Vector3(sin(i*TAU/8),0,cos(i*TAU/8)))
		cooldown=5
	elif kind == Kind.DEER:
		if get_tree().get_nodes_in_group("regular_projectiles").size()<32:
			var wave:=preload("res://scripts/deer_shockwave.gd").new()
			wave.target=target
			wave.direction=locked
			wave.position=position
			wave.damage=roundi(12*damage_multiplier)
			preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,wave)
			get_parent().add_child(wave)
		special_state="recover"
		timer=1.2
		cooldown=4.0
	elif kind == Kind.MOLE:
		global_position=landing
		digging.position=Vector3.ZERO
		digging.scale=Vector3.ONE
		warning.position=Vector3(0,0.05,0)
		model.show()
		model.position.y=0
		model.rotation.x=0
		health_bar.show()
		targetable=true
		add_to_group("enemies")
		if position.distance_to(target.global_position)<=1.5+0.42:
			target.take_damage(roundi(12*damage_multiplier),preload("res://scripts/difficulty_tiers.gd").source(self))
		special_state="recover"
		timer=2
		cooldown=1.8 # 0.4s digging + 1.2s warning + 2s exposed + 1.8s movement.
func _fire(direction: Vector3) -> void:
	if get_tree().get_nodes_in_group("regular_projectiles").size()>=32: return
	var bolt := Bolt.new()
	bolt.regular=true
	bolt.target=target
	bolt.direction=direction
	bolt.position=position+Vector3.UP
	bolt.damage=roundi(10*damage_multiplier)
	bolt.speed=4.5
	bolt.lifetime=3.5
	bolt.tint=Color("ecb778") if kind==Kind.HEDGEHOG else Color("bf99e8")
	preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,bolt)
	get_parent().add_child(bolt)
func danger_contains(point: Vector3) -> bool:
	if special_state != "warn": return false
	if kind == Kind.MOLE: return point.distance_to(landing)<2.5
	if kind == Kind.DEER: return antlers_contain(point)
	if kind == Kind.OWL:
		return Geometry3D.get_closest_point_to_segment(point,global_position,global_position+locked*(12 if kind==Kind.OWL else 5)).distance_to(point)<2
	return point.distance_to(global_position)<5

func sample_landing(center: Vector3) -> Vector3:
	if rng.randf()<0.2: return center
	for attempt in range(16):
		var angle:=rng.randf_range(0,TAU)
		var radius:=sqrt(rng.randf_range(1.5*1.5,4.0*4.0))
		var candidate:=center+Vector3(cos(angle),0,sin(angle))*radius
		if absf(candidate.x)<=23 and absf(candidate.z)<=23: return candidate
	return Vector3(clampf(center.x,-23,23),center.y,clampf(center.z,-23,23))
func antlers_contain(point: Vector3) -> bool:
	var offset:=point-global_position
	offset.y=0
	var along:=offset.dot(locked)
	return along>=-0.42 and along<=14.42 and absf(offset.dot(Vector3(-locked.z,0,locked.x)))<=1.62

func cancel_control_action() -> void:
	super.cancel_control_action()
	special_state="move"
	timer=0
	cooldown=maxf(cooldown,2.0 if kind==Kind.MOLE else 1.0)
	warning.hide()
	if is_instance_valid(digging): digging.hide()
	if model.has_node("Head"): model.get_node("Head").rotation=Vector3.ZERO
