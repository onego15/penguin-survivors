extends RefCounted
const V=preload("res://scripts/visuals.gd")
const S=preload("res://scripts/beach_sculpt.gd")
static var creature_cache: Dictionary={}
static func eyes(root: Node3D, height: float, depth: float, width:=0.24, style:="crab") -> void:
	var face:=V.pivot(root,"FaceEyes")
	for side in [-1,1]:
		var p:=Vector3(side*width,height,depth)
		match style:
			"crab", "hermit":
				# Small stalk beads versus shy vertical button eyes; no shared white rim.
				var size:=Vector3(0.105,0.125,0.095) if style=="crab" else Vector3(0.055,0.115,0.065)
				V.ellipsoid(face,Color("172b35"),p,size)
				V.ellipsoid(face,Color("effaf2"),p+Vector3(-0.025,0.04,0.08),Vector3.ONE*0.025)
			"jelly", "shelley":
				# Relaxed closed crescents, clearly different from open eyeballs.
				S.tube(face,[p+Vector3(-0.11,0.035,0.08),p+Vector3(0,-0.035,0.11),p+Vector3(0.11,0.035,0.08)],[0.032,0.037,0.025],Color("443554"))
			"fish", "clapper", "octo":
				var size:=Vector3(0.17,0.095,0.10) if style!="octo" else Vector3(0.23,0.115,0.10)
				V.ellipsoid(face,Color("ffe6a8"),p,size)
				V.ellipsoid(face,Color("223144"),p+Vector3(-side*0.025,0,0.09),Vector3(0.045,0.075,0.04))
				V.rod(face,Color("3f3656"),p+Vector3(-side*size.x,0.01,0.1),p+Vector3(side*size.x,0.12,0.1),0.04)
			"squid", "sumire":
				V.ellipsoid(face,Color("f4e8da"),p,Vector3(0.105,0.20,0.10))
				V.ellipsoid(face,Color("44314e"),p+Vector3(0,0,0.10),Vector3(0.028,0.135,0.035))
				if style=="sumire":
					V.ellipsoid(face,Color("8a679f"),p+Vector3(0,0.16,0.015),Vector3(0.12,0.10,0.11))
			"puffer":
				V.ellipsoid(face,Color("fff8df"),p,Vector3(0.18,0.19,0.14))
				V.ellipsoid(face,Color("45392c"),p+Vector3(side*0.035,0.01,0.135),Vector3.ONE*0.045)
			"lumina":
				S.tube(face,[p+Vector3(-0.12,0.06,0.07),p+Vector3(0,0.0,0.13),p+Vector3(0.12,0.09,0.07)],[0.04,0.045,0.025],Color("e6ffff"))
				V.ellipsoid(face,Color("425881"),p-Vector3(0,0.025,0),Vector3(0.16,0.085,0.07))
static func smile(root: Node3D, height: float, depth: float) -> void:
	S.tube(root,[Vector3(-0.12,height+0.04,depth),Vector3(0,height,depth+0.02),Vector3(0.12,height+0.04,depth)],[0.022,0.025,0.022],Color("68495e"))
static func own_parts(node: Node, root: Node) -> void:
	for child in node.get_children(): child.owner=root; own_parts(child,root)
