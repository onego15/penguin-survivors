extends Node3D
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var damage:=30
var radius:=5.0
var age:=0.0
var struck:=false
var falling: Node3D
var boundary: MeshInstance3D
var shock: MeshInstance3D
var fragments: Array[Node3D]=[]
static func star(parent: Node3D, size: float) -> Node3D:
	var root:=V.pivot(parent,"GoldenStar")
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	for side in [-1,1]:
		for i in range(10):
			var a:=i*TAU/10+PI/2
			var b:=(i+1)*TAU/10+PI/2
			var center:=Vector3(0,0,size*0.18*side)
			var p:=Vector3(cos(a),sin(a),0)*size*(1.0 if i%2==0 else 0.44)
			var q:=Vector3(cos(b),sin(b),0)*size*(1.0 if (i+1)%2==0 else 0.44)
			if side<0:
				var swap:=p; p=q; q=swap
			var normal: Vector3=(p-center).cross(q-center).normalized()
			vertices.append_array(PackedVector3Array([center,q,p]))
			normals.append_array(PackedVector3Array([normal,normal,normal]))
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_NORMAL]=normals
	var shape:=ArrayMesh.new(); shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface:=V.mesh(root,shape,Color("fff1bc"))
	var mat:=surface.material_override.duplicate() as StandardMaterial3D
	mat.emission_enabled=true; mat.emission=Color("665a32"); mat.emission_energy_multiplier=0.4
	surface.material_override=mat
	V.ellipsoid(root,Color("fffbed"),Vector3.ZERO,Vector3(size*0.23,size*0.23,size*0.2))
	return root
func _ready() -> void:
	add_to_group("weapon_attacks")
	boundary=C.friendly(self,radius)
	shock=C.friendly(self,1)
	shock.hide()
	var mark:=star(self,0.4)
	mark.rotation.x=PI/2; mark.position.y=0.07
	falling=star(self,1.3)
	for i in range(7):
		V.ellipsoid(falling,Color("a8e9ff"),Vector3(0,0.6+i*0.55,0),Vector3.ONE*(0.22-i*0.022))
	for i in range(24):
		var shard:=star(self,0.21)
		shard.hide(); fragments.append(shard)
	falling.position.y=10
	get_tree().call_group("game_audio","play_effect","star_fall")
func _physics_process(delta: float) -> void:
	age+=delta
	if not struck:
		falling.position.y=10*pow(maxf(0,1-age/1.2),1.4)
		falling.rotation.z=age*3
		if age>=1.2:
			struck=true
			falling.hide()
			get_tree().call_group("game_audio","play_effect","star_impact")
			var targets:=get_tree().get_nodes_in_group("enemies")
			# Apply ordinary hits before a boss can suspend the combat scene.
			targets.sort_custom(func(a,b): return not a.is_in_group("final_bosses") and b.is_in_group("final_bosses"))
			for enemy in targets:
				if not is_instance_valid(enemy) or enemy.dead or not enemy.targetable: continue
				var offset: Vector3=enemy.global_position-global_position; offset.y=0
				if offset.length()<=radius+enemy.hit_radius and O.visible_between(self,global_position,enemy.global_position): preload("res://scripts/contributions.gd").hit(self,enemy,damage)
	if struck:
		var t:=clampf((age-1.2)/0.8,0,1)
		shock.show()
		shock.scale=Vector3.ONE*maxf(0.01,radius*t)
		for i in range(fragments.size()):
			var angle:=i*TAU/fragments.size()
			fragments[i].show()
			fragments[i].position=Vector3(cos(angle)*radius*t,0.3+sin(t*PI)*(0.6+i%3*0.3),sin(angle)*radius*t)
			fragments[i].rotation=Vector3(t*3,angle,t*5)
			fragments[i].scale=Vector3.ONE*(1-t)
		if age>=2: queue_free()
