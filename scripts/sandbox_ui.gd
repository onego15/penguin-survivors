extends CanvasLayer
var game: Node3D
var panel: PanelContainer
var info: Label
var result: Label
var enemy_picker: OptionButton
var amount: SpinBox
var refill: CheckBox
var phase: OptionButton
var weapon_options: Dictionary={}
var entries: Array[Dictionary]=[]
var formation_list: VBoxContainer
var placing:=false
var cursor: Node3D
var point:=Vector3.ZERO
var preview_root: Node3D
var preview_view: SubViewport
var description: Label
var current_spec: Dictionary={}
var random_mode: OptionButton
var random_button: Button
var placement_actions: HBoxContainer
var placement_count:=0
var placement_message:=""
var manual_count:=1

func button(parent: Node, text: String, action: Callable) -> Button:
	var b:=Button.new()
	b.text=text
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(action)
	parent.add_child(b)
	return b
func label(parent: Node, text: String) -> Label:
	var l:=Label.new(); l.text=text; parent.add_child(l); return l
func row(parent: Node) -> HBoxContainer:
	var box:=HBoxContainer.new(); parent.add_child(box); return box
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=50
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var font:=SystemFont.new()
	font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	root.theme=Theme.new(); root.theme.default_font=font; root.theme.default_font_size=17
	add_child(root)
	var status_panel:=PanelContainer.new(); status_panel.position=Vector2(16,16); root.add_child(status_panel)
	var status_style:=StyleBoxFlat.new(); status_style.bg_color=Color("d3e5ee"); status_panel.add_theme_stylebox_override("panel",status_style)
	var bar:=HBoxContainer.new(); status_panel.add_child(bar)
	button(bar,"設定 [Tab]",open_menu)
	info=label(bar,"")
	info.add_theme_color_override("font_color",Color("193246"))
	panel=PanelContainer.new()
	panel.position=Vector2(150,74); panel.size=Vector2(980,610)
	root.add_child(panel)
	var background:=StyleBoxFlat.new()
	background.bg_color=Color("182c3f")
	background.border_color=Color("80cbd5")
	background.set_border_width_all(2)
	background.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel",background)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	panel.add_child(margin)
	var column:=VBoxContainer.new(); margin.add_child(column)
	label(column,"SANDBOX  /  設定中は戦闘停止")
	var tabs:=TabContainer.new(); tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(tabs)
	var weapons:=VBoxContainer.new(); weapons.name="キャラ・武器"; tabs.add_child(weapons)
	var chars:=row(weapons)
	for id in ["classic","pink"]:
		button(chars,game.Roster.CHARACTERS[id].name,func(): game.settings.character=id; game.rebuild_player(true))
	var actions:=row(weapons)
	button(actions,"初期装備へ戻す",func(): replace_weapons({game.Roster.CHARACTERS[game.settings.character].weapon:1}))
	button(actions,"全解除",func(): replace_weapons({}))
	button(actions,"全武器MAX",func():
		var loadout: Dictionary={}
		for id in game.Catalog.all_ids(): loadout[id]=game.Catalog.max_rank(id)
		replace_weapons(loadout))
	var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; weapons.add_child(scroll)
	var grid:=GridContainer.new(); grid.columns=4; grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(grid)
	for id in game.Catalog.all_ids():
		var name_label:=label(grid,game.Catalog.data(id).name); name_label.custom_minimum_size.x=240
		var option:=OptionButton.new(); option.add_item("未装備",0)
		for i in range(game.Catalog.min_rank(id),game.Catalog.max_rank(id)+1): option.add_item("Lv.%d"%i,i)
		option.select(option.get_item_index(game.settings.weapons.get(id,0))); grid.add_child(option)
		option.item_selected.connect(func(index): game.set_weapon(id,option.get_item_id(index)))
		weapon_options[id]=option
	var enemies:=VBoxContainer.new(); enemies.name="敵"; tabs.add_child(enemies)
	label(enemies,"① 敵を選ぶ　→　② 配置方法を選ぶ　→　③「再開」で戦闘開始")
	enemy_picker=OptionButton.new(); enemies.add_child(enemy_picker)
	for i in range(game.Enemy.NAMES.size()): add_entry("通常 / "+game.Enemy.NAMES[i],{"type":"normal","index":i,"hint":game.Enemy.ROLES[i]})
	for i in range(2): add_entry("手下 / "+["氷アザラシ","氷ユキヒョウ"][i],{"type":"minion","index":i,"hint":["腹滑りで接近","左右から回り込む"][i]})
	for i in range(12):
		var roster=preload("res://scripts/beach_miniboss.gd").ROSTER if i>=8 else preload("res://scripts/castle_miniboss.gd").ROSTER if i>=4 else game.Miniboss.ROSTER
		add_entry("中ボス / "+roster[i%4].name,{"type":"mid","index":i,"hint":"予告を見て回避。制御効果は無効。"})
	for i in range(3): add_entry("ラスボス / "+["グレイシャー","ノクティス","オクト"][i],{"type":"final","index":i,"hint":["放射弾・突進。第二形態は大氷震。","城門の勅令・跳躍・門を貫く氷羽・氷輪。","潮の操作・触手・墨・水たまり。"][i]})
	var options:=row(enemies)
	label(options,"まとめて配置する数")
	amount=SpinBox.new(); amount.min_value=1; amount.max_value=100; amount.value=1; options.add_child(amount)
	refill=CheckBox.new(); refill.text="倒した分を3秒後から補充"; options.add_child(refill)
	phase=OptionButton.new(); phase.add_item("第一形態"); phase.add_item("第二形態"); options.add_child(phase)
	phase.item_selected.connect(func(_index): select_enemy(enemy_picker.selected))
	var display:=row(enemies)
	var view_container:=SubViewportContainer.new(); view_container.custom_minimum_size=Vector2(210,140); display.add_child(view_container)
	preview_view=SubViewport.new(); preview_view.size=Vector2i(210,140); preview_view.own_world_3d=true; view_container.add_child(preview_view)
	var light:=DirectionalLight3D.new(); light.rotation_degrees=Vector3(-40,-30,0); preview_view.add_child(light)
	var camera:=Camera3D.new(); camera.position=Vector3(4,4,7); preview_view.add_child(camera); camera.look_at(Vector3(0,1,0)); camera.current=true
	description=label(display,""); description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; description.custom_minimum_size.x=540
	enemy_picker.item_selected.connect(select_enemy)
	enemy_picker.select(int(game.settings.get("enemy_selection",0)))
	amount.value=game.settings.get("enemy_count",20)
	refill.button_pressed=game.settings.get("enemy_refill",false)
	phase.select(int(game.settings.get("enemy_phase",0)))
	select_enemy(enemy_picker.selected)
	var manual:=row(enemies)
	button(manual,"1匹ずつ置く（連続クリック）",func(): start_placing(1))
	button(manual,"指定数をひとかたまりで置く",func(): start_placing(int(amount.value)))
	var random_row:=row(enemies)
	random_mode=OptionButton.new()
	random_mode.add_item("いろいろな通常敵を混ぜる")
	random_mode.add_item("選んだ種類だけ")
	random_row.add_child(random_mode)
	for number in [20,50,100]: button(random_row,"%d体"%number,func(): amount.value=number)
	random_button=button(random_row,"ランダムにまとめて配置",scatter)
	random_mode.item_selected.connect(func(_i): update_random_button())
	amount.value_changed.connect(func(_value): update_random_button())
	var emphasis:=StyleBoxFlat.new()
	emphasis.bg_color=Color("276b70"); emphasis.set_corner_radius_all(5)
	emphasis.content_margin_left=12; emphasis.content_margin_right=12
	emphasis.content_margin_top=6; emphasis.content_margin_bottom=6
	random_button.add_theme_stylebox_override("normal",emphasis)
	for control in manual.get_children():
		control.add_theme_stylebox_override("normal",emphasis.duplicate())
	update_random_button()
	label(enemies,"ランダム配置：場内へ散らす / プレイヤーから5m以上 / 合計100体まで")
	var enemy_actions:=row(enemies)
	button(enemy_actions,"平坦な練習場へ戻す",func(): game.switch_terrain(false); open_menu())
	button(enemy_actions,"敵と危険物を全消去",func(): game.clear_enemies(); open_menu(); result.text="全消去しました")
	button(enemy_actions,"同じ設定でやり直す",func(): game.reset_trial(); open_menu(); result.text="同じ編成で再開できます")
	var formation_scroll:=ScrollContainer.new(); formation_scroll.custom_minimum_size.y=78; enemies.add_child(formation_scroll)
	formation_list=VBoxContainer.new(); formation_scroll.add_child(formation_list)
	var aids:=VBoxContainer.new(); aids.name="補助"; tabs.add_child(aids)
	var inv:=CheckBox.new(); inv.text="無敵"; inv.button_pressed=game.settings.invincible; aids.add_child(inv)
	inv.toggled.connect(func(value): game.settings.invincible=value; game.player.training_invincible=value; game.save_settings())
	var stop:=CheckBox.new(); stop.text="敵の行動停止（状態異常・押し返しは有効）"; stop.button_pressed=game.settings.stopped; aids.add_child(stop); stop.toggled.connect(game.set_stopped)
	button(aids,"HP全回復",func():
		if game.player.health>0: game.player.heal(100))
	button(aids,"必殺技を充填・残り3回へ",func(): game.ultimate.uses=0; game.ultimate.charge=0; game.ultimate.reward(200))
	var difficulty_row:=row(aids); label(difficulty_row,"難易度（次の生成から適用）")
	var difficulty:=OptionButton.new(); difficulty_row.add_child(difficulty)
	for id in game.Tiers.IDS: difficulty.add_item(game.Tiers.data(id).name)
	difficulty.select(game.Tiers.IDS.find(game.settings.difficulty))
	difficulty.item_selected.connect(func(index): game.settings.difficulty=game.Tiers.IDS[index]; game.save_settings())
	label(aids,"既存の敵と、その敵の弾・罠は生成時の難易度を維持します。")
	var strength:=row(aids); label(strength,"本編の経過時間相当（次の生成から適用）")
	var minutes:=SpinBox.new(); minutes.max_value=10; minutes.suffix="分"; minutes.value=game.settings.minute; strength.add_child(minutes)
	minutes.value_changed.connect(func(value): game.settings.minute=int(value); game.save_settings())
	var counters:=row(aids)
	button(counters,"撃破数リセット",func(): game.kills=0)
	button(counters,"与ダメージリセット",func(): game.dealt=0)
	button(counters,"被ダメージリセット",func(): game.received=0)
	result=label(column,"")
	var footer:=row(column)
	button(footer,"再開 [Tab]",close_menu)
	button(footer,"同じ設定でやり直す",func(): game.reset_trial(); close_menu())
	button(footer,"タイトルへ",game.return_title)
	panel.hide()
	cursor=game.Visuals.pivot(game,"PlacementPreview")
	game.Visuals.ring(cursor,Color("80eeed"),Vector3(0,0.06,0),1,0.045)
	cursor.hide()
	placement_actions=HBoxContainer.new()
	placement_actions.position=Vector2(16,58)
	root.add_child(placement_actions)
	button(placement_actions,"✓ 配置を完了・設定へ戻る",open_menu)
	button(placement_actions,"▶ 配置を完了・戦闘を再開",close_menu)
	placement_actions.hide()

