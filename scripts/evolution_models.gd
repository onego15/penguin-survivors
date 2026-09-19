extends RefCounted
const V=preload("res://scripts/visuals.gd")
const M=preload("res://scripts/character_models.gd")
static func build(parent: Node3D, id: String) -> Node3D:
	var root:=V.pivot(parent,"EvolutionModel")
	match id:
		"pop_cannon","triple_cannon":
			var gun:=M.blaster(root); gun.scale=Vector3.ONE*0.6
			for i in range(3 if id=="triple_cannon" else 1):
				V.rod(root,Color("c2f8ff"),Vector3((i-1)*0.16 if id=="triple_cannon" else 0,0.12,0.05),Vector3((i-1)*0.22 if id=="triple_cannon" else 0,0.12,0.8),0.08,0.04)
			var flash:=V.pivot(root,"MuzzleFlash",Vector3(0,0.12,0.85))
			for i in range(3 if id=="triple_cannon" else 1):
				preload("res://scripts/combat_visuals.gd").ink(V.ring(flash,Color("dcfaff"),Vector3((i-1)*0.22 if id=="triple_cannon" else 0,0,0),0.13,0.035,true))
			flash.hide()
			V.ring(root,Color("fff2b8"),Vector3(0,0.12,0.32),0.28,0.03,true)
		"big_heart","heart_ring":
			M.heart_wand(root)
			if id=="big_heart": root.scale=Vector3.ONE*1.3
			else:
				for i in range(6):
					var h:=M.heart(root); h.scale=Vector3.ONE*0.25; h.position=Vector3(cos(i*TAU/6)*0.4,0.7,sin(i*TAU/6)*0.4)
		"rainbow_heart":
			var crystal=preload("res://scripts/evolution_visuals.gd").heart(root)
			crystal.position.y=0.4
			for i in range(6):
				var shard=preload("res://scripts/prism_visual.gd").build_crystal(root)
				shard.position=Vector3(cos(i*TAU/6)*0.6,0.4+sin(i*TAU/6)*0.6,0); shard.scale=Vector3.ONE*0.3
		"blizzard_fan":
			preload("res://scripts/control_attack.gd").build_model(root,"gust")
			for side in [-1,1]:
				var ice:=preload("res://scripts/control_attack.gd").build_model(root,"popsicle")
				ice.position=Vector3(side*0.36,0.15,0); ice.scale=Vector3.ONE*0.5
		"pearl_chime":
			for i in range(3):
				V.rod(root,Color("d2ecff"),Vector3((i-1)*0.22,0.5,0),Vector3((i-1)*0.22,-0.2-i*0.09,0),0.06)
				V.ellipsoid(root,Color("fff4da"),Vector3((i-1)*0.22,0.55,0),Vector3.ONE*0.13)
		"thunder_dome":
			preload("res://scripts/weapon_models.gd").build(root,"storm")
			for i in range(3):
				V.ellipsoid(root,Color("939ecb"),Vector3((i-1)*0.18,0.45,0),Vector3(0.22,0.16,0.18))
			V.rod(root,Color("f1eeff"),Vector3(0.1,0.4,0.2),Vector3(-0.08,0.05,0.2),0.045)
	return root

static func animate(root: Node3D,id: String,time: float,pulse: float) -> void:
	if root.has_node("MuzzleFlash"):
		root.get_node("MuzzleFlash").visible=pulse>0.3
		root.get_node("MuzzleFlash").scale=Vector3.ONE*(0.6+pulse)
	root.position.z=-pulse*0.12 if id in ["pop_cannon","triple_cannon"] else 0.0
	if id=="pearl_chime": root.rotation.z=sin(time*8)*0.08
	if id=="rainbow_heart": root.rotation.y=sin(time)*0.2; root.scale=Vector3.ONE*(1+pulse*0.15)
