extends RefCounted
const V = preload("res://scripts/visuals.gd")
const INK := Color("253442")
const WHITE := Color("f4f3e5")

static func eyes(parent: Node3D, width: float, height: float, front: float) -> void:
	for side in [-1, 1]:
		V.ellipsoid(parent, INK, Vector3(side * width, height, front), Vector3.ONE * 0.08)
		V.ellipsoid(parent, Color.WHITE, Vector3(side * width - 0.022, height + 0.027, front + 0.067), Vector3.ONE * 0.021)

static func feet(parent: Node3D, color: Color, wide := 0.3, long := 0.35) -> void:
	for side in [-1, 1]:
		for end in [-1, 1]:
			var foot := V.pivot(parent, "Paw_%d_%d" % [side, end], Vector3(side * wide, 0.2, end * long))
			V.ellipsoid(foot, color, Vector3.ZERO, Vector3(0.17, 0.2, 0.23))

static func build(parent: Node3D, kind: int) -> void:
	var colors := [Color("ad8cbb"), Color("7b9fb9"), Color("555275"), Color("b89969"), Color("a68182"), Color("ccad79")]
	var color: Color = colors[kind - 4]
	var head: Node3D
	if kind == 4: # Owl: upright body, facial discs and hinged wings.
		V.ellipsoid(parent, color, Vector3(0, 0.75, 0), Vector3(0.55, 0.65, 0.45))
		head = V.pivot(parent, "Head", Vector3(0, 1.3, 0.15))
		V.ellipsoid(head, color, Vector3.ZERO, Vector3(0.6, 0.46, 0.4))
		for side in [-1, 1]:
			V.ellipsoid(head, WHITE, Vector3(side * 0.25, 0, 0.32), Vector3(0.28, 0.3, 0.1))
			V.rod(head, color, Vector3(side * 0.42, 0.25, 0), Vector3(side * 0.55, 0.65, 0), 0.17, 0)
			var wing := V.pivot(parent, "WingLeft" if side < 0 else "WingRight", Vector3(side * 0.5, 0.85, 0))
			V.ellipsoid(wing, color.darkened(0.15), Vector3(side * 0.08, -0.18, 0), Vector3(0.2, 0.5, 0.3))
		eyes(head, 0.25, 0, 0.43)
		V.rod(head, Color("f4c976"), Vector3(0, -0.13, 0.36), Vector3(0, -0.22, 0.62), 0.12, 0)
		feet(parent, Color("d7aa65"), 0.2, 0.12)
		return
	var body_height := 0.65 if kind != 9 else 1.0
	V.ellipsoid(parent, color, Vector3(0, body_height, 0), Vector3(0.45, 0.45, 0.7))
	feet(parent, color.darkened(0.15), 0.3, 0.4)
	head = V.pivot(parent, "Head", Vector3(0, 0.95 if kind != 9 else 1.6, 0.5))
	V.ellipsoid(head, color, Vector3.ZERO, Vector3(0.4, 0.4, 0.38))
	eyes(head, 0.19, 0.08, 0.34)
	V.ellipsoid(head, WHITE if kind in [5, 6] else color.lightened(0.25), Vector3(0, -0.13, 0.34), Vector3(0.26, 0.17, 0.25))
	V.ellipsoid(head, Color("efa9b5") if kind == 8 else INK, Vector3(0, -0.08, 0.56), Vector3(0.11, 0.08, 0.07))
	if kind in [5, 6, 9]:
		for side in [-1, 1]:
			V.rod(head, color, Vector3(side * 0.25, 0.22, 0), Vector3(side * 0.4, 0.64, -0.03), 0.16, 0)
	if kind == 5:
		var tail := V.pivot(parent, "Tail", Vector3(0, 0.65, -0.6))
		V.ellipsoid(tail, color.darkened(0.15), Vector3(0, 0.12, -0.4), Vector3(0.25, 0.28, 0.62))
		V.rod(parent, WHITE, Vector3(0, 0.95, 0.2), Vector3(0, 1.1, 0.1), 0.35, 0)
	elif kind == 6:
		V.ellipsoid(parent, WHITE, Vector3(0, 0.98, -0.1), Vector3(0.12, 0.13, 0.59))
		var tail := V.pivot(parent, "Tail", Vector3(0, 0.6, -0.5))
		V.ellipsoid(tail, color, Vector3(0, 0.65, -0.3), Vector3(0.38, 0.85, 0.3))
		V.ellipsoid(tail, WHITE, Vector3(0, 0.68, -0.05), Vector3(0.12, 0.69, 0.09))
	elif kind == 7:
		for i in range(16):
			var angle := i * TAU / 16
			var start := Vector3(cos(angle) * 0.35, 0.8, sin(angle) * 0.5 - 0.15)
			V.rod(parent, Color("705454"), start, start + Vector3(cos(angle)*0.3, 0.6, sin(angle)*0.3), 0.13, 0)
	elif kind == 8:
		for side in [-1,1]:
			var hand:=V.pivot(parent,"DigHand%d" % side,Vector3(side*0.48,0.4,0.5))
			V.ellipsoid(hand,Color("e3c2ac"),Vector3.ZERO,Vector3(0.28,0.12,0.34))
			for claw in range(3):
				V.rod(hand,WHITE,Vector3((claw-1)*0.1,0,0.15),Vector3((claw-1)*0.1,0,0.48),0.04,0)
	elif kind == 9:
		for side in [-1, 1]:
			V.rod(head, Color("ffe2a0"), Vector3(side * 0.2, 0.3, 0), Vector3(side * 0.45, 1.1, -0.1), 0.06)
			for i in range(2):
				V.rod(head, Color("ffe2a0"), Vector3(side * (0.29+i*0.1),0.55+i*0.3,-0.03), Vector3(side*(0.65+i*0.1),0.8+i*0.3,0),0.045,0.01)
		for i in range(6):
			V.ellipsoid(parent, WHITE, Vector3(0.4 if i%2 else -0.4,1.12,-0.4+(i/2)*0.25),Vector3.ONE*0.06)
		var glow := StandardMaterial3D.new()
		glow.albedo_color=Color("ffe2a0")
		glow.emission_enabled=true
		glow.emission=Color("f7c56c")
		glow.emission_energy_multiplier=1.2
		for part in head.get_children():
			if part is MeshInstance3D and part.mesh is CylinderMesh:
				part.material_override=glow

