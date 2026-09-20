extends "res://scripts/beach_enemy.gd"
const ROSTER=[
 {"kind":15,"name":"大ハサミのクラッパー","speed":2.0},
 {"kind":16,"name":"帆貝のシェリー","speed":1.6},
 {"kind":19,"name":"墨筆のスミーレ","speed":2.0},
 {"kind":17,"name":"電冠のルミナ","speed":1.2},
]
var encounter:=0
var boss_name:=""
func _ready() -> void:
	is_miniboss=true; kind=ROSTER[encounter].kind; boss_name=ROSTER[encounter].name; speed=ROSTER[encounter].speed; visual_scale=1.8
	super._ready()
	add_to_group("minibosses"); health=100+encounter*80; max_health=health; hit_radius=1.25; contact_damage=18+encounter*2; reward_value=8
	model.get_node("FaceEyes").free()
	var faces=[[1.04,0.45,0.24,"clapper"],[0.86,0.73,0.19,"shelley"],[1.05,0.38,0.23,"sumire"],[1.15,0.58,0.24,"lumina"]]
	var face=faces[encounter]
	preload("res://scripts/beach_models.gd").eyes(model,face[0],face[1],face[2],face[3])
	var V=Visuals
	var S=preload("res://scripts/beach_sculpt.gd")
	if kind==15:
		for child in model.get_children():
			if str(child.name).begins_with("Claw"): child.scale=Vector3.ONE*(1.7 if child.position.x<0 else 1.3)
		for side in [-1,1]:
			S.tube(model,[Vector3(side*0.12,1.0,0),Vector3(side*0.48,1.12,0),Vector3(side*0.68,1.37,-0.06)],[0.13,0.10,0.015],Color("f2c68c"))
			V.ellipsoid(model,Color("934749"),Vector3(side*0.53,0.76,-0.10),Vector3(0.32,0.18,0.38))
	elif kind==16:
		V.rod(model,Color("805641"),Vector3(0,1,-0.4),Vector3(0,2.6,-0.4),0.055)
		S.fin(model,[Vector3(-0.6,1.55,-0.4),Vector3(-0.48,2.36,-0.42),Vector3(0,2.48,-0.62),Vector3(0.55,2.2,-0.45),Vector3(0.62,1.5,-0.4)],Color("ecd4aa"))
		S.tube(model,[Vector3(-0.50,1.62,-0.37),Vector3(0,1.75,-0.57),Vector3(0.53,1.59,-0.37)],[0.045,0.045,0.045],Color("a06564"))
		V.ring(model,Color("b78655"),Vector3(0.45,1.26,0.35),0.21,0.05,true)
	elif kind==19:
		S.tube(model,[Vector3(0.52,0.5,0.2),Vector3(0.80,0.9,0.3),Vector3(0.85,1.5,0.25)],[0.095,0.07,0.055],Color("baac83"))
		V.ring(model,Color("e0c394"),Vector3(0.85,1.5,0.25),0.09,0.035)
		S.tube(model,[Vector3(0.85,1.48,0.25),Vector3(0.86,1.74,0.25),Vector3(0.99,1.94,0.23)],[0.13,0.12,0.01],Color("40304e"))
		for side in [-1,1]:
			S.tube(model,[Vector3(side*0.15,1.68,0.13),Vector3(side*0.25,1.42,0.3),Vector3(side*0.23,1.26,0.34)],[0.04,0.06,0.015],Color("654c82"))
		V.ellipsoid(model,Color("48365e"),Vector3(-0.6,0.55,0.2),Vector3(0.21,0.27,0.18))
	elif kind==17:
		for i in range(5):
			var a:=i*TAU/5; var p:=Vector3(sin(a)*0.48,1.4,cos(a)*0.4)
			S.tube(model,[p,p+Vector3.UP*0.32,p+Vector3.UP*0.6],[0.095,0.11,0.005],Color("8dcada"))
			V.ellipsoid(model,Color("e8d7a1"),p,Vector3.ONE*0.10)
		for side in [-1,1]:
			S.tube(model,[Vector3(side*0.5,0.7,0),Vector3(side*0.9,0.95,0),Vector3(side*1.05,0.65,0.1)],[0.075,0.065,0.045],Color("9aa8d3"))
			V.ring(model,Color("e5c5b3"),Vector3(side*1.05,0.67,0.1),0.17,0.04)
	S.bake(model)
func status_label() -> String: return " / 予告を避け、異常は泉で解除"
