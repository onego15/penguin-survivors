extends Node3D
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
const Hits=preload("res://scripts/contributions.gd")
var mode:="shell_wave"
var stats: Dictionary
var direction:=Vector3.BACK
var age:=0.0
var hit_ids: Dictionary={}
var parts: Array[Node3D]=[]
var bubbles: Array[Dictionary]=[]
var side:=Vector3.RIGHT
func _ready() -> void:
	add_to_group("weapon_attacks")
	side=Vector3(direction.z,0,-direction.x)
	if mode=="shell_wave":
		for i in range(17): parts.append(C.ink(V.ellipsoid(self,Color(0.57,0.91,0.96,0.45),Vector3.ZERO,Vector3(0.22,0.42,0.18))))
	elif mode=="bubble":
		for i in range(int(stats.count)):
			var root:=V.pivot(self,"Bubble")
			C.ink(V.ellipsoid(root,Color(0.6,0.85,1,0.2),Vector3.UP*0.6,Vector3.ONE*0.45))
			C.ink(V.ring(root,Color("b3faff"),Vector3.UP*0.6,0.45,0.025,true))
			C.ink(V.ellipsoid(root,Color.WHITE,Vector3(-0.15,0.8,0.3),Vector3.ONE*0.065))
			bubbles.append({"node":root,"velocity":direction.rotated(Vector3.UP,(i-(stats.count-1)/2.0)*0.3)*1.5,"popped":false,"pop_age":0.0})
	else:
		for sign_value in [-1,1]:
			var root:=V.pivot(self,"Snap",side*float(stats.reach)*sign_value)
			preload("res://scripts/beach_models.gd").claw(root,Vector3.UP*0.4,sign_value).scale=Vector3.ONE*1.4
			C.friendly(root,stats.radius); parts.append(root)
	translucent(self)
func translucent(root: Node) -> void:
	if root is MeshInstance3D and root.material_override.albedo_color.a<1:
		root.material_override=root.material_override.duplicate()
		root.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	for child in root.get_children(): translucent(child)
func ground_distance(a: Vector3,b: Vector3) -> float:
	return Vector2(a.x-b.x,a.z-b.z).length()
func hit(enemy: Node3D, center: Vector3, history: Dictionary) -> void:
	if enemy.dead or not enemy.targetable or history.has(enemy.get_instance_id()) or not O.visible_between(self,center,enemy.global_position): return
	history[enemy.get_instance_id()]=true
	Hits.hit(self,enemy,int(stats.damage))
func pop(item: Dictionary) -> void:
	if item.popped: return
	item.popped=true
	var center: Vector3=item.node.global_position
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if ground_distance(center,enemy.global_position)<=float(stats.radius)+enemy.hit_radius: hit(enemy,center,{})
	C.friendly(item.node,stats.radius)
	get_tree().call_group("game_audio","play_effect","sea_hit")
func _physics_process(delta: float) -> void:
	var previous:=age
	age+=delta
	if mode=="shell_wave":
		var start:=minf(previous*7,stats.reach)
		var finish:=minf(age*7,stats.reach)
		for i in range(parts.size()):
			var across: float=(float(i)/16*2-1)*float(stats.width)*(0.3+0.7*finish/float(stats.reach))
			parts[i].position=direction*finish+side*across+Vector3.UP*(0.35+sin(i*0.6+age*9)*0.1)
			parts[i].visible=O.visible_between(self,global_position,parts[i].global_position)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var offset: Vector3=enemy.global_position-global_position
			var along:=offset.dot(direction)
			if along<start-enemy.hit_radius-0.25 or along>finish+enemy.hit_radius+0.25: continue
			var width: float=stats.width*(0.3+0.7*clampf(along/float(stats.reach),0,1))
			if absf(offset.dot(side))<=width+enemy.hit_radius: hit(enemy,global_position,hit_ids)
		if finish>=float(stats.reach): queue_free()
	elif mode=="bubble":
		for item in bubbles:
			if item.popped:
				item.pop_age+=delta
				item.node.scale=Vector3.ONE*(1+item.pop_age*2)
				item.node.visible=item.pop_age<0.25
				continue
			var node: Node3D=item.node
			var start:=node.global_position
			var current:=Vector3.ZERO
			var field=get_tree().get_first_node_in_group("beach_fields")
			if field!=null: current=field.flow(start)
			var finish: Vector3=start+(item.velocity+current)*delta
			if not O.visible_between(self,start,finish): item.popped=true; item.pop_age=1; node.hide(); continue
			node.global_position=finish
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.dead or not enemy.targetable: continue
				var closest:=Geometry3D.get_closest_point_to_segment(enemy.global_position,start,finish)
				if ground_distance(closest,enemy.global_position)<=0.45+enemy.hit_radius:
					node.global_position=closest; pop(item); break
		if age>=float(stats.duration): queue_free()
	else:
		for root in parts:
			root.scale=Vector3.ONE*(0.85+0.15*sin(clampf(age/0.35,0,1)*PI))
		if previous==0:
			for enemy in get_tree().get_nodes_in_group("enemies"):
				for root in parts:
					if ground_distance(root.global_position,enemy.global_position)<=float(stats.radius)+enemy.hit_radius and O.visible_between(self,global_position,root.global_position): hit(enemy,root.global_position,hit_ids)
		if age>=0.4: queue_free()
