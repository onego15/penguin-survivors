extends Node3D
const C=preload("res://scripts/combat_visuals.gd")
var target: Node3D
var radius:=2.5
var length:=0.0
var half_angle:=PI
var direction:=Vector3.BACK
var damage:=8
var effect:=""
var delay:=1.2
var total:=1.2
var active_left:=0.0
var fired:=false
var warning: Node3D
var danger: Node3D
func _ready() -> void:
	add_to_group("beach_hazards")
	total=delay
	rotation.y=atan2(direction.x,direction.z)
	warning=C.sector_warning(self,radius,half_angle) if half_angle<PI else C.warning(self,radius,length)
	danger=Node3D.new(); add_child(danger); danger.position.y=0.09
	danger.add_to_group("ink_readable"); danger.set_meta("outline",{"radius":radius,"length":length,"half":half_angle,"warning":false})
	var V=preload("res://scripts/visuals.gd")
	if length>0:
		var corners=[Vector3(-radius,0,-length/2),Vector3(radius,0,-length/2),Vector3(radius,0,length/2),Vector3(-radius,0,length/2)]
		for i in range(4): C.ink(V.rod(danger,C.DANGER,corners[i],corners[(i+1)%4],0.065))
		for i in range(12):
			var z: float=-length/2+(i+0.5)*length/12
			C.ink(V.rod(danger,C.DANGER,Vector3(-radius,0,z),Vector3(radius,0,z),0.025))
			V.ellipsoid(danger,Color("a16bb4"),Vector3(0,0.17,z),Vector3(radius*0.6,0.25,length/20))
	else:
		for i in range(32):
			var a:=lerpf(-half_angle,half_angle,i/32.0); var b:=lerpf(-half_angle,half_angle,(i+1)/32.0)
			C.ink(V.rod(danger,C.DANGER,Vector3(sin(a),0,cos(a))*radius,Vector3(sin(b),0,cos(b))*radius,0.065))
		for i in range(12):
			var a:=lerpf(-half_angle,half_angle,(i+0.5)/12.0)
			C.ink(V.rod(danger,C.DANGER,Vector3.ZERO,Vector3(sin(a),0,cos(a))*radius,0.025))
		if half_angle<PI:
			for sign_value in [-1,1]: C.ink(V.rod(danger,C.DANGER,Vector3.ZERO,Vector3(sin(sign_value*half_angle),0,cos(sign_value*half_angle))*radius,0.065))
	C.symbol(danger,"!",C.DANGER)
	danger.hide()
func contains(point: Vector3, margin:=0.42) -> bool:
	var p:=to_local(point); p.y=0
	if length>0: return absf(p.x)<=radius+margin and absf(p.z)<=length/2+margin
	return p.length()<=radius+margin and (half_angle>=PI or p.length()<margin or absf(atan2(p.x,p.z))<=half_angle)
func _physics_process(delta: float) -> void:
	if fired:
		active_left-=delta
		if active_left<=0: queue_free()
		return
	delay=maxf(0,delay-delta); C.progress(warning,delay/maxf(total,0.01))
	if delay>0: return
	fired=true; active_left=0.45; warning.hide(); danger.show()
	get_tree().call_group("game_audio","play_effect","sea_hit")
	if is_instance_valid(target) and contains(target.global_position) and preload("res://scripts/castle_obstacles.gd").visible_between(self,global_position,target.global_position):
		if target.take_damage(damage,preload("res://scripts/difficulty_tiers.gd").source(self)) and target.health>0 and effect!="": target.statuses.apply(effect)
func danger_contains(point: Vector3) -> bool: return contains(point,0.7)
