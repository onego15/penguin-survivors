extends "res://scripts/enemy.gd"

const Bolt = preload("res://scripts/boss_projectile.gd")
signal phase_changed
var cinematic_locked := false
var phase_attack_index := 0
var casting: Node3D
var quake_warning: Node3D
var quake_area: Node3D
var quake_ice: Node3D
var quake_center := Vector3.ZERO
var quake_flash := 0.0
var quake_wave: MeshInstance3D
var crown_glow: MeshInstance3D
var phase_armor: Node3D
var arms: Array[Node3D] = []
var boss_name := "冬の王・グレイシャー"
var enraged := false
var attack_cooldown := 2.5
var warning_left := 0.0
var attack_index := 0
var attack_kind := ""
var locked_direction := Vector3.FORWARD
const C = preload("res://scripts/combat_visuals.gd")
var active_area: Node3D
var warning_ring: Node3D
var aim_line: Node3D
var flash_left := 0.0
var dash_left := 0.0
var dash_speed := 16.0
var dash_distance := 11.0
var dash_recovery := 1.2
var recovery_left := 0.0
var dash_hit := false
var dash_marker: Node3D
const SLAM_RADIUS := 5.2


func _ready() -> void:
	kind = Kind.TURTLE
	visual_scale = 2.4
	super._ready()
	model.free()
	model = Visuals.pivot(self, "PolarKing")
	_build_polar_bear()
	model.scale = Vector3.ONE * visual_scale
	health = 1400
	max_health = health
	hit_radius = 1.55
	contact_damage = 24
	health_bar.position.y = 5.8
	warning_ring=C.warning(self,SLAM_RADIUS)
	active_area=C.danger(self,SLAM_RADIUS)
	active_area.hide()
	aim_line=C.warning(self,0.3,8.0)
	dash_marker=C.warning(self,hit_radius,11.0)
	warning_ring.hide()
	aim_line.hide()
	dash_marker.hide()
	casting=Visuals.pivot(self,"RemoteIceStream")
	for i in range(12): Visuals.ellipsoid(casting,Color("c8f4ff"),Vector3.ZERO,Vector3.ONE*0.09)
	casting.hide()
	quake_warning=C.warning(self,9.0)
	quake_area=C.danger(self,9.0)
	quake_ice=Visuals.pivot(self,"QuakeIce")
	for i in range(12):
		var a:=i*TAU/12
		var point:=Vector3(cos(a),0,sin(a))*(4.0+(i%2)*3.5)
		Visuals.rod(quake_ice,Color("b3e8ff"),point,point+Vector3.UP*(1.5+(i%3)*0.4),0.3,0)
	quake_wave=Visuals.ring(quake_ice,Color("d4f8ff"),Vector3(0,0.15,0),1.0,0.08)
	quake_warning.hide()
	quake_area.hide()
	quake_ice.hide()
	phase_armor=Visuals.pivot(model,"PhaseArmor")
	for side in [-1,1]:
		for i in range(3):
			var point:=Vector3(side*(0.55+i*0.12),1.3-i*0.22,0)
			Visuals.rod(phase_armor,Color("8bcfff"),point,point+Vector3(side*0.22,0.55,0),0.23,0)
		Visuals.ellipsoid(phase_armor,Color("fe9fb7"),Vector3(side*0.27,1.79,0.7),Vector3(0.08,0.045,0.05))
	for i in range(7):
		var a:=i*TAU/7
		var point:=Vector3(cos(a)*0.48,2.25,0.22+sin(a)*0.48)
		Visuals.rod(phase_armor,Color("a8c2ff"),point,point+Vector3(0,0.85,0),0.15,0)
	for part in phase_armor.get_children():
		if part is MeshInstance3D:
			var mat:=part.material_override.duplicate() as StandardMaterial3D
			mat.emission_enabled=true
			mat.emission=mat.albedo_color
			mat.emission_energy_multiplier=0.25
			part.material_override=mat
	phase_armor.hide()
	crown_glow=Visuals.ring(model,Color("d7edff"),Vector3(0,2.25,0.22),0.65,0.035)
	crown_glow.hide()
	add_to_group("final_bosses")


