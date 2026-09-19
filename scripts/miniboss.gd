extends "res://scripts/enemy.gd"

const Bolt = preload("res://scripts/boss_projectile.gd")
const ROSTER := [
	{"kind": Kind.BOAR, "name": "牙王・ブリストル", "speed": 2.4, "scale": 1.9, "color": Color("ffd482")},
	{"kind": Kind.TURTLE, "name": "甲羅王・モスバック", "speed": 3.0, "scale": 1.9, "color": Color("80dfce")},
	{"kind": Kind.FOX, "name": "狐姫・アンバー", "speed": 2.7, "scale": 1.8, "color": Color("f59eae")},
	{"kind": Kind.RABBIT, "name": "月兎・ルナ", "speed": 2.5, "scale": 1.6, "color": Color("c7abff")},
]
var encounter := 0
var boss_name := ""
var stomp_cooldown := 6.0
var stomp_warning := 0.0
var stomp_radius := 4.2
const C = preload("res://scripts/combat_visuals.gd")
var active_area: Node3D
var stomp_ring: Node3D
var stomp_flash := 0.0
var guard_left := 0.0
var guard_cooldown := 5.0
var guard_ring: MeshInstance3D
var special_cooldown := 2.5
var special_warning := 0.0
var special_direction := Vector3.FORWARD
var aim_marker: Node3D
var rabbit_state := "pursue"
var jump_start := Vector3.ZERO
var jump_target := Vector3.ZERO
var jump_elapsed := 0.0


func _ready() -> void:
	is_miniboss = true
	var entry: Dictionary = ROSTER[clampi(encounter, 0, ROSTER.size() - 1)]
	kind = entry.kind
	visual_scale = entry.scale
	damage_multiplier = 1.0
	windup_duration = 1.2
	recovery_duration = 1.6
	super._ready()
	health = 100 + encounter * 80
	max_health = health
	contact_damage = 18 + mini(encounter * 2, 10)
	boss_name = entry.name
	# Crown and a gold collar distinguish bosses from enlarged ordinary animals.
	for index in range(5):
		var angle := TAU * index / 5.0
		var point := Vector3(cos(angle) * 0.28, 1.2 if kind == Kind.TURTLE else 1.65, 0.4 + sin(angle) * 0.28)
		Visuals.rod(model, entry.color, point, point + Vector3(0, 0.4, 0), 0.12, 0.0)
	Visuals.ring(model, entry.color, Vector3(0, 0.7, 0), 0.8, 0.06)
	if kind == Kind.RABBIT:
		stomp_radius = 3.2
	stomp_ring = C.warning(self,stomp_radius)
	active_area=C.danger(self,stomp_radius)
	active_area.hide()
	stomp_ring.hide()
	guard_ring = Visuals.ring(self, Color("d6b184"), Vector3(0, 0.15, 0), 1.9, 0.11)
	guard_ring.hide()
	aim_marker=C.warning(self,0.3,7.0)
	aim_marker.hide()
	add_to_group("minibosses")


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	if kind == Kind.FOX:
		_fox_attack(delta)
		return
	if kind == Kind.RABBIT:
		_rabbit_attack(delta)
		return
	if kind == Kind.TURTLE:
		guard_left = maxf(0, guard_left - delta)
		guard_cooldown -= delta
		if guard_cooldown <= 0:
			guard_left = 2.4
			guard_cooldown = 8.0
		guard_ring.visible = guard_left > 0
	if stomp_warning > 0:
		stomp_warning = maxf(0, stomp_warning - delta)
		C.progress(stomp_ring,stomp_warning/1.25)
		model.rotation.z = sin(stomp_warning * 36) * 0.035
		if stomp_warning <= 0:
			var offset := target.global_position - global_position
			offset.y = 0
			if offset.length() <= stomp_radius + 0.42:
				if preload("res://scripts/castle_obstacles.gd").visible_between(self,global_position,target.global_position): target.take_damage(22 + mini(encounter * 2, 10),preload("res://scripts/difficulty_tiers.gd").source(self))
			stomp_ring.hide()
			active_area.show()
			stomp_flash = 0.3
			stomp_cooldown = 7.0
		return
	super._physics_process(delta)
	stomp_flash = maxf(0, stomp_flash - delta)
	if stomp_flash <= 0:
		stomp_ring.hide()
		active_area.hide()
	stomp_cooldown -= delta
	if stomp_cooldown <= 0 and global_position.distance_to(target.global_position) < 6.0 and (kind == Kind.TURTLE or charge_state == ChargeState.APPROACH):
		stomp_warning = 1.25
		C.progress(stomp_ring,1)
		C.progress(stomp_ring,1)
		stomp_ring.show()