static func support(parent: Node3D, kind: int) -> Node3D:
	var root := V.pivot(parent, "SupportModel")
	if kind==3:
		build_den(root)
	elif kind == 1: # Small friendly polar bear, distinct from the crowned boss.
		V.ellipsoid(root, WHITE, Vector3(0,0.65,0),Vector3(0.47,0.6,0.38))
		V.ellipsoid(root, WHITE, Vector3(0,1.25,0.08),Vector3(0.49,0.43,0.39))
		for side in [-1,1]:
			V.ellipsoid(root, WHITE, Vector3(side*0.35,1.58,0),Vector3.ONE*0.16)
			var arm:=V.pivot(root,"WaveArm" if side<0 else "OtherArm",Vector3(side*0.48,0.95,0))
			V.ellipsoid(arm,WHITE,Vector3(0,-0.25,0),Vector3(0.15,0.4,0.18))
		eyes(root,0.2,1.3,0.43)
		V.ellipsoid(root, WHITE, Vector3(0,1.12,0.43),Vector3(0.25,0.16,0.18))
		V.ellipsoid(root, INK, Vector3(0,1.17,0.57),Vector3(0.09,0.065,0.05))
		V.ring(root,Color("39c9b6"),Vector3(0,0.98,0),0.37,0.075)
		V.rod(root,Color("39c9b6"),Vector3(0.16,0.97,0.35),Vector3(0.25,0.55,0.4),0.1)
		feet(root,WHITE,0.25,0.15)
	else:
		var color := WHITE if kind == 0 else Color("ffe578")
		V.ellipsoid(root,color,Vector3(0,0.65,0),Vector3(0.48,0.47,0.4))
		eyes(root,0.2,0.77,0.38)
		V.rod(root,INK if kind==0 else Color("f5a34e"),Vector3(0,0.59,0.37),Vector3(0,0.58,0.62),0.095,0)
		for side in [-1,1]:
			var wing := V.pivot(root,"WingLeft" if side<0 else "WingRight",Vector3(side*0.43,0.65,0))
			V.ellipsoid(wing,Color("777b87") if kind==0 else color.darkened(0.1),Vector3(side*0.08,0,0),Vector3(0.23,0.12,0.3))
			V.rod(root,Color("c99565"),Vector3(side*0.18,0.3,0),Vector3(side*0.18,0.12,0.12),0.035)
		if kind==0:
			V.rod(root,Color("555566"),Vector3(0,0.6,-0.3),Vector3(0,0.8,-1.05),0.12,0.03)
		else:
			V.rod(root,Color("ffc05a"),Vector3(0,1.02,0),Vector3(0.1,1.22,0),0.08,0)
	return root