func add_entry(text: String, spec: Dictionary) -> void:
	enemy_picker.add_item(text); entries.append(spec)
func select_enemy(index: int) -> void:
	var spec: Dictionary=entries[index]
	game.settings.enemy_selection=index
	game.settings.enemy_phase=phase.selected
	game.save_settings()
	if is_instance_valid(random_button): update_random_button()
	amount.editable=true
	refill.disabled=false
	phase.disabled=spec.type!="final"
	description.text=spec.hint+"\n"+("ボスは合計1体まで。既存ボスは全消去してから配置。\nノクティスは城門、オクトは潮と泉を設置。地形変更時は全消去します。" if spec.type in ["mid","final"] else "左クリックで配置。水色の輪＝配置可能、赤＝配置不可。\nランダム配置なら、場所を選ばず一度に追加できます。")
	if is_instance_valid(preview_root): preview_root.free()
	# Use the real model in an isolated viewport, with combat processing disabled.
	preview_root=Node3D.new(); preview_view.add_child(preview_root)
	var enemy: Node3D
	if spec.type=="normal":
		enemy=load("res://scripts/beach_enemy.gd" if spec.index>=15 else "res://scripts/castle_enemy.gd" if spec.index>=10 else ("res://scripts/special_enemy.gd" if spec.index>=4 else "res://scripts/enemy.gd")).new(); enemy.kind=spec.index
	elif spec.type=="minion": enemy=preload("res://scripts/boss_minion.gd").new(); enemy.second_phase=spec.index==1
	elif spec.type=="mid": enemy=load("res://scripts/beach_miniboss.gd" if spec.index>=8 else "res://scripts/castle_miniboss.gd" if spec.index>=4 else "res://scripts/miniboss.gd").new(); enemy.encounter=spec.index%4
	else: enemy=load("res://scripts/octo.gd" if spec.index==2 else "res://scripts/noctis.gd" if spec.index==1 else "res://scripts/final_boss.gd").new()
	game.actors.add_child(enemy)
	if spec.type=="final": enemy.initialize_training_phase(phase.selected==1)
	enemy.process_mode=Node.PROCESS_MODE_DISABLED
	for group in enemy.get_groups(): enemy.remove_from_group(group)
	enemy.model.reparent(preview_root,false)
	if spec.type in ["mid","final"]: preview_root.scale=Vector3.ONE*0.65
	enemy.free()
