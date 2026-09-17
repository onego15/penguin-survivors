extends RefCounted
## Shared cosmetic silhouettes. No combat state or collision lives here.
const V=preload("res://scripts/visuals.gd")
static func build(parent: Node3D, id: String) -> Node3D:
	var root:=V.pivot(parent,"Motif")
	match id:
		"fan":
			V.rod(root,Color("fff4da"),Vector3(0,0,-0.4),Vector3(0,0,0.45),0.025)
			for side in [-1,1]:
				for i in range(5):
					V.rod(root,Color("ead0fa"),Vector3(0,0,-0.28+i*0.13),Vector3(side*(0.19-i*0.022),0, -0.12+i*0.13),0.04,0.01)
		"rear_fan":
			preload("res://scripts/starfall_attack.gd").star(root,0.22)
			root.rotation.x=PI/2
		"lightning":
			V.ring(root,Color("e9b652"),Vector3(0,0.38,0),0.09,0.025,true)
			V.rod(root,Color("ffe49c"),Vector3.ZERO,Vector3(0,0.3,0),0.25,0.11)
			V.ellipsoid(root,Color("9a754f"),Vector3(0,-0.03,0),Vector3.ONE*0.065)
			var points:=[Vector3(-0.07,0.27,0.2),Vector3(0.06,0.17,0.24),Vector3(-0.04,0.15,0.24),Vector3(0.06,0.04,0.25)]
			for i in range(3): V.rod(root,Color.WHITE,points[i],points[i+1],0.02)
		"nova":
			V.rod(root,Color("557d9e"),Vector3(-0.32,0.5,0),Vector3(0.32,0.5,0),0.045)
			for i in range(3):
				var tube:=V.pivot(root,"Tube%d"%i,Vector3((i-1)*0.23,0.45,0))
				V.rod(tube,Color("c1ebf5"),Vector3.ZERO,Vector3(0,-0.3-i*0.12,0),0.06)
		"mine":
			V.ellipsoid(root,Color("bd874d"),Vector3(0,0.23,0),Vector3(0.25,0.28,0.25))
			V.ellipsoid(root,Color("735641"),Vector3(0,0.43,0),Vector3(0.29,0.11,0.29))
			V.rod(root,Color("775137"),Vector3(0,0.45,0),Vector3(0.07,0.62,0),0.035)
		"ember":
			V.rod(root,Color("b78463"),Vector3(0,-0.35,0),Vector3(0,0.2,0),0.04)
			V.ellipsoid(root,Color("fff3b8"),Vector3(0,0.25,0),Vector3.ONE*0.18)
			for i in range(8):
				var d:=Vector3(cos(i*TAU/8),sin(i*TAU/8),0)
				V.rod(root,Color("ffc476"),Vector3(0,0.25,0)+d*0.22,Vector3(0,0.25,0)+d*0.32,0.045,0)
		"storm":
			V.rod(root,Color("789bbb"),Vector3(0,-0.08,0),Vector3.ZERO,0.32)
			var dome:=V.ellipsoid(root,Color("bce4f5"),Vector3(0,0.2,0),Vector3.ONE*0.3)
			var mat:=dome.material_override.duplicate() as StandardMaterial3D
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=0.2; dome.material_override=mat
			for i in range(6): V.ellipsoid(root,Color.WHITE,Vector3(cos(i*2.4)*0.16,0.09+i*0.045,sin(i*2.4)*0.16),Vector3.ONE*0.025)
		"whip":
			V.rod(root,Color("eee1c5"),Vector3(0,-0.25,0),Vector3(0,0.35,0),0.035)
			for i in range(7): V.rod(root,Color("dc8bce"),Vector3(i*0.09,0.35+sin(i*0.9)*0.14,0),Vector3((i+1)*0.09,0.35+sin((i+1)*0.9)*0.14,0),0.035)
		"trail":
			for side in [-1,1]:
				V.ellipsoid(root,Color("e89978"),Vector3(side*0.18,0.14,0),Vector3(0.12,0.16,0.25))
				V.rod(root,Color("c3edf2"),Vector3(side*0.18,-0.05,-0.25),Vector3(side*0.18,-0.05,0.27),0.025)
		"bounce":
			V.ellipsoid(root,Color("8bdde9"),Vector3.ZERO,Vector3.ONE*0.45)
			for i in range(3):
				var band:=V.ring(root,Color("e5fcff"),Vector3.ZERO,0.45,0.018,true)
				band.rotation.y=i*PI/3
		"turret":
			V.ellipsoid(root,Color("e2f5ff"),Vector3(0,-0.4,0),Vector3.ONE*0.48)
			V.ellipsoid(root,Color("f5fbff"),Vector3(0,0.2,0),Vector3.ONE*0.33)
			for side in [-1,1]:
				V.ellipsoid(root,Color("283f57"),Vector3(side*0.12,0.28,0.3),Vector3.ONE*0.035)
				V.rod(root,Color("9e775e"),Vector3(side*0.35,-0.2,0),Vector3(side*0.68,0.02,0.1),0.035)
			V.rod(root,Color("e5ae79"),Vector3(0,0.2,0.25),Vector3(0,0.2,0.49),0.07,0)
			V.rod(root,Color("567dab"),Vector3(0,0.5,0),Vector3(0,0.68,0),0.21)
			V.ring(root,Color("567dab"),Vector3(0,0.5,0),0.3,0.045)
			var cannon:=V.pivot(root,"Cannon",Vector3(0,-0.3,0.3))
			V.rod(cannon,Color("7da6bd"),Vector3.ZERO,Vector3(0,0,0.5),0.13)
			V.ring(cannon,Color.WHITE,Vector3(0,0,0.5),0.13,0.025,true)
		"seeker":
			V.ellipsoid(root,Color("ffd276"),Vector3.ZERO,Vector3(0.2,0.2,0.4))
			for i in range(3): V.ring(root,Color("4b4658"),Vector3(0,0,-0.2+i*0.18),0.18,0.025,true)
			for side in [-1,1]:
				var wing:=V.pivot(root,"Wing%d"%(side+1),Vector3(side*0.15,0.12,0))
				V.ellipsoid(wing,Color("e2faff"),Vector3(side*0.2,0,0),Vector3(0.26,0.035,0.14))
				V.rod(root,Color("4b4658"),Vector3(side*0.08,0.1,0.28),Vector3(side*0.16,0.3,0.4),0.02)
			V.rod(root,Color("b8f4ff"),Vector3(0,0,-0.35),Vector3(0,0,-0.7),0.08,0)
	return root

static func animate(root: Node3D, id: String, time: float, pulse: float=0.0) -> void:
	if id=="seeker":
		for side in [-1,1]: root.get_node("Wing%d"%(side+1)).rotation.z=side*sin(time*42)*0.5
	elif id=="nova":
		for i in range(3): root.get_node("Tube%d"%i).rotation.z=sin(time*17+i)*0.22*pulse
	elif id=="lightning": root.rotation.z=sin(time*24)*0.35*pulse
	elif id=="bounce": root.rotation=Vector3(time*3,time*2,time)
	elif id=="turret": root.get_node("Cannon").position.z=0.3-pulse*0.13
