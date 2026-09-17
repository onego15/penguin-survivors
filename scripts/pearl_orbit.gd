extends Node3D
const V=preload("res://scripts/visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
const PERIOD:=2.1
var player: Node3D
var stats: Dictionary
var age:=0.0
var hit_times: Dictionary={}
var pearls: Array[Node3D]=[]
var previous_center:=Vector3.ZERO
func _ready() -> void:
	add_to_group("weapon_attacks")
	global_position=player.global_position
	previous_center=global_position
	configure(stats)
func configure(values: Dictionary) -> void:
	stats=values
	while pearls.size()<int(stats.count):
		var pearl:=V.pivot(self,"Pearl")
		var shell:=V.ellipsoid(pearl,Color("b9d9f7"),Vector3.ZERO,Vector3.ONE*0.3)
		shell.material_override=shell.material_override.duplicate()
		shell.material_override.roughness=0.15
		shell.material_override.metallic=0.25
		V.ellipsoid(pearl,Color("fffceb"),Vector3(-0.08,0.1,0.17),Vector3.ONE*0.12)
		for i in range(4):
			V.ellipsoid(pearl,Color("9ce8ed"),Vector3(0,0,-0.22-i*0.12),Vector3.ONE*(0.075-i*0.012))
		pearls.append(pearl)
	for i in range(pearls.size()): pearls[i].visible=i<int(stats.count)
func at(center: Vector3, time: float, index: int) -> Vector3:
	var angle:=time*TAU/PERIOD+index*TAU/int(stats.count)
	return center+Vector3(cos(angle)*stats.radius,1,sin(angle)*stats.radius)
func clear_at(center: Vector3, point: Vector3) -> bool:
	return O.placement(self,point,0.3) and O.visible_between(self,center,point)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): queue_free(); return
	var center: Vector3=player.global_position
	var steps:=maxi(1,ceili(maxf(delta/0.02,previous_center.distance_to(center)/0.15)))
	var start_age:=age
	for step in range(steps):
		var a:=float(step)/steps
		var b:=float(step+1)/steps
		var origin:=previous_center.lerp(center,a)
		var finish_origin:=previous_center.lerp(center,b)
		var time:=start_age+delta*b
		for i in range(int(stats.count)):
			var begin:=at(origin,start_age+delta*a,i)
			var finish:=at(finish_origin,time,i)
			if not clear_at(origin,begin) or not clear_at(finish_origin,finish): continue
			if not O.visible_between(self,begin,finish): continue
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.dead or not enemy.targetable or time-float(hit_times.get(enemy.get_instance_id(),-100))<0.6: continue
				if not O.visible_between(self,finish_origin,enemy.global_position): continue
				var closest:=Geometry3D.get_closest_point_to_segment(enemy.global_position+Vector3.UP,begin,finish)
				if closest.distance_to(enemy.global_position+Vector3.UP)<=0.3+enemy.hit_radius:
					hit_times[enemy.get_instance_id()]=time
					enemy.take_damage(stats.damage)
	age+=delta
	global_position=center
	for i in range(int(stats.count)):
		var point:=at(center,age,i)
		pearls[i].global_position=point
		pearls[i].rotation.y=-age*TAU/PERIOD-i*TAU/int(stats.count)
		pearls[i].visible=clear_at(center,point)
	previous_center=center
	for id in hit_times.keys():
		if age-float(hit_times[id])>1: hit_times.erase(id)
