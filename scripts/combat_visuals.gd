extends RefCounted
## Shared faction language. These nodes never own damage or timing.
const V = preload("res://scripts/visuals.gd")
const FRIEND = Color("65e8ff")
const WARN = Color("ffe16b")
const DANGER = Color("ff573c")
static func ink(part: MeshInstance3D) -> MeshInstance3D:
	var mat := part.material_override.duplicate() as StandardMaterial3D
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	part.material_override=mat
	part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part
static func symbol(parent: Node3D, text: String, color: Color) -> Label3D:
	var label:=Label3D.new()
	label.text=text
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	label.font=font
	label.font_size=48
	label.pixel_size=0.016
	label.position.y=0.65
	label.no_depth_test=true
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=color
	label.outline_modulate=Color("302b35")
	label.outline_size=8
	parent.add_child(label)
	return label
static func friendly(parent: Node3D, radius: float) -> MeshInstance3D:
	var ring:=ink(V.ring(parent,FRIEND,Vector3(0,0.09,0),radius,0.035))
	ring.set_meta("readability_boundary",true)
	return ring
static func tail(parent: Node3D) -> Node3D:
	return ink(V.rod(parent,FRIEND,Vector3(0,0,-0.85),Vector3(0,0,-0.2),0.015,0.07))
static func warning(parent: Node3D, radius: float, length:=0.0) -> Node3D:
	var root:=V.pivot(parent,"DangerWarning",Vector3(0,0.09,0))
	root.add_to_group("ink_readable"); root.set_meta("outline",{"radius":radius,"length":length,"warning":true})
	for i in range(24):
		var a:=i*TAU/24
		if length>0:
			var z: float=-length/2.0+length*(i%12)/12.0
			var x: float=radius*(-1 if i<12 else 1)
			ink(V.rod(root,WARN,Vector3(x,0,z),Vector3(x,0,z+length/18),0.045))
		else:
			ink(V.rod(root,WARN,Vector3(cos(a),0,sin(a))*radius,Vector3(cos(a+0.15),0,sin(a+0.15))*radius,0.045))
	var countdown:=ink(V.ring(root,WARN,Vector3(0,0.03,0),radius,0.04))
	countdown.name="Countdown"
	symbol(root,"!",WARN)
	return root
static func progress(root: Node3D, fraction: float) -> void:
	root.get_node("Countdown").scale=Vector3.ONE*maxf(0.02,clampf(fraction,0,1))
static func danger(parent: Node3D, radius: float, text:="!") -> Node3D:
	var root:=V.pivot(parent,"ActiveDanger",Vector3(0,0.09,0))
	root.add_to_group("ink_readable"); root.set_meta("outline",{"radius":radius,"warning":false})
	ink(V.ring(root,DANGER,Vector3.ZERO,radius,0.09))
	for i in range(-4,5):
		var z:=i*radius/5
		var half:=sqrt(radius*radius-z*z)
		ink(V.rod(root,DANGER,Vector3(-half,0,z),Vector3(half,0,z),0.028))
	root.rotation.y=PI/4
	symbol(root,text,DANGER)
	return root
static func soil(parent: Node3D) -> Node3D:
	var root:=V.pivot(parent,"DiggingSoil")
	V.ellipsoid(root,Color("46382f"),Vector3(0,0.015,0),Vector3(0.6,0.04,0.6))
	for i in range(8):
		var d:=Vector3(cos(i*TAU/8),0,sin(i*TAU/8))
		V.ellipsoid(root,Color("aa8060"),d*0.7+Vector3.UP*0.14,Vector3(0.22,0.2,0.18))
		ink(V.rod(root,Color("73513e"),d*0.8+Vector3.UP*0.05,d*1.2+Vector3.UP*0.05,0.025))
	for i in range(5):
		var puff:=V.ellipsoid(root,Color("bd9a7b"),Vector3(cos(i*TAU/5)*0.6,0.35,sin(i*TAU/5)*0.6),Vector3(0.32,0.28,0.32))
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color(0.74,0.6,0.48,0.2)
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		puff.material_override=mat
		puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root

static func sector_warning(parent: Node3D, radius: float, half_angle: float) -> Node3D:
	var root:=V.pivot(parent,"AntlerWarning",Vector3(0,0.09,0))
	root.add_to_group("ink_readable"); root.set_meta("outline",{"radius":radius,"half":half_angle,"warning":true})
	for i in range(16):
		var a:=lerpf(-half_angle,half_angle,i/16.0)
		var b:=a+half_angle*2/16*0.6
		ink(V.rod(root,WARN,Vector3(sin(a),0,cos(a))*radius,Vector3(sin(b),0,cos(b))*radius,0.045))
	for side in [-1,1]:
		var d:=Vector3(sin(side*half_angle),0,cos(side*half_angle))
		for i in range(6): ink(V.rod(root,WARN,d*radius*i/6,d*radius*(i+0.6)/6,0.045))
	var countdown:=V.pivot(root,"Countdown")
	for i in range(20):
		var a:=lerpf(-half_angle,half_angle,i/20.0)
		var b:=lerpf(-half_angle,half_angle,(i+1)/20.0)
		ink(V.rod(countdown,WARN,Vector3(sin(a),0.03,cos(a))*radius,Vector3(sin(b),0.03,cos(b))*radius,0.035))
	var label:=symbol(root,"!",WARN)
	label.position.z=2.1
	return root
