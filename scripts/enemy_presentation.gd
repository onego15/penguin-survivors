extends RefCounted
const V = preload("res://scripts/visuals.gd")

static func shell(model: Node3D, fraction: float) -> void:
	if not is_instance_valid(model) or not model.has_node("Head"): return
	var head := model.get_node("Head") as Node3D
	if not head.has_meta("rest_position"): head.set_meta("rest_position",head.position)
	head.position = head.get_meta("rest_position") + Vector3(0,-0.12,-0.5)*fraction
	for part in model.get_children():
		if str(part.name).begins_with("Paw_"): part.scale = Vector3.ONE*(1.0-fraction*0.7)
	var shine := model.get_node_or_null("ShellShine")
	if shine == null:
		shine = V.ellipsoid(model,Color("b7cfc1"),Vector3(0,1.15,-0.14),Vector3(0.3,0.07,0.3))
		shine.name = "ShellShine"
		shine.material_override=shine.material_override.duplicate()
		shine.material_override.roughness=0.15
		shine.material_override.metallic=0.3
	shine.visible = fraction > 0.5

static func decorate(actor: Node3D) -> void:
	var model: Node3D = actor.model
	if actor.is_miniboss:
		if model.has_node("Tail"): model.get_node("Tail").scale *= 1.4
		if actor.kind == 1:
			for ear in ["Head/EarLeft","Head/EarRight"]: model.get_node(ear).scale.y *= 1.2
		if actor.kind == 2:
			for side in [-1,1]:
				V.rod(model,Color("fff0ce"),Vector3(side*0.45,0.8,0.8),Vector3(side*0.7,1.35,1.1),0.15,0.02)
		if actor.kind == 13:
			for side in [-1,1]:
				var plate:=PrismMesh.new(); plate.size=Vector3(0.45,0.55,0.65)
				V.mesh(model,plate,Color("606c8a"),Vector3(side*0.43,0.85,0.12))
		if actor.kind == 3: model.set_meta("height_factor",1.1)
		if actor.kind == 10:
			for wing_name in ["WingLeft","WingRight"]:
				var wing:=model.get_node(wing_name) as Node3D
				wing.scale *= 1.2
				var side := -1.0 if wing_name=="WingLeft" else 1.0
				for i in range(2): V.rod(wing,Color("b6dcf2"),Vector3(side*(0.8+i*0.14),0,-i*0.32),Vector3(side*(1.04+i*0.14),0.12,-i*0.32),0.06,0.0)
		if actor.kind == 11:
			V.ellipsoid(model,Color("725775"),Vector3(0,0.75,-0.65),Vector3(0.5,0.6,0.25))
			V.ellipsoid(model,Color("b6efff"),Vector3(-0.48,0.8,0.6),Vector3.ONE*0.24).name = "SecondIceBall"
	if actor.kind == 14:
		var trail := V.pivot(model,"PhaseTrail")
		for i in range(3): V.ring(trail,Color("d9bafa"),Vector3(0,0.7,-0.35-i*0.25),0.35-i*0.07,0.018,true)
		trail.hide()

static func motion(actor: Node3D, velocity: Vector3, delta := 1.0/60.0) -> void:
	var model: Node3D = actor.model
	if actor.kind == 0:
		model.rotation.z = sin(actor.age*4.2+actor.movement_phase)*0.12
	elif actor.kind == 1:
		var t: float = clampf(actor.hop_phase/0.62,0,1)
		for part in model.get_children():
			if str(part.name).begins_with("Paw_") and part.position.z<0: part.scale.y=0.8+sin(t*PI)*0.5
	elif actor.kind == 14:
		var world = preload("res://scripts/castle_obstacles.gd").world(actor)
		var crossing: bool = world != null and not world.clear(actor.global_position,actor.hit_radius)
		var left: float = maxf(0,float(actor.get_meta("phase_glow",0))-delta)
		if crossing: left=0.3
		actor.set_meta("phase_glow",left)
		if model.has_node("PhaseTrail"): model.get_node("PhaseTrail").visible=left>0
	if actor.kind == 2 and actor.charge_state == actor.ChargeState.WINDUP:
		for part in model.get_children():
			if str(part.name).begins_with("Paw_"): part.rotation.x=sin(actor.age*28+part.position.x*5)*0.4

static func throw_pose(model: Node3D, cooldown: float) -> void:
	for name in ["HeldIceBall","SecondIceBall"]:
		if model.has_node(name): model.get_node(name).visible=cooldown<5.4
	for name in ["ThrowLeft","ThrowRight"]:
		if model.has_node(name): model.get_node(name).rotation.x=clampf((0.4-cooldown)/0.4,0,1)*0.8-maxf(0,1.0-absf(cooldown-5.8)*5)*1.2
