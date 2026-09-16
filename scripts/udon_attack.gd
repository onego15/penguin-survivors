extends "res://scripts/weapon_attack.gd"
var reach:=11.0
var grip: Node3D
var splash_radius:=1.2
var tip:=Vector3.ZERO
var destination:=Vector3.ZERO
var noodles: Array[MeshInstance3D]=[]
var caught: Node3D
var pulled:=0.0
var returning_noodle:=false
static func bowl(parent: Node3D) -> Node3D:
	var root:=V.pivot(parent,"UdonBowl")
	V.ellipsoid(root,Color("437b9b"),Vector3.ZERO,Vector3(0.4,0.25,0.4))
	V.ring(root,Color("f6f0df"),Vector3(0,0.26,0),0.37,0.045)
	V.rod(root,Color("b77c46"),Vector3(0,0.24,0),Vector3(0,0.26,0),0.34)
	for i in range(4):
		V.ring(root,Color("fff0bb"),Vector3((i%2-0.5)*0.16,0.28,(i/2-0.5)*0.14),0.12,0.018)
	for side in [-1,1]: V.rod(root,Color("e8be83"),Vector3(side*0.05,0.19,0),Vector3(side*0.05,0.6,-0.5),0.018)
	V.ellipsoid(root,Color("7eaf79"),Vector3(0.12,0.29,0.15),Vector3(0.08,0.025,0.05))
	return root
func origin() -> Vector3:
	return player.body.to_global(Vector3(-0.75,1,0.35)) if is_instance_valid(player) else launch_origin
func _ready() -> void:
	add_to_group("weapon_attacks")
	piercing=true
	radius=0.3
	lifetime=1.25
	launch_origin=origin()
	tip=launch_origin
	destination=launch_origin+direction*reach
	var obstacle=O.world(self)
	if obstacle!=null: destination=obstacle.sweep(launch_origin,destination,0.06).point
	for i in range(24):
		var segment:=V.rod(self,Color("fff0ba") if i%3 else Color("ffffeb"),Vector3.ZERO,Vector3.UP,0.055)
		noodles.append(segment)
	grip=V.pivot(self,"NoodleGrip")
	for i in range(3): V.ring(grip,Color("fff0bb"),Vector3(0,0.5+i*0.2,0),0.65,0.035)
	grip.hide()
	preload("res://scripts/combat_visuals.gd").tail(self)
func _damage(enemy: Node3D) -> void:
	if not O.visible_between(self,origin(),enemy.global_position): return
	if not returning_noodle and not is_instance_valid(caught) and not enemy.is_miniboss and not enemy.is_in_group("final_bosses"): caught=enemy
	super._damage(enemy)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): queue_free(); return
	var end:=minf(age+delta,lifetime)
	while age<end-0.00001:
		var step:=minf(1.0/120,end-age)
		if age<0.35: step=minf(step,0.35-age)
		age+=step
		var next:=launch_origin.lerp(destination,minf(1,age/0.35)) if age<=0.35 else destination.lerp(origin(),clampf((age-0.35)/0.9,0,1))
		_segment_hit(tip,next,false)
		if is_queued_for_deletion(): return
		tip=next
		if age>=0.35 and not returning_noodle:
			var old:=global_position
			global_position=destination-Vector3.UP
			_area_hit(splash_radius,false)
			global_position=old
			returning_noodle=true
			hit_times.clear()
		if returning_noodle and is_instance_valid(caught) and not caught.dead and caught.targetable and pulled<4 and not caught.is_knocked_back():
			var toward: Vector3=player.global_position-caught.global_position
			var length:=minf(minf(4-pulled,4.5*step),maxf(0,toward.length()-3))
			var finish: Vector3=caught.global_position+toward.normalized()*length
			var obstacle=O.world(self)
			if obstacle!=null: finish=obstacle.move_actor(caught,finish,caught.hit_radius)
			pulled+=caught.global_position.distance_to(finish)
			caught.global_position=finish
	if is_instance_valid(caught) and not caught.dead and caught.targetable and returning_noodle:
		grip.show()
		grip.global_position=caught.global_position
		grip.rotation.y=age*12
		grip.scale=Vector3.ONE*maxf(0.8,caught.hit_radius/0.6)
		tip=caught.global_position+Vector3.UP
	else: grip.hide()
	var start:=origin()
	for i in range(noodles.size()):
		var a:=noodle_point(start,tip,float(i)/noodles.size())
		var b:=noodle_point(start,tip,float(i+1)/noodles.size())
		noodles[i].position=to_local((a+b)*0.5)
		noodles[i].scale.y=maxf(0.001,a.distance_to(b))
		if a.distance_squared_to(b)>0.000001: noodles[i].quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	if end>=lifetime-0.00001:
		if is_instance_valid(caught) and not caught.dead and caught.targetable and not hit_times.has(caught.get_instance_id()): _damage(caught)
		queue_free()
func noodle_point(a: Vector3,b: Vector3,t: float) -> Vector3:
	var side:=Vector3(-direction.z,0,direction.x)
	return a.lerp(b,t)+Vector3.UP*sin(t*PI)*0.35+side*sin(t*TAU*2+age*15)*sin(t*PI)*0.1

func _can_hit(enemy: Node3D, repeat: bool) -> bool:
	# Finish the tug before the return hit can kill the captured enemy.
	if returning_noodle and enemy==caught and age<lifetime-0.00001: return false
	return super._can_hit(enemy,repeat)
