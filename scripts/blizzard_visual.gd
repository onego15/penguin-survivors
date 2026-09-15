extends "res://scripts/weapon_flourish.gd"
## Fixed cosmetic geometry; never deals damage.
var ultimate := false
var mist: Array[MeshInstance3D] = []
func _ready() -> void:
	for i in range(2): bands.append(materialize(V.ring(self,Color("a4efff"),Vector3(0,0.1+i*0.09,0),1,0.003 if ultimate else 0.006),0.65))
	for i in range(12): mist.append(materialize(V.ellipsoid(self,Color("c7eeff"),Vector3.ZERO,Vector3.ONE),0.12))
	for i in range(16):
		var part:=V.pivot(self,"SnowCrystal")
		for arm in range(3):
			var d:=Vector3(cos(arm*PI/3),sin(arm*PI/3),0)*0.15
			materialize(V.rod(part,Color("fff0bf") if ultimate else Color("d5faff"),-d,d,0.023),0.8)
		pieces.append(part)
	animate(0,0.9)
func animate(time: float, _lifetime: float) -> void:
	var f:=clampf(time/0.9,0,1)
	var r:=radius*minf(time/0.65,1)
	for i in range(bands.size()): bands[i].scale=Vector3.ONE*maxf(0.01,r*(1-i*0.12))
	for i in range(mist.size()):
		var a:=i*TAU/12+time*0.25
		mist[i].position=Vector3(cos(a)*r,0.15+f*1.5,sin(a)*r)
		mist[i].scale=Vector3(0.4+f*0.5,0.2+f*0.65,0.4+f*0.5)
		mist[i].material_override.albedo_color.a=0.12*(1-f)
	for i in range(pieces.size()):
		var a:=i*TAU/16+time*0.7
		pieces[i].position=Vector3(cos(a)*r,0.2+f*(1.2+(i%3)*0.2),sin(a)*r)
		pieces[i].rotation=Vector3(time*2,a,time*3)
		pieces[i].scale=Vector3.ONE*(1-f)
