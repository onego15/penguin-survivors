extends Node3D
## Cosmetic geometry only. Animation is driven by the owning attack's combat clock.
const V=preload("res://scripts/visuals.gd")
var mode:="storm"
var radius:=2.6
var direction:=Vector3.BACK
var pieces: Array[Node3D]=[]
var bands: Array[Node3D]=[]
var shell: MeshInstance3D
var auto_lifetime:=0.0
var age:=0.0
func materialize(part: MeshInstance3D, alpha: float) -> MeshInstance3D:
	var mat:=part.material_override.duplicate() as StandardMaterial3D
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.albedo_color.a=alpha
	if alpha<1: mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	part.material_override=mat
	part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part
func ribbon(color: Color, r: float, width: float, start: float, end: float, height: float) -> MeshInstance3D:
	var vertices:=PackedVector3Array()
	for i in range(40):
		var a:=lerpf(start,end,i/40.0)
		var b:=lerpf(start,end,(i+1)/40.0)
		var p:=Vector3(sin(a)*r,height+sin(a*2)*0.13,cos(a)*r)
		var q:=Vector3(sin(b)*r,height+sin(b*2)*0.13,cos(b)*r)
		vertices.append_array(PackedVector3Array([p,q,q+Vector3.UP*width,p,q+Vector3.UP*width,p+Vector3.UP*width]))
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return materialize(V.mesh(self,mesh,color),0.55)
func _ready() -> void:
	if mode=="storm":
		var hemisphere:=SphereMesh.new()
		hemisphere.radius=radius
		hemisphere.height=radius*2
		hemisphere.is_hemisphere=true
		shell=materialize(V.mesh(self,hemisphere,Color("b7e9ff")),0.055)
		shell.scale.y=0.65
		for i in range(3): bands.append(ribbon(Color("b4eaff"),radius*(0.6+i*0.12),0.045,0,TAU,0.25+i*0.4))
		for i in range(18):
			var star:=V.pivot(self,"SnowStar")
			for arm in range(3):
				var d:=Vector3(cos(arm*PI/3),sin(arm*PI/3),0)*0.1
				materialize(V.rod(star,Color("e7fbff"),-d,d,0.018),0.8)
			pieces.append(star)
	elif mode=="whip":
		rotation.y=atan2(direction.x,direction.z)
		for i in range(4): bands.append(ribbon([Color("bb66ef"),Color("ff70bc"),Color("75e9ff"),Color.WHITE][i],3.45+i*0.08,0.63 if i<3 else 0.095,-PI/3,PI/3,-0.12+i*0.1))
	elif mode=="trail":
		for i in range(5):
			var flame:=V.pivot(self,"Flame")
			flame.position=Vector3(cos(i*2.4),0,sin(i*2.4))*0.7
			for layer in range(2):
				var vertices:=PackedVector3Array([Vector3(-0.18,0,0),Vector3(0.18,0,0),Vector3(0.12,0.65,0),Vector3(-0.18,0,0),Vector3(0.12,0.65,0),Vector3(-0.08,1.1,0)])
				var arrays:=[]
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX]=vertices
				var mesh:=ArrayMesh.new()
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var face:=materialize(V.mesh(flame,mesh,Color("f6a46f") if layer==0 else Color("fff3d6")),0.42)
				face.rotation.y=i*1.8+layer*PI/2
				face.scale=Vector3.ONE*(1.0 if layer==0 else 0.6)
			pieces.append(flame)
		for i in range(8): bands.append(materialize(V.ellipsoid(self,Color("ffe9ce"),Vector3.ZERO,Vector3.ONE*0.035),0.8))
	else:
		for i in range(2): bands.append(materialize(V.ring(self,Color("a4efff"),Vector3(0,0.15+i*0.14,0),1,0.025),0.55))
		for i in range(20): pieces.append(materialize(V.rod(self,Color("ffdae9") if mode=="firework" else Color("d9faff"),Vector3.ZERO,Vector3(0,0,0.35),0.04,0),0.85))
func animate(time: float, lifetime: float) -> void:
	var fraction:=clampf(time/lifetime,0,1)
	if mode=="storm":
		scale=Vector3.ONE*minf(1,minf(time/0.25,(lifetime-time)/0.35))
		for i in range(bands.size()): bands[i].rotation.y=time*(0.8+i*0.3)
		for i in range(pieces.size()):
			var a:=time*1.6+i*2.4
			pieces[i].position=Vector3(cos(a)*radius*0.7,0.25+fposmod(i*0.37+time*0.5,1.3),sin(a)*radius*0.7)
			pieces[i].rotation.z=time+i
	elif mode=="whip":
		for i in range(bands.size()):
			bands[i].rotation.y=lerpf(-0.15,0.15,fraction)
			bands[i].scale.y=maxf(0.05,sin(fraction*PI))
	elif mode=="trail":
		for i in range(pieces.size()):
			pieces[i].scale.y=(1-fraction*0.85)*(1+0.2*sin(time*17+i))*(1+0.5*exp(-time*8))
			pieces[i].rotation.z=sin(time*9+i)*0.15
		for i in range(bands.size()):
			bands[i].position=Vector3(sin(i*2.4)*0.8,fposmod(time+i*0.2,1.3),cos(i*2.4)*0.8)
			bands[i].scale=Vector3.ONE*0.035*(1-fraction)
	else:
		for i in range(bands.size()): bands[i].scale=Vector3.ONE*maxf(0.01,radius*maxf(0,fraction-i*0.15))
		for i in range(pieces.size()):
			var a:=i*TAU/pieces.size()
			pieces[i].position=Vector3(sin(a)*radius*fraction,0.2+sin(fraction*PI)*(0.3+(i%3)*0.2),cos(a)*radius*fraction)
			pieces[i].rotation.y=a
			pieces[i].scale=Vector3.ONE*(1-fraction)
func _physics_process(delta: float) -> void:
	if auto_lifetime<=0: return
	age+=delta
	animate(age,auto_lifetime)
	if age>=auto_lifetime: queue_free()
