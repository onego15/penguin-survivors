extends Node3D

const V = preload("res://scripts/visuals.gd")
const Models = preload("res://scripts/character_models.gd")
var hero: Node3D
var sound: Node
var start_button: Button
var fade: ColorRect
var starting := false
var time := 0.0

func _ready() -> void:
	preload("res://scripts/arena.gd").build(self)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.8
	camera.position = Vector3(0, 5.8, 14)
	add_child(camera)
	camera.look_at(Vector3(0, 1.2, 0))
	camera.current = true
	var stand := V.pivot(self, "PenguinDisplay", Vector3(3.3, 0.1, 0))
	stand.scale = Vector3.ONE * 1.55
	hero = Models.penguin(stand)
	hero.rotation.y = -0.25
	var gun := Models.blaster(hero)
	gun.position = Vector3(0.83, 0.95, 0.15)
	V.rod(self, Color("98cdd8"), Vector3(3.3, -0.2, 0), Vector3(3.3, 0.05, 0), 2.0)
	V.ring(self, Color("eef9ed"), Vector3(3.3, 0.06, 0), 1.8, 0.055)
	sound = preload("res://scripts/game_audio.gd").new()
	add_child(sound)
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "sans-serif"])
	ui.theme = Theme.new()
	ui.theme.default_font = font
	layer.add_child(ui)
	var panel := ColorRect.new()
	panel.color = Color(0.035, 0.10, 0.15, 0.96)
	panel.size = Vector2(640, 720)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	_label(ui, "SNOWFIELD SURVIVAL", Vector2(72, 74), 17, Color("7ee6d4"))
	_label(ui, "PENGUIN\nSURVIVORS", Vector2(67, 114), 66, Color("f1f7ec"))
	_label(ui, "小さなペンギン、大きなサバイバル。", Vector2(74, 292), 22, Color("ffdc94"))
	_label(ui, "18種類の武器を組み合わせ、動物の群れを突破。\n10分後に待つ「冬の王」を倒そう。", Vector2(74, 342), 18, Color("bfced6"))
	start_button = Button.new()
	start_button.text = "ゲーム開始   →"
	start_button.position = Vector2(74, 432)
	start_button.size = Vector2(410, 66)
	start_button.add_theme_font_size_override("font_size", 25)
	start_button.add_theme_color_override("font_color", Color("102d39"))
	for state in ["font_focus_color", "font_hover_color", "font_pressed_color"]:
		start_button.add_theme_color_override(state, Color("102d39"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("83dfcc") if state == "normal" else Color("b8f3df")
		style.set_corner_radius_all(12)
		if state == "focus":
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = Color("ffe2a3")
			style.set_border_width_all(3)
		start_button.add_theme_stylebox_override(state, style)
	ui.add_child(start_button)
	start_button.pressed.connect(start_game)
	start_button.grab_focus()
	_label(ui, "ENTER / SPACE でも開始", Vector2(75, 509), 15, Color("94b4bf"))
	_label(ui, "WASD  移動     /     攻撃は自動\nマウスホイール  ズーム     /     1・2・3  武器選択", Vector2(74, 570), 17, Color("bfd9df"))
	_label(ui, "一歩ずつ、強くなる。", Vector2(822, 591), 22, Color("23485a"))
	_label(ui, "! 黄の破線：敵の予告   /   赤の斜線：危険\n水色の輪：自分の攻撃   /   緑の柱：仲間", Vector2(74, 633), 16, Color("8fe5dc"))
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.03, 0.08, 0.12, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)

func _label(parent: Control, text: String, offset: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = offset
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _process(delta: float) -> void:
	time += delta
	hero.position.y = sin(time * 2) * 0.035
	hero.get_node("Head").rotation.z = sin(time * 1.4) * 0.035
	hero.get_node("WingLeft").rotation.z = -0.15 + sin(time * 2.5) * 0.12
	hero.get_node("WingRight").rotation.z = 0.15 - sin(time * 2.5) * 0.12

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER, KEY_SPACE]:
		start_game()
		get_viewport().set_input_as_handled()

func start_game() -> void:
	if starting:
		return
	starting = true
	start_button.disabled = true
	sound.play_effect("choose")
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
