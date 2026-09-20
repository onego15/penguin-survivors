extends "res://scripts/enemy.gd"
signal phase_changed
var boss_name:="潮騒の大王・オクト"
var enraged:=false
var cinematic_locked:=false
var crown_glow: MeshInstance3D
var phase_armor: Node3D
var warning_left:=0.0
var dash_left:=0.0
var wall_busy:=false
var attack_kind:=""
var attack_index:=0
var attack_cooldown:=2.0
var tide_left:=0.0
var tide_cast:=false
var locked_direction:=Vector3.BACK
var marker: Node3D
var hazards: Array=[]
var field: Node3D
const C=preload("res://scripts/combat_visuals.gd")
func _ready() -> void:
	kind=15; is_miniboss=true
	super._ready()
	model.free(); model=preload("res://scripts/beach_models.gd").octopus(self); visual_scale=2; model.scale=Vector3.ONE*2
	health=1600; max_health=health; contact_damage=18; hit_radius=1.7; speed=1.8; health_bar.position.y=5.5
	add_to_group("final_bosses")
	crown_glow=Visuals.ring(model,Color("b9f9ef"),Vector3(0,2.4,0),0.7,0.05)
	phase_armor=Visuals.pivot(model,"TideCrown")
	for i in range(8):
		var a:=i*TAU/8; var p:=Vector3(cos(a)*0.65,2.2,sin(a)*0.65)
		Visuals.rod(phase_armor,Color("8ff2e2"),p,p+Vector3.UP*0.8,0.12,0)
	phase_armor.hide()
func beach_field():
	if is_instance_valid(field): return field
	for node in get_tree().get_nodes_in_group("beach_fields"): field=node; return field
	return null
func _physics_process(delta: float) -> void:
	if dead or cinematic_locked or not is_instance_valid(target): return
	age+=delta; hurt_time=maxf(0,hurt_time-delta)
	for part in model.get_children():
		if str(part.name).begins_with("Arm"): part.rotation.z=sin(age*2+part.get_index())*0.12
	if tide_left>0:
		tide_left=maxf(0,tide_left-delta)
		warning_left=maxf(0,warning_left-delta)
		if enraged and tide_left<=3 and not tide_cast:
			tide_cast=true; tentacles()
		if tide_left<=0: wall_busy=false; attack_index=2 if enraged else 1; attack_cooldown=2
		return
	if warning_left>0:
		warning_left=maxf(0,warning_left-delta)
		if is_instance_valid(marker): C.progress(marker,warning_left/1.2)
		if warning_left<=0:
			if attack_kind=="ink": shoot_ink()
			attack_cooldown=2; wall_busy=false
		return
	if attack_cooldown>0:
		attack_cooldown=maxf(0,attack_cooldown-delta)
		# Gentle approach during the latter half of recovery; no damage overlap with a telegraph.
		if attack_cooldown<1 and position.distance_to(target.position)>4:
			_move_and_contact(delta,(target.position-position).normalized()*speed)
		return
	begin_attack()
func status_label() -> String:
	return " / 潮と触手の間へ" if attack_kind=="tide" else " / 墨は泉で解除"
func begin_attack() -> void:
	locked_direction=(target.position-position).normalized(); locked_direction.y=0
	if attack_index%4==0:
		attack_kind="tide"; wall_busy=true; tide_left=8; warning_left=2; tide_cast=false
		var water=beach_field()
		if water!=null: water.command()
	elif attack_index%4==1:
		attack_kind="tentacle"
		if not tentacles(): attack_cooldown=1; return
		warning_left=2.8 if enraged else 1.95; wall_busy=true; attack_index+=1
	elif attack_index%4==2:
		attack_kind="ink"; warning_left=1.2; wall_busy=true; attack_index+=1
		if is_instance_valid(marker): marker.free()
		marker=C.sector_warning(self,8,0.6); marker.rotation.y=atan2(locked_direction.x,locked_direction.z)
	else:
		attack_kind="puddle"
		if not puddles(): attack_cooldown=1; return
		warning_left=2.45; wall_busy=true; attack_index+=1
	get_tree().call_group("game_audio","play_effect","sea_cast")
func spawn_hazard(center: Vector3, radius: float, length: float, delay: float, amount: int, direction: Vector3) -> Node3D:
	var h=preload("res://scripts/beach_hazard.gd").new(); h.position=center; h.target=target; h.radius=radius; h.length=length; h.delay=delay; h.damage=amount; h.direction=direction
	preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,h); get_parent().add_child(h); hazards.append(h)
	return h
