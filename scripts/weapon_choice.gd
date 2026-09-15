extends CanvasLayer

signal selected(index: int)
const Catalog = preload("res://scripts/weapon_catalog.gd")
var backdrop: Control
var title: Label
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
	var description := Label.new()
	description.text = "新しい武器を追加するか、所持武器を強化。全10種類からランダムに3候補。"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_font_size_override("font_size", 18)
	layout.add_child(description)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	layout.add_child(row)
	for index in range(3):
		var card := Button.new()
		card.custom_minimum_size = Vector2(320, 285)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_font_size_override("font_size", 20)
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
	backdrop.hide()


func show_choices(ids: Array[String], levels: Dictionary, next_level: int) -> void:
	opened = true
	title.text = "LEVEL UP!   Lv.%d   /   武器を選ぼう" % next_level
	for index in range(3):
		var id := ids[index]
		var data: Dictionary = Catalog.ITEMS[id]
		var rank := int(levels.get(id, 0))
		var status := "新しい武器" if rank == 0 else "強化  Lv.%d → Lv.%d" % [rank, rank + 1]
		var detail: String = data.description if rank == 0 else "攻撃間隔が短くなります。\n2回の強化ごとに威力も上昇。"
		cards[index].text = "%d   /   %s\n\n%s\n\n%s\n\n%s" % [index + 1, status, data.name, detail, data.style]
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
	if opened:
		opened = false # Only one acquisition per popup, even with repeated input.
		selected.emit(index)


func _input(event: InputEvent) -> void:
	if not opened or not event is InputEventKey or not event.pressed or event.echo:
		return
	var index: int = [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
	if index >= 0:
		get_viewport().set_input_as_handled()
		_select(index)
