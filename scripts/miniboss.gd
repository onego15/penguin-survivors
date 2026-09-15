extends "res://scripts/enemy.gd"

var encounter := 0
var boss_name := ""
var stomp_cooldown := 6.0
var stomp_warning := 0.0
var stomp_radius := 4.2
var stomp_ring: MeshInstance3D
var stomp_flash := 0.0


func _ready() -> void:
	is_miniboss = true
	kind = Kind.BOAR if encounter % 2 == 0 else Kind.TURTLE
	visual_scale = 1.9
	damage_multiplier = 1.0
	windup_duration = 1.2
	recovery_duration = 1.6
	super._ready()
	health = 100 + encounter * 80
	max_health = health
	contact_damage = 18 + mini(encounter * 2, 10)
	boss_name = "牙王・ブリストル" if kind == Kind.BOAR else "甲羅王・モスバック"
	# Crown and a gold collar distinguish bosses from enlarged ordinary animals.
	for index in range(5):
		var angle := TAU * index / 5.0
		var point := Vector3(cos(angle) * 0.28, 1.75 if kind == Kind.BOAR else 1.2, 0.4 + sin(angle) * 0.28)
		Visuals.rod(model, Color("ffd482"), point, point + Vector3(0, 0.4, 0), 0.12, 0.0)
	Visuals.ring(model, Color("ffd482"), Vector3(0, 0.7, 0), 0.8, 0.06)
	stomp_ring = Visuals.ring(self, Color("ffad6b"), Vector3(0, 0.05, 0), stomp_radius, 0.075)
	stomp_ring.hide()
	add_to_group("minibosses")


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target):
		return
	if stomp_warning > 0:
		stomp_warning = maxf(0, stomp_warning - delta)
		model.rotation.z = sin(stomp_warning * 36) * 0.035
		if stomp_warning <= 0:
			var offset := target.global_position - global_position
			offset.y = 0
			if offset.length() <= stomp_radius + 0.42:
				target.take_damage(22 + mini(encounter * 2, 10))
			stomp_flash = 0.3
			stomp_cooldown = 7.0
		return
	super._physics_process(delta)
	stomp_flash = maxf(0, stomp_flash - delta)
	if stomp_flash <= 0:
		stomp_ring.hide()
	stomp_cooldown -= delta
	if stomp_cooldown <= 0 and global_position.distance_to(target.global_position) < 6.0 and (kind == Kind.TURTLE or charge_state == ChargeState.APPROACH):
		stomp_warning = 1.25
		stomp_ring.show()
