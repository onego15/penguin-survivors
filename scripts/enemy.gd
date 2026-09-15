extends Node3D

signal defeated
signal rewarded(amount: int)
const Visuals = preload("res://scripts/visuals.gd")
const Models = preload("res://scripts/character_models.gd")
const Effects = preload("res://scripts/hit_effect.gd")
enum Kind { FOX, RABBIT, BOAR, TURTLE, OWL, WOLF, SKUNK, HEDGEHOG, MOLE, DEER }
enum ChargeState { APPROACH, WINDUP, CHARGE, RECOVER }
const STATS := [
	{"health": 2, "speed": 1.1, "radius": 0.58, "damage": 10, "color": Color("de743a")},
	{"health": 2, "speed": 1.05, "radius": 0.55, "damage": 10, "color": Color("dfc7ef")},
	{"health": 5, "speed": 0.85, "radius": 0.8, "damage": 18, "color": Color("a77362")},
	{"health": 8, "speed": 0.48, "radius": 0.85, "damage": 12, "color": Color("72a27a")},
	{"health": 4, "speed": 0.8, "radius": 0.6, "damage": 10, "color": Color("ad8cbb")},
	{"health": 4, "speed": 1.1, "radius": 0.65, "damage": 10, "color": Color("7b9fb9")},
	{"health": 5, "speed": 0.8, "radius": 0.6, "damage": 10, "color": Color("555275")},
	{"health": 7, "speed": 0.5, "radius": 0.7, "damage": 10, "color": Color("b89969")},
	{"health": 5, "speed": 0.65, "radius": 0.6, "damage": 10, "color": Color("a68182")},
	{"health": 10, "speed": 0.65, "radius": 0.8, "damage": 10, "color": Color("ccad79")},
]
const NAMES := ["キツネ", "ウサギ", "イノシシ", "カメ", "フクロウ", "オオカミ", "スカンク", "ハリネズミ", "モグラ", "シカ"]
const ROLES := ["ジグザグ接近", "跳躍", "直線突進", "高耐久", "遠距離射撃", "回り込み", "危険範囲設置", "放射状射撃", "潜行・奇襲", "角から遠距離の衝撃波"]
static func cost(type: int) -> int:
	return 3 if type == Kind.DEER else (2 if type >= Kind.OWL else 1)

@export_enum("Fox", "Rabbit", "Boar", "Turtle", "Owl", "Wolf", "Skunk", "Hedgehog", "Mole", "Deer") var kind: int = Kind.FOX
var target: Node3D
var speed := 2.3
var health := 2
var max_health := 2
var hit_radius := 0.58
var dead := false
var targetable := true
var reward_value := 1
var model: Node3D
var age := 0.0
var movement_phase := 0.0
var hop_phase := 0.0
var hop_direction := Vector3.ZERO
var charge_state := ChargeState.APPROACH
var state_time := 0.0
var charge_direction := Vector3.ZERO
var charge_marker: Node3D
var health_fill: MeshInstance3D
var health_bar: Node3D
var hurt_time := 0.0
var health_multiplier := 1.0
var damage_multiplier := 1.0
var contact_damage := 10
var visual_scale := 1.0
var is_miniboss := false
var windup_duration := 0.8
var recovery_duration := 1.1


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("all_enemies")
	reward_value = cost(kind)
	health = maxi(1, roundi(STATS[kind].health * health_multiplier))
	max_health = health
	hit_radius = STATS[kind].radius * visual_scale
	contact_damage = maxi(1, roundi(STATS[kind].damage * damage_multiplier))
	model = Models.animal(self, kind)
	model.scale = Vector3.ONE * visual_scale
	health_bar = Visuals.pivot(self, "HealthBar", Vector3(0, 2.8 if kind == Kind.RABBIT else 2.3, 0))
	var backdrop := BoxMesh.new()
	backdrop.size = Vector3(1.04, 0.085, 0.07)
	Visuals.mesh(health_bar, backdrop, Color("263d50"))
	var fill := BoxMesh.new()
	fill.size = Vector3(1, 0.06, 0.08)
	health_fill = Visuals.mesh(health_bar, fill, Color("ffab81"), Vector3(0, 0.005, 0.015))
	health_bar.visible = false
	if is_miniboss:
		health_bar.position.y = 4.0
	if kind == Kind.BOAR:
		charge_marker = preload("res://scripts/combat_visuals.gd").warning(self,hit_radius,6.0)
		charge_marker.visible = false


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	age += delta
	hurt_time = maxf(0.0, hurt_time - delta)
	var offset := target.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var toward := offset.normalized()
	var motion := Vector3.ZERO
	match kind:
		Kind.FOX:
			var sideways := Vector3(-toward.z, 0, toward.x)
			motion = (toward + sideways * sin(age * 4.2 + movement_phase) * 0.85).normalized() * speed * STATS[kind].speed
		Kind.RABBIT:
			# A hop commits to a direction, followed by a stationary landing pause.
			hop_phase += delta
			if hop_phase >= 1.05:
				hop_phase = fmod(hop_phase, 1.05)
				hop_direction = toward
			if hop_direction == Vector3.ZERO:
				hop_direction = toward
			if hop_phase < 0.62:
				motion = hop_direction * speed * STATS[kind].speed * 2.0
		Kind.BOAR:
			motion = _boar_motion(delta, toward, distance)
		Kind.TURTLE:
			motion = toward * speed * STATS[kind].speed
	# Gentle separation keeps packs from completely overlapping.
	if kind == Kind.TURTLE or kind == Kind.FOX:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other == self or other.dead:
				continue
			var separation: Vector3 = global_position - other.global_position
			var gap := separation.length()
			if gap > 0.01 and gap < hit_radius + other.hit_radius:
				motion += separation / gap * 0.6
	if distance < 0.15 and kind != Kind.BOAR:
		motion = Vector3.ZERO
	_move_and_contact(delta, motion)


