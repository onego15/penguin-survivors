extends Node3D
const V=preload("res://scripts/visuals.gd")
func _ready() -> void:
	preload("res://scripts/beach_models.gd").arena(self)
	var camera:=Camera3D.new(); camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=26; camera.position=Vector3(0,27,25); add_child(camera); camera.look_at(Vector3.ZERO); camera.current=true
	for i in range(6):
		var point:=Vector3((i-2.5)*5,0,-7)
		var stand:=V.pivot(self,"Normal",point)
		preload("res://scripts/beach_models.gd").animal(stand,15+i).scale=Vector3.ONE*1.2
		label(preload("res://scripts/enemy.gd").NAMES[15+i],point+Vector3(0,0,2),34)
	for i in range(4):
		var boss=preload("res://scripts/beach_miniboss.gd").new(); boss.encounter=i; boss.position=Vector3((i-1.5)*7,0,1); add_child(boss); boss.set_physics_process(false); boss.health_bar.hide()
		label(boss.boss_name,boss.position+Vector3(0,0,2.5),28)
	var boss=preload("res://scripts/octo.gd").new(); boss.position=Vector3(0,0,9); add_child(boss); boss.set_physics_process(false); boss.health_bar.hide(); boss.phase_armor.show()
	label(boss.boss_name,boss.position+Vector3(0,0,3.5),32)
func label(text: String, point: Vector3, size: int) -> void:
	var node=preload("res://scripts/combat_visuals.gd").symbol(self,text,Color("244756")); node.position=point; node.font_size=size; node.outline_size=0
