extends "res://scripts/enemy.gd"
signal phase_changed
const C=preload("res://scripts/combat_visuals.gd")
const O=preload("res://scripts/castle_obstacles.gd")
var boss_name:="氷城の梟王・ノクティス"
var cinematic_locked:=false
var enraged:=false
var warning_left:=0.0
var dash_left:=0.0
var attack_kind:=""
var attack_index:=0
var attack_cooldown:=2.0
var recovery_left:=0.0
var locked:=Vector3.ZERO
var centers: Array[Vector3]=[]
var markers: Array[Node3D]=[]
var areas: Array[Node3D]=[]
var flash_left:=0.0
var crown_glow: MeshInstance3D
var phase_armor: Node3D
var mask_parts: Array[MeshInstance3D]=[]
var flight_origin:=Vector3.ZERO
var flight_via:=Vector3.ZERO
var flight_end:=Vector3.ZERO
var move_caption: Label3D
func _ready() -> void:
	kind=Kind.OWL
	visual_scale=2.4
	super._ready()
	add_to_group("final_bosses")
	recolor(model)
	health=1600
	max_health=health
	hit_radius=1.5
	contact_damage=18
	speed=2
	health_bar.position.y=5
	phase_armor=Visuals.pivot(model,"CrystalWings")
	for side in [-1,1]:
		for i in range(4):
			Visuals.rod(phase_armor,Color("9bd7ff"),Vector3(side*(0.5+i*0.2),1.2-i*0.15,0),Vector3(side*(0.9+i*0.25),1.9-i*0.2,0),0.14,0)
	phase_armor.hide()
	for side in [-1,1]:
		for i in range(3):
			Visuals.rod(model,Color("80badc"),Vector3(side*0.5,1-i*0.17,0),Vector3(side*(0.85+i*0.1),1.3-i*0.2,0),0.09,0)
	for side in [-1,1]:
		var center:=Vector3(side*0.24,1.3,0.59)
		for i in range(4):
			var a:=center+Vector3(cos(i*PI/2),sin(i*PI/2),0)*0.28
			var b:=center+Vector3(cos((i+1)*PI/2),sin((i+1)*PI/2),0)*0.28
			mask_parts.append(C.ink(Visuals.rod(model,Color("a6e6ff"),a,b,0.045)))
	Visuals.rod(model,Color("7886b5"),Vector3(0.9,0,0.2),Vector3(0.9,2,0.2),0.055)
	Visuals.rod(model,Color("d0f3ff"),Vector3(0.9,2,0.2),Vector3(0.9,2.5,0.2),0.2,0)
	crown_glow=Visuals.ellipsoid(model,Color("d6ceff"),Vector3(0,2,0),Vector3(0.55,0.1,0.55))
	move_caption=C.symbol(self,"",Color("e5d8ff"))
	move_caption.position.y=5.5
	move_caption.font_size=28
func clear_markers() -> void:
	for marker in markers+areas:
		if is_instance_valid(marker): marker.hide(); marker.queue_free()
	markers.clear()
	areas.clear()
	centers.clear()
func cancel_attacks() -> void:
	if dash_left>0: global_position=flight_origin
	dash_left=0
	model.position.y=0
	targetable=true
	if not dead and not is_in_group("enemies"): add_to_group("enemies")
	if is_instance_valid(move_caption): move_caption.text=""
	clear_markers()
	warning_left=0
	flash_left=0
	attack_kind=""
	var obstacle=O.world(self)
	if obstacle!=null: obstacle.open_all()
func safe_escape() -> bool:
	var obstacle=O.world(self)
	var r:=2.5 if enraged else 3.0
	for distance in [4.0,7.0,10.0,12.0]:
		for i in range(32):
			var point: Vector3=target.global_position+Vector3(cos(i*TAU/32),0,sin(i*TAU/32))*distance
			if not obstacle.clear(point,0.5): continue
			var safe:=true
			for center in centers:
				if point.distance_to(center)<=r+0.7 and attack_visible(center,point): safe=false
			if not safe: continue
			var route: PackedVector2Array=obstacle.path(target.global_position,point,0.5)
			var length:=0.0
			for n in range(1,route.size()): length+=route[n].distance_to(route[n-1])
			if not route.is_empty() and length<=12: return true
	return false
func begin_attack() -> bool:
	clear_markers()
	var obstacle=O.world(self)
	attack_kind=["gates","fan","rings"][attack_index%3]
	locked=(target.global_position-global_position).normalized()
	move_caption.text={"gates":"門の勅令 → 城門跳躍","fan":"門を貫く氷羽：横へ回避","rings":"月影の氷輪：門越しも危険"}[attack_kind]
	if attack_kind=="gates":
		obstacle.command(8 if enraged else 6)
		warning_left=2
	elif attack_kind=="fan":
		warning_left=1.2
		var marker=C.warning(self,0.4,12)
		marker.position=locked*6
		marker.rotation.y=atan2(locked.x,locked.z)
		markers.append(marker)
	else:
		var origin:=target.global_position
		var side:=Vector3(-locked.z,0,locked.x)
		for offset in ([0.0,-4.5,4.5] if enraged else [0.0]):
			var point: Vector3=origin+side*offset
			if not obstacle.clear(point,0.1): attack_cooldown=0.5; return false
			centers.append(point)
		if not safe_escape(): attack_cooldown=0.5; return false
		warning_left=2
		for point in centers:
			var marker=C.warning(self,2.5 if enraged else 3)
			marker.global_position=point
			markers.append(marker)
		get_tree().call_group("game_audio","play_effect","noctis_cast")
	return true
