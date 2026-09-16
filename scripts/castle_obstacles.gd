extends Node3D
const V=preload("res://scripts/visuals.gd")
var game: Node3D
var walls: Array[Rect2]=[]
var gates: Array[Dictionary]=[]
var revision:=0
var grids: Dictionary={}
var clock:=0.0
var next_cycle:=60.0
var diagonal:=0
var suspended:=false
static func world(node: Node) -> Node:
	return node.get_tree().get_first_node_in_group("castle_obstacles") if node.is_inside_tree() else null
static func visible_between(node: Node, a: Vector3, b: Vector3) -> bool:
	var obstacle=world(node)
	return obstacle==null or obstacle.sweep(a,b,0).t>=1
static func placement(node: Node, point: Vector3, radius: float=0.5) -> bool:
	var obstacle=world(node)
	return obstacle==null or obstacle.clear(point,radius)
func box(rect: Rect2, color: Color) -> MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=Vector3(rect.size.x,1.2,rect.size.y)
	return V.mesh(self,mesh,color,Vector3(rect.get_center().x,0.6,rect.get_center().y))
func _ready() -> void:
	add_to_group("castle_obstacles")
	for x in [-8.0,8.0]:
		for span in [Vector2(-16,5),Vector2(-5,10),Vector2(11,5)]:
			var rect:=Rect2(x-0.5,span.x,1,span.y)
			walls.append(rect)
			box(rect,Color("6889ab"))
			for j in range(int(span.y/2)):
				var cap:=BoxMesh.new()
				cap.size=Vector3(1.12,0.2,1.0)
				V.mesh(self,cap,Color("b0cfe3"),Vector3(x,1.25,span.x+1+j*2))
		for z in [-8.0,8.0]:
			var rect:=Rect2(x-0.5,z-3,1,6)
			var mesh:=box(rect,Color("a0dcea"))
			mesh.hide()
			var label:=Label3D.new()
			label.position=Vector3(x,2,z)
			label.text="鍵 OPEN"
			label.font_size=38
			label.pixel_size=0.014
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)
			for dz in [-3.2,3.2]:
				V.rod(self,Color("9bcee4"),Vector3(x,0,z+dz),Vector3(x,2.3,z+dz),0.25)
			V.ring(self,Color("e5faff"),Vector3(x,2.8,z),0.18,0.045,true)
			V.rod(self,Color("e5faff"),Vector3(x,2.65,z),Vector3(x,2.25,z),0.04)
			gates.append({"rect":rect,"mesh":mesh,"label":label,"state":"open","left":0.0,"wait":0.0,"duration":8.0})
func rectangles(ignore_gates: bool=false) -> Array[Rect2]:
	var result: Array[Rect2]=walls.duplicate()
	for gate in gates:
		if gate.state=="closed" and not ignore_gates: result.append(gate.rect)
	return result
func clear(point: Vector3, radius: float=0.5, ignore_gates: bool=false) -> bool:
	if absf(point.x)>23-radius or absf(point.z)>23-radius: return false
	for rect in rectangles(ignore_gates):
		if rect.grow(radius).has_point(Vector2(point.x,point.z)): return false
	return true
func sweep(a: Vector3, b: Vector3, radius: float=0.0, ignore_gates: bool=false) -> Dictionary:
	var best:=1.0
	var normal:=Vector3.ZERO
	var start:=Vector2(a.x,a.z)
	var movement:=Vector2(b.x-a.x,b.z-a.z)
	for raw in rectangles(ignore_gates):
		var rect:=raw.grow(radius)
		var enter:=0.0
		var leave:=1.0
		var n:=Vector3.ZERO
		var valid:=true
		for axis in range(2):
			if absf(movement[axis])<0.000001:
				if start[axis]<rect.position[axis] or start[axis]>rect.end[axis]: valid=false
				continue
			var lo: float=(rect.position[axis]-start[axis])/movement[axis]
			var hi: float=(rect.end[axis]-start[axis])/movement[axis]
			var sign_normal: float=-signf(movement[axis])
			if lo>hi:
				var tmp:=lo
				lo=hi
				hi=tmp
			if lo>enter:
				enter=lo
				n=Vector3(sign_normal,0,0) if axis==0 else Vector3(0,0,sign_normal)
			leave=minf(leave,hi)
		if valid and enter<=leave and leave>=0 and enter<best:
			best=maxf(0,enter)
			normal=n
	return {"t":best,"point":b if best>=1 else a.lerp(b,maxf(0,best-0.001)),"normal":normal}
func move_actor(actor: Node3D, finish: Vector3, radius: float, slide: bool=true) -> Vector3:
	var start:=actor.global_position
	var phasing: bool=actor.get_meta("gate_phasing",false)
	var hit:=sweep(start,finish,radius,phasing)
	actor.set_meta("wall_blocked",hit.t<1)
	if hit.t>=1: return finish
	var point: Vector3=hit.point
	if slide:
		var remaining:=finish-point
		remaining-=hit.normal*remaining.dot(hit.normal)
		point=sweep(point,point+remaining,radius,phasing).point
	return point