static func build_den(root: Node3D) -> void:
	var teal:=Color("285d69")
	var cream:=Color("f1e2bd")
	var belly:=V.pivot(root,"Belly")
	V.ellipsoid(belly,teal,Vector3(0,1.02,0),Vector3(0.9,1.0,0.65))
	V.ellipsoid(belly,cream,Vector3(0,0.94,0.44),Vector3(0.72,0.75,0.29))
	V.ellipsoid(root,teal,Vector3(0,1.96,0),Vector3(0.67,0.59,0.5))
	# One continuous face patch prevents a seam between the cheeks.
	V.ellipsoid(root,cream,Vector3(0,1.99,0.36),Vector3(0.59,0.32,0.19))
	for side in [-1,1]:
		V.rod(root,teal,Vector3(side*0.46,2.29,0),Vector3(side*0.6,2.7,-0.02),0.22,0.045)
		V.rod(root,INK,Vector3(side*0.24-0.12,2.07,0.55),Vector3(side*0.24+0.12,2.065,0.55),0.022)
		var arm:=V.pivot(root,"WaveArm" if side<0 else "OtherArm",Vector3(side*0.8,1.25,0))
		V.ellipsoid(arm,teal,Vector3(side*0.06,-0.23,0.04),Vector3(0.24,0.43,0.26))
		V.ellipsoid(root,cream,Vector3(side*0.52,0.18,0.4),Vector3(0.34,0.22,0.42))
		for toe in range(3): V.rod(root,WHITE,Vector3(side*0.52+(toe-1)*0.12,0.21,0.69),Vector3(side*0.52+(toe-1)*0.12,0.2,0.84),0.045,0)
	V.rod(root,INK,Vector3(-0.12,1.83,0.54),Vector3(0.12,1.83,0.54),0.017)

static func animate_den(root: Node3D, time: float, charging: float=-1.0, celebrating: bool=false) -> void:
	root.get_node("Belly").scale=Vector3(1+sin(time*1.8)*0.025,1+sin(time*1.8)*0.018,1)
	root.position.y=0
	root.scale=Vector3.ONE
	if charging>=0:
		root.scale=Vector3(1+sin(charging*PI)*0.09,1-sin(charging*PI)*0.1,1)
		root.position.y=sin(charging*PI)*0.38
	for side in ["WaveArm","OtherArm"]:
		root.get_node(side).rotation.z=(sin(time*5)*0.22 if celebrating else sin(time*2)*0.07)*(1 if side=="WaveArm" else -1)
	if celebrating: root.get_node("WaveArm").rotation.z=-1.3+sin(time*5)*0.3