static func animal(parent: Node3D, kind: int) -> Node3D:
	if creature_cache.has(kind):
		var cached: Node3D=creature_cache[kind].instantiate(); parent.add_child(cached); return cached
	var root:=V.pivot(parent,"BeachCreature")
	match kind:
		15:
			V.ellipsoid(root,Color("843e45"),Vector3(0,0.51,0),Vector3(0.72,0.20,0.5))
			V.ellipsoid(root,Color("d56858"),Vector3(0,0.7,-0.05),Vector3(0.73,0.35,0.52))
			V.ellipsoid(root,Color("f29c73"),Vector3(0,0.89,-0.06),Vector3(0.52,0.16,0.36))
			for side in [-1,1]:
				V.rod(root,Color("bd554b"),Vector3(side*0.23,0.8,0.3),Vector3(side*0.26,1.05,0.4),0.09)
				for i in range(3):
					var foot:=V.pivot(root,"FinCrabLeg",Vector3(side*0.5,0.53,(i-1)*0.29))
					S.tube(foot,[Vector3.ZERO,Vector3(side*0.3,0.12,-0.05),Vector3(side*0.52,-0.38,0.10)],[0.085,0.07,0.015],Color("c05d53"))
				claw(root,Vector3(side*0.84,0.69,0.48),side)
				for i in range(3): V.ellipsoid(root,Color("f5c894"),Vector3(side*(0.18+i*0.14),0.96-i*0.06,-0.1),Vector3(0.045,0.022,0.065))
			eyes(root,1.04,0.45); smile(root,0.64,0.52)
		16:
			V.ellipsoid(root,Color("a96b4d"),Vector3(0,0.42,0.3),Vector3(0.46,0.27,0.43))
			V.ellipsoid(root,Color("edb67f"),Vector3(0,0.70,0.46),Vector3(0.42,0.33,0.32))
			V.ellipsoid(root,Color("87634c"),Vector3(0,0.91,-0.17),Vector3(0.69,0.72,0.62))
			var points: Array[Vector3]=[]; var radii: Array[float]=[]
			for i in range(37):
				var t:=i/36.0; var a:=t*TAU*2.4; var r:=0.65*(1-t)+0.055
				points.append(Vector3(cos(a)*r,1.05+sin(a)*r,0.17+t*0.25)); radii.append(0.13-0.07*t)
			S.tube(root,points,radii,Color("eac398"))
			for side in [-1,1]:
				for i in range(2): S.tube(root,[Vector3(side*0.3,0.4,i*0.24),Vector3(side*0.6,0.32,i*0.24),Vector3(side*0.68,0.08,0.25+i*0.24)],[0.07,0.055,0.025],Color("c28c62"))
				var hand:=claw(root,Vector3(side*0.55,0.47,0.63),side); hand.scale=Vector3.ONE*0.5
				S.tube(root,[Vector3(side*0.24,0.83,0.65),Vector3(side*0.37,1.1,0.64),Vector3(side*0.46,1.15,0.72)],[0.027,0.02,0.01],Color("ab754e"))
			eyes(root,0.86,0.73,0.19,"hermit"); smile(root,0.59,0.77)
		17:
			V.ellipsoid(root,Color("7155a0"),Vector3(0,0.9,0),Vector3(0.66,0.28,0.57))
			V.ellipsoid(root,Color("b49ae0"),Vector3(0,1.16,0),Vector3(0.76,0.53,0.65))
			V.ellipsoid(root,Color("dfc4f1"),Vector3(-0.16,1.48,0.14),Vector3(0.37,0.16,0.28))
			for i in range(8):
				var a:=i*TAU/8
				V.ellipsoid(root,Color("d1b4ef"),Vector3(cos(a)*0.6,0.94,sin(a)*0.51),Vector3(0.22,0.14,0.19))
				var tentacle:=V.pivot(root,"Tentacle",Vector3(cos(a)*0.45,0.83,sin(a)*0.37))
				S.tube(tentacle,[Vector3.ZERO,Vector3(0.1,-0.22,0),Vector3(-0.08,-0.47,0.08),Vector3(0.06,-0.67,0.14)],[0.055,0.045,0.035,0.018],Color("9bc7d9"))
			eyes(root,1.19,0.68,0.24,"jelly"); smile(root,0.95,0.6)
		18:
			V.ellipsoid(root,Color("317f9d"),Vector3(0,0.85,0),Vector3(0.39,0.44,0.84))
			V.ellipsoid(root,Color("acd9da"),Vector3(0,0.65,0.12),Vector3(0.35,0.22,0.65))
			for side in [-1,1]:
				var fin:=V.pivot(root,"Fin",Vector3(side*0.29,0.8,-0.05))
				S.fin(fin,[Vector3.ZERO,Vector3(side*1.02,0.15,0.25),Vector3(side*1.1,-0.04,-0.34),Vector3(side*0.38,0,-0.68)],Color("63b8c9"))
				for i in range(3): V.ellipsoid(root,Color("82cdd9"),Vector3(side*0.345,0.89,-0.26+i*0.22),Vector3(0.035,0.1,0.08))
			S.fin(root,[Vector3(0,1.0,-0.35),Vector3(0,1.5,-0.45),Vector3(0,1.1,-0.7)],Color("5da9c0"))
			var tail:=V.pivot(root,"FinTail",Vector3(0,0.84,-0.7))
			S.fin(tail,[Vector3.ZERO,Vector3(-0.4,0.12,-0.47),Vector3(0,0,-0.29),Vector3(0.4,0.12,-0.47)],Color("559bad"))
			eyes(root,1.04,0.61,0.25,"fish"); V.ring(root,Color("d7eddf"),Vector3(0,0.81,0.80),0.075,0.025,true)
		19:
			V.ellipsoid(root,Color("8263a7"),Vector3(0,0.92,0),Vector3(0.46,0.52,0.42))
			S.tube(root,[Vector3(0,0.9,0),Vector3(0,1.35,-0.04),Vector3(0,1.66,-0.08),Vector3(0,1.88,-0.12)],[0.46,0.39,0.23,0.015],Color("a486bf"))
			for side in [-1,1]:
				var fin:=V.pivot(root,"FinMantle")
				S.fin(fin,[Vector3(side*0.2,1.2,0),Vector3(side*0.72,1.08,-0.13),Vector3(side*0.2,1.72,-0.08)],Color("c4a8d9"))
			for i in range(6):
				var x: float=(i-2.5)*0.16
				var arm:=V.pivot(root,"Tentacle",Vector3(x,0.65,0.1))
				S.tube(arm,[Vector3.ZERO,Vector3(x*0.25,-0.28,0.12),Vector3(x*0.55,-0.45,0.36),Vector3(x*0.6,-0.3,0.5)],[0.09,0.075,0.05,0.018],Color("ccacdb"))
			eyes(root,1.05,0.38,0.23,"squid"); V.ellipsoid(root,Color("54465f"),Vector3(0,0.79,0.45),Vector3(0.09,0.09,0.08))
		20:
			V.ellipsoid(root,Color("c79d52"),Vector3(0,0.88,0),Vector3(0.68,0.65,0.63))
			V.ellipsoid(root,Color("f3d9a0"),Vector3(0,0.65,0.2),Vector3(0.59,0.40,0.5))
			for i in range(24):
				var a:=i*2.399963; var y:=0.1+0.8*(i%6)/5.0; var radial:=sqrt(1-y*y)
				var normal:=Vector3(cos(a)*radial,y,sin(a)*radial)
				var p:=Vector3(0,0.88,0)+normal*0.58
				V.rod(root,Color("fff0ba"),p,p+normal*0.23,0.055,0)
			for side in [-1,1]:
				var fin:=V.pivot(root,"Fin",Vector3(side*0.55,0.72,0))
				S.fin(fin,[Vector3.ZERO,Vector3(side*0.4,0.13,0.13),Vector3(side*0.3,0,-0.3)],Color("dbb36e"))
				for i in range(3): V.ellipsoid(root,Color("977a49"),Vector3(side*0.53,1.0+i*0.09,0.17-i*0.14),Vector3(0.055,0.045,0.055))
			eyes(root,1.03,0.52,0.32,"puffer"); V.ring(root,Color("d0a765"),Vector3(0,0.79,0.7),0.1,0.045,true)
	S.bake(root)
	own_parts(root,root)
	var packed:=PackedScene.new(); packed.pack(root); creature_cache[kind]=packed
	return root