func grid(radius: float, ignore_gates: bool=false) -> AStarGrid2D:
	var size:=1.7 if radius>1 else 0.95
	var key:=Vector2(size,1 if ignore_gates else 0)
	if grids.has(key): return grids[key]
	var nav:=AStarGrid2D.new()
	nav.region=Rect2i(-23,-23,47,47)
	nav.cell_size=Vector2.ONE
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for x in range(-23,24):
		for z in range(-23,24): nav.set_point_solid(Vector2i(x,z),not clear(Vector3(x,0,z),size,ignore_gates))
	grids[key]=nav
	return nav
func cell(point: Vector3, nav: AStarGrid2D) -> Vector2i:
	var origin:=Vector2i(roundi(point.x),roundi(point.z))
	var best:=Vector2i(999,999)
	var distance:=INF
	for x in range(origin.x-3,origin.x+4):
		for z in range(origin.y-3,origin.y+4):
			var p:=Vector2i(x,z)
			if not nav.region.has_point(p) or nav.is_point_solid(p): continue
			var d:=Vector2(x,z).distance_squared_to(Vector2(point.x,point.z))
			if d<distance: best=p; distance=d
	return best
func path(a: Vector3, b: Vector3, radius: float, ignore_gates: bool=false) -> PackedVector2Array:
	var nav:=grid(radius,ignore_gates)
	var start:=cell(a,nav)
	var finish:=cell(b,nav)
	if start.x==999 or finish.x==999: return PackedVector2Array()
	return nav.get_point_path(start,finish)
func steer(actor: Node3D, goal: Vector3, radius: float) -> Vector3:
	var phasing: bool=actor.get_meta("gate_phasing",false)
	if sweep(actor.global_position,goal,radius,phasing).t>=1: return (goal-actor.global_position).normalized()
	var cache: Dictionary=actor.get_meta("castle_route",{})
	var now:=Engine.get_physics_frames()
	if cache.is_empty() or cache.rev!=revision or now>=cache.until:
		cache={"rev":revision,"until":now+24+actor.get_instance_id()%17,"index":0,"path":path(actor.global_position,goal,radius,phasing)}
		actor.set_meta("castle_route",cache)
	var route: PackedVector2Array=cache.path
	while cache.index<route.size():
		var p: Vector2=route[cache.index]
		var point:=Vector3(p.x,actor.global_position.y,p.y)
		if point.distance_to(actor.global_position)>0.65: return (point-actor.global_position).normalized()
		cache.index+=1
	return Vector3.ZERO
func reachable(a: Vector3,b: Vector3,radius: float=0.5) -> bool:
	return clear(b,radius) and not path(a,b,radius).is_empty()
func occupied(rect: Rect2) -> bool:
	for actor in [game.player]+get_tree().get_nodes_in_group("all_enemies"):
		if not is_instance_valid(actor) or actor.is_queued_for_deletion() or actor.get_meta("gate_phasing",false): continue
		var r: float=0.5 if actor==game.player else actor.hit_radius
		if rect.grow(r+0.1).has_point(Vector2(actor.position.x,actor.position.z)): return true
	return false
func open_all() -> void:
	var changed:=false
	for gate in gates:
		changed=changed or gate.state!="open"
		gate.state="open"
		gate.mesh.hide()
		gate.label.text="鍵 OPEN"
	if changed: revision+=1; grids.clear()
func command(duration: float) -> void:
	open_all()
	for i in ([0,3] if diagonal==0 else [1,2]):
		gates[i].state="warning"
		gates[i].left=2.0
		gates[i].wait=0.0
		gates[i].duration=duration
	diagonal=1-diagonal
	game.sound.play_effect("gate")
func commanding() -> bool:
	for gate in gates:
		if gate.state=="warning": return true
	return false
func tick(delta: float) -> void:
	if game.run_state!="combat" or game.get_tree().paused or game.player.health<=0: return
	var miniboss: bool=not game.final_boss_spawned and ((is_instance_valid(game.active_boss) and not game.active_boss.dead) or game.elapsed<game.recovery_until)
	if miniboss:
		open_all()
		suspended=true
		return
	if suspended: next_cycle=clock; suspended=false
	clock+=delta
	var started:=false
	if not game.final_boss_spawned and game.elapsed>=60 and clock>=next_cycle:
		command(8)
		next_cycle=clock+20
		started=true
	for gate in gates:
		if gate.state=="open" or started: continue
		gate.left-=delta
		if gate.state=="warning":
			gate.label.text="鍵 閉鎖 %.1f" % maxf(0,gate.left)
			gate.label.modulate=Color("a3e9ff") if sin(clock*8)>0 else Color.WHITE
			if gate.left<=0:
				if occupied(gate.rect):
					gate.wait+=delta
					if gate.wait<2: continue
					gate.state="open"
					gate.label.text="鍵 OPEN"
				else:
					gate.state="closed"
					gate.left=gate.duration
					gate.mesh.show()
					revision+=1
					grids.clear()
		else:
			gate.label.text="鍵 開放 %d" % ceili(maxf(0,gate.left))
			if gate.left<=0:
				gate.state="open"
				gate.mesh.hide()
				gate.label.text="鍵 OPEN"
				revision+=1
				grids.clear()
