extends Node3D
const V=preload("res://scripts/visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
const C=preload("res://scripts/combat_visuals.gd")
var mode:="gust"
var stats: Dictionary
var direction:=Vector3.BACK
var age:=0.0
var travelled:=0.0
var exploded:=false
var visual: Node3D
var streams: Array[Node3D]=[]
var hit_ids: Dictionary={}
static func build_model(parent: Node3D, kind: String) -> Node3D:
	var root:=V.pivot(parent,"ControlModel")
	if kind=="gust":
		V.rod(root,Color("94cec9"),Vector3.ZERO,Vector3(0,0.45,0),0.07)
		V.ring(root,Color("d0ffee"),Vector3(0,0.45,0),0.3,0.035,true)
		var rotor:=V.pivot(root,"Rotor",Vector3(0,0.45,0))
		for i in range(4):
			var angle:=i*TAU/4
			var blade:=V.ellipsoid(rotor,Color("a4ece2"),Vector3(cos(angle),sin(angle),0)*0.15,Vector3(0.17,0.07,0.04))
			blade.rotation.z=angle+0.3
		V.ellipsoid(rotor,Color.WHITE,Vector3(0,0,0.05),Vector3.ONE*0.065)
	else:
		var box:=BoxMesh.new()
		box.size=Vector3(0.32,0.5,0.18)
		V.mesh(root,box,Color("a7ddff"),Vector3(0,0.2,0))
		V.ellipsoid(root,Color("c6f0ff"),Vector3(0,0.46,0),Vector3(0.16,0.12,0.09))
		V.rod(root,Color("e2bb8b"),Vector3(0,-0.32,0),Vector3(0,0,0),0.04)
		V.rod(root,Color.WHITE,Vector3(-0.08,0.05,0.105),Vector3(-0.08,0.4,0.105),0.018)
	return root
func _ready() -> void:
	add_to_group("weapon_attacks")
	add_to_group("control_attacks")
	visual=V.pivot(self,"ControlVisual")
	if mode=="gust":
		# Geometry and the hit test share the same fixed origin and facing.
		for i in range(13):
			var angle: float=deg_to_rad(-50+i*100.0/12)
			var ray:=direction.rotated(Vector3.UP,angle)

			if i<12:
				var next:=direction.rotated(Vector3.UP,angle+deg_to_rad(100.0/12))
				C.ink(V.rod(visual,Color("86e5ee"),ray*stats.reach+Vector3.UP*0.06,next*stats.reach+Vector3.UP*0.06,0.018))
		for i in range(56): streams.append(C.ink(V.rod(visual,Color("d3fff8"),Vector3.ZERO,Vector3.UP,0.024)))
		animate_wind()
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var offset: Vector3=enemy.global_position-global_position
			offset.y=0
			if offset.length()<=float(stats.reach)+enemy.hit_radius and (offset.length()<0.01 or direction.dot(offset.normalized())>=cos(deg_to_rad(50))):
				hit(enemy,"knockback",stats.knockback,offset.normalized() if offset.length()>0.01 else direction)
	else:
		build_model(visual,"popsicle")
		visual.rotation.y=atan2(direction.x,direction.z)
		C.tail(visual)
func hit(enemy: Node3D, effect: String, value: float, push:=Vector3.ZERO) -> void:
	if enemy.dead or hit_ids.has(enemy.get_instance_id()) or not O.visible_between(self,global_position,enemy.global_position): return
	hit_ids[enemy.get_instance_id()]=true
	enemy.take_damage(int(stats.damage))
	if is_instance_valid(enemy) and not enemy.dead and enemy.has_method("apply_control"):
		enemy.apply_control(effect,value,push)
func burst(center: Vector3) -> void:
	exploded=true
	global_position=center
	age=0
	for part in visual.get_children(): part.free()
	C.friendly(visual,stats.radius)
	for i in range(12):
		var shard:=V.rod(visual,Color("d4faff"),Vector3.ZERO,Vector3.UP*0.3,0.065,0)
		streams.append(shard)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector3=enemy.global_position-center
		offset.y=0
		if offset.length()<=float(stats.radius)+enemy.hit_radius: hit(enemy,"freeze",stats.freeze)
	get_tree().call_group("game_audio","play_effect","ice_break")
func _physics_process(delta: float) -> void:
	age+=delta
	if mode=="gust":
		animate_wind()
		if age>=0.4: queue_free()
		return
	if exploded:
		for i in range(streams.size()):
			var angle:=i*TAU/streams.size()
			streams[i].position=Vector3(cos(angle)*age*4,0.2+sin(age*8)*0.7,sin(angle)*age*4)
			streams[i].scale=Vector3.ONE*maxf(0.01,1-age/0.4)
		if age>=0.4: queue_free()
		return
	var start:=global_position
	var distance:=minf(delta*11,12-travelled)
	var finish:=start+direction*distance
	var obstacle=O.world(self)
	var wall_t:=1.0
	if obstacle!=null: wall_t=obstacle.sweep(start,finish,0.3).t
	var best:=wall_t
	var victim: Node3D
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dead: continue
		var center: Vector3=enemy.global_position+Vector3.UP
		var offset:=start-center
		var b:=offset.dot(direction)
		var c:=offset.length_squared()-pow(0.3+enemy.hit_radius,2)
		var disc:=b*b-c
		if disc<0 or -b+sqrt(disc)<0: continue
		var entry:=maxf(0,-b-sqrt(disc))/maxf(distance,0.00001)
		if entry<best and O.visible_between(self,start,enemy.global_position): best=entry; victim=enemy
	if is_instance_valid(victim):
		burst(victim.global_position)
		return
	global_position=start.lerp(finish,wall_t)
	travelled+=distance
	if wall_t<1 or travelled>=12-0.00001: queue_free()

func wind_point(lane: int, t: float) -> Vector3:
	var ray:=direction.rotated(Vector3.UP,deg_to_rad(-43+lane*86.0/6))
	var side:=Vector3(-ray.z,0,ray.x)
	return ray*float(stats.reach)*t+Vector3.UP*(0.3+sin(t*PI)*0.5)+side*sin(t*TAU*1.5-age*19+lane)*0.14*sin(t*PI)
func animate_wind() -> void:
	for i in range(streams.size()):
		var lane:=i/8
		var a:=wind_point(lane,float(i%8)/8)
		var b:=wind_point(lane,float(i%8+1)/8)
		streams[i].position=(a+b)*0.5
		streams[i].scale.y=a.distance_to(b)
		streams[i].quaternion=Quaternion(Vector3.UP,(b-a).normalized())