func release() -> void:
	for marker in markers: marker.hide()
	if attack_kind=="vault":
		dash_left=0.9
		targetable=false
		remove_from_group("enemies")
		return
	if attack_kind=="gates" and plan_vault():
		attack_index+=1
		attack_kind="vault"
		warning_left=0.8
		move_caption.text="城門跳躍：着地点から離れる"
		var marker=C.warning(self,hit_radius+0.3)
		marker.global_position=flight_end
		markers.append(marker)
		return
	if attack_kind=="fan":
		var count:=7 if enraged else 5
		for i in range(count):
			var bolt=preload("res://scripts/boss_projectile.gd").new()
			bolt.target=target
			bolt.position=global_position+Vector3.UP
			bolt.direction=locked.rotated(Vector3.UP,(i-(count-1)/2.0)*0.2)
			bolt.pass_gates=true
			bolt.speed=6
			bolt.damage=12
			get_parent().add_child(bolt)
	elif attack_kind=="rings":
		var radius:=2.5 if enraged else 3.0
		for center in centers:
			var area=C.danger(self,radius)
			area.global_position=center
			areas.append(area)
			if target.global_position.distance_to(center)<=radius+0.42 and attack_visible(center,target.global_position): target.take_damage(24)
		flash_left=0.4
	attack_index+=1
	attack_cooldown=3.5
	recovery_left=1.5
func _physics_process(delta: float) -> void:
	if dead or cinematic_locked or not is_instance_valid(target): return
	age+=delta
	if dash_left>0:
		dash_left=maxf(0,dash_left-delta)
		var t:=1-dash_left/0.9
		global_position=flight_origin.lerp(flight_via,t*2) if t<0.5 else flight_via.lerp(flight_end,(t-0.5)*2)
		model.position.y=sin(t*PI)*3.8
		move_caption.position.y=8
		model.get_node("WingLeft").rotation.z=sin(t*TAU*2)*0.6
		model.get_node("WingRight").rotation.z=-sin(t*TAU*2)*0.6
		if dash_left<=0:
			global_position=flight_end
			model.position.y=0
			targetable=true
			add_to_group("enemies")
			clear_markers()
			attack_kind=""
			move_caption.text=""
			move_caption.position.y=5.5
			attack_cooldown=0.8
			recovery_left=0.8
		return
	if flash_left>0:
		flash_left-=delta
		if flash_left<=0:
			for area in areas: area.hide()
	if warning_left>0:
		warning_left=maxf(0,warning_left-delta)
		for marker in markers: C.progress(marker,warning_left/(0.8 if attack_kind=="vault" else (1.2 if attack_kind=="fan" else 2)))
		if warning_left<=0:
			if attack_kind=="gates" and O.world(self).commanding(): warning_left=0.001
			else: release()
		return
	attack_cooldown-=delta
	if attack_cooldown<=0:
		begin_attack()
		return
	recovery_left=maxf(0,recovery_left-delta)
	if recovery_left<=0:
		_move_and_contact(delta,(target.position-position).normalized()*speed)
	if position.distance_to(target.position)<hit_radius+0.42 and O.visible_between(self,position,target.position): target.take_damage(contact_damage)
func take_damage(amount: int) -> void:
	if cinematic_locked or not targetable: return
	super.take_damage(amount)
	if dead: cancel_attacks(); return
	if not enraged and health<=max_health/2:
		enraged=true
		speed=2.4
		cancel_attacks()
		phase_armor.show()
		for part in mask_parts:
			part.material_override=part.material_override.duplicate()
			part.material_override.albedo_color=Color("efb6ff")
		crown_glow.material_override=crown_glow.material_override.duplicate()
		crown_glow.material_override.albedo_color=Color("eab3ff")
		attack_index=0
		attack_cooldown=2
		phase_changed.emit()
func danger_contains(point: Vector3) -> bool:
	if attack_kind=="rings" and (warning_left>0 or flash_left>0):
		for center in centers:
			if center.distance_to(point)<(3 if enraged else 3.5) and attack_visible(center,point): return true
	return false

func recolor(node: Node) -> void:
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		var color: Color=node.material_override.albedo_color
		if color.b>color.r and color.r>color.g:
			node.material_override=node.material_override.duplicate()
			node.material_override.albedo_color=Color("435982")
	for child in node.get_children(): recolor(child)

func attack_visible(a: Vector3,b: Vector3) -> bool:
	var obstacle=O.world(self)
	return obstacle==null or obstacle.sweep(a,b,0,true).t>=1
func plan_vault() -> bool:
	var obstacle=O.world(self)
	var best:=INF
	var found:=false
	for gate in obstacle.gates:
		var p: Vector2=gate.rect.get_center()
		var sign_side: float=1 if global_position.x<p.x else -1
		var candidate:=Vector3(p.x+sign_side*3.0,0,p.y)
		if not obstacle.clear(candidate,hit_radius+0.1) or candidate.distance_to(target.global_position)<3.2: continue
		var score:=global_position.distance_to(Vector3(p.x,0,p.y))+candidate.distance_to(target.global_position)*0.4+(0 if gate.state=="closed" else 40)
		if score<best:
			best=score
			flight_origin=global_position
			flight_via=Vector3(p.x,0,p.y)
			flight_end=candidate
			found=true
	return found