func replace_weapons(loadout: Dictionary) -> void:
	game.settings.weapons=loadout
	game.rebuild_player()
	for id in weapon_options: weapon_options[id].select(weapon_options[id].get_item_index(loadout.get(id,0)))
func open_menu() -> void:
	placing=false; cursor.hide(); panel.show(); game.get_tree().paused=true
	if is_instance_valid(placement_actions): placement_actions.hide()
	for child in formation_list.get_children(): child.free()
	for i in range(game.formations.size()):
		var formation: Dictionary=game.formations[i]
		if formation.spec.type not in ["normal","minion"]: continue
		var toggle:=CheckBox.new()
		var enemy_name: String=game.Enemy.NAMES[formation.spec.index] if formation.spec.type=="normal" else ["氷アザラシ","氷ユキヒョウ"][formation.spec.index]
		toggle.text="編成%d：%s × %d / 補充"%[i+1,enemy_name,formation.count]
		toggle.button_pressed=formation.spec.get("refill",false)
		toggle.toggled.connect(func(enabled): game.set_formation_refill(i,enabled))
		formation_list.add_child(toggle)
	result.text="倒れました。「同じ設定でやり直す」で再開できます。" if game.game_over else "設定を変更して再開できます"
func close_menu() -> void:
	if game.game_over: return
	placing=false; cursor.hide(); panel.hide(); game.get_tree().paused=false
	placement_actions.hide()
