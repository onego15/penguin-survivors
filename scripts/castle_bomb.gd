extends Node3D
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var target: Node3D
var origin:=Vector3.ZERO
var age:=0.0
var damage:=12
var warning: Node3D
var active: Node3D
var ball: MeshInstance3D
func _ready() -> void:
	add_to_group("castle_bombs")
	add_to_group("enemy_clouds")
	add_to_group("regular_projectiles")
	warning=C.warning(self,2)
	active=C.danger(self,2)
	active.hide()
	ball=preload("res://scripts/visuals.gd").ellipsoid(self,Color("f47b57"),Vector3.ZERO,Vector3.ONE*0.25)
func _physics_process(delta: float) -> void:
	var old:=age
	age+=delta
	if age<1.5:
		if not O.visible_between(self,origin,global_position): hide(); queue_free(); return
		var t:=minf(age/1.5,1)
		ball.global_position=origin.lerp(global_position,t)+Vector3.UP*(1+sin(t*PI)*2)
		C.progress(warning,1-t)
	if old<1.5 and age>=1.5:
		if not O.visible_between(self,origin,global_position): hide(); queue_free(); return
		warning.hide()
		ball.hide()
		active.show()
		if is_instance_valid(target) and target.global_position.distance_to(global_position)<=2.42 and O.visible_between(self,global_position,target.global_position): target.take_damage(damage)
	if age>=1.85: hide(); queue_free()
func danger_contains(point: Vector3) -> bool:
	return age<1.85 and point.distance_to(global_position)<2.5
