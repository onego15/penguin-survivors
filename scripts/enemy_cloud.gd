extends Node3D
const V = preload("res://scripts/visuals.gd")
var target: Node3D
var lifetime := 3.0
var radius := 1.4
var damage := 8
var age := 0.0
func _ready() -> void:
	add_to_group("enemy_clouds")
	V.ring(self,Color("a888b7"),Vector3(0,0.06,0),radius,0.05)
	for i in range(4):
		var puff := V.ellipsoid(self,Color(0.65,0.53,0.69,0.25),Vector3(cos(i*TAU/4)*0.6,0.25,sin(i*TAU/4)*0.6),Vector3(0.7,0.3,0.7))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.65,0.53,0.69,0.25)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff.material_override = mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func _physics_process(delta: float) -> void:
	age += delta
	if is_instance_valid(target) and danger_contains(target.global_position):
		target.take_damage(damage)
	if age >= lifetime:
		queue_free()
func danger_contains(point: Vector3) -> bool:
	return Vector2(point.x-position.x, point.z-position.z).length() <= radius + 0.42
