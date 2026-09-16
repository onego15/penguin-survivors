extends "res://scripts/weapon_flourish.gd"
const Models=preload("res://scripts/character_models.gd")
var player: Node3D
var healed:=0
var bloom: Node3D
var hearts: Array[Node3D]=[]
var petals: Array[Node3D]=[]
var heal_label: Label3D
func _ready() -> void:
	auto_lifetime=2.2
	bloom=Models.heart(self)
	for i in range(3): bands.append(materialize(V.ring(self,Color("a4efff"),Vector3(0,0.12+i*0.08,0),1,0.003),0.65))
	for i in range(24):
		var heart:=Models.heart(self)
		heart.scale=Vector3.ONE*0.5
		for part in heart.get_children():
			if part is GeometryInstance3D: part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hearts.append(heart)
	for i in range(32):
		petals.append(materialize(V.ellipsoid(self,Color("fff0c0") if i%3==0 else Color("fbb3d4"),Vector3.ZERO,Vector3(0.11,0.035,0.24)),0.7))
	if healed>0:
		heal_label=Label3D.new()
		heal_label.text="HP +%d" % healed
		heal_label.font_size=48
		heal_label.pixel_size=0.009
		heal_label.modulate=Color("afffd4")
		heal_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		heal_label.no_depth_test=true
		add_child(heal_label)
	animate(0,2.2)
func animate(time: float, _duration: float) -> void:
	var fade:=clampf((2.2-time)/0.7,0,1)
	var travel:=1-pow(1-clampf(time/1.2,0,1),3)
	if is_instance_valid(player):
		bloom.global_position=player.weapon.global_position+Vector3.UP*0.8
		if is_instance_valid(heal_label): heal_label.global_position=player.global_position+Vector3.UP*(3.4+time*0.35)
	bloom.scale=Vector3.ONE*maxf(0.001,minf(time/0.12,1)*1.8*fade)
	bloom.rotation.y=sin(time*3)*0.25
	if is_instance_valid(heal_label): heal_label.modulate.a=fade
	for i in range(bands.size()):
		var f:=clampf((time-i*0.12)/0.8,0,1)
		bands[i].scale=Vector3.ONE*maxf(0.01,radius*f)
		bands[i].material_override.albedo_color.a=0.6*(1-f)
	for i in range(hearts.size()):
		var a:=i*TAU/hearts.size()+time*0.2
		hearts[i].position=Vector3(cos(a),0,sin(a))*radius*travel*(0.6+0.4*(i%2))+Vector3.UP*(0.6+sin(time*1.3+i)*0.3)
		hearts[i].rotation=Vector3(0,sin(a+time)*0.4,sin(time*3+i)*0.3)
		hearts[i].scale=Vector3.ONE*0.65*fade
	for i in range(petals.size()):
		var a:=i*2.4+time*0.6
		petals[i].position=Vector3(cos(a)*radius*travel*(0.3+i%5*0.15),0.5+sin(time/2.2*PI)*(0.8+i%4*0.5),sin(a)*radius*travel*(0.3+i%5*0.15))
		petals[i].rotation=Vector3(time*3+i,a,time*2)
		petals[i].scale=Vector3(0.11,0.035,0.24)*fade
