extends Node3D
## Cosmetic, bounded geometry driven exclusively by the owning attack's clock.
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const COLORS=[Color("ff91c9"),Color("bc9bff"),Color("76dbff"),Color("99efc7"),Color("fff1b6"),Color("ffb5cf")]
var attack: Node3D
var parts: Array[Node3D]=[]
var beads: Array[Node3D]=[]
var halos: Array[Node3D]=[]
var shards: Array[Node3D]=[]
var crown: Node3D
var finish: Node3D
static func heart(parent: Node3D, color: Color=Color("edacd9")) -> Node3D:
	var root:=V.pivot(parent,"FacetedHeart")
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for i in range(32):
		var t:=TAU*i/32
		points.append(Vector3(16*pow(sin(t),3),13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t),0)*0.035)
	for i in range(32):
		var a:=points[i]; var b:=points[(i+1)%32]
		for side in [-1,1]:
			st.set_color(color.lightened((i%4)*0.09))
			for p in ([Vector3(0,0,side*0.23),a,b] if side==1 else [Vector3(0,0,side*0.23),b,a]): st.add_vertex(p)
	st.generate_normals()
	var part:=V.mesh(root,st.commit(),color)
	part.material_override=part.material_override.duplicate(); part.material_override.vertex_color_use_as_albedo=true; part.material_override.albedo_color=Color.WHITE
	part.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED; part.material_override.metallic=0.3; part.material_override.roughness=0.2
	return root
static func line(part: Node3D,a: Vector3,b: Vector3,width: float) -> void:
	var d:=b-a
	part.position=(a+b)/2; part.scale=Vector3(width,maxf(0.001,d.length()),width)
	if d.length()>0.001: part.quaternion=Quaternion(Vector3.UP,d.normalized())
func rod(color: Color) -> Node3D:
	return C.ink(V.rod(self,color,Vector3.ZERO,Vector3.UP,1))
func _ready() -> void:
	match attack.mode:
		"rainbow_heart":
			for color in [Color(0.64,0.45,1,0.18),Color(0.8,0.95,1,0.25)]:
				var halo:=rod(color); halo.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; halos.append(halo)
			for i in range(7): parts.append(rod(Color.WHITE if i==6 else COLORS[i]))
			for i in range(24): parts.append(rod(COLORS[i%6]))
			for i in range(8):
				var h:=heart(self,COLORS[i%6]); h.scale=Vector3.ONE*0.2; beads.append(h)
			crown=V.pivot(self,"CrystalCorolla")
			for i in range(6):
				var h:=heart(crown,COLORS[i]); h.position=Vector3(cos(i*TAU/6),sin(i*TAU/6),0)*0.42; h.scale=Vector3.ONE*0.35; h.rotation.z=-i*TAU/6
			finish=heart_outline(self); finish.hide()
			for i in range(10):
				var crystal:=PrismMesh.new(); crystal.size=Vector3(0.08,0.22,0.08)
				shards.append(V.mesh(self,crystal,COLORS[i%6]))
		"blizzard_fan":
			for i in range(12): parts.append(rod(Color("cef8ff")))
			for i in range(12):
				var ice:=PrismMesh.new(); ice.size=Vector3(0.12,0.3,0.1); beads.append(V.mesh(self,ice,Color("f4fbff")))
		"pearl_chime":
			for i in range(8):
				var mist:=V.ellipsoid(self,Color("d3f2ff"),Vector3.ZERO,Vector3.ONE)
				mist.material_override=mist.material_override.duplicate(); mist.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mist.material_override.albedo_color.a=0.13
				parts.append(mist)
		"thunder_dome":
			for i in range(12): parts.append(rod(Color.WHITE if i%2 else Color("b7a0ff")))
			finish=C.friendly(self,1)
