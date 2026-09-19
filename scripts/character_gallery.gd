extends Node3D
const V=preload("res://scripts/visuals.gd")
const Models=preload("res://scripts/character_models.gd")
const Creatures=preload("res://scripts/creature_models.gd")
const Enemy=preload("res://scripts/enemy.gd")
const Friend=preload("res://scripts/support_friend.gd")
var models: Array[Node3D]=[]
var time:=0.0
func _ready() -> void:
	preload("res://scripts/arena.gd").build(self)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=28
	camera.position=Vector3(0,23,30)
	add_child(camera)
	camera.look_at(Vector3(0,0,4))
	camera.current=true
	for kind in range(10):
		var point:=Vector3((kind%5-2)*6,0,-7+floori(kind/5.0)*7)
		var stand:=V.pivot(self,"EnemyDisplay_%d" % kind,point)
		stand.scale=Vector3.ONE*1.2
		models.append(Models.animal(stand,kind))
		_plinth(point,1.3,Color("d8b497"))
		_label(Enemy.NAMES[kind],point+Vector3(0,0.2,1.65),38)
		_label(Enemy.ROLES[kind],point+Vector3(0,0,2.5),25)
	var hero:=V.pivot(self,"Hero",Vector3(-12,0,8))
	models.append(Models.penguin(hero))
	_plinth(hero.position,1.3,Color("7fdacb"))
	_label("プレイヤー",hero.position+Vector3(0,0.2,1.6),32)
	for kind in range(Friend.NAMES.size()):
		var point:=Vector3(kind*6 if kind<3 else -12,0,8 if kind<3 else 14)
		var stand:=V.pivot(self,"FriendDisplay_%d" % kind,point)
		stand.scale=Vector3.ONE*1.2
		models.append(Creatures.support(stand,kind))
		_plinth(point,1.3,Color("7fdacb"))
		_label("%s %s" % [Friend.ICONS[kind],Friend.NAMES[kind]],point+Vector3(0,0.2,1.65),34)
		_label(["回復","防御","攻撃援護","狙って跳躍・4m押し返し"][kind],point+Vector3(0,0,2.5),25)
	var pink:=V.pivot(self,"PinkHero",Vector3(-6,0,8))
	models.append(Models.penguin(pink,"pink"))
	_label("ピンクペンギン",pink.position+Vector3(0,0.2,1.6),28)
	for phase in [1,2]:
		var point:=Vector3(-5 if phase==1 else 5,0,15)
		var minion:=preload("res://scripts/boss_minion.gd").new()
		minion.second_phase=phase==2
		minion.position=point
		add_child(minion)
		minion.set_physics_process(false)
		models.append(minion.model)
		_plinth(point,1.3,Color("839cae"))
		_label("氷アザラシ" if phase==1 else "氷ユキヒョウ",point+Vector3(0,0.2,1.65),34)
		_label("第一形態：腹滑り追跡" if phase==1 else "第二形態：回り込み",point+Vector3(0,0,2.5),25)
	var layer:=CanvasLayer.new()
	add_child(layer)
	var title:=Label.new()
	title.text="PENGUIN SURVIVORS  /  10 ENEMIES + 2 BOSS MINIONS + 4 FRIENDS"
	title.position=Vector2(32,22)
	title.add_theme_font_size_override("font_size",25)
	title.add_theme_color_override("font_color",Color("203e50"))
	layer.add_child(title)
	var weapons:=Button.new()
	weapons.text="基本23種＋進化8種のモデル一覧"
	weapons.position=Vector2(950,24)
	weapons.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/weapon_gallery.tscn"))
	layer.add_child(weapons)
func _plinth(point: Vector3, radius: float, color: Color) -> void:
	V.rod(self,color,point-Vector3(0,0.2,0),point+Vector3(0,0.04,0),radius)
func _label(caption: String, point: Vector3, size: int) -> void:
	var label:=Label3D.new()
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	label.font=font
	label.text=caption
	label.font_size=size
	label.pixel_size=0.014
	label.no_depth_test=true
	label.position=point
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("234c5b")
	label.outline_size=0
	add_child(label)
func _process(delta: float) -> void:
	time+=delta
	for i in range(models.size()):
		models[i].rotation.y=sin(time*0.6+i)*0.16
