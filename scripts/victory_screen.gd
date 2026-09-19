extends CanvasLayer
signal play_again
signal return_title
const V=preload("res://scripts/visuals.gd")
const Models=preload("res://scripts/character_models.gd")
const Friends=preload("res://scripts/creature_models.gd")
const Catalog=preload("res://scripts/weapon_catalog.gd")
var results: Dictionary
var characters: Array[Node3D]=[]
var confetti: Array[Node3D]=[]
var time:=0.0
var viewport: SubViewport
var ui: Control
func _ready() -> void:
	layer=8
	ui=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	ui.theme=Theme.new()
	ui.theme.default_font=font
	add_child(ui)
	var container:=SubViewportContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(container)
	viewport=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var stage:=Node3D.new()
	viewport.add_child(stage)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("c9e8e9")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("fff0d3")
	environment.environment.ambient_light_energy=0.65
	stage.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-48,-28,0)
	light.light_color=Color("fff0d4")
	light.light_energy=1.3
	stage.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=11.5
	camera.position=Vector3(0,7,15)
	stage.add_child(camera)
	camera.look_at(Vector3(0,1,0))
	camera.current=true
	V.rod(stage,Color("edf7ec"),Vector3(-2,-0.6,0),Vector3(-2,-0.05,0),4.6)
	V.ring(stage,Color("e2bd6c"),Vector3(-2,0,0),4.3,0.07)
	var hero:=Models.penguin(stage,results.get("character_id","classic"))
	hero.position=Vector3(-2,0,0)
	hero.scale=Vector3.ONE*1.5
	characters.append(hero)
	for kind in range(preload("res://scripts/support_friend.gd").NAMES.size()):
		var friend:=Friends.support(stage,kind)
		friend.position=[Vector3(-4,1.9,0),Vector3(-4,0,1),Vector3(0.3,0,1),Vector3(-5.4,0,-1.8)][kind]
		friend.scale=Vector3.ONE*(1.0 if kind==3 else 1.35)
		characters.append(friend)
	for i in range(65):
		var paper:=BoxMesh.new()
		paper.size=Vector3(0.10,0.16,0.025)
		var piece:=V.mesh(stage,paper,[Color("e5b959"),Color("eb91af"),Color("66caba"),Color.WHITE][i%4])
		piece.position=Vector3(-6+(i*31%90)/10.0,2+(i%11)*0.3,-2+(i%7)*0.5)
		confetti.append(piece)
	for i in range(7):
		var star:=V.pivot(stage,"CelebrationStar",Vector3(-6+i*1.15,3.8+(i%2)*0.45,-1))
		for ray in range(5):
			var a:=ray*TAU/5
			V.rod(star,Color("e7b859"),Vector3.ZERO,Vector3(sin(a),cos(a),0)*0.2,0.055,0)
	_label("CLEAR!",Vector2(72,38),58,Color("255864"))
	_label(results.get("boss_name","冬の王")+"を倒した！",Vector2(76,110),27,Color("42666b"))
	_label("みんなで、冬を越えた。",Vector2(76,620),24,Color("315e62"))
	_label("M：BGM切替   /   N：効果音切替",Vector2(76,662),15,Color("41676b"))
	var panel:=Panel.new()
	panel.position=Vector2(830,38)
	panel.size=Vector2(420,636)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("163b45")
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	_label(results.get("stage_name","雪原")+" CHAMPION",Vector2(853,59),20,Color("f7d888"))
	_label("TIME  %02d:%02d   /   Lv.%d\nDEFEATED  %d" % [int(results.elapsed)/60,int(results.elapsed)%60,results.level,results.kills],Vector2(853,101),21,Color("effbf8"))
	_label("一緒に戦った武器",Vector2(853,174),19,Color("9de4d5"))
	var index:=0
	for id in results.weapons:
		_label("%s  Lv.%d" % [Catalog.data(id).name,results.weapons[id]],Vector2(853,209+index*(14 if results.weapons.size()>20 else (16 if results.weapons.size()>19 else 17))),13 if results.weapons.size()>19 else 14,Color("e0eeee"))
		index+=1
	_button("もう一度遊ぶ  ["+get_node("/root/Settings").binding_label("restart")+" / Y]",Vector2(851,543),func(): play_again.emit())
	_button("タイトルへ",Vector2(851,603),func(): return_title.emit())
func _label(text: String, point: Vector2, size: int, color: Color) -> void:
	var label:=Label.new()
	label.text=text
	label.position=point
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	ui.add_child(label)
func _button(text: String, point: Vector2, action: Callable) -> void:
	var button:=Button.new()
	button.text=text
	button.position=point
	button.size=Vector2(376,48)
	button.add_theme_font_size_override("font_size",20)
	button.pressed.connect(action)
	ui.add_child(button)
	if text.begins_with("もう一度"): button.grab_focus()
func _process(delta: float) -> void:
	time+=delta
	var hero:=characters[0]
	hero.position.y=absf(sin(time*4))*0.23
	hero.get_node("WingLeft").rotation.z=-0.7+sin(time*7)*0.4
	hero.get_node("WingRight").rotation.z=0.7-sin(time*7)*0.4
	characters[1].position=Vector3(-2+cos(time*1.8)*2.4,2.3+sin(time*4)*0.2,sin(time*1.8)*1.4)
	for side in ["WingLeft","WingRight"]:
		characters[1].get_node(side).rotation.z=sin(time*13)*(0.6 if side=="WingLeft" else -0.6)
	characters[2].rotation.z=sin(time*3)*0.08
	if characters[2].has_node("WaveArm"):
		characters[2].get_node("WaveArm").rotation.z=-1.8+sin(time*6)*0.4
	characters[3].position.y=absf(sin(time*5))*0.35
	Friends.animate_den(characters[4],time,-1,true)
	for i in range(confetti.size()):
		confetti[i].position.y=5-fmod(time*(0.6+(i%3)*0.2)+i*0.17,5)
		confetti[i].rotation+=Vector3(delta,delta*0.6,delta*1.2)