func tentacles() -> bool:
	locked_direction=(target.position-position).normalized(); locked_direction.y=0
	var side:=Vector3(-locked_direction.z,0,locked_direction.x)
	var centers: Array[Vector3]=[]
	for i in range(2 if enraged else 1):
		var center:=position+locked_direction*5+side*((-3 if i==0 else 3) if enraged else 0)
		centers.append(center)
	if not safe_floor(centers,1,10,locked_direction): return false
	for i in range(centers.size()): spawn_hazard(centers[i],1,10,1.5+i*0.8,24,locked_direction)
	return true
func puddles() -> bool:
	var centers: Array[Vector3]=[]
	var side:=Vector3(-locked_direction.z,0,locked_direction.x)
	var game=target.get_parent().get_parent()
	var rng: RandomNumberGenerator=game.rng
	var center: Vector3=target.position
	for attempt in range(16):
		var angle:=rng.randf_range(0,TAU)
		var candidate: Vector3=target.position+Vector3(cos(angle),0,sin(angle))*sqrt(rng.randf())*1.5
		if absf(candidate.x)<=23.3 and absf(candidate.z)<=23.3: center=candidate; break
	var radius:=2.5 if enraged else 3.0
	centers.append(center)
	if enraged:
		var found:=false
		for i in range(32):
			var point:=center+side.rotated(Vector3.UP,i*TAU/32)*6
			if absf(point.x)>23.3 or absf(point.z)>23.3: continue
			var candidate: Array[Vector3]=[center,point]
			if safe_floor(candidate,radius,0,Vector3.BACK): centers.append(point); found=true; break
		if not found: return false
	if not safe_floor(centers,radius,0,Vector3.BACK): return false
	for point in centers: spawn_hazard(point,radius,0,2,24,Vector3.BACK)
	return true
func safe_floor(centers: Array[Vector3], radius: float, length: float, facing: Vector3) -> bool:
	# Four metres fits the shortest telegraph even with sand and opposing 1.2 m/s tide.
	var side:=Vector3(-facing.z,0,facing.x)
	for distance in [0.0,1.0,2.0,3.0,4.0]:
		for i in range(32):
			var p: Vector3=target.position+Vector3(cos(i*TAU/32),0,sin(i*TAU/32))*distance
			if absf(p.x)>23.3 or absf(p.z)>23.3 or p.distance_to(position)<hit_radius+0.6: continue
			var clear:=true
			for center in centers:
				var offset:=p-center
				if length>0:
					if absf(offset.dot(side))<radius+0.6 and absf(offset.dot(facing))<length/2+0.6: clear=false
				elif offset.length()<radius+0.6: clear=false
			if clear: return true
	return false
func shoot_ink() -> void:
	if is_instance_valid(marker): marker.hide()
	var count:=7 if enraged else 5
	for i in range(count):
		var shot=preload("res://scripts/boss_projectile.gd").new(); shot.target=target; shot.position=position+Vector3.UP
		shot.direction=locked_direction.rotated(Vector3.UP,lerpf(-0.6,0.6,float(i)/(count-1))); shot.speed=5; shot.damage=10; shot.lifetime=4; shot.status_effect="ink"
		preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,shot); get_parent().add_child(shot)
func cancel_attacks() -> void:
	warning_left=0; tide_left=0; wall_busy=false
	if is_instance_valid(marker): marker.hide()
	for h in hazards:
		if is_instance_valid(h): h.queue_free()
	hazards.clear()
	var water=beach_field()
	if water!=null: water.stop_flow()
func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if dead: cancel_attacks(); return
	if health<=max_health/2 and not enraged and not get_meta("phase_locked",false):
		cancel_attacks(); enraged=true; phase_armor.show(); attack_index=0; attack_cooldown=2; phase_changed.emit()
func initialize_training_phase(second: bool) -> void:
	set_meta("phase_locked",true); cancel_attacks(); enraged=second; phase_armor.visible=second
	if second: health=max_health/2
	attack_index=0; attack_cooldown=2
func danger_contains(point: Vector3) -> bool:
	for h in hazards:
		if is_instance_valid(h) and h.danger_contains(point): return true
	return false
func _exit_tree() -> void:
	for h in hazards:
		if is_instance_valid(h): h.queue_free()
