extends CanvasLayer

var pool_size:=16
signal selected(index: int)
signal branch_selected(id: String)
signal back_requested
var branch_ids: Array=[]
var back_button: Button
const Catalog = preload("res://scripts/weapon_catalog.gd")
var backdrop: Control
var title: Label
var description: Label
var cards: Array[Button] = []
var opened := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	backdrop = ColorRect.new()
	backdrop.color = Color(0.025, 0.055, 0.095, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var layout := VBoxContainer.new()
	layout.custom_minimum_size = Vector2(1000, 0)
	layout.add_theme_constant_override("separation", 22)
	center.add_child(layout)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "sans-serif"])
	var theme := Theme.new()
	theme.default_font = font
	layout.theme = theme
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("ffe5a9"))
	layout.add_child(title)
	description = Label.new()
	description.text = "基本%d種類＋所持武器の強化。条件が揃うと進化・合体を1枠優先表示。" % pool_size
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	layout.add_child(description)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	layout.add_child(row)
	for index in range(3):
		var card := Button.new()
		card.custom_minimum_size = Vector2(320, 370)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_font_size_override("font_size", 18)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.pressed.connect(_select.bind(index))
		row.add_child(card)
		cards.append(card)
	var help := Label.new()
	help.text = "クリック / 1・2・3 で決定    ｜    矢印キー＋Enter でも選択できます\n選択中は時間・敵・弾がすべて停止します"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color("aac8da"))
	layout.add_child(help)
	back_button=Button.new(); back_button.text="戻る"; back_button.pressed.connect(func(): back_requested.emit()); layout.add_child(back_button)
	back_button.hide()
	backdrop.hide()


func show_choices(ids: Array[String], levels: Dictionary, next_level: int) -> void:
	opened = true
	branch_ids.clear(); back_button.hide()
	description.text="基本%d種類＋所持武器の強化。条件が揃うと進化・合体を1枠優先表示。"%pool_size
	title.text = "LEVEL UP!   Lv.%d   /   武器を選ぼう" % next_level
	for index in range(3):
		cards[index].visible=index<ids.size()
		if index>=ids.size():
			cards[index].disabled=true
			continue
		var id := ids[index]
		var evolution: bool=id.begins_with("@")
		var recipe: String=id.substr(1) if evolution else ""
		var data: Dictionary = Catalog.data(Catalog.Evolution.RECIPES[recipe].outputs[0]) if evolution else Catalog.data(id)
		var rank := int(levels.get(id, 0))
		var status := "新しい武器" if rank == 0 else "強化  Lv.%d → Lv.%d" % [rank, rank + 1]
		var detail: String = data.description if rank == 0 else Catalog.upgrade_text(id,rank)
		cards[index].text = "%d   /   %s\n\n%s\n\n%s\n\n%s" % [index + 1, status, data.name, detail, data.style if rank==0 else "最大 Lv.%d"%Catalog.max_rank(id)]
		if evolution:
			var sources: Array=Catalog.Evolution.RECIPES[recipe].sources
			var material_text:=""
			for source in sources: material_text+="%s Lv.%d\n"%[Catalog.data(source).name,levels[source]]
			cards[index].text="%d / %s\n\n%s\n%s\n\n%s"%[index+1,"単体進化：分岐を選ぶ" if sources.size()==1 else "合体進化",material_text,"引き継ぎ Lv.%d"%Catalog.Evolution.inherited_level(recipe,levels),"2つの攻撃方式から選択\n（次の画面から戻れます）" if sources.size()==1 else data.name+"\n"+data.description]
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("23394f") if state == "normal" else Color("354e67")
			style.border_color = data.color
			style.set_border_width_all(3 if state == "focus" else 2)
			style.set_corner_radius_all(14)
			cards[index].add_theme_stylebox_override(state, style)
		cards[index].disabled = false
	backdrop.show()
	cards[0].grab_focus()


func close() -> void:
	opened = false
	backdrop.hide()
	for card in cards:
		card.disabled = true
		card.release_focus()


func _select(index: int) -> void:
	if opened and index>=0 and index<cards.size() and cards[index].visible and not cards[index].disabled:
		opened = false # Only one acquisition per popup, even with repeated input.
		if not branch_ids.is_empty(): branch_selected.emit(branch_ids[index])
		else: selected.emit(index)


func _input(event: InputEvent) -> void:
	if Settings.opened: return
	if opened and not branch_ids.is_empty() and event is InputEventJoypadButton and event.is_action_pressed("ui_cancel"):
		back_requested.emit(); get_viewport().set_input_as_handled(); return
	if not opened or not event is InputEventKey or not event.pressed or event.echo:
		return
	var index: int = [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
	if index >= 0:
		get_viewport().set_input_as_handled()
		_select(index)

func show_branches(recipe: String, levels: Dictionary, next_level: int) -> void:
	var ids: Array[String]=[]
	ids.assign(Catalog.Evolution.RECIPES[recipe].outputs)
	show_choices(ids,{},next_level)
	branch_ids=ids.duplicate(); back_button.show()
	title.text="単体進化 / 攻撃方式を選ぼう"
	description.text="現在のLv.%dを引き継ぎ、進化後もLv.5まで強化できます"%Catalog.Evolution.inherited_level(recipe,levels)
	for i in range(ids.size()):
		var values:=Catalog.stats(ids[i],Catalog.Evolution.inherited_level(recipe,levels))
		cards[i].text="%d / 進化\n\n%s\n\n%s\n\n威力%d / 間隔%.2f秒\n射程%.1fm"%[i+1,Catalog.data(ids[i]).name,Catalog.data(ids[i]).description,values.damage,values.cooldown,values.reach]
