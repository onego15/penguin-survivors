extends RefCounted
const C = preload("res://scripts/combat_visuals.gd")
const O = preload("res://scripts/castle_obstacles.gd")
const V = preload("res://scripts/visuals.gd")

static func endpoint(actor: Node3D, direction: Vector3, distance: float) -> Vector3:
	var start: Vector3 = actor.global_position
	var end := start + direction * distance
	var world = O.world(actor)
	if world != null: return world.sweep(start, end, actor.hit_radius).point
	var t := 1.0
	for axis in [0, 2]:
		if absf(direction[axis]) > 0.00001:
			t = minf(t, maxf(0, (24.0 * signf(direction[axis])-start[axis]) / (direction[axis]*maxf(distance,0.00001))))
	return start.lerp(end, t)

static func lane(actor: Node3D, end: Vector3, hostile := true) -> Node3D:
	var offset: Vector3 = end-actor.global_position
	var root := C.warning(actor, actor.hit_radius, maxf(0.01,offset.length()))
	root.position = offset*0.5+Vector3.UP*0.09
	root.rotation.y = atan2(offset.x,offset.z)
	for sign_value in [-1,1]:
		for i in range(8):
			var a:=i*PI/8
			var b:=a+PI/12
			var center:=Vector3(0,0,sign_value*offset.length()*0.5)
			C.ink(V.rod(root,C.WARN,center+Vector3(cos(a),0,sign_value*sin(a))*actor.hit_radius,center+Vector3(cos(b),0,sign_value*sin(b))*actor.hit_radius,0.04))
	if not hostile:
		for child in root.get_children():
			if child is Label3D: child.text = "↗"
			if child is MeshInstance3D:
				child.material_override.albedo_color = Color("d5f2ff")
	return root

static func fan(parent: Node3D, count: int, spacing: float, radius := 6.0) -> Node3D:
	var root := C.sector_warning(parent,radius,(count-1)*spacing*0.5+0.04)
	var directions: Array[Vector3]=[]
	for i in range(count):
		var angle := (i-(count-1)*0.5)*spacing
		var d := Vector3(sin(angle),0,cos(angle))
		directions.append(d)
		for j in range(3): C.ink(V.rod(root,C.WARN,d*(1+j),d*(1.6+j),0.035))
	root.set_meta("shot_directions",directions)
	return root

static func radial(parent: Node3D) -> Node3D:
	var root := C.warning(parent,2.0)
	for i in range(8):
		var d := Vector3(sin(i*TAU/8),0,cos(i*TAU/8))
		C.ink(V.rod(root,C.WARN,d*0.8,d*3.0,0.035))
	return root