func _move_and_contact(delta: float, motion: Vector3) -> void:
	var start := global_position
	global_position += motion * delta
	position.x = clampf(position.x, -24, 24)
	position.z = clampf(position.z, -24, 24)
	if motion.length_squared() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(motion.x, motion.z), 1.0 - exp(-delta * 12.0))
	_animate(motion.length())
	# Sweep contact so a fast charge cannot skip the player.
	var closest := Geometry3D.get_closest_point_to_segment(target.global_position, start, global_position)
	if closest.distance_to(target.global_position) < hit_radius + 0.42:
		target.take_damage(contact_damage)


func _boar_motion(delta: float, toward: Vector3, distance: float) -> Vector3:
	state_time += delta
	match charge_state:
		ChargeState.APPROACH:
			if distance < 9.0 and state_time > 1.2:
				charge_state = ChargeState.WINDUP
				state_time = 0.0
				charge_direction = toward
				charge_marker.position = charge_direction * 3.0 + Vector3(0, 0.035, 0)
				charge_marker.rotation.y = atan2(toward.x, toward.z)
				charge_marker.show()
				return Vector3.ZERO
			return toward * speed * STATS[kind].speed
		ChargeState.WINDUP:
			preload("res://scripts/combat_visuals.gd").progress(charge_marker,1-state_time/windup_duration)
			if state_time >= windup_duration:
				charge_state = ChargeState.CHARGE
				state_time = 0.0
				charge_marker.hide()
			return Vector3.ZERO
		ChargeState.CHARGE:
			if state_time >= 0.85:
				charge_state = ChargeState.RECOVER
				state_time = 0.0
				return Vector3.ZERO
			return charge_direction * speed * 3.8
		ChargeState.RECOVER:
			if state_time >= recovery_duration:
				charge_state = ChargeState.APPROACH
				state_time = 0.0
	return Vector3.ZERO


func _animate(motion_speed: float) -> void:
	var walking := minf(motion_speed / 2.0, 1.0)
	model.position.y = absf(sin(age * 10.0)) * 0.045 * walking
	model.rotation.z = sin(age * 8.0) * 0.04 * walking
	model.rotation.x = 0.0
	if kind == Kind.RABBIT:
		var progress := clampf(hop_phase / 0.62, 0, 1)
		model.position.y = sin(progress * PI) * 0.65
		model.rotation.x = sin(progress * TAU) * 0.15
		model.get_node("Head/EarLeft").rotation.x = sin(progress * TAU) * 0.2
		model.get_node("Head/EarRight").rotation.x = sin(progress * TAU + 0.3) * 0.2
	if kind == Kind.FOX:
		model.get_node("Tail").rotation.y = sin(age * 5.0 + movement_phase) * 0.4
	if kind == Kind.BOAR and charge_state == ChargeState.WINDUP:
		model.rotation.z = sin(age * 45.0) * 0.035
		model.rotation.x = -0.13
	for part in model.get_children():
		if str(part.name).begins_with("Paw_"):
			part.rotation.x = sin(age * 10.0 + part.position.x * 5.0 + part.position.z * 4.0) * 0.35 * walking
	model.scale = Vector3(1.0 + hurt_time * 0.7, 1.0 - hurt_time * 0.6, 1.0 + hurt_time * 0.7) * visual_scale


func take_damage(amount: int) -> void:
	if dead or not targetable:
		return
	health -= amount
	get_tree().call_group("game_audio", "play_effect", "defeat" if health <= 0 else "hit")
	hurt_time = 0.16
	health_bar.show()
	var fraction := maxf(0.0, float(health) / max_health)
	health_fill.scale.x = fraction
	health_fill.position.x = (fraction - 1.0) * 0.5
	var effect := Effects.new()
	effect.position = position + Vector3(0, 0.85, 0)
	effect.tint = STATS[kind].color if health <= 0 else Color("b5f5ff")
	effect.burst = health <= 0
	get_parent().add_child(effect)
	if health <= 0:
		dead = true
		remove_from_group("enemies")
		remove_from_group("all_enemies")
		rewarded.emit(reward_value)
		defeated.emit()
		queue_free()
