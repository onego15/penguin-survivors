extends Node3D
## Sea fusions snapshot stats and launch coordinates. All damage uses the shared reward path.
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
const Hits=preload("res://scripts/contributions.gd")
const Models=preload("res://scripts/beach_models.gd")
var mode:="pearl_wave"
var stats: Dictionary
var direction:=Vector3.BACK
var age:=0.0
var pulses:=0
var wave: Node3D
var dome: Node3D
var water_rings: Array[Node3D]=[]
var bubbles: Array[Node3D]=[]
var lanes: Array[Dictionary]=[]
var noodle_hits: Dictionary={}
var snap_hits: Dictionary={}
var snapped:=false
func _ready() -> void:
	add_to_group("weapon_attacks")
	stats=stats.duplicate(true)
	direction.y=0; direction=direction.normalized()
	if mode=="pearl_wave":
		wave=preload("res://scripts/beach_attack.gd").new(); wave.mode="shell_wave"; wave.direction=direction
		wave.stats=stats.duplicate(); wave.stats.width=float(stats.width)/2
		add_child(wave); wave.set_physics_process(false)
		var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var profile: Array[Vector2]=[Vector2(-0.28,-0.24),Vector2(0.02,-0.12),Vector2(0.42,0.04),Vector2(0.57,0.21),Vector2(0.46,0.34),Vector2(0.31,0.32)]
		for j in range(profile.size()-1):
			var a:=Vector3(-0.25,profile[j].x,profile[j].y); var b:=Vector3(0.25,profile[j].x,profile[j].y)
			var c:=Vector3(-0.25,profile[j+1].x,profile[j+1].y); var d:=Vector3(0.25,profile[j+1].x,profile[j+1].y)
			for vertex in [a,b,c,b,d,c]: surface.add_vertex(vertex)
		surface.generate_normals(); var mesh:=surface.commit()
		for i in range(wave.parts.size()):
			var part: Node3D=wave.parts[i]
			for child in part.get_children(): child.free()
			var water:=C.ink(V.mesh(part,mesh,Color(0.25,0.81,0.9,0.5))); water.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
			C.ink(V.rod(part,Color("e6ffff"),Vector3(-0.25,0.56,0.22),Vector3(0.25,0.56,0.22),0.065))
			C.ink(V.rod(part,Color("65e8ff"),Vector3(-0.25,-0.26,-0.23),Vector3(0.25,-0.26,-0.23),0.025))
			if i%3==1: part.set_meta("pearl",C.ink(V.ellipsoid(part,Color("fff4df"),Vector3(0,0.57,0.12),Vector3.ONE*0.28)))
	elif mode=="bubble_aquarium":
		dome=V.pivot(self,"WaterDome")
		var shape:=SphereMesh.new(); shape.radius=stats.radius; shape.height=stats.radius*2; shape.is_hemisphere=true
		var mesh:=C.ink(V.mesh(dome,shape,Color(0.42,0.83,0.96,0.13)))
		mesh.scale.y=0.45
		C.friendly(dome,stats.radius)
		for i in range(3): water_rings.append(C.ink(V.ring(dome,Color(0.65,0.94,1,0.45),Vector3.UP*(0.1+i*0.25),stats.radius*(1-i*0.1),0.025)))
		for i in range(6):
			var bubble=preload("res://scripts/beach_attack.gd").new(); bubble.mode="bubble"
			bubble.direction=direction.rotated(Vector3.UP,i*TAU/6)
			bubble.stats={"count":1,"damage":stats.pulse_damage,"radius":stats.pulse_radius,"duration":3.0}
			bubble.position=bubble.direction*float(stats.radius); add_child(bubble); bubble.set_physics_process(false); bubble.hide(); bubbles.append(bubble)
	else:
		var side:=Vector3(direction.z,0,-direction.x)
		for sign_value in [-1,1]:
			var d: Vector3=side*sign_value
			var end: Vector3=global_position+d*float(stats.reach)
			var world=O.world(self)
			if world!=null: end=world.sweep(global_position,end,0.3).point
			var ropes: Array[MeshInstance3D]=[]
			for i in range(20): ropes.append(C.ink(V.rod(self,Color("fff0bd"),Vector3.ZERO,Vector3.UP,0.045)))
			var grip:=V.pivot(self,"Grip")
			for i in range(3): C.ink(V.ring(grip,Color("fff1c3"),Vector3.UP*(0.35+i*0.16),0.55,0.025))
			grip.hide()
			var claw_root:=V.pivot(self,"ClosingClaw")
			Models.claw(claw_root,Vector3.UP*0.4,sign_value).scale=Vector3.ONE*1.5
			C.friendly(claw_root,stats.radius); claw_root.hide()
			lanes.append({"direction":d,"end":end,"tip":global_position,"caught":null,"pulled":0.0,"ropes":ropes,"grip":grip,"claw":claw_root})
	transparent(self)
func transparent(node: Node) -> void:
	if node is MeshInstance3D and node.material_override!=null and node.material_override.albedo_color.a<1:
		node.material_override=node.material_override.duplicate(); node.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for child in node.get_children(): transparent(child)
