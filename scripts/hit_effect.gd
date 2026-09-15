extends Node3D

const V = preload("res://scripts/visuals.gd")
var tint := Color("b5f5ff")
var burst := false
var time := 0.0
var pieces: Array[MeshInstance3D] = []


func _ready() -> void:
	for index in range(9 if burst else 4):
		var part := V.ellipsoid(self, tint, Vector3.ZERO, Vector3.ONE * (0.13 if burst else 0.07))
		pieces.append(part)


func _physics_process(delta: float) -> void:
	time += delta
	for index in range(pieces.size()):
		var angle := TAU * index / pieces.size()
		pieces[index].position = Vector3(cos(angle) * time * 2.7, sin(time * PI * 2.0) * 0.55, sin(angle) * time * 2.7)
		pieces[index].scale = Vector3.ONE * maxf(0, 1.0 - time * 2.2) * (0.13 if burst else 0.07)
	if time > 0.45:
		queue_free()
