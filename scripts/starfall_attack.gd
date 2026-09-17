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
var fragments: Array[Node3D]=[]
static func star(parent: Node3D, size: float) -> Node3D:
	var root:=V.pivot(parent,"GoldenStar")
	V.ellipsoid(root,Color("fff9d9"),Vector3.ZERO,Vector3.ONE*size*0.48)
	for i in range(5):
		var angle:=i*TAU/5+PI/2
		V.rod(root,Color("ffe3a0"),Vector3.ZERO,Vector3(cos(angle),sin(angle),0)*size,size*0.23,0)
	return root
func _ready() -> void:
	add_to_group("weapon_attacks")
	boundary=C.friendly(self,radius)
	var mark:=star(self,0.4)
	mark.rotation.x=PI/2; mark.position.y=0.07
	falling=star(self,1.3)
	for i in range(7):
		V.ellipsoid(falling,Color("a8e9ff"),Vector3(0,0.6+i*0.55,0),Vector3.ONE*(0.22-i*0.022))
	for i in range(24):
		var shard:=star(self,0.12)
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
				if offset.length()<=radius+enemy.hit_radius and O.visible_between(self,global_position,enemy.global_position): enemy.take_damage(damage)
	if struck:
		var t:=clampf((age-1.2)/0.8,0,1)
		boundary.scale=Vector3.ONE*(1+t*0.08)
		for i in range(fragments.size()):
			var angle:=i*TAU/fragments.size()
			fragments[i].show()
			fragments[i].position=Vector3(cos(angle)*radius*t,0.3+sin(t*PI)*(0.6+i%3*0.3),sin(angle)*radius*t)
			fragments[i].rotation=Vector3(t*3,angle,t*5)
			fragments[i].scale=Vector3.ONE*(1-t)
		if age>=2: queue_free()
