extends RefCounted
## Hand-built toy-like models. All faces point along local +Z.
## Named pivots provide animation joints without external assets or a skeleton.

const V = preload("res://scripts/visuals.gd")
const INK := Color("182a40")
const CREAM := Color("fff1d5")
const WHITE := Color("f7fcff")
const GOLD := Color("ffbf4d")
const TEAL := Color("269ca8")


static func eyes(parent: Node3D, spread: float, height: float, depth: float, radius := 0.075) -> void:
	for side in [-1.0, 1.0]:
		V.ellipsoid(parent, INK, Vector3(side * spread, height, depth), Vector3(radius, radius * 1.15, radius * 0.65))
		V.ellipsoid(parent, WHITE, Vector3(side * spread - radius * 0.2, height + radius * 0.35, depth + radius * 0.6), Vector3.ONE * radius * 0.3)


static func penguin(parent: Node3D) -> Node3D:
	var root := V.pivot(parent, "Penguin")
	V.ellipsoid(root, INK, Vector3(0, 0.77, 0), Vector3(0.61, 0.74, 0.48))
	V.ellipsoid(root, WHITE, Vector3(0, 0.79, 0.33), Vector3(0.47, 0.58, 0.23))
	# Golden breast and ear patches distinguish an emperor penguin.
	V.ellipsoid(root, GOLD, Vector3(0, 1.22, 0.36), Vector3(0.33, 0.23, 0.12))
	V.ellipsoid(root, CREAM, Vector3(0, 1.12, 0.43), Vector3(0.29, 0.19, 0.1))
	var head := V.pivot(root, "Head", Vector3(0, 1.73, 0))
	V.ellipsoid(head, INK, Vector3.ZERO, Vector3(0.67, 0.63, 0.56))
	for side in [-1.0, 1.0]:
		V.ellipsoid(head, GOLD, Vector3(side * 0.55, -0.16, 0.13), Vector3(0.14, 0.29, 0.28))
		V.ellipsoid(head, WHITE, Vector3(side * 0.265, 0.045, 0.46), Vector3(0.25, 0.28, 0.12))
		V.ellipsoid(head, Color("f4b4a1"), Vector3(side * 0.39, -0.15, 0.52), Vector3(0.11, 0.055, 0.035))
		# Thick circular rims and arms are geometry, so the glasses read in silhouette.
		V.ring(head, Color("b47e36"), Vector3(side * 0.275, 0.065, 0.605), 0.235, 0.032, true)
		V.rod(head, Color("b47e36"), Vector3(side * 0.5, 0.08, 0.59), Vector3(side * 0.62, 0.02, 0.04), 0.025)
		V.rod(head, WHITE, Vector3(side * 0.275 - 0.1, 0.18, 0.625), Vector3(side * 0.275 - 0.045, 0.225, 0.625), 0.016)
	eyes(head, 0.265, 0.035, 0.583, 0.095)
	V.rod(head, Color("b47e36"), Vector3(-0.06, 0.1, 0.63), Vector3(0.06, 0.1, 0.63), 0.027)
	V.ellipsoid(head, Color("f3a238"), Vector3(0, -0.18, 0.6), Vector3(0.16, 0.095, 0.23))
	V.ellipsoid(head, INK, Vector3(0, -0.2, 0.78), Vector3(0.085, 0.028, 0.065))
	V.ring(root, TEAL, Vector3(0, 1.26, 0), 0.43, 0.095)
	var scarf := V.ellipsoid(root, TEAL, Vector3(-0.3, 0.98, 0.49), Vector3(0.13, 0.31, 0.065))
	scarf.rotation.z = -0.25
	V.ellipsoid(root, GOLD, Vector3(-0.3, 1.16, 0.57), Vector3(0.085, 0.085, 0.025))
	for side in [-1.0, 1.0]:
		var wing := V.pivot(root, "WingLeft" if side < 0 else "WingRight", Vector3(side * 0.5, 1.1, 0))
		V.ellipsoid(wing, INK, Vector3(side * 0.1, -0.3, 0), Vector3(0.18, 0.47, 0.16))
		var foot := V.pivot(root, "FootLeft" if side < 0 else "FootRight", Vector3(side * 0.28, 0.13, 0.16))
		V.ellipsoid(foot, Color("eeb14e"), Vector3.ZERO, Vector3(0.25, 0.12, 0.36))
		for toe in [-1.0, 0.0, 1.0]:
			V.ellipsoid(foot, GOLD, Vector3(toe * 0.12, 0, 0.24), Vector3(0.07, 0.07, 0.14))
	return root