func _build_polar_bear() -> void:
	var fur := Color("e4edf5")
	Visuals.ellipsoid(model, fur, Vector3(0, 0.8, -0.05), Vector3(0.75, 0.85, 0.63))
	Visuals.ellipsoid(model, Color("bed5e5"), Vector3(0, 0.75, 0.48), Vector3(0.48, 0.57, 0.16))
	var head := Visuals.pivot(model, "Head", Vector3(0, 1.75, 0.22))
	Visuals.ellipsoid(head, fur, Vector3.ZERO, Vector3(0.68, 0.56, 0.5))
	for side in [-1.0, 1.0]:
		Visuals.ellipsoid(head, fur, Vector3(side * 0.51, 0.4, -0.02), Vector3.ONE * 0.22)
		Visuals.ellipsoid(head, Color("8199b5"), Vector3(side * 0.51, 0.4, 0.16), Vector3(0.13, 0.13, 0.035))
		var arm:=Visuals.pivot(model,"Arm",Vector3(side*0.64,1.25,0))
		Visuals.ellipsoid(arm,fur,Vector3(0,-0.5,0),Vector3(0.24,0.61,0.27))
		arms.append(arm)
		Visuals.rod(head, Color("395474"), Vector3(side * 0.15, 0.14, 0.46), Vector3(side * 0.41, 0.22, 0.38), 0.045)
	Visuals.ellipsoid(head, Color("f1f7f8"), Vector3(0, -0.15, 0.47), Vector3(0.32, 0.22, 0.21))
	Visuals.ellipsoid(head, Color("263d57"), Vector3(0, -0.08, 0.65), Vector3(0.14, 0.09, 0.065))
	Models.eyes(head, 0.27, 0.045, 0.459, 0.085)
	Models.paws(model, fur, 0.46, 0.28, 0.26)
	Visuals.ring(head, Color("b38de9"), Vector3(0, 0.45, 0), 0.47, 0.07)
	for index in range(7):
		var angle := index * TAU / 7
		var point := Vector3(cos(angle) * 0.44, 0.45, sin(angle) * 0.44)
		Visuals.rod(head, Color("a4e9fa"), point, point + Vector3(0, 0.5 if index % 2 == 0 else 0.3, 0), 0.12, 0)
	Visuals.ring(model, Color("8666b5"), Vector3(0, 1.25, 0), 0.68, 0.08)


func _physics_process(delta: float) -> void:
	if dead or cinematic_locked or not is_instance_valid(target):
		return
	age += delta
	hurt_time = maxf(0, hurt_time - delta)
	if not enraged and health<=max_health/2:
		_enter_phase_two()
		return
	quake_flash=maxf(0,quake_flash-delta)
	quake_wave.scale=Vector3.ONE*lerpf(1,9,1-quake_flash/0.45)
	if quake_flash<=0:
		quake_area.hide()
		quake_ice.hide()
	if dash_left > 0:
		_tick_dash(delta)
		return
	if recovery_left > 0:
		recovery_left = maxf(0, recovery_left - delta)
		model.rotation.x = 0
		model.rotation.z = 0
		return
	if warning_left > 0:
		warning_left = maxf(0, warning_left - delta)
		if attack_kind=="quake":
			C.progress(quake_warning,warning_left/3.0)
			for i in range(casting.get_child_count()):
				var f:=fposmod(age*0.7+i/12.0,1.0)
				casting.get_child(i).global_position=(global_position+Vector3.UP*5.5).lerp(quake_center+Vector3.UP*0.2,f)+Vector3.UP*sin(f*PI)
			casting.show()
			for arm in arms: arm.rotation.x=-2.6
		for marker in [warning_ring,aim_line,dash_marker]:
			C.progress(marker,warning_left/(1.3 if attack_kind=="slam" else (0.8 if attack_kind=="dash" and enraged else 1.0)))
		model.rotation.z = sin(age * 30) * 0.03
		if warning_left <= 0:
			_release_attack()
		return
	flash_left = maxf(0, flash_left - delta)
	if flash_left <= 0:
		warning_ring.hide()
		active_area.hide()
	var offset := target.global_position - global_position
	offset.y = 0
	var movement := offset.normalized() * (3.0 if enraged else 2.1) * delta
	if offset.length() > 1.8:
		global_position += movement
		model.rotation.y = lerp_angle(model.rotation.y, atan2(offset.x, offset.z), 1 - exp(-delta * 8))
	_animate(2.0)
	if global_position.distance_to(target.global_position) < hit_radius + 0.42:
		target.take_damage(contact_damage)
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		attack_kind = "slam" if attack_index % 2 == 0 and offset.length() < 7 else "shards"
		if attack_index % 3 == 2:
			attack_kind = "dash"
		attack_index += 1
		if enraged:
			attack_kind=["quake","shards","dash","slam"][phase_attack_index%4]
			phase_attack_index+=1
			if attack_kind=="slam" and offset.length()>=7: attack_kind="shards"
		warning_left = 1.3 if attack_kind == "slam" else 1.0
		locked_direction = offset.normalized() if offset.length() > 0.01 else Vector3.FORWARD
		if attack_kind=="quake":
			warning_left=3.0
			quake_center=sample_quake_center(target.global_position)
			quake_warning.global_position=quake_center+Vector3(0,0.09,0)
			C.progress(quake_warning,1)
			quake_warning.show()
			get_tree().call_group("game_audio","play_effect","quake_charge")
		elif attack_kind == "dash":
			warning_left = 0.8 if enraged else 1.0
			dash_speed = 20.0 if enraged else 16.0
			dash_distance = 13.0 if enraged else 11.0
			dash_recovery = 1.0 if enraged else 1.2
			dash_marker.scale.z=dash_distance/11.0
			dash_marker.position = locked_direction * dash_distance * 0.5 + Vector3(0, 0.06, 0)
			dash_marker.rotation.y = atan2(locked_direction.x, locked_direction.z)
			model.rotation.y = dash_marker.rotation.y
			dash_marker.show()
			get_tree().call_group("game_audio", "play_effect", "warning")
		elif attack_kind == "slam":
			warning_ring.show()
		else:
			aim_line.position = locked_direction * 4 + Vector3(0, 0.05, 0)
			aim_line.rotation.y = atan2(locked_direction.x, locked_direction.z)
			aim_line.show()


