extends Node3D
## Open this scene and press F6 to inspect the models at a larger scale.

const V = preload("res://scripts/visuals.gd")
const Models = preload("res://scripts/character_models.gd")
var models: Array[Node3D] = []
var time := 0.0


func _ready() -> void:
	preload("res://scripts/arena.gd").build(self)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5
	camera.position = Vector3(0, 12, 23)
	add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0))
	camera.current = true
	var hero := V.pivot(self, "HeroDisplay", Vector3(-5.3, 0.15, 0.1))
	hero.scale = Vector3.ONE * 1.65
	models.append(Models.penguin(hero))
	var gun := Models.blaster(hero)
	gun.position = Vector3(0.9, 0.95, 0.1)
	gun.rotation.y = 0.3
	_plinth(Vector3(-5.3, 0, 0.1), 1.95)
	_label("EMPEROR PENGUIN", Vector3(-5.3, 0.3, 2.1), 40)
	_label("Round glasses + Frostfin blaster", Vector3(-5.3, -0.02, 2.8), 26)
	var positions := [Vector3(-0.3, 0.15, -4.4), Vector3(4.4, 0.15, -4.4), Vector3(-0.3, 0.15, 3.0), Vector3(4.4, 0.15, 3.0)]
	var labels := ["FOX / ZIGZAG", "RABBIT / HOP", "BOAR / CHARGE", "TURTLE / TANK"]
	for kind in range(4):
		var stand := V.pivot(self, "AnimalDisplay", positions[kind])
		stand.scale = Vector3.ONE * 1.2
		models.append(Models.animal(stand, kind))
		_plinth(positions[kind] - Vector3(0, 0.15, 0), 1.65)
		_label(labels[kind], positions[kind] + Vector3(0, 0.1, 1.8), 34)
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "PENGUIN SURVIVORS"
	title.position = Vector2(36, 24)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("213e50"))
	layer.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "CHARACTER COLLECTION"
	subtitle.position = Vector2(38, 66)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("456a7b"))
	layer.add_child(subtitle)


func _plinth(point: Vector3, radius: float) -> void:
	V.rod(self, Color("a2c5ce"), point - Vector3(0, 0.2, 0), point + Vector3(0, 0.05, 0), radius)
	V.rod(self, Color("f0f4e9"), point + Vector3(0, 0.05, 0), point + Vector3(0, 0.14, 0), radius * 0.95)


func _label(caption: String, point: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font_size = font_size
	label.pixel_size = 0.008
	label.outline_size = 0
	label.modulate = Color("24485a")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = point
	add_child(label)


func _process(delta: float) -> void:
	time += delta
	for model in models:
		model.rotation.y = sin(time * 0.65) * 0.3 - 0.18
