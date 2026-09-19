extends CanvasLayer
var settings: Node
var message: Label
var key_buttons: Dictionary={}
var resume: Button
var confirm: ConfirmationDialog
var evolution_book: AcceptDialog
func _ready() -> void:
	layer=100
	var root:=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(root)
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	var theme:=Theme.new(); theme.default_font=font; theme.default_font_size=18; root.theme=theme
	var shade:=ColorRect.new(); shade.color=Color(0.025,0.065,0.12,0.84); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(shade)
	var center:=CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(center)
	var panel:=PanelContainer.new(); panel.custom_minimum_size=Vector2(700,610); center.add_child(panel)
	var style:=StyleBoxFlat.new(); style.bg_color=Color("132b3f"); style.border_color=Color("74b9cf")
	style.set_border_width_all(2); style.set_corner_radius_all(12); panel.add_theme_stylebox_override("panel",style)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	panel.add_child(margin)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); margin.add_child(box)
	var title:=Label.new(); title.text="ポーズ / 設定"; title.add_theme_font_size_override("font_size",28); box.add_child(title)
	var tabs:=TabContainer.new(); tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; box.add_child(tabs)
	var display:=VBoxContainer.new(); display.name="音・見やすさ"; display.add_theme_constant_override("separation",16); tabs.add_child(display)
	add_slider(display,"BGM音量",settings.music_volume,0,func(v): settings.music_volume=v; settings.save_preferences())
	add_slider(display,"効果音音量",settings.sfx_volume,0,func(v): settings.sfx_volume=v; settings.save_preferences())
	add_slider(display,"味方エフェクトの濃さ",settings.effect_opacity,20,func(v): settings.effect_opacity=v; settings.save_preferences())
	var shake:=CheckButton.new(); shake.text="画面の揺れ"; shake.button_pressed=settings.camera_shake; shake.toggled.connect(func(v): settings.camera_shake=v; settings.save_preferences()); display.add_child(shake)
	for entry in [["BGMをミュート","music_muted"],["効果音をミュート","sfx_muted"]]:
		var check:=CheckButton.new(); check.text=entry[0]; check.button_pressed=settings.get(entry[1]); display.add_child(check)
		check.toggled.connect(func(v): settings.set(entry[1],v); settings.save_preferences())
		settings.changed.connect(func(): check.set_pressed_no_signal(settings.get(entry[1])))
	var hint:=Label.new(); hint.text="敵の危険予告・味方の水色境界は薄くなりません。\n変更は自動保存され、次回の起動にも引き継がれます。"; hint.add_theme_font_size_override("font_size",16); display.add_child(hint)
	var inputs:=VBoxContainer.new(); inputs.name="操作"; tabs.add_child(inputs)
	var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",24); inputs.add_child(grid)
	for action in settings.keys:
		var label:=Label.new(); label.text=settings.NAMES[action]; label.custom_minimum_size.x=260; grid.add_child(label)
		var button:=Button.new(); button.custom_minimum_size=Vector2(280,32); grid.add_child(button); key_buttons[action]=button
		button.pressed.connect(func(): settings.capturing=action; message.text="新しいキーを押してください（Escでキャンセル）")
	var reset:=Button.new(); reset.text="キー配置を初期値へ戻す"; inputs.add_child(reset)
	reset.pressed.connect(func(): settings.keys=settings.DEFAULT_KEYS.duplicate(); settings.install_inputs(); settings.save_preferences(); refresh_keys())
	var pad:=Label.new(); pad.text="パッド：左スティック / 十字キーで移動、Xで必殺技\nStart：ポーズ、A：決定、B：戻る、Y：終了後に再挑戦\nEsc・Tab・Enter・1〜3はメニュー操作用です。"; pad.add_theme_font_size_override("font_size",16); inputs.add_child(pad)
	message=Label.new(); message.add_theme_font_size_override("font_size",15); box.add_child(message)
	var actions:=HBoxContainer.new(); box.add_child(actions)
	resume=Button.new(); resume.text="閉じる / 再開（Esc・Start）"; resume.size_flags_horizontal=Control.SIZE_EXPAND_FILL; resume.pressed.connect(settings.close_menu); actions.add_child(resume)
	evolution_book=preload("res://scripts/evolution_book.gd").new(); root.add_child(evolution_book)
	var book_button:=Button.new(); book_button.text="進化一覧"; actions.add_child(book_button)
	book_button.pressed.connect(func(): evolution_book.show_book(get_tree().current_scene))
	var quit_button:=Button.new(); quit_button.text="タイトルへ"; actions.add_child(quit_button)
	confirm=ConfirmationDialog.new(); confirm.dialog_text="現在のプレイを終了してタイトルへ戻りますか？"; confirm.title="タイトルへ戻る"; root.add_child(confirm)
	quit_button.pressed.connect(func(): confirm.popup_centered())
	confirm.confirmed.connect(func(): settings.close_menu(); get_tree().paused=false; get_tree().change_scene_to_file("res://scenes/title.tscn"))
	refresh_keys(); hide()
func add_slider(parent: Node, caption: String, initial: float, minimum: float, callback: Callable) -> void:
	var row:=HBoxContainer.new(); parent.add_child(row)
	var label:=Label.new(); label.custom_minimum_size.x=225; row.add_child(label)
	var slider:=HSlider.new(); slider.min_value=minimum; slider.max_value=100; slider.step=5; slider.value=initial*100; slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(slider)
	label.text=caption+"  %d%%"%slider.value
	slider.value_changed.connect(func(v): label.text=caption+"  %d%%"%v; callback.call(v/100.0))
func refresh_keys() -> void:
	for action in key_buttons: key_buttons[action].text=settings.binding_label(action)
func show_menu() -> void:
	message.text="戦闘と演出を停止中"; show(); resume.grab_focus()