func _fox_attack(delta: float) -> void:
	if special_warning > 0:
		special_warning = maxf(0, special_warning - delta)
		C.progress(aim_marker,special_warning/0.85)
		if special_warning <= 0:
			aim_marker.hide()
			for index in range(3):
				var bolt := Bolt.new()
				bolt.target = target
				bolt.direction = special_direction.rotated(Vector3.UP, (index - 1) * 0.28)
				bolt.position = position + Vector3.UP + bolt.direction * 1.3
				bolt.speed = 5.0
				preload("res://scripts/difficulty_tiers.gd").inherit_attack(self,bolt)
				get_parent().add_child(bolt)
			special_cooldown = 4.5
		return
	super._physics_process(delta)
	special_cooldown -= delta
	if special_cooldown <= 0 and global_position.distance_to(target.global_position) < 12:
		special_direction = (target.global_position - global_position).normalized()
		if special_direction.length_squared() < 0.01:
			special_direction = Vector3.FORWARD
		special_warning = 0.85
		model.rotation.y = atan2(special_direction.x, special_direction.z)
		aim_marker.position = special_direction * 4.5 + Vector3(0, 0.05, 0)
		aim_marker.rotation.y = model.rotation.y
		C.progress(aim_marker,1)
		aim_marker.show()


func _rabbit_attack(delta: float) -> void:
	if rabbit_state == "warn":
		special_warning = maxf(0, special_warning - delta)
		C.progress(stomp_ring,(special_warning+0.7)/1.65)
		if special_warning <= 0:
			rabbit_state = "air"
			jump_elapsed = 0
		return
	if rabbit_state == "air":
		jump_elapsed += delta
		var progress := minf(1, jump_elapsed / 0.7)
		C.progress(stomp_ring,(0.7-jump_elapsed)/1.65)
		global_position = jump_start.lerp(jump_target, progress)
		model.position.y = sin(progress * PI) * 2.2
		model.rotation.x = sin(progress * PI) * 0.15
		stomp_ring.global_position = jump_target + Vector3(0, 0.05, 0)
		if progress >= 1:
			if global_position.distance_to(target.global_position) < stomp_radius + 0.42:
				if preload("res://scripts/castle_obstacles.gd").visible_between(self,global_position,target.global_position): target.take_damage(24,preload("res://scripts/difficulty_tiers.gd").source(self))
			stomp_ring.hide()
			active_area.position=Vector3(0,0.09,0)
			active_area.show()
			rabbit_state = "recover"
			special_warning = 1.4
			model.position.y = 0
			model.rotation.x = 0
		return
	if rabbit_state == "recover":
		special_warning -= delta
		if special_warning < 1.1:
			stomp_ring.hide()
			active_area.hide()
		if special_warning <= 0:
			rabbit_state = "pursue"
			special_cooldown = 2.8
		return
	super._physics_process(delta)
	special_cooldown -= delta
	if special_cooldown <= 0:
		jump_start = global_position
		var offset := target.global_position - jump_start
		offset.y = 0
		jump_target = jump_start + offset.limit_length(8.0)
		var obstacle=preload("res://scripts/castle_obstacles.gd").world(self)
		if obstacle!=null: jump_target=obstacle.sweep(jump_start,jump_target,hit_radius).point
		rabbit_state = "warn"
		special_warning = 0.95
		stomp_ring.global_position = jump_target + Vector3(0, 0.05, 0)
		C.progress(stomp_ring,1)
		stomp_ring.show()


func take_damage(amount: int) -> void:
	if kind == Kind.TURTLE and guard_left > 0 and amount > 0:
		amount = maxi(1, ceili(amount * 0.5))
	super.take_damage(amount)


func status_label() -> String:
	if guard_left > 0:
		return " / 甲羅防御"
	if rabbit_state == "warn":
		return " / 跳躍予告"
	if kind == Kind.FOX and special_warning > 0:
		return " / 扇状弾予告"
	return ""
