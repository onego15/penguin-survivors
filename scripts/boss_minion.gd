extends "res://scripts/enemy.gd"
var second_phase:=false
var side:=1.0
var tail: Node3D
func _ready() -> void:
	kind=Kind.FOX
	health_multiplier=1
	damage_multiplier=1
	super._ready()
	model.free()
	model=Visuals.pivot(self,"IceSnowLeopard" if second_phase else "IceSeal")
	var fur:=Color("344c68")
	Visuals.ellipsoid(model,fur,Vector3(0,0.55,0),Vector3(0.55,0.43,0.95))
	Visuals.ellipsoid(model,Color("617f98"),Vector3(0,0.9,0.65),Vector3(0.43,0.4,0.4))
	for sign_value in [-1,1]:
		Visuals.ellipsoid(model,Color("ff4d66"),Vector3(sign_value*0.22,1.02,0.97),Vector3(0.065,0.045,0.045))
		if second_phase:
			Visuals.rod(model,fur,Vector3(sign_value*0.3,1.1,0.6),Vector3(sign_value*0.34,1.45,0.6),0.14,0)
			for z in [-0.55,0.55]: Visuals.ellipsoid(model,fur,Vector3(sign_value*0.38,0.25,z),Vector3(0.16,0.35,0.2))
		else:
			Visuals.ellipsoid(model,fur,Vector3(sign_value*0.58,0.18,0.2),Vector3(0.5,0.08,0.25)).rotation.y=sign_value*0.4
			Visuals.ellipsoid(model,fur,Vector3(sign_value*0.2,0.18,-1),Vector3(0.3,0.08,0.4))
	for i in range(4):
		var p:=Vector3(0,0.83,-0.7+i*0.32)
		Visuals.rod(model,Color("86b8d9"),p,p+Vector3(0,0.5,-0.15),0.17,0)
	tail=Visuals.pivot(model,"Tail",Vector3(0,0.6,-0.7))
	if second_phase:
		for i in range(7):
			Visuals.ellipsoid(tail,fur,Vector3(sin(i*0.3)*0.5,0.1+i*0.04,-i*0.22),Vector3.ONE*0.13)
		for i in range(10): Visuals.ellipsoid(model,Color("152b43"),Vector3((1 if i%2 else -1)*0.49,0.64,-0.6+(i/2)*0.24),Vector3(0.04,0.09,0.1))
	health=14 if second_phase else 10
	max_health=health
	speed=3.2 if second_phase else 2.2
	contact_damage=10 if second_phase else 8
	reward_value=3 if second_phase else 2
	hit_radius=0.65
	add_to_group("final_minions")
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target): return
	if control_step(delta): return
	age+=delta
	hurt_time=maxf(0,hurt_time-delta)
	var toward: Vector3=(target.global_position-global_position).normalized()
	var lateral:=Vector3(-toward.z,0,toward.x)*side
	var motion:=toward*speed
	if second_phase and global_position.distance_to(target.global_position)<7: motion=(toward*0.65+lateral*0.75).normalized()*speed
	var next:=position+motion*delta
	if absf(next.x)>23 or absf(next.z)>23: side*=-1
	_move_and_contact(delta,motion)
	model.position.y=sin(age*(12 if second_phase else 5))*0.04
	tail.rotation.y=sin(age*7)*0.45
