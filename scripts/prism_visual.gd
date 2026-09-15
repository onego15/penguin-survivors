extends Node3D
## Layered beam works with Compatibility: no screen-space glow dependency.
const V = preload("res://scripts/visuals.gd")
var direction := Vector3.FORWARD
var length := 12.0
var sparks: Array[MeshInstance3D] = []
var collars: Array[MeshInstance3D] = []
var layers: Array[MeshInstance3D] = []
var crystal: Node3D

static func light_material(color: Color, additive := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 1.4
	if additive:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.no_depth_test = false
	return mat

static func build_crystal(parent: Node3D) -> Node3D:
	var root := V.pivot(parent, "PrismCrystal")
	for sign_y in [-1, 1]:
		var mesh := CylinderMesh.new()
		mesh.radial_segments = 6
		mesh.height = 0.45
		mesh.bottom_radius = 0.22 if sign_y > 0 else 0.0
		mesh.top_radius = 0.0 if sign_y > 0 else 0.22
		var part := V.mesh(root, mesh, Color("89dfff"), Vector3(0, sign_y * 0.225, 0))
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("9dcfff") if sign_y > 0 else Color("9673df")
		mat.metallic = 0.5
		mat.roughness = 0.18
		mat.emission_enabled = true
		mat.emission = Color("153d63")
		part.material_override = mat
	V.ring(root, Color("ffdc91"), Vector3.ZERO, 0.31, 0.04)
	return root

func _ready() -> void:
	# White core, cyan body and translucent violet halo use the same hit-width envelope.
	for spec in [[0.43, Color(0.55, 0.22, 1, 0.16)], [0.23, Color(0.2, 0.85, 1, 0.35)], [0.07, Color("fff9ff")]]:
		var rod := V.rod(self, spec[1], Vector3.ZERO, direction * length, spec[0], spec[0] * 0.5)
		rod.material_override = light_material(spec[1], spec[0] > 0.1)
		rod.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		layers.append(rod)
	crystal = build_crystal(self)
	crystal.scale = Vector3.ONE * 1.5
	for index in range(4):
		var ring := V.ring(self, Color("a3f2ff"), direction * (index * 3.0 + 0.5), 0.44, 0.025)
		ring.quaternion = Quaternion(Vector3.UP, direction)
		ring.material_override = light_material(Color(0.5, 0.85, 1, 0.55), true)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		collars.append(ring)
	for index in range(12):
		var spark := V.ellipsoid(self, Color.WHITE, Vector3.ZERO, Vector3.ONE * 0.065)
		spark.material_override = light_material(Color("ffe9fc") if index % 2 else Color("89eeff"))
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.append(spark)
	animate(0, 1.3)

func animate(age: float, duration: float) -> void:
	var side := direction.cross(Vector3.UP).normalized()
	var fade := minf(1, maxf(0.03, (duration - age) / 0.2))
	for layer in layers:
		var width := (0.93 + sin(age * 24) * 0.07) * fade
		layer.scale = Vector3(width, 1, width)
	crystal.rotation.y = age * 3
	for index in range(collars.size()):
		collars[index].position = direction * fposmod(index * 3 + age * 7, length)
		collars[index].scale = Vector3.ONE * fade
	for index in range(sparks.size()):
		var distance := fposmod(index + age * 12, length)
		var angle := age * 8 + index * 2.4
		sparks[index].position = direction * distance + (side * cos(angle) + Vector3.UP * sin(angle)) * 0.38
		sparks[index].scale = Vector3.ONE * (0.035 + 0.035 * sin(index + age * 18)) * fade
