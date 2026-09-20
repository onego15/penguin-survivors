extends AcceptDialog
const Catalog=preload("res://scripts/weapon_catalog.gd")
var body: RichTextLabel
func _ready() -> void:
	title="武器の進化・合体一覧"
	min_size=Vector2i(760,570)
	var box:=VBoxContainer.new(); add_child(box)
	body=RichTextLabel.new(); body.bbcode_enabled=true; body.custom_minimum_size=Vector2(720,480); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; box.add_child(body)
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"]); body.add_theme_font_override("normal_font",font); body.add_theme_font_size_override("normal_font_size",18)
func show_book(game: Node=null) -> void:
	var levels: Dictionary={}; var consumed: Dictionary={}; var stage_pool: Array=[]; var slots:="1プレイで進化・合体は合計2つまで"
	if game!=null and "armory" in game:
		levels=game.armory.levels; consumed=game.armory.consumed; stage_pool=game.Stages.weapon_pool(game.stage_id)
		slots="残り進化枠 %d / 2"%maxi(0,2-game.armory.evolution_count())
	body.text="[b]"+slots+"[/b]\n単体：Lv.2から分岐、現在レベルを引き継ぎLv.5まで。\n合体：素材2種がLv.1から。合体Lv＝素材Lv合計−1、最大9。\n素材は消費され、このプレイでは再取得できません。\n\n"
	for recipe in Catalog.Evolution.RECIPES:
		var def: Dictionary=Catalog.Evolution.RECIPES[recipe]
		var names: PackedStringArray=[]
		for id in def.sources:
			var state:=""
			if game!=null and "armory" in game:
				state="（消費済み）" if consumed.has(id) else ("（このステージ対象外）" if not id in stage_pool else (" Lv.%d"%levels[id] if levels.has(id) else "（未所持）"))
			names.append(Catalog.data(id).name+state)
		var stages: PackedStringArray=[]
		for stage in preload("res://scripts/stage_catalog.gd").STAGES:
			var pool=preload("res://scripts/stage_catalog.gd").weapon_pool(stage)
			var valid:=true
			for source in def.sources:
				if not source in pool: valid=false
			if valid: stages.append(preload("res://scripts/stage_catalog.gd").STAGES[stage].name)
		body.text+="【"+"・".join(stages)+"】\n"
		body.text+="[color=#9feaff][b]"+" ＋ ".join(names)+"[/b][/color]\n必要：各Lv.%d以上\n"%def.minimum
		for id in def.outputs: body.text+="→ [b]"+Catalog.data(id).name+"[/b]\n"+Catalog.data(id).description.replace("\n"," ")+"\n"
		body.text+="\n"
	popup_centered(Vector2i(780,600))
