extends "res://scripts/weapon_flourish.gd"
var trails: Array[MeshInstance3D]=[]
var history: Array[Vector3]=[]
var fin: Node3D
var flash: MeshInstance3D
func _ready() -> void:
	if mode in ["lance","boomerang","fuse"]:
		for i in range(10):
			var rod:=materialize(V.rod(self,Color("93edff"),Vector3.ZERO,Vector3.UP,0.035*(1-i/12.0)),0.6)
			rod.set_as_top_level(true)
			rod.hide()
			trails.append(rod)
	match mode:
		"lance":
			var shape:=CylinderMesh.new()
			shape.radial_segments=5
			shape.top_radius=0
			shape.bottom_radius=0.23
			shape.height=2.1
			var tip:=V.mesh(self,shape,Color("79c9f4"),Vector3(0,0,0.55))
			tip.rotation.x=PI/2
			materialize(V.rod(self,Color.WHITE,Vector3(0,0,-0.6),Vector3(0,0,1.55),0.06,0),1)
			for side in [-1,1]: V.rod(self,Color("bddbff"),Vector3(side*0.13,0,-0.5),Vector3(side*0.3,0,-0.9),0.09,0)
		"boomerang":
			fin=V.pivot(self,"TailFin",Vector3(0,0,-0.3))
			for side in [-1,1]: V.rod(fin,Color("fff1b1"),Vector3.ZERO,Vector3(side*0.26,0,-0.4),0.015,0.12)
		"fireball":
			materialize(V.ellipsoid(self,Color("ff8c45"),Vector3.ZERO,Vector3.ONE*0.57),0.55)
			materialize(V.ellipsoid(self,Color("fff1c0"),Vector3.ZERO,Vector3.ONE*0.36),1)
			for i in range(8):
				var a:=i*TAU/8
				var start:=Vector3(cos(a)*0.3,0,sin(a)*0.3)
				pieces.append(materialize(V.rod(self,Color("ffbb65"),start,start+Vector3.UP*(0.8+i%3*0.3),0.17,0),0.5))
			for i in range(8): bands.append(materialize(V.ellipsoid(self,Color("ffda8e"),Vector3.ZERO,Vector3.ONE*0.04),0.8))
		"lightning":
			var points: Array[Vector3]=[Vector3(0,8,0),Vector3(0.4,6.8,0),Vector3(-0.35,5.6,0.1),Vector3(0.25,4.3,0),Vector3(-0.45,3.1,0),Vector3(0.3,1.7,0),Vector3.ZERO]
			for i in range(points.size()-1):
				pieces.append(materialize(V.rod(self,Color("8277ff"),points[i],points[i+1],0.14),0.42))
				pieces.append(materialize(V.rod(self,Color("f3fbff"),points[i],points[i+1],0.047),1))
				if i in [1,3,4]:
					var bend:=points[i]+Vector3(0.7 if i%2 else -0.7,-0.5,0.2)
					pieces.append(materialize(V.rod(self,Color("b9baff"),points[i],bend,0.035),0.8))
					pieces.append(materialize(V.rod(self,Color("b9baff"),bend,bend+Vector3(0.25,-0.65,0.15),0.022),0.8))
			flash=materialize(V.ellipsoid(self,Color("e6f7ff"),Vector3(0,0.12,0),Vector3(0.6,0.1,0.6)),0.6)
		"fuse":
			materialize(V.rod(self,Color("fff2ae"),Vector3(0,0.25,0),Vector3(0.2,0.55,0),0.03),1)
			flash=materialize(V.ellipsoid(self,Color("fff6d2"),Vector3(0.2,0.55,0),Vector3.ONE*0.08),1)
		"firework", "fire_impact", "lance_hit":
			flash=materialize(V.ellipsoid(self,Color("fff2d4"),Vector3(0,0.3,0),Vector3.ONE*0.3),0.65)
			for i in range(24 if mode=="firework" else 8):
				var color: Color=[Color("ffaddb"),Color("bdb2ff"),Color("8febff"),Color("ffe4a5")][i%4] if mode=="firework" else Color("a9edff") if mode=="lance_hit" else Color("ffbf80")
				pieces.append(materialize(V.rod(self,color,Vector3.ZERO,Vector3.UP,0.04,0.015),0.9))
			if mode=="lance_hit":
				var hoop:=materialize(V.ring(self,Color("9aeaff"),Vector3.ZERO,0.3,0.025,true),0.7)
				bands.append(hoop)
func animate(time: float, duration: float) -> void:
	var t:=clampf(time/duration,0,1)
	if is_instance_valid(fin): fin.rotation.y=sin(time*25)*0.4
	if mode=="fireball":
		for i in range(pieces.size()): pieces[i].scale.y=1+sin(time*28+i)*0.25
		for i in range(bands.size()): bands[i].position=Vector3(cos(i*2.4)*0.45,0.4+fposmod(time*3+i*0.21,1.3),sin(i*2.4)*0.45)
	if mode=="lightning":
		for part in pieces:
			var mat:=part.material_override as StandardMaterial3D
			mat.albedo_color.a=pow(1-t,0.6)*(1 if part.mesh.bottom_radius<0.1 else 0.42)
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		flash.scale=Vector3(0.6,0.1,0.6)*(1-t)
	if mode=="fuse": flash.scale=Vector3.ONE*(0.07+sin(time*40)*0.015)
	if mode in ["firework","fire_impact","lance_hit"]:
		flash.scale=Vector3.ONE*0.3*maxf(0,1-t*4)
		for i in range(pieces.size()):
			var a:=i*TAU/pieces.size()
			var velocity:=Vector3(cos(a),0,sin(a))*radius
			velocity.y=1.4+(i%3)*0.6
			if mode=="lance_hit": velocity=direction*2+Vector3(cos(a),sin(a),0)*0.4
			var travel:=1-exp(-5*t) if mode=="firework" else t
			var pos:=Vector3(velocity.x*travel,velocity.y*t+0.3-1.4*t*t,velocity.z*travel)
			var tangent: Vector3=(velocity-Vector3.UP*2.8*t).normalized()
			pieces[i].position=pos
			pieces[i].quaternion=Quaternion(Vector3.UP,tangent)
			pieces[i].scale=Vector3(1-t,maxf(0.02,(0.85 if mode=="firework" else 0.5)*(1-t)),1-t)
		for band in bands: band.scale=Vector3.ONE*(1+t*2)
func update_trail() -> void:
	history.push_front(global_position)
	if history.size()>11: history.pop_back()
	for i in range(trails.size()):
		if i+1>=history.size(): continue
		var a:=history[i]
		var b:=history[i+1]
		var length:=a.distance_to(b)
		trails[i].visible=length>0.001
		if length<=0.001: continue
		trails[i].global_position=(a+b)*0.5
		trails[i].global_basis=Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled(Vector3(1,length,1))
