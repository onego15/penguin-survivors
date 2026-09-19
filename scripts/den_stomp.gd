extends Node3D
## Fixed cosmetic geometry; the support's combat clock drives it.
const V=preload("res://scripts/visuals.gd")
var age:=1.0
var ring: MeshInstance3D
var upper: MeshInstance3D
var dust: Array[MeshInstance3D]=[]
func _ready() -> void:
	set_as_top_level(true)
	upper=V.ring(self,Color("b9f7ec"),Vector3.UP*0.5,1,0.065)
	ring=preload("res://scripts/combat_visuals.gd").friendly(self,1)
	for i in range(12):
		var part:=V.ellipsoid(self,Color("d6e6df"),Vector3.ZERO,Vector3(0.22,0.1,0.22))
		var mat:=part.material_override.duplicate() as StandardMaterial3D
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=0.22
		part.material_override=mat; dust.append(part)
	hide()
func start(center: Vector3) -> void:
	global_position=center; age=0; show(); tick(0)
func tick(delta: float) -> void:
	age+=delta
	if age>=0.7: hide(); return
	var t:=age/0.7
	upper.scale=Vector3.ONE*maxf(0.01,4.8*t); upper.position.y=sin(t*PI)*0.75+0.1
	ring.scale=Vector3.ONE*maxf(0.01,5*t)
	for i in range(dust.size()):
		var angle:=i*TAU/dust.size()
		dust[i].position=Vector3(cos(angle)*4*t,0.1+sin(t*PI)*0.3,sin(angle)*4*t)
		dust[i].scale=Vector3(0.22,0.1,0.22)*(1+t*2)
		dust[i].material_override.albedo_color.a=0.22*(1-t)
