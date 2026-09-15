extends "res://scripts/weapon_flourish.gd"
## Visual only: immediate starburst, rising crown, spiralling snow, lingering sparks.
const DURATION:=2.2
var crown: Node3D
var rays: Array[Node3D]=[]
var snow: Array[Node3D]=[]
var winds: Array[MeshInstance3D]=[]
func _ready() -> void:
	auto_lifetime=DURATION
	radius=12
	crown=V.pivot(self,"EmperorCrown",Vector3(0,2.4,0))
	for i in range(8):
		var a:=i*TAU/8
		var p:=Vector3(cos(a),0,sin(a))*0.75
		materialize(V.rod(crown,Color("fff2c0"),p,p+Vector3.UP*(0.65 if i%2==0 else 0.35),0.12,0),0.85)
	materialize(V.ring(crown,Color("fff2c0"),Vector3.ZERO,0.75,0.035),0.8)
	for i in range(3): bands.append(materialize(V.ring(self,Color("cffaff"),Vector3(0,0.12+i*0.14,0),1,0.004),0.75))
	for i in range(18):
		var ray:=V.pivot(self,"BurstRay")
		materialize(V.rod(ray,Color("e4fbff"),Vector3.ZERO,Vector3(0,0,1.3),0.065,0),0.7)
		rays.append(ray)
	for i in range(36):
		var star:=V.pivot(self,"BlizzardStar")
		for arm in range(3):
			var d:=Vector3(cos(arm*PI/3),sin(arm*PI/3),0)*0.3
			materialize(V.rod(star,Color("fff0b2") if i%3==0 else Color("d9faff"),-d,d,0.025),0.8)
		snow.append(star)
	for i in range(6):
		var wind:=ribbon(Color("71c9f5") if i%2 else Color("e7faff"),1,0.055,0,PI*0.65,0)
		winds.append(wind)
	animate(0,DURATION)
func fade(part: MeshInstance3D, alpha: float) -> void:
	part.material_override.albedo_color.a=clampf(alpha,0,1)
func animate(time: float, _lifetime: float) -> void:
	var fade_out:=clampf((DURATION-time)/0.8,0,1)
	crown.position.y=2.4+minf(time,1)*0.6
	crown.rotation.y=time*1.4
	crown.scale=Vector3.ONE*maxf(0.001,minf(time/0.08,1)*fade_out)
	for i in range(bands.size()):
		var f:=clampf((time-i*0.12)/0.65,0,1)
		bands[i].scale=Vector3.ONE*maxf(0.01,radius*(1-pow(1-f,3)))
		fade(bands[i],(1-f)*0.7)
	for i in range(rays.size()):
		var a:=i*TAU/rays.size()
		var f:=clampf(time/0.65,0,1)
		rays[i].position=Vector3(sin(a),0,cos(a))*radius*f+Vector3.UP*(0.45+sin(f*PI)*0.8)
		rays[i].rotation.y=a
		rays[i].scale=Vector3(1,1,2)*maxf(0.001,1-f)
	for i in range(winds.size()):
		var f:=clampf((time-i*0.06)/1.5,0,1)
		winds[i].scale=Vector3(1,1,1)*maxf(0.01,(2+8*f))
		winds[i].position.y=0.3+f*1.8
		winds[i].rotation.y=i*TAU/6+time*1.8
		fade(winds[i],0.38*sin(f*PI)*fade_out)
	for i in range(snow.size()):
		var a:=i*2.4+time*(0.5+i%3*0.2)
		var r:=minf(12,time*11)*(0.35+0.65*(i%7)/6.0)
		snow[i].position=Vector3(cos(a)*r,0.5+sin(minf(time/2,1)*PI)*(0.7+i%5*0.45),sin(a)*r)
		snow[i].rotation=Vector3(time,a,time*2)
		snow[i].scale=Vector3.ONE*fade_out*(0.7+0.3*sin(time*8+i))