func tick() -> void:
	var t: float=attack.age; var pulse: float=attack.flash_left
	match attack.mode:
		"rainbow_heart":
			var d: Vector3=attack.direction; var side:=Vector3(-d.z,0,d.x); var length: float=attack.beam_length
			var radius: float=attack.stats.width/2
			for i in range(halos.size()): line(halos[i],Vector3.ZERO,d*length,radius*(0.95-i*0.3))
			for i in range(7):
				var offset:=side*((i-2.5)*radius/3.5 if i<6 else 0.0)
				line(parts[i],offset,d*length+offset,0.025 if i<6 else 0.055+pulse*0.04)
			for i in range(24):
				var u:=float(i)/24; var v:=float(i+1)/24
				var a:=d*length*u+(side*cos(u*TAU*3-t*9)+Vector3.UP*sin(u*TAU*3-t*9))*radius*0.75
				var b:=d*length*v+(side*cos(v*TAU*3-t*9)+Vector3.UP*sin(v*TAU*3-t*9))*radius*0.75
				line(parts[i+7],a,b,0.012+pulse*0.012)
			for i in range(beads.size()):
				beads[i].position=d*fposmod(t*12+i*length/8,maxf(0.01,length)); beads[i].rotation.y=atan2(d.x,d.z)
			crown.rotation.y=atan2(d.x,d.z); crown.scale=Vector3.ONE*(0.9+pulse)
			for i in range(shards.size()):
				shards[i].visible=attack.pulse_count>=5
				var spread:=maxf(0,t-1.2)*2
				shards[i].position=d*maxf(0,length-0.4)+(side*cos(i*TAU/10)+Vector3.UP*sin(i*TAU/10))*spread
				shards[i].rotation=Vector3(t*3,i,t*4)
			finish.visible=attack.pulse_count>=5
			finish.position=d*maxf(0,length-0.4); finish.scale=Vector3.ONE*(0.95+(t-1.2)*2.2); finish.rotation.y=atan2(d.x,d.z)
		"blizzard_fan":
			global_position=attack.player.global_position
			var d: Vector3=attack.core.direction; var u:=clampf(1-pulse/0.45,0,1)
			for i in range(12):
				parts[i].visible=pulse>0; beads[i].visible=pulse>0
				var aim:=d.rotated(Vector3.UP,deg_to_rad(-30+i*60.0/11)); var end:=global_position+aim*float(attack.stats.reach)*u
				var o=preload("res://scripts/castle_obstacles.gd").world(self)
				if o!=null: end=o.sweep(global_position,end,0.02).point
				var local:=end-global_position+Vector3.UP*(0.2+i%3*0.25)
				line(parts[i],local-aim*0.5,local,0.035*(1-u)+0.01); beads[i].position=local; beads[i].rotation=Vector3(t*3,i,t*2)
		"pearl_chime":
			var u:=clampf(1-pulse/0.55,0,1)
			for i in range(8):
				parts[i].visible=i<int(attack.stats.count) and pulse>0 and attack.core.clear_at(attack.player.global_position,attack.core.at(attack.player.global_position,t,i))
				parts[i].global_position=attack.core.at(attack.player.global_position,t,i)+Vector3.UP*(0.2+u*0.9)
				parts[i].scale=Vector3(0.7,0.15+u*0.7,0.7)*float(attack.stats.pulse_radius)
		"thunder_dome":
			var p: Vector3=attack.cloud_points[clampi(attack.pulse_count-1,0,5)]
			for i in range(12):
				parts[i].visible=pulse>0
				var a:=p+Vector3(sin(i*3.2)*0.2,2.7-i%6*0.43,0)
				var b:=a+Vector3(0.4 if i>=6 else -sin(i*3.2)*0.25,-0.42,0.16 if i>=6 else 0)
				line(parts[i],a,b,0.035 if i<6 else 0.015)
			finish.visible=pulse>0; finish.position=p+Vector3.UP*0.1; finish.scale=Vector3.ONE*float(attack.stats.pulse_radius)*(1-pulse/0.3)

static func heart_outline(parent: Node3D) -> Node3D:
	var root:=V.pivot(parent,"FinalHeartWave")
	var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(32):
		var a:=TAU*i/32; var b:=TAU*(i+1)/32
		var p:=Vector3(16*pow(sin(a),3),13*cos(a)-5*cos(2*a)-2*cos(3*a)-cos(4*a),0)*0.045
		var q:=Vector3(16*pow(sin(b),3),13*cos(b)-5*cos(2*b)-2*cos(3*b)-cos(4*b),0)*0.045
		for point in [p,q,q*0.9,p,q*0.9,p*0.9]: st.add_vertex(point)
	st.generate_normals()
	var mesh:=C.ink(V.mesh(root,st.commit(),Color("fff2d9")))
	mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	return root
