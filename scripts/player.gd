extends CharacterBody3D

const Visuals = preload("res://scripts/visuals.gd")
const Models = preload("res://scripts/character_models.gd")
signal damage_received(amount: int)
var training_invincible := false
const SPEED := 7.0
const ARENA_LIMIT := 23.0
var character_id:=preload("res://scripts/character_roster.gd").selected()
var has_frost:=true
var ultimate_pose:=0.0
var cinematic_locked := false
var health := 100
var invulnerability := 0.0
var support_damage_multiplier := 1.0
var body: Node3D
var weapon_pivot: Node3D
var frost_weapon: Node3D
var weapon: Node3D
var muzzle_flash: MeshInstance3D
var gait := 0.0
var recoil := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	body = Models.penguin(self,character_id)
	weapon_pivot = Visuals.pivot(self, "WeaponAim", Vector3(0, 1.0, 0))
	weapon = Models.blaster(weapon_pivot) if character_id=="classic" else Models.heart_wand(weapon_pivot)
	if character_id=="classic": frost_weapon=weapon
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
	var before_move:=global_position
	move_and_slide()
	var obstacle=preload("res://scripts/castle_obstacles.gd").world(self)
	if obstacle!=null:
		var finish:=global_position
		global_position=before_move
		global_position=obstacle.move_actor(self,finish,0.45)
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
	ultimate_pose=maxf(0,ultimate_pose-delta)
	if ultimate_pose>0:
		body.get_node("WingLeft").rotation.z=-1.1
		body.get_node("WingRight").rotation.z=1.1
	recoil = maxf(0, recoil - delta * 7.0)
	weapon.position.z = 0.12 - recoil * 0.15
	weapon.rotation.x = -recoil * 0.12
	weapon.position.y=0
	if character_id=="pink" and ultimate_pose>0:
		weapon.position.y=0.65
		weapon.rotation.x=-0.25
	muzzle_flash.visible = has_frost and recoil > 0.65
	muzzle_flash.scale = Vector3.ONE * (0.12 + recoil * 0.16)


func aim_at(target_position: Vector3) -> void:
	var direction := target_position - global_position
	weapon_pivot.rotation.y = atan2(direction.x, direction.z)


func facing_direction() -> Vector3:
	var forward := body.global_basis.z
	forward.y = 0
	return forward.normalized()


func muzzle_position() -> Vector3:
	return frost_weapon.to_global(Vector3(0,0,0.85)) if is_instance_valid(frost_weapon) else weapon.global_position


func fire_feedback() -> void:
	recoil = 1.0


func take_damage(amount: int) -> void:
	if cinematic_locked or training_invincible: return
	if invulnerability > 0.0 or health <= 0:
		return
	var original:=maxi(0,amount)
	amount = maxi(1, ceili(amount * support_damage_multiplier))
	if support_damage_multiplier<1:
		preload("res://scripts/contributions.gd").record(self,"support:1","prevented",mini(health,original)-mini(health,amount))
	damage_received.emit(mini(health,amount))
	health = maxi(0, health - amount)
	get_tree().call_group("game_audio", "play_effect", "hurt")
	invulnerability = 0.8


func heal(amount: int) -> void:
	if health > 0:
		health = mini(100, health + maxi(0, amount))

func equip_frost() -> void:
	has_frost=true
	if character_id=="pink" and not weapon_pivot.has_node("FrostfinBlaster"):
		var gun:=Models.blaster(weapon_pivot)
		gun.position=Vector3(-0.8,0,0.12)
		frost_weapon=gun
		muzzle_flash.reparent(gun,false)
		muzzle_flash.position=Vector3(0,0,0.85)
