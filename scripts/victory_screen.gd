extends CanvasLayer
signal play_again
signal return_title
const V=preload("res://scripts/visuals.gd")
const Models=preload("res://scripts/character_models.gd")
const Friends=preload("res://scripts/creature_models.gd")
const Catalog=preload("res://scripts/weapon_catalog.gd")
var results: Dictionary
var characters: Array[Node3D]=[]
var friends: Dictionary={}
var equipment: Dictionary={}
var castle:=false
var shore:=false
var won:=true
var confetti: Array[Node3D]=[]
var time:=0.0
var viewport: SubViewport
var report: Control
var ui: Control
func _ready() -> void:
	layer=8
	shore=results.get("stage_id","")=="beach"
	castle=results.get("stage_id","snowfield")=="castle"
	won=results.get("won",true)
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
	environment.environment.background_color=Color("151d40") if castle else Color("c9e8e9")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("fff0d3")
	environment.environment.ambient_light_energy=0.5
	stage.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-48,-28,0)
	light.light_color=Color("fff0d4")
	light.light_energy=0.9
	stage.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=11.5
	camera.position=Vector3(0,7,15)
	stage.add_child(camera)
	camera.look_at(Vector3(0,1,0))
	camera.current=true
	_build_background(stage)
	V.rod(stage,Color("687da1") if castle else Color("edf7ec"),Vector3(-2,-0.6,0),Vector3(-2,-0.05,0),4.6)
	V.ring(stage,Color("e2bd6c"),Vector3(-2,0,0),4.3,0.07)
	var hero:=Models.penguin(stage,results.get("character_id","classic"))
	hero.position=Vector3(-2,0,0)
	hero.scale=Vector3.ONE*1.5
	characters.append(hero)
	_build_equipment(hero)
	for kind in range(preload("res://scripts/support_friend.gd").NAMES.size()):
		if not results.get("contributions",{}).has("support:"+str(kind)): continue
		var friend:=Friends.support(stage,kind)
		friend.position=[Vector3(-4,1.9,0),Vector3(-4,0,1),Vector3(0.3,0,1),Vector3(-5.4,0,-1.8)][kind]
		friend.scale=Vector3.ONE*(1.0 if kind==3 else 1.35)
		friends[kind]=friend
		characters.append(friend)
	for i in range(65 if won else 0):
		var paper:=BoxMesh.new()
		paper.size=Vector3(0.10,0.16,0.025)
		var piece:=V.mesh(stage,paper,[Color("e5b959"),Color("eb91af"),Color("66caba"),Color.WHITE][i%4])
		piece.position=Vector3(-6+(i*31%90)/10.0,2+(i%11)*0.3,-2+(i%7)*0.5)
		confetti.append(piece)
	for i in range(7 if won else 0):
		var star:=V.pivot(stage,"CelebrationStar",Vector3(-6+i*1.15,3.8+(i%2)*0.45,-1))
		for ray in range(5):
			var a:=ray*TAU/5
			V.rod(star,Color("e7b859"),Vector3.ZERO,Vector3(sin(a),cos(a),0)*0.2,0.055,0)
	_label("CLEAR!" if won else "GAME OVER",Vector2(72,38),58,Color("fff0ce") if castle else Color("255864"))
	_label(results.get("boss_name","冬の王")+"を倒した！" if won else "Wave %d / 冒険の記録" % mini(10,int(results.elapsed)/60+1),Vector2(76,110),27,Color("d4e5ff") if castle else Color("42666b"))
	_label(("氷の城に、夜明けが来た。" if castle else "サンゴ浜に、穏やかな潮が戻った。" if shore else "雪原に、平和が戻った。") if won else "また、この仲間と冒険へ。",Vector2(76,620),24,Color("e2edff") if castle else Color("315e62"))
	_label("M：BGM切替   /   N：効果音切替",Vector2(76,662),15,Color("c5dbef") if castle else Color("41676b"))
	var panel:=Panel.new()
	panel.position=Vector2(830,38)
	panel.size=Vector2(420,636)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("163b45")
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	_label(results.get("stage_name","雪原")+" / "+results.get("difficulty_name","ノーマル"),Vector2(853,59),17,Color("f7d888"))
	_label("TIME  %02d:%02d   /   Lv.%d\nDEFEATED  %d" % [int(results.elapsed)/60,int(results.elapsed)%60,results.level,results.kills],Vector2(853,101),21,Color("effbf8"))
	var cleanup: Dictionary=results.get("cleanup",{})
	if cleanup.get("started",false):
		_label("掃討：残敵%d体 / 中ボスHP %.1f％\nラスボスHP＋%d％%s"%[cleanup.remaining,cleanup.boss_ratio*100,cleanup.bonus,"" if cleanup.get("locked",false) else "（死亡時点）"],Vector2(853,160),15,Color("f7d888"))
	report=preload("res://scripts/contribution_panel.gd").new()
	report.entries=results.get("contributions",{}); report.weapons=results.weapons
	report.position=Vector2(851,210 if cleanup.get("started",false) else 174); report.size=Vector2(376,316 if cleanup.get("started",false) else 352); ui.add_child(report)
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
	hero.position.y=absf(sin(time*4))*0.23 if won else 0.0
	hero.get_node("WingLeft").rotation.z=(-0.7+sin(time*7)*0.4) if won else -0.12
	hero.get_node("WingRight").rotation.z=(0.7-sin(time*7)*0.4) if won else 0.12
	if friends.has(0):
		friends[0].position=Vector3(-2+cos(time*1.8)*2.4,2.3+sin(time*4)*0.2,sin(time*1.8)*1.4)
		for side in ["WingLeft","WingRight"]:
			friends[0].get_node(side).rotation.z=sin(time*13)*(0.6 if side=="WingLeft" else -0.6)
	if friends.has(1):
		friends[1].rotation.z=sin(time*3)*0.08
		if friends[1].has_node("WaveArm"): friends[1].get_node("WaveArm").rotation.z=-1.8+sin(time*6)*0.4
	if friends.has(2): friends[2].position.y=absf(sin(time*5))*0.35
	if friends.has(3): Friends.animate_den(friends[3],time,-1,true)
	for i in range(confetti.size()):
		confetti[i].position.y=5-fmod(time*(0.6+(i%3)*0.2)+i*0.17,5)
		confetti[i].rotation+=Vector3(delta,delta*0.6,delta*1.2)

