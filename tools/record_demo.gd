extends SceneTree
## Real-engine fixed-step showcase; staging affects this recording process only.
const FPS:=60
const DURATION:=72
const Stages=preload("res://scripts/stage_catalog.gd")
const Roster=preload("res://scripts/character_roster.gd")
var game: Node3D
var frame:=0
var steering:=Vector3.ZERO
var caption: Label
func _initialize() -> void:
	Engine.physics_ticks_per_second=FPS
	call_deferred("start")
func start() -> void:
	chapter("snowfield","classic")
	var layer:=CanvasLayer.new(); layer.layer=20; root.add_child(layer)
	caption=Label.new(); caption.position=Vector2(320,647)
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_color",Color("effbf8"))
	caption.add_theme_color_override("font_outline_color",Color("173e49"))
	caption.add_theme_constant_override("outline_size",6)
	layer.add_child(caption)
	caption.text="雪原：動きと予告で見分ける動物たち"
	process_frame.connect(tick)
func release_input() -> void:
	for action in ["move_right","move_left","move_up","move_down"]:
		if InputMap.has_action(action): Input.action_release(action)
func chapter(stage_id: String, character_id: String) -> void:
	release_input(); steering=Vector3.ZERO
	if is_instance_valid(game): game.free()
	Stages.selected_id=stage_id; Roster.selected_id=character_id
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	game.rng.seed=73
	game.difficulty_id="normal"
	game.elapsed=370; game.level=10; game.xp_needed=100000
	game.next_boss_at=9999; game.support.next_at=9999
	for i in range(15): game.director.introduced[i]=true
	game.director.advance()
	var weapons: Array=["orbit","nova","spear","rear_bomb"] if stage_id=="snowfield" else ["whip","beam","seeker","starfall"]
	for id in weapons:
		for rank in range(2): game.armory.acquire(id)
	for i in range(24):
		var enemy=game.spawn_enemy([0,1,2,3,5,7][i%6] if stage_id=="snowfield" else [0,3,10,11,12,13][i%6])
		if enemy!=null: enemy.position=Vector3(cos(i*TAU/24),0,sin(i*TAU/24))*(7+i%4)
	game.camera.size=20
func tick() -> void:
	frame+=1
	var t:=frame/float(FPS)
	if frame==2*FPS:
		game.support.spawn_friend(3,game.player.position+Vector3(2.5,0,0))
		caption.text="デン：敵の集まりへ跳んで、どすん！"
	if frame==9*FPS: game.ultimate.reward(200)
	if frame==11*FPS:
		game.ultimate.activate()
		caption.text="メガネペンギンの必殺技：エンペラー・ブリザード"
	if frame==18*FPS:
		chapter("castle","pink")
		caption.text="夜の氷の城：ピンクペンギンと、きらきらプリズム"
	if frame==21*FPS:
		game.armory.evolve("rainbow_heart","rainbow_heart")
		caption.text="ときめき虹プリズム：ハートの結晶から虹の光線"
	if frame==24*FPS:
		game.armory.cooldowns.starfall=0
		caption.text="おほしさまメテオ：巨大な星が固定地点へ落下"
	if frame==26*FPS:
		game.support.spawn_friend(3,game.player.position+Vector3(1,0,0))
	if frame==29*FPS: game.ultimate.reward(200)
	if frame==31*FPS:
		game.player.health=75; game.ultimate.activate()
		caption.text="ピンクペンギンの必殺技：ラブリー・ブルーム"
	if frame==36*FPS:
		game.elapsed=600; game._start_final_boss()
		caption.text="氷城の梟王・ノクティス：城門を操る決戦"
	if frame==46*FPS and is_instance_valid(game.active_boss):
		game.active_boss.take_damage(maxi(1,game.active_boss.health-790))
		caption.text="第二形態：城壁から氷棘が迫る"
	if frame==49*FPS and is_instance_valid(game.active_boss):
		game.active_boss.cancel_attacks()
		game.active_boss.attack_index=1
		game.active_boss.begin_attack()
		caption.text="氷棘の城壁：白い矢印の隙間へ！"
	if frame==66*FPS and is_instance_valid(game.active_boss):
		game.active_boss.take_damage(99999)
		caption.text=""
	if not game.victory:
		# Stable steering; health and rewards are staged, not a normal gameplay run.
		game.player.health=100
		var desired:=Vector3(cos(t*0.45),0,sin(t*0.45))*5
		if is_instance_valid(game.support.active) and game.support.active.state=="waiting": desired=game.support.active.position
		if is_instance_valid(game.active_boss) and game.active_boss.warning_left>0:
			desired=(game.player.position-game.active_boss.position).normalized()*12
		if is_instance_valid(game.active_boss) and game.active_boss.get("wall_busy")==true:
			desired=Vector3(game.player.position.x,0,game.active_boss.ice_walls.gap)
		var offset: Vector3=desired-game.player.position
		var direction: Vector3=offset.normalized()*minf(1,offset.length()/1.5)
		if game.obstacles!=null and offset.length()>1: direction=game.obstacles.steer(game.player,desired,0.45)
		steering=steering.lerp(direction,1-exp(-6.0/FPS))
		release_input()
		Input.action_press("move_right" if steering.x>0 else "move_left",absf(steering.x))
		Input.action_press("move_down" if steering.z>0 else "move_up",absf(steering.z))
	if frame>=DURATION*FPS:
		release_input(); quit()