func valid(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.dead and enemy.targetable
func distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()
func area(center: Vector3,radius: float,damage: int,history: Dictionary) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not valid(enemy) or history.has(enemy.get_instance_id()): continue
		if distance(center,enemy.global_position)>radius+enemy.hit_radius or not O.visible_between(self,center,enemy.global_position): continue
		history[enemy.get_instance_id()]=true; Hits.hit(self,enemy,damage)
func _physics_process(delta: float) -> void:
	if is_queued_for_deletion(): return
	if mode=="pearl_wave":
		age+=delta; wave._physics_process(delta)
		for part in wave.parts:
			if part.has_meta("pearl"): part.get_meta("pearl").scale.x=1.0/maxf(0.01,part.scale.x)
		if age>=float(stats.reach)/7: queue_free()
		return
	var end:=age+delta
	while age<end-0.000001:
		var step:=minf(1.0/120,end-age)
		if mode=="bubble_aquarium" and pulses<6: step=minf(step,maxf(0.000001,(pulses+1)*0.5-age))
		if mode=="crab_udon" and age<0.35: step=minf(step,0.35-age)
		if mode=="crab_udon" and age<1.25: step=minf(step,1.25-age)
		var previous:=age; age+=step
		if mode=="bubble_aquarium":
			for i in range(pulses):
				if is_instance_valid(bubbles[i]) and not bubbles[i].is_queued_for_deletion(): bubbles[i]._physics_process(step)
			if pulses<6 and age+0.000001>=(pulses+1)*0.5:
				area(global_position,stats.radius,stats.damage,{})
				var bubble:=bubbles[pulses]
				if O.placement(self,bubble.global_position,0.45) and O.visible_between(self,global_position,bubble.global_position): bubble.show()
				else: bubble.queue_free()
				pulses+=1
		else:
			for lane in lanes: step_lane(lane,previous,step)
			if not snapped and age>=1.25-0.000001:
				snapped=true
				for lane in lanes:
					var point: Vector3=lane.caught.global_position if valid(lane.caught) else global_position+lane.direction*3
					lane.claw.global_position=point; lane.claw.visible=O.visible_between(self,global_position,point)
					if lane.claw.visible: area(point,stats.radius,stats.pulse_damage,snap_hits)
				get_tree().call_group("game_audio","play_effect","sea_hit")
		if (mode=="bubble_aquarium" and age>=6.3) or (mode=="crab_udon" and age>=1.6): queue_free(); break
	if mode=="bubble_aquarium":
		dome.visible=pulses<6
		for i in range(water_rings.size()):
			water_rings[i].scale=Vector3.ONE*(0.75+0.23*fmod(age*2+i/3.0,1.0))
	else: draw_noodles()
func step_lane(lane: Dictionary,previous: float,step: float) -> void:
	if previous<0.35:
		var next:=global_position.lerp(lane.end,minf(1,age/0.35))
		var candidates: Array=[]
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not valid(enemy) or noodle_hits.has(enemy.get_instance_id()): continue
			var point:=Geometry3D.get_closest_point_to_segment(enemy.global_position,lane.tip,next)
			if distance(point,enemy.global_position)<=0.3+enemy.hit_radius and O.visible_between(self,global_position,enemy.global_position): candidates.append(enemy)
		candidates.sort_custom(func(a,b): return global_position.distance_squared_to(a.global_position)<global_position.distance_squared_to(b.global_position))
		for enemy in candidates:
			noodle_hits[enemy.get_instance_id()]=true; Hits.hit(self,enemy,stats.damage)
			if valid(enemy) and not valid(lane.caught) and not enemy.is_miniboss and not enemy.is_in_group("final_bosses"): lane.caught=enemy
		lane.tip=next
	elif previous<1.25:
		if valid(lane.caught):
			var enemy: Node3D=lane.caught
			if not enemy.is_knocked_back() and O.visible_between(self,global_position,enemy.global_position):
				var toward:=global_position-enemy.global_position; toward.y=0
				var length:=minf(minf(4-float(lane.pulled),4.0/0.9*step),maxf(0,toward.length()-3))
				var finish:=enemy.global_position+toward.normalized()*length
				var world=O.world(self)
				if world!=null: finish=world.move_actor(enemy,finish,enemy.hit_radius)
				lane.pulled+=enemy.global_position.distance_to(finish); enemy.global_position=finish
			lane.tip=enemy.global_position
		else: lane.tip=lane.end.lerp(global_position+lane.direction*3,clampf((age-0.35)/0.9,0,1))
func draw_noodles() -> void:
	for lane in lanes:
		lane.grip.visible=not snapped and age>=0.35 and valid(lane.caught)
		if lane.grip.visible: lane.grip.global_position=lane.caught.global_position; lane.grip.rotation.y=age*12
		if not snapped:
			lane.claw.global_position=lane.tip
			lane.claw.visible=O.visible_between(self,global_position,lane.tip)
		var claw=lane.claw.get_node("Claw")
		claw.get_node("JawLeft").rotation.y=-0.45 if not snapped else 0.0
		claw.get_node("JawRight").rotation.y=0.45 if not snapped else 0.0
		for i in range(lane.ropes.size()):
			var rope: MeshInstance3D=lane.ropes[i]; rope.visible=not snapped
			var t: float=float(i)/lane.ropes.size(); var u: float=float(i+1)/lane.ropes.size()
			var a:=global_position.lerp(lane.tip,t)+Vector3.UP*(0.5+sin(t*PI)*0.3)+direction*sin(t*TAU*2+age*12)*sin(t*PI)*0.08
			var b:=global_position.lerp(lane.tip,u)+Vector3.UP*(0.5+sin(u*PI)*0.3)+direction*sin(u*TAU*2+age*12)*sin(u*PI)*0.08
			rope.global_position=(a+b)*0.5; rope.scale.y=maxf(0.001,a.distance_to(b))
			if a.distance_squared_to(b)>0.000001: rope.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