func _build_equipment(hero: Node3D) -> void:
	var ids: Array[String]=[]
	for id in results.get("weapons",{}):
		if id in Catalog.all_ids(): ids.append(id)
	for key in results.get("contributions",{}):
		if not str(key).begins_with("weapon:"): continue
		var id:=str(key).trim_prefix("weapon:")
		if id in Catalog.all_ids() and not id in ids: ids.append(id)
	# Rows of small, attached charms keep even a full loadout below the face.
	for i in range(ids.size()):
		var mount:=V.pivot(hero,"ResultWeapon_"+ids[i])
		preload("res://scripts/equipment_models.gd").build(mount,ids[i])
		mount.scale=Vector3.ONE*(0.55 if ids.size()<=6 else 0.30)
		var columns:=mini(8,ids.size())
		var angle: float=-1.25+2.5*(float(i%columns)/maxi(1,columns-1))
		mount.position=Vector3(sin(angle)*0.90,1.05-floori(float(i)/columns)*0.23,cos(angle)*0.66)
		mount.rotation.y=angle*0.3
		equipment[ids[i]]=mount

func _build_background(stage: Node3D) -> void:
	var floor_mesh:=BoxMesh.new()
	floor_mesh.size=Vector3(50,0.2,24)
	V.mesh(stage,floor_mesh,Color("7187aa") if castle else Color("d9d3b4") if shore else Color("dfedf3"),Vector3(0,-0.8,6))
	if shore:
		var backdrop:=V.pivot(stage,"BeachBackdrop")
		var sea:=BoxMesh.new(); sea.size=Vector3(35,0.05,12)
		V.mesh(backdrop,sea,Color("63bbcc"),Vector3(0,-0.65,-7))
		for i in range(12):
			var p:=Vector3(-10+i*1.7,-0.5,-3-i%2)
			for j in range(3): V.rod(backdrop,Color("e4a5b0"),p,p+Vector3((j-1)*0.35,0.8+j*0.2,0),0.09,0.04)
	elif castle:
		var backdrop:=V.pivot(stage,"CastleBackdrop")
		for x in range(-12,13,3):
			var wall:=BoxMesh.new(); wall.size=Vector3(2.9,3.2,0.7)
			V.mesh(backdrop,wall,Color("36466c"),Vector3(x,0.7,-5))
			for side in [-0.95,0.0,0.95]:
				var cap:=BoxMesh.new(); cap.size=Vector3(0.55,0.6,0.9)
				V.mesh(backdrop,cap,Color("637fa6"),Vector3(x+side,2.6,-5))
		for x in [-7.0,2.0]:
			V.rod(backdrop,Color("99c8e5"),Vector3(x,-0.6,-3.8),Vector3(x,3.5,-3.8),0.38,0.22)
			V.ellipsoid(backdrop,Color("ffce82"),Vector3(x,2.4,-3.35),Vector3(0.17,0.3,0.15))
			var lamp:=OmniLight3D.new(); lamp.position=Vector3(x,2.4,-3); lamp.light_color=Color("ffca8a"); lamp.light_energy=1.4; lamp.omni_range=5; backdrop.add_child(lamp)
		V.ellipsoid(backdrop,Color("e9e7ff"),Vector3(1.5,3.5,-7),Vector3.ONE*0.7)
	else:
		var backdrop:=V.pivot(stage,"SnowfieldBackdrop")
		for i in range(9):
			V.ellipsoid(backdrop,Color("f4fbff"),Vector3(-12+i*3,-0.4,-5-i%2),Vector3(2.2,0.8+i%3*0.3,1.9))
		for x in [-8.0,3.0]:
			V.rod(backdrop,Color("a9d3e6"),Vector3(x,-0.5,-3),Vector3(x,2,-3),0.65,0)