func _release_attack() -> void:
	casting.hide()
	aim_line.hide()
	for arm in arms: arm.rotation.x=0
	if attack_kind=="quake":
		quake_warning.hide()
		if target.global_position.distance_to(quake_center)<=9.0+0.42: target.take_damage(40)
		quake_area.global_position=quake_center+Vector3.UP*0.09
		quake_ice.global_position=quake_center
		quake_area.show()
		quake_ice.show()
		quake_flash=0.45
		quake_wave.scale=Vector3.ONE
		recovery_left=2.0
		get_tree().call_group("game_audio","play_effect","quake_impact")
	elif attack_kind == "dash":
		dash_marker.hide()
		dash_left = dash_distance
		dash_hit = false
		get_tree().call_group("game_audio", "play_effect", "slash")
	elif attack_kind == "slam":
		if global_position.distance_to(target.global_position) < SLAM_RADIUS + 0.42:
			target.take_damage(28)
		warning_ring.hide()
		active_area.show()
		flash_left = 0.3
	else:
		for index in range(12 if enraged else 7):
			var bolt := Bolt.new()
			bolt.target = target
			var angle := index * TAU / 12 if enraged else (index - 3) * 0.2
			bolt.direction = locked_direction.rotated(Vector3.UP, angle)
			bolt.position = position + Vector3.UP + bolt.direction * 1.7
			bolt.speed = 6.0 if enraged else 5.0
			get_parent().add_child(bolt)
	attack_cooldown = 2.0 if enraged else 3.0


func _tick_dash(delta: float) -> void:
	var start := global_position
	var step := minf(dash_left, dash_speed * delta)
	var finish := start + locked_direction * step
	finish.x = clampf(finish.x, -23, 23)
	finish.z = clampf(finish.z, -23, 23)
	# Sweep the whole movement segment so a fast dash cannot skip the player.
	var player_ground: Vector3 = target.global_position
	player_ground.y = start.y
	var closest := Geometry3D.get_closest_point_to_segment(player_ground, start, finish)
	if not dash_hit and closest.distance_to(player_ground) <= hit_radius + 0.42:
		target.take_damage(28)
		dash_hit = true
	global_position = finish
	dash_left = maxf(0, dash_left - step)
	model.rotation.x = 0.16
	model.rotation.z = sin(age * 45) * 0.025
	if absf(finish.x) >= 23 or absf(finish.z) >= 23:
		dash_left = 0
	if dash_left <= 0:
		recovery_left = dash_recovery
		model.rotation.x = 0
		model.rotation.z = 0

func cancel_attacks() -> void:
	casting.hide()
	warning_left=0
	dash_left=0
	recovery_left=0
	flash_left=0
	quake_flash=0
	for marker in [warning_ring,aim_line,dash_marker,active_area,quake_warning,quake_area,quake_ice]: marker.hide()
	for arm in arms: arm.rotation.x=0
func _enter_phase_two() -> void:
	if enraged or dead: return
	enraged=true
	cancel_attacks()
	phase_armor.show()
	attack_cooldown=2.0
	phase_attack_index=0
	phase_changed.emit()
func take_damage(amount: int) -> void:
	if cinematic_locked: return
	super.take_damage(amount)
	if not dead and health<=max_health/2 and not enraged: _enter_phase_two()

func sample_quake_center(center: Vector3) -> Vector3:
	var random: RandomNumberGenerator=get_parent().get_parent().rng
	for attempt in range(16):
		var a:=random.randf_range(0,TAU)
		var r:=sqrt(random.randf())*2.5
		var point:=center+Vector3(cos(a),0,sin(a))*r
		if absf(point.x)<=23 and absf(point.z)<=23: return point
	return center
func danger_contains(point: Vector3) -> bool:
	if warning_left>0 and attack_kind=="quake": return point.distance_to(quake_center)<9.5
	if quake_flash>0 and point.distance_to(quake_center)<9.5: return true
	if attack_kind=="slam" and (warning_left>0 or flash_left>0): return point.distance_to(global_position)<SLAM_RADIUS+0.5
	if dash_left>0 or (warning_left>0 and attack_kind=="dash"):
		return Geometry3D.get_closest_point_to_segment(point,global_position,global_position+locked_direction*dash_distance).distance_to(point)<hit_radius+0.7
	return false
