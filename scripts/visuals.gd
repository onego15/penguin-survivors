extends RefCounted

static var materials: Dictionary = {}
static var unit_sphere: SphereMesh


static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.72
		materials[color] = result
	return materials[color]


static func mesh(parent: Node3D, shape: Mesh, color: Color, offset := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = material(color)
	instance.position = offset
	parent.add_child(instance)
	return instance


static func sphere(radius: float) -> SphereMesh:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 16
	shape.rings = 8
	return shape


static func ellipsoid(parent: Node3D, color: Color, offset: Vector3, size: Vector3) -> MeshInstance3D:
	if unit_sphere == null:
		unit_sphere = sphere(1.0)
	var part := mesh(parent, unit_sphere, color, offset)
	part.scale = size
	return part


static func pivot(parent: Node3D, label: String, offset := Vector3.ZERO) -> Node3D:
	var part := Node3D.new()
	part.name = label
	part.position = offset
	parent.add_child(part)
	return part


static func rod(parent: Node3D, color: Color, start: Vector3, finish: Vector3, radius: float, tip_radius := -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if tip_radius < 0.0 else tip_radius
	shape.height = start.distance_to(finish)
	shape.radial_segments = 12
	var part := mesh(parent, shape, color, (start + finish) * 0.5)
	part.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	return part


static func ring(parent: Node3D, color: Color, offset: Vector3, radius: float, thickness: float, vertical := false) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 24
	shape.ring_segments = 8
	var part := mesh(parent, shape, color, offset)
	if vertical:
		part.rotation.x = PI / 2.0
	return part