static func blaster(parent: Node3D) -> Node3D:
	var root := V.pivot(parent, "FrostfinBlaster")
	V.ellipsoid(root, TEAL, Vector3(0, 0, 0.05), Vector3(0.25, 0.26, 0.48))
	V.ellipsoid(root, CREAM, Vector3(0, -0.13, 0.1), Vector3(0.2, 0.1, 0.34))
	V.rod(root, INK, Vector3(0, 0, 0.28), Vector3(0, 0, 0.7), 0.18)
	V.ring(root, GOLD, Vector3(0, 0, 0.55), 0.19, 0.035, true)
	V.ring(root, GOLD, Vector3(0, 0, 0.72), 0.17, 0.04, true)
	V.ellipsoid(root, Color("92f5ff"), Vector3(0, 0, 0.71), Vector3(0.13, 0.13, 0.03))
	V.rod(root, Color("68dbe5"), Vector3(0, 0.17, -0.1), Vector3(0, 0.46, -0.21), 0.15, 0.0)
	for side in [-1.0, 1.0]:
		var fin := V.ellipsoid(root, GOLD, Vector3(side * 0.2, 0, -0.38), Vector3(0.22, 0.055, 0.23))
		fin.rotation.y = side * 0.6
		V.ellipsoid(root, INK, Vector3(side * 0.24, 0.075, 0.22), Vector3(0.025, 0.07, 0.07))
		V.ellipsoid(root, WHITE, Vector3(side * 0.261, 0.095, 0.24), Vector3(0.013, 0.021, 0.023))
	V.rod(root, Color("926348"), Vector3(0, -0.1, -0.15), Vector3(0, -0.43, -0.25), 0.09)
	var crystal := V.rod(root, Color("a8faff"), Vector3(0, 0.19, 0.09), Vector3(0, 0.49, 0.09), 0.12, 0)
	crystal.mesh.radial_segments = 6
	return root


static func animal(parent: Node3D, kind: int) -> Node3D:
	var root := V.pivot(parent, "Animal")
	match kind:
		0: fox(root)
		1: rabbit(root)
		2: boar(root)
		3: turtle(root)
		_: preload("res://scripts/creature_models.gd").build(root, kind)
	return root


static func paws(root: Node3D, color: Color, width: float, length: float, radius := 0.17) -> void:
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			var foot := V.pivot(root, "Paw_%s_%s" % [side, end], Vector3(side * width, 0.2, end * length))
			V.ellipsoid(foot, color, Vector3.ZERO, Vector3(radius, 0.2, radius * 1.3))


static func fox(root: Node3D) -> void:
	var orange := Color("de743a")
	V.ellipsoid(root, orange, Vector3(0, 0.65, -0.1), Vector3(0.43, 0.48, 0.66))
	V.ellipsoid(root, CREAM, Vector3(0, 0.72, 0.39), Vector3(0.33, 0.4, 0.2))
	paws(root, Color("654439"), 0.28, 0.37)
	var tail := V.pivot(root, "Tail", Vector3(0, 0.65, -0.55))
	V.ellipsoid(tail, orange, Vector3(0, 0.15, -0.46), Vector3(0.32, 0.3, 0.64))
	V.ellipsoid(tail, CREAM, Vector3(0, 0.2, -0.95), Vector3(0.25, 0.24, 0.3))
	var head := V.pivot(root, "Head", Vector3(0, 1.18, 0.43))
	V.ellipsoid(head, orange, Vector3.ZERO, Vector3(0.5, 0.43, 0.4))
	for side in [-1.0, 1.0]:
		V.rod(head, Color("654439"), Vector3(side * 0.32, 0.24, 0), Vector3(side * 0.4, 0.86, 0.03), 0.23, 0.015)
		V.rod(head, Color("ecaa86"), Vector3(side * 0.32, 0.31, 0.1), Vector3(side * 0.4, 0.72, 0.11), 0.13, 0.0)
		V.ellipsoid(head, CREAM, Vector3(side * 0.23, -0.12, 0.26), Vector3(0.29, 0.2, 0.23))
	V.ellipsoid(head, CREAM, Vector3(0, -0.12, 0.43), Vector3(0.2, 0.14, 0.27))
	V.ellipsoid(head, INK, Vector3(0, -0.075, 0.65), Vector3(0.095, 0.075, 0.08))
	eyes(head, 0.235, 0.085, 0.36)


