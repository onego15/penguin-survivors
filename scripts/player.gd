extends CharacterBody3D

const Visuals = preload("res://scripts/visuals.gd")
const Models = preload("res://scripts/character_models.gd")
const SPEED := 7.0
const ARENA_LIMIT := 23.0
var health := 100
var invulnerability := 0.0
var body: Node3D
var weapon_pivot: Node3D
var weapon: Node3D
var muzzle_flash: MeshInstance3D
var gait := 0.0
var recoil := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	body = Models.penguin(self)
	weapon_pivot = Visuals.pivot(self, "WeaponAim", Vector3(0, 1.0, 0))
	weapon = Models.blaster(weapon_pivot)
	weapon.position = Vector3(0.83, 0, 0.12)
	muzzle_flash = Visuals.ellipsoid(weapon, Color("ceffff"), Vector3(0, 0, 0.85), Vector3.ONE * 0.22)
	muzzle_flash.visible = false
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.5
	collider.shape = shape
	collider.position.y = 0.75
	add_child(collider)


func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)
	body.visible = invulnerability <= 0.0 or int(invulnerability * 15.0) % 2 == 0
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input.x, 0, input.y) * SPEED
	move_and_slide()
	position.x = clampf(position.x, -ARENA_LIMIT, ARENA_LIMIT)
	position.z = clampf(position.z, -ARENA_LIMIT, ARENA_LIMIT)
	if velocity.length_squared() > 0.1:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-delta * 14.0))
	_animate(delta)


func _animate(delta: float) -> void:
	var moving := velocity.length() / SPEED
	gait += delta * (11.0 if moving > 0.1 else 2.0)
	body.position.y = absf(sin(gait)) * 0.09 * moving
	body.rotation.z = sin(gait) * 0.095 * moving
	body.get_node("Head").rotation.z = sin(gait) * 0.025
	body.get_node("WingLeft").rotation.z = -0.15 - sin(gait) * 0.17 * moving
	body.get_node("WingRight").rotation.z = 0.15 - sin(gait) * 0.17 * moving
	body.get_node("FootLeft").rotation.x = sin(gait) * 0.4 * moving
	body.get_node("FootRight").rotation.x = -sin(gait) * 0.4 * moving
	recoil = maxf(0, recoil - delta * 7.0)
	weapon.position.z = 0.12 - recoil * 0.15
	weapon.rotation.x = -recoil * 0.12
	muzzle_flash.visible = recoil > 0.65
	muzzle_flash.scale = Vector3.ONE * (0.12 + recoil * 0.16)


func aim_at(target_position: Vector3) -> void:
	var direction := target_position - global_position
	weapon_pivot.rotation.y = atan2(direction.x, direction.z)


func muzzle_position() -> Vector3:
	return weapon.to_global(Vector3(0, 0, 0.85))


func fire_feedback() -> void:
	recoil = 1.0


func take_damage(amount: int) -> void:
	if invulnerability > 0.0 or health <= 0:
		return
	health = maxi(0, health - amount)
	invulnerability = 0.8