func start_placing(count: int=1) -> void:
	if game.game_over: return
	game.settings.enemy_count=int(amount.value)
	game.settings.enemy_refill=refill.button_pressed
	game.save_settings()
	current_spec=entries[enemy_picker.selected].duplicate()
	current_spec.phase=phase.selected+1
	current_spec.refill=refill.button_pressed and current_spec.type in ["normal","minion"]
	if current_spec.type=="final": game.switch_terrain(current_spec.index==1,current_spec.index==2)
	if current_spec.type in ["mid","final"] and is_instance_valid(game.active_boss) and not game.active_boss.dead:
		result.text="ボスはすでに配置されています。「敵と危険物を全消去」してから置いてください。"
		return
	manual_count=count if current_spec.type in ["normal","minion"] else 1
	placement_count=0; placement_message=""
	placing=true; panel.hide(); cursor.show(); placement_actions.show()
	game.get_tree().paused=true
func _input(event: InputEvent) -> void:
	if Settings.opened: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode ==KEY_TAB:
			if panel.visible and not placing: close_menu()
			else: open_menu()
			get_viewport().set_input_as_handled()
	if placing and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		open_menu(); get_viewport().set_input_as_handled(); return
	if placing and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if event.position.y<105: return
		var count:=0
		if game.valid_position(point,game.radius_for(current_spec)):
			count=game.place_batch(current_spec,point,manual_count)
		placement_count+=count
		placement_message="%d体追加しました"%count if count>0 else "配置不可：赤い輪・重なり・上限を確認してください"
		if current_spec.type in ["mid","final"] and count>0:
			open_menu(); result.text=placement_message
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	info.text="HP %d  敵 %d  撃破 %d  与ダメ %d  被ダメ %d"%[game.player.health,get_tree().get_nodes_in_group("all_enemies").size(),game.kills,game.dealt,game.received]+"  必殺技 %d/200 残り%d"%[game.ultimate.charge,3-game.ultimate.uses]
	if placing:
		info.text="配置中（戦闘停止） 左クリック：%d体 / 右クリック：戻る / 設置済み%d体　%s"%[manual_count,placement_count,placement_message]
		var mouse:=get_viewport().get_mouse_position()
		var origin: Vector3=game.camera.project_ray_origin(mouse)
		var direction: Vector3=game.camera.project_ray_normal(mouse)
		if absf(direction.y)>0.001: point=origin-direction*(origin.y/direction.y)
		cursor.position=point
		cursor.scale=Vector3.ONE*game.radius_for(current_spec)
		for mesh in cursor.get_children():
			if mesh is MeshInstance3D: mesh.material_override.albedo_color=Color("80eeed") if game.valid_position(point,game.radius_for(current_spec)) else Color("ed6b7b")

func update_random_button() -> void:
	var spec: Dictionary=entries[enemy_picker.selected]
	random_button.text="%d体をランダム配置"%int(amount.value)
	random_button.disabled=random_mode.selected==1 and spec.type not in ["normal","minion"]
	random_button.tooltip_text="ボスの一括配置はできません。通常敵ミックスを選んでください。" if random_button.disabled else "指定数の敵を、空いた床へランダムに追加します"

func scatter() -> void:
	if game.game_over: return
	var spec: Dictionary=entries[enemy_picker.selected].duplicate()
	spec.refill=refill.button_pressed
	var requested:=int(amount.value)
	var placed: int=game.place_random(requested,spec,random_mode.selected==0)
	open_menu()
	result.text="%d / %d体をランダム配置しました。現在%d / 100体。「再開」で戦闘開始。"%[placed,requested,get_tree().get_nodes_in_group("all_enemies").size()]
	if placed<requested: result.text+="（上限または空きスペース不足）"
