extends Node3D
## Boss-owned moving damage volumes, never navigation obstacles.
const V=preload("res://scripts/visuals.gd")
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var boss: Node3D
var gap:=0.0
var age:=0.0
var active:=false
var finished:=false
var columns: Array[Dictionary]=[]
var warning: Node3D
var previous_player:=Vector3.ZERO
const HALF_THICKNESS=0.6
func _ready() -> void:
	set_as_top_level(true); global_position=Vector3.ZERO
	previous_player=boss.target.global_position
	warning=V.pivot(self,"WallPaths")
func segments() -> Array[Vector2]: return [Vector2(-16,gap-2),Vector2(gap+2,16)]
func plan() -> bool:
	var p: Vector3=boss.target.global_position
	var x:= -8.0 if p.x<0 else 8.0
	var direction:=signf(p.x-x)
	if direction==0: direction=-signf(x)
	columns=[{"x":x,"direction":direction,"hit":false}]
	if boss.enraged: columns=[{"x":-8.0,"direction":1.0,"hit":false},{"x":8.0,"direction":-1.0,"hit":false}]
	var rng: RandomNumberGenerator=boss.get_parent().get_parent().rng
	for attempt in range(16):
		gap=clampf(p.z+(-1 if rng.randf()<0.5 else 1)*rng.randf_range(3,6),-14,14)
		if can_escape(p):
			build(); return true
	return false
func can_escape(p: Vector3) -> bool:
	var world=O.world(boss)
	for x in [p.x,p.x-2,p.x+2,-6.0,0.0,6.0,-10.0,10.0]:
		for z in [gap,gap-1,gap+1,-17.0,17.0,p.z]:
			var q:=Vector3(x,0,z)
			if not world.clear(q,0.5) or sweep_contains(q): continue
			var route: PackedVector2Array=world.path(p,q,0.5)
			var length:=0.0
			if not route.is_empty(): length=Vector2(p.x,p.z).distance_to(route[0])+route[-1].distance_to(Vector2(q.x,q.z))
			for i in range(1,route.size()): length+=route[i].distance_to(route[i-1])
			if not route.is_empty() and length<=boss.target.SPEED*2.4: return true
	return false
func sweep_contains(p: Vector3) -> bool:
	if p.z<-16.42 or p.z>16.42 or absf(p.z-gap)<1.58: return false
	for col in columns:
		if p.x>=minf(col.x,col.direction*24)-1.02 and p.x<=maxf(col.x,col.direction*24)+1.02: return true
	return false
func build() -> void:
	for col in columns:
		var mesh_root:=V.pivot(self,"MovingIceWall"); col["node"]=mesh_root; mesh_root.position.x=col.x
		for span in segments():
			if span.y-span.x<0.01: continue
			var shape:=BoxMesh.new(); shape.size=Vector3(0.5,0.75,span.y-span.x)
			V.mesh(mesh_root,shape,Color("779eae"),Vector3(0,0.45,(span.x+span.y)/2))
			for z in range(ceili(span.x),floori(span.y)+1):
				C.ink(V.rod(mesh_root,Color("ff684c"),Vector3(col.direction*0.1,0.4,z),Vector3(col.direction*0.6,0.35,z),0.13,0))
			for edge in [-0.6,0.6]: C.ink(V.rod(mesh_root,C.DANGER,Vector3(edge,0.06,span.x),Vector3(edge,0.06,span.y),0.045))
			for z in [span.x,span.y]:
				for n in range(16):
					var a:=lerpf(col.x,col.direction*24,n/16.0)
					C.ink(V.rod(warning,C.WARN,Vector3(a,0.1,z),Vector3(a+col.direction*0.7,0.1,z),0.035))
		mesh_root.hide()
	for x in [-5.0,0.0,5.0]:
		for side in [-1,1]: C.ink(V.rod(warning,Color.WHITE,Vector3(x-side*0.5,0.12,gap-0.5),Vector3(x,0.12,gap),0.055))
func start() -> void:
	active=true; warning.hide(); previous_player=boss.target.global_position
	for col in columns: col.node.show()
	get_tree().call_group("game_audio","play_effect","noctis_cast")
func tick(delta: float) -> void:
	if not active or finished: return
	age+=delta
	var p: Vector3=boss.target.global_position
	var all_done:=true
	for col in columns:
		if absf(col.x)>=24: continue
		var old: float=col.x
		col.x=clampf(old+col.direction*(3.5 if boss.enraged else 3.0)*delta,-24,24)
		col.node.position.x=col.x
		if not col.hit and touches(previous_player,p,old,col.x):
			col.hit=true
			boss.target.take_damage(28 if boss.enraged else 24,preload("res://scripts/difficulty_tiers.gd").source(self))
		col.node.visible=absf(col.x)<24
		all_done=all_done and absf(col.x)>=24
	previous_player=p
	if all_done: finished=true; hide()
func touches(a: Vector3,b: Vector3,old_x: float,new_x: float) -> bool:
	# Relative-motion segment vs expanded rectangles, including both actors' movement.
	var from:=Vector2(a.x-old_x,a.z); var to:=Vector2(b.x-new_x,b.z)
	for span in segments():
		if span.y-span.x<0.01: continue
		var lo:=Vector2(-1.02,span.x-0.42); var hi:=Vector2(1.02,span.y+0.42)
		var enter:=0.0; var leave:=1.0; var valid:=true
		for axis in range(2):
			var d: float=to[axis]-from[axis]
			if absf(d)<0.000001:
				if from[axis]<lo[axis] or from[axis]>hi[axis]: valid=false
			else:
				var t1: float=(lo[axis]-from[axis])/d; var t2: float=(hi[axis]-from[axis])/d
				enter=maxf(enter,minf(t1,t2)); leave=minf(leave,maxf(t1,t2))
		if valid and enter<=leave: return true
	return false