static func claw(parent: Node3D, point: Vector3, side: float=1) -> Node3D:
	var root:=V.pivot(parent,"Claw",point)
	V.ellipsoid(root,Color("aa4b49"),Vector3(0,-0.04,-0.12),Vector3(0.2,0.18,0.23))
	V.ellipsoid(root,Color("e97c64"),Vector3.ZERO,Vector3(0.31,0.24,0.32))
	for sign_value in [-1,1]:
		var jaw:=V.pivot(root,"JawLeft" if sign_value<0 else "JawRight",Vector3(0,0,0.15))
		S.tube(jaw,[Vector3(sign_value*0.18,0,0),Vector3(sign_value*0.24,0.02,0.23),Vector3(sign_value*0.17,0.02,0.44),Vector3(sign_value*0.065,0,0.51)],[0.13,0.11,0.065,0.015],Color("f6b787"))
	V.ellipsoid(root,Color("ffd7a4"),Vector3(-0.07,0.2,0),Vector3(0.14,0.035,0.18))
	root.rotation.z=side*0.15
	S.bake(root)
	return root
static func octopus(parent: Node3D) -> Node3D:
	var root:=V.pivot(parent,"Octo")
	V.ellipsoid(root,Color("70437d"),Vector3(0,1.25,-0.08),Vector3(0.86,0.94,0.79))
	V.ellipsoid(root,Color("a775af"),Vector3(0,1.65,-0.09),Vector3(0.82,0.65,0.75))
	V.ellipsoid(root,Color("d5a9cb"),Vector3(0,0.98,0.57),Vector3(0.57,0.5,0.3))
	eyes(root,1.53,0.70,0.34,"octo")
	for side in [-1,1]:
		S.tube(root,[Vector3(side*0.13,1.8,0.76),Vector3(side*0.32,1.88,0.75),Vector3(side*0.55,1.82,0.64)],[0.085,0.09,0.035],Color("573a70"))
		V.ellipsoid(root,Color("cb8eba"),Vector3(side*0.48,1.13,0.70),Vector3(0.14,0.1,0.06))
		for i in range(3): V.ellipsoid(root,Color("cea1d0"),Vector3(side*(0.63-i*0.07),1.6+i*0.15,0.45),Vector3(0.07,0.06,0.045))
	V.ring(root,Color("79486e"),Vector3(0,1.12,0.88),0.13,0.06,true)
	for i in range(8):
		var a:=i*TAU/8
		var arm:=V.pivot(root,"Arm",Vector3(cos(a)*0.43,0.43,sin(a)*0.43)); arm.rotation.y=-a
		var points: Array[Vector3]=[Vector3.ZERO,Vector3(0.35,-0.08,0),Vector3(0.72,-0.18,0.10),Vector3(1.06,-0.13,0.24),Vector3(1.2,0.13,0.28),Vector3(1.12,0.33,0.22),Vector3(0.99,0.35,0.14)]
		S.tube(arm,points,[0.26,0.24,0.19,0.14,0.10,0.065,0.025],Color("9d64a0"))
		for j in range(1,5):
			var p: Vector3=points[j]+Vector3(0,0.12,0)
			V.ring(arm,Color("edb7cb"),p,0.09-j*0.009,0.025)
	V.ring(root,Color("c89b61"),Vector3(0,2.13,-0.03),0.59,0.10)
	for i in range(7):
		var a:=i*TAU/7; var p:=Vector3(sin(a)*0.57,2.15,cos(a)*0.57)
		S.tube(root,[p,p+Vector3(sin(a)*0.12,0.22,cos(a)*0.12),p+Vector3(sin(a)*0.08,0.47,cos(a)*0.08)],[0.095,0.08,0.01],Color("e8c688"))
		V.ellipsoid(root,Color("79d6d6"),p+Vector3.UP*0.05,Vector3(0.065,0.11,0.065))
	S.bake(root)
	return root