static func rabbit(root: Node3D) -> void:
	var fur := Color("e7d8f4")
	V.ellipsoid(root, fur, Vector3(0, 0.62, -0.14), Vector3(0.43, 0.51, 0.53))
	V.ellipsoid(root, WHITE, Vector3(0, 0.6, 0.28), Vector3(0.3, 0.36, 0.15))
	paws(root, fur, 0.3, 0.28, 0.22)
	V.ellipsoid(root, WHITE, Vector3(0, 0.67, -0.67), Vector3.ONE * 0.23)
	var head := V.pivot(root, "Head", Vector3(0, 1.14, 0.28))
	V.ellipsoid(head, fur, Vector3.ZERO, Vector3(0.46, 0.44, 0.4))
	for side in [-1.0, 1.0]:
		var ear := V.pivot(head, "EarLeft" if side < 0 else "EarRight", Vector3(side * 0.24, 0.28, -0.02))
		ear.rotation.z = -side * 0.16
		V.ellipsoid(ear, fur, Vector3(0, 0.47, 0), Vector3(0.16, 0.58, 0.115))
		V.ellipsoid(ear, Color("edabc7"), Vector3(0, 0.48, 0.09), Vector3(0.085, 0.43, 0.035))
		V.ellipsoid(head, WHITE, Vector3(side * 0.115, -0.13, 0.37), Vector3(0.17, 0.125, 0.105))
	eyes(head, 0.235, 0.065, 0.353, 0.083)
	V.ellipsoid(head, Color("da87a7"), Vector3(0, -0.08, 0.46), Vector3(0.07, 0.05, 0.035))
	V.rod(head, WHITE, Vector3(0, -0.17, 0.435), Vector3(0, -0.27, 0.435), 0.045)


static func boar(root: Node3D) -> void:
	var fur := Color("966357")
	V.ellipsoid(root, fur, Vector3(0, 0.79, -0.2), Vector3(0.67, 0.65, 0.87))
	paws(root, Color("493f47"), 0.44, 0.48, 0.23)
	V.ring(root, Color("674843"), Vector3(0, 0.84, -1.02), 0.16, 0.045, true)
	var head := V.pivot(root, "Head", Vector3(0, 0.95, 0.6))
	V.ellipsoid(head, fur, Vector3.ZERO, Vector3(0.59, 0.49, 0.43))
	V.ellipsoid(head, Color("d79888"), Vector3(0, -0.08, 0.4), Vector3(0.34, 0.22, 0.18))
	for side in [-1.0, 1.0]:
		V.ellipsoid(head, Color("674843"), Vector3(side * 0.115, -0.07, 0.562), Vector3(0.055, 0.075, 0.027))
		V.rod(head, fur, Vector3(side * 0.42, 0.26, 0), Vector3(side * 0.63, 0.61, 0.01), 0.2, 0.035)
		V.rod(head, CREAM, Vector3(side * 0.34, -0.25, 0.35), Vector3(side * 0.48, 0.03, 0.54), 0.11, 0.015)
		V.rod(head, Color("493f47"), Vector3(side * 0.16, 0.21, 0.37), Vector3(side * 0.37, 0.28, 0.3), 0.05)
	eyes(head, 0.28, 0.1, 0.377, 0.075)
	for index in range(5):
		V.rod(root, Color("493f47"), Vector3(0, 1.26, -0.76 + index * 0.26), Vector3(0, 1.57, -0.8 + index * 0.26), 0.14, 0.0)


static func turtle(root: Node3D) -> void:
	var green := Color("91ba71")
	V.ellipsoid(root, Color("e5cd8d"), Vector3(0, 0.45, -0.08), Vector3(0.72, 0.28, 0.83))
	V.ellipsoid(root, Color("315e59"), Vector3(0, 0.67, -0.14), Vector3(0.77, 0.58, 0.86))
	# Raised scutes give the shell a readable patterned silhouette from above.
	V.ellipsoid(root, Color("72a27a"), Vector3(0, 1.14, -0.14), Vector3(0.37, 0.16, 0.42))
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			V.ellipsoid(root, Color("548870"), Vector3(side * 0.43, 0.95, -0.14 + end * 0.36), Vector3(0.23, 0.16, 0.27))
	paws(root, green, 0.62, 0.47, 0.21)
	var head := V.pivot(root, "Head", Vector3(0, 0.67, 0.84))
	V.ellipsoid(head, green, Vector3.ZERO, Vector3(0.34, 0.32, 0.4))
	V.ellipsoid(head, Color("c8d69a"), Vector3(0, -0.13, 0.24), Vector3(0.25, 0.11, 0.18))
	eyes(head, 0.19, 0.08, 0.31, 0.071)
	V.rod(root, green, Vector3(0, 0.35, -0.8), Vector3(0, 0.35, -1.17), 0.13, 0.015)
