extends RefCounted
## Display-only equipment shared by combat and results.
const V=preload("res://scripts/visuals.gd")
const Catalog=preload("res://scripts/weapon_catalog.gd")
const E=preload("res://scripts/evolution_catalog.gd")
const Motifs=preload("res://scripts/weapon_models.gd")
static func build(mount: Node3D, id: String) -> void:
	if id in ["shell_wave","bubble","crab_claw"]:
		preload("res://scripts/beach_models.gd").weapon(mount,id)
		return
	if id=="frost":
		preload("res://scripts/character_models.gd").blaster(mount)
		return
	var tint: Color = Catalog.data(id).color
	if E.ITEMS.has(id):
		preload("res://scripts/evolution_models.gd").build(mount,id)
		return
	if id in ["spear","boomerang"]: V.rod(mount, Color("947044"), Vector3(0, -0.25, 0), Vector3(0, 0.15, 0), 0.04)
	match id:
		"ember","lightning","nova","mine","storm","whip","trail","bounce","turret","seeker","fan":
			var motif:=Motifs.build(mount,id)
			if id=="turret": motif.scale=Vector3.ONE*0.48
			if id=="fan": motif.rotation.x=PI/2
		"starfall": preload("res://scripts/starfall_attack.gd").star(mount,0.3)
		"gust", "popsicle": preload("res://scripts/control_attack.gd").build_model(mount,id)
		"udon": preload("res://scripts/udon_attack.gd").bowl(mount)
		"heart": preload("res://scripts/character_models.gd").heart_wand(mount)
		"beam": preload("res://scripts/prism_visual.gd").build_crystal(mount)
		"rear_fan":
			V.rod(mount,Color("b695d7"),Vector3(0,0,-0.15),Vector3(0,0,0.35),0.06,0.2)
			var seal:=Motifs.build(mount,"rear_fan")
			seal.scale=Vector3.ONE*0.45; seal.position=Vector3(0,0.13,0.15)
		"rear_bomb":
			V.ellipsoid(mount,Color("bc8fd7"),Vector3.ZERO,Vector3.ONE*0.23)
			V.rod(mount,Color("ffe4bd"),Vector3(0,0.2,0),Vector3(0.1,0.43,0),0.025)
		"orbit":
			for i in range(3): V.ellipsoid(mount,Color("c5ddf8"),Vector3((i-1)*0.17,0,0),Vector3.ONE*0.085)
		"spear": V.rod(mount, tint, Vector3(0, 0.1, 0), Vector3(0, 0.65, 0), 0.14, 0)
		"boomerang":
			V.ellipsoid(mount, tint, Vector3(0, 0.2, 0), Vector3(0.3, 0.12, 0.1))
			V.rod(mount, tint, Vector3(-0.25, 0.2, 0), Vector3(-0.45, 0.2, 0), 0.02, 0.13)