static func arena(parent: Node3D) -> void:
	var environment:=WorldEnvironment.new(); environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR; environment.environment.background_color=Color("94d5e4")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e7edee"); environment.environment.ambient_light_energy=0.55; parent.add_child(environment)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-60,-30,0); sun.light_energy=0.8; parent.add_child(sun)
	var sea:=BoxMesh.new(); sea.size=Vector3(100,0.2,100); V.mesh(parent,sea,Color("4babc4"),Vector3(0,-0.4,0))
	var sand:=BoxMesh.new(); sand.size=Vector3(48,0.2,48); V.mesh(parent,sand,Color("d5d4bb"),Vector3(0,-0.17,0))
	for i in range(100):
		var x:=sin(i*17.13)*22; var z:=cos(i*11.27)*22
		var patch:=BoxMesh.new(); patch.size=Vector3(0.10+(i%4)*0.04,0.003,0.045)
		V.mesh(parent,patch,Color("c4c6af"),Vector3(x,-0.064,z))
	for i in range(24):
		var a:=i*TAU/24
		var p:=Vector3(cos(a),0,sin(a))*23.2
		V.ellipsoid(parent,Color("e2c5b2"),p,Vector3(0.4,0.12,0.25))
	for i in range(32):
		var a:=i*TAU/32
		var p:=Vector3(cos(a),0,sin(a))*33
		var coral:=V.pivot(parent,"Coral",p)
		for j in range(3): V.rod(coral,Color("db9bb8") if i%2==0 else Color("95c9c5"),Vector3((j-1)*0.35,0,0),Vector3((j-1)*0.8,1.0+j*0.4,0),0.16,0.08)
static func weapon(parent: Node3D, id: String) -> void:
	if id=="shell_wave":
		# Flared conch with a visible dark opening and tapered spiral body.
		V.ellipsoid(parent,Color("dda787"),Vector3(0,0,-0.05),Vector3(0.25,0.25,0.38))
		for i in range(5): V.ring(parent,Color("f6d6b1"),Vector3(0,0,0.23-i*0.14),0.27-i*0.043,0.055,true)
		V.ellipsoid(parent,Color("865b66"),Vector3(0,0,0.265),Vector3(0.23,0.23,0.028))
		V.ring(parent,Color("fff1d3"),Vector3(0,0,0.29),0.26,0.06,true)
		for i in range(5):
			var a:=i*TAU/5
			V.rod(parent,Color("f4c5a5"),Vector3(cos(a)*0.18,sin(a)*0.18,-0.04),Vector3(cos(a)*0.33,sin(a)*0.33,-0.10),0.055,0.008)
	elif id=="bubble":
		V.rod(parent,Color("edb8da"),Vector3(0,-0.4,0),Vector3(0,0.02,0),0.075)
		for i in range(3): V.ring(parent,Color("fff2db"),Vector3(0,-0.31+i*0.10,0),0.075,0.018)
		V.ring(parent,Color("72b7d7"),Vector3(0,0.22,0),0.25,0.055,true)
		V.ring(parent,Color("f4d5ed"),Vector3(0,0.22,0.015),0.19,0.025,true)
		V.ellipsoid(parent,Color("f8ffff"),Vector3(-0.13,0.4,0.045),Vector3(0.08,0.035,0.025))
	else: claw(parent,Vector3.ZERO).scale=Vector3.ONE*0.65
