extends "res://scripts/enemy.gd"
const Bolt = preload("res://scripts/boss_projectile.gd")
const Cloud = preload("res://scripts/enemy_cloud.gd")
var cooldown := 2.0
var special_state := "move"
var timer := 0.0
var locked := Vector3.BACK
var landing := Vector3.ZERO
var dash_remaining := 0.0
var warning: MeshInstance3D
var aura: MeshInstance3D
var hint_radius := 1.5
func _ready() -> void:
	health_multiplier = sqrt(health_multiplier)
	super._ready()
	cooldown += fposmod(movement_phase, 1.0)
	if kind == Kind.OWL or kind == Kind.WOLF:
		var line := BoxMesh.new()
		line.size = Vector3(0.15 if kind == Kind.OWL else 2.1,0.025,12 if kind==Kind.OWL else 5)
		warning = Visuals.mesh(self,line,Color("efa86e"))
	else:
		warning = Visuals.ring(self,Color("efa86e"),Vector3(0,0.05,0),1.5 if kind==Kind.MOLE else 2,0.055)
	warning.hide()
	if kind == Kind.DEER:
		add_to_group("deer_aura")
		aura = Visuals.ring(self,Color("e6c578"),Vector3(0,0.05,0),5,0.035)
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	age += delta
	hurt_time = maxf(0,hurt_time-delta)
	var offset := target.global_position-global_position
	offset.y=0
	var distance := offset.length()
	var toward := offset.normalized() if distance>0.01 else Vector3.BACK
	if special_state == "warn":
		timer -= delta
		if timer <= 0: _release()
		return
	if special_state == "dash":
		var step := minf(dash_remaining, 10 * delta)
		var start := global_position
		position += locked * step
		position.x = clampf(position.x,-23,23)
		position.z = clampf(position.z,-23,23)
		var closest := Geometry3D.get_closest_point_to_segment(target.global_position,start,global_position)
		if closest.distance_to(target.global_position) < hit_radius+0.42:
			target.take_damage(roundi(12*damage_multiplier))
		dash_remaining -= step
		_animate(5)
		if dash_remaining <= 0 or absf(position.x)>=23 or absf(position.z)>=23:
			special_state="recover"
			timer=1.2
		return
	if special_state == "recover":
		timer-=delta
		if timer<=0: special_state="move"
		return
	var motion: Vector3 = toward * speed * STATS[kind].speed
	if kind == Kind.OWL:
		motion = toward * speed * (1 if distance>9 else (-1 if distance<7 else 0))
	elif kind == Kind.WOLF:
		var side := Vector3(-toward.z,0,toward.x) * (-1 if sin(movement_phase)<0 else 1)
		motion = (toward*0.55+side*0.85).normalized()*speed*1.1
	_move_and_contact(delta,motion*aura_multiplier())
	if kind == Kind.OWL:
		model.position.y = 0.2 + sin(age*4)*0.08
		model.get_node("WingLeft").rotation.z=sin(age*8)*0.25
		model.get_node("WingRight").rotation.z=-sin(age*8)*0.25
	cooldown-=delta
	if cooldown>0: return
	locked=toward
	# Limit simultaneous committed attacks, so a large pack still leaves a dodge route.
	if kind in [Kind.WOLF,Kind.MOLE]:
		var committed := 0
		for other in get_tree().get_nodes_in_group("all_enemies"):
			if other!=self and not other.dead and other.kind==kind and other.get("special_state") in ["warn","dash"]: committed+=1
		if committed >= (2 if kind==Kind.WOLF else 1):
			cooldown=0.4+fposmod(movement_phase,0.3)
			return
	if kind == Kind.SKUNK:
		if get_tree().get_nodes_in_group("enemy_clouds").size()<6:
			var cloud := Cloud.new()
			cloud.target=target
			cloud.position=position
			cloud.damage=roundi(8*damage_multiplier)
			get_parent().add_child(cloud)
		cooldown=4
	elif kind == Kind.OWL and distance<=12:
		_begin_warning(0.9)
	elif kind == Kind.WOLF and distance<=9:
		_begin_warning(0.8)
	elif kind == Kind.HEDGEHOG and distance<=12:
		_begin_warning(1.0)
	elif kind == Kind.MOLE:
		landing=target.global_position
		landing.x=clampf(landing.x,-23,23)
		landing.z=clampf(landing.z,-23,23)
		targetable=false
		remove_from_group("enemies")
		model.hide()
		health_bar.hide()
		_begin_warning(1.2)
		warning.global_position=landing+Vector3(0,0.06,0)
func _begin_warning(duration: float) -> void:
	special_state="warn"
	timer=duration
	warning.show()
	if kind in [Kind.OWL,Kind.WOLF]:
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
	elif kind == Kind.WOLF:
		special_state="dash"
		dash_remaining=5
		cooldown=3
	elif kind == Kind.MOLE:
		global_position=landing
		warning.position=Vector3(0,0.05,0)
		model.show()
		targetable=true
		add_to_group("enemies")
		if position.distance_to(target.global_position)<=1.5+0.42:
			target.take_damage(roundi(12*damage_multiplier))
		special_state="recover"
		timer=2
		cooldown=1.8 # 1.2s warning + 2s exposed + 1.8s movement = 5s cycle.
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
	get_parent().add_child(bolt)
func danger_contains(point: Vector3) -> bool:
	if special_state != "warn": return false
	if kind == Kind.MOLE: return point.distance_to(landing)<2.5
	if kind in [Kind.OWL,Kind.WOLF]:
		return Geometry3D.get_closest_point_to_segment(point,global_position,global_position+locked*(12 if kind==Kind.OWL else 5)).distance_to(point)<2
	return point.distance_to(global_position)<5
