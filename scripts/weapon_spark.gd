extends Node3D
const V=preload("res://scripts/visuals.gd")
var age:=0.0
var shards: Array[Node3D]=[]
static func spawn(source: Node3D, point: Vector3) -> void:
	if source.get_tree().get_nodes_in_group("weapon_sparks").size()>=16: return
	var effect=load("res://scripts/weapon_spark.gd").new()
	source.get_parent().add_child(effect)
	effect.global_position=point
func _ready() -> void:
	add_to_group("weapon_sparks")
	add_to_group("weapon_attacks")
	for i in range(5):
		var shard:=V.rod(self,Color("c7f6ff"),Vector3.ZERO,Vector3.UP*0.14,0.035,0)
		shards.append(shard)
func _physics_process(delta: float) -> void:
	age+=delta
	for i in range(shards.size()):
		shards[i].position=Vector3(cos(i*TAU/5),sin(age*PI/0.3),sin(i*TAU/5))*age*1.8
		shards[i].scale=Vector3.ONE*maxf(0,1-age/0.3)
	if age>=0.3: queue_free()
