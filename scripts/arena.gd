extends RefCounted

const V = preload("res://scripts/visuals.gd")


static func build(parent: Node3D) -> void:
	var world := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("233f50")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c4e2ef")
	settings.ambient_light_energy = 0.3
	world.environment = settings
	parent.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	parent.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 140, 0)
	fill.light_color = Color("9dcfef")
	fill.light_energy = 0.12
	parent.add_child(fill)
	var ground := BoxMesh.new()
	ground.size = Vector3(51, 0.8, 51)
	V.mesh(parent, ground, Color("91afb9"), Vector3(0, -0.4, 0))
	# Flat snow flecks replace the prototype grid without hiding silhouettes.
	var random := RandomNumberGenerator.new()
	random.seed = 84721
	for index in range(90):
		var point := Vector3(random.randf_range(-24, 24), 0.012, random.randf_range(-24, 24))
		V.ellipsoid(parent, Color("a9c5cc"), point, Vector3(random.randf_range(0.1, 0.35), 0.012, random.randf_range(0.1, 0.35)))
	for side in [-1.0, 1.0]:
		for index in range(13):
			var along := -24.0 + index * 4.0
			for point in [Vector3(along, 0, side * 25), Vector3(side * 25, 0, along)]:
				V.ellipsoid(parent, Color("eaf1ed"), point, Vector3(1.5, random.randf_range(0.25, 0.6), 1.1))
	for index in range(28):
		var angle := TAU * index / 28.0
		var point := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(30, 35)
		pine(parent, point, random.randf_range(0.8, 1.5))
	for corner in [Vector3(-23, 0, -23), Vector3(23, 0, -23), Vector3(-23, 0, 23), Vector3(23, 0, 23)]:
		V.ellipsoid(parent, Color("8ba9b4"), corner, Vector3(1.2, 0.7, 1))
		V.rod(parent, Color("769cb0"), corner, corner + Vector3(0, 1.8, 0), 0.22)
		V.ellipsoid(parent, Color("ffe6a5"), corner + Vector3(0, 1.9, 0), Vector3(0.35, 0.45, 0.35))


static func pine(parent: Node3D, point: Vector3, size: float) -> void:
	var tree := V.pivot(parent, "Pine", point)
	tree.scale = Vector3.ONE * size
	V.rod(tree, Color("7c6d60"), Vector3.ZERO, Vector3(0, 2, 0), 0.18)
	for index in range(3):
		var bottom := 0.8 + index * 0.75
		var radius := 1.2 - index * 0.25
		V.rod(tree, Color("426c71"), Vector3(0, bottom, 0), Vector3(0, bottom + 1.8, 0), radius, 0.0)
		V.rod(tree, Color("e4eeea"), Vector3(0, bottom + 0.38, 0), Vector3(0, bottom + 1.82, 0), radius * 0.82, 0.0)
