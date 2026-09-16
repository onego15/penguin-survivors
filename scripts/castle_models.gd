extends RefCounted
const V=preload("res://scripts/visuals.gd")
static func animal(parent: Node3D, kind: int) -> Node3D:
	var root:=V.pivot(parent,"CastleAnimal")
	var colors: Array[Color]=[Color("76659d"),Color("8c9bab"),Color("eef5ec"),Color("c5ccde")]
	var color: Color=colors[kind-10]
	V.ellipsoid(root,color,Vector3(0,0.65,0),Vector3(0.42,0.5,0.68 if kind==12 else 0.45))
	var head:=V.pivot(root,"Head",Vector3(0,1.1,0.4))
	V.ellipsoid(head,color,Vector3.ZERO,Vector3(0.43,0.36,0.34))
	for side in [-1,1]:
		V.ellipsoid(head,Color("302e51") if kind==11 else Color("e9e8df"),Vector3(side*0.2,0,0.29),Vector3(0.18,0.16,0.08))
		V.ellipsoid(head,Color("ac354f"),Vector3(side*0.2,0.025,0.36),Vector3(0.06,0.08,0.035))
		V.rod(head,color,Vector3(side*0.3,0.2,0),Vector3(side*0.36,0.65 if kind==10 else 0.4,0),0.16,0.02)
		if kind==13:
			V.rod(head,Color("626b88"),Vector3(side*0.25,0.3,-0.1),Vector3(side*0.38,0.9,-0.4),0.13,0.035)
		if kind==10:
			var wing:=V.pivot(root,"WingLeft" if side<0 else "WingRight",Vector3(side*0.3,0.9,0))
			for i in range(3):
				V.ellipsoid(wing,color,Vector3(side*(0.3+i*0.15),0,-i*0.22),Vector3(0.5-i*0.08,0.055,0.25))
		else:
			for z in [-0.3,0.3]:
				var paw:=V.pivot(root,"Paw_%s_%s" % [side,z],Vector3(side*0.3,0.2,z))
				V.ellipsoid(paw,Color("41455d"),Vector3.ZERO,Vector3(0.14,0.2,0.2))
	V.ellipsoid(head,Color("34354b"),Vector3(0,-0.12,0.39),Vector3(0.12,0.08,0.12))
	if kind in [11,12]:
		var tail:=V.pivot(root,"Tail",Vector3(0,0.6,-0.5))
		for i in range(5): V.ellipsoid(tail,Color("434657") if i%2==0 else color,Vector3(0,0,-i*0.15),Vector3(0.18,0.18,0.15))
	if kind==11: V.ellipsoid(root,Color("afe9ff"),Vector3(0,0.8,0.65),Vector3.ONE*0.24)
	if kind==13: V.rod(head,Color("e5e9ed"),Vector3(0,-0.25,0.15),Vector3(0,-0.55,0.25),0.12,0)
	return root
static func arena(parent: Node3D) -> void:
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("111b38")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("bac9ed")
	environment.environment.ambient_light_energy=0.32
	parent.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-25,0)
	light.light_energy=0.55
	light.light_color=Color("c2caf1")
	light.shadow_enabled=true
	parent.add_child(light)
	var floor_mesh:=BoxMesh.new()
	floor_mesh.size=Vector3(51,0.5,51)
	V.mesh(parent,floor_mesh,Color("748798"),Vector3(0,-0.3,0))
	for x in range(-24,25,4):
		V.rod(parent,Color("7893ad"),Vector3(x,0,-24),Vector3(x,0,24),0.014)
		V.rod(parent,Color("7893ad"),Vector3(-24,0,x),Vector3(24,0,x),0.014)
	for side in [-1,1]:
		for index in range(9):
			for p in [Vector3(-24+index*6,0,side*26),Vector3(side*26,0,-24+index*6)]:
				V.rod(parent,Color("596786"),p,p+Vector3.UP*3.5,0.9)
				V.rod(parent,Color("b1d9eb"),p+Vector3.UP*3.5,p+Vector3.UP*4.8,0.8,0)
				V.ellipsoid(parent,Color("ffdb97"),p+Vector3.UP*2.8,Vector3.ONE*0.24)

	for side in [-1,1]:
		for point in [Vector3(0,1,side*26),Vector3(side*26,1,0)]:
			var wall:=BoxMesh.new()
			wall.size=Vector3(52,2,0.8) if point.x==0 else Vector3(0.8,2,52)
			V.mesh(parent,wall,Color("3c4669"),point)
	for x in [-8,8]:
		for z in [-16,0,16]:
			var lamp:=V.pivot(parent,"CastleLantern",Vector3(x,1.2,z))
			V.rod(lamp,Color("bb9856"),Vector3.ZERO,Vector3.UP*0.55,0.09)
			var glow:=V.ellipsoid(lamp,Color("ffe0a2"),Vector3.UP*0.7,Vector3(0.13,0.22,0.13))
			var mat:=V.material(Color("ffe0a2")).duplicate()
			mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			glow.material_override=mat
			V.ring(lamp,Color("bb9856"),Vector3.UP*0.8,0.24,0.035)
	# A distant moon and fixed stars are scenery, outside the walkable arena.
	V.ellipsoid(parent,Color("d5d8ec"),Vector3(-22,14,-37),Vector3.ONE*2)
	for i in range(30):
		var star:=V.ellipsoid(parent,Color("d0d5ff"),Vector3(-40+(i*17%80),8+(i*7%15),-38),Vector3.ONE*0.07)
		var mat:=V.material(Color("d0d5ff")).duplicate()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		star.material_override=mat
