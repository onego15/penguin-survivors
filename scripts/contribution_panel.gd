extends VBoxContainer
const Catalog=preload("res://scripts/weapon_catalog.gd")
var entries: Dictionary={}
var weapons: Dictionary={}
var listing: RichTextLabel
var order: OptionButton
func display_name(id: String) -> String:
	var key: String=id.get_slice(":",1)
	match id.get_slice(":",0):
		"weapon": return Catalog.data(key).get("name",key)
		"support": return ["シマエナガ","シロクマ","ひよこ","デン"][int(key)]
		"ultimate": return "ラブリー・ブルーム" if key=="bloom" else "エンペラー・ブリザード"
	return id
func leader(field: String) -> String:
	var best:=0.0; var winners: Array[String]=[]
	for id in entries:
		var value: float=entries[id].get(field,0)
		if value>best: best=value; winners=[display_name(id)]
		elif value==best and value>0: winners.append(display_name(id))
	if best<=0: return "記録なし"
	return winners[0]+(" ほか%d件（同率）"%(winners.size()-1) if winners.size()>1 else "")
func _ready() -> void:
	var ledger:=preload("res://scripts/contributions.gd").new()
	ledger.entries=entries.duplicate(true); entries=ledger.snapshot(weapons)
	var font:=SystemFont.new(); font.font_names=PackedStringArray(["Yu Gothic UI","Meiryo"])
	theme=Theme.new(); theme.default_font=font; theme.default_font_size=15
	var heading:=Label.new(); heading.text="今回の活躍"; heading.add_theme_font_size_override("font_size",22); add_child(heading)
	var highlights:=Label.new(); highlights.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	highlights.text="最多ダメージ："+leader("damage")+"\n最多撃破："+leader("kills"); add_child(highlights)
	order=OptionButton.new(); order.add_item("ダメージ順"); order.add_item("撃破数順"); order.add_item("凍結・押し返し回数順"); order.item_selected.connect(func(_index): refresh()); add_child(order)
	listing=RichTextLabel.new(); listing.bbcode_enabled=true; listing.size_flags_vertical=Control.SIZE_EXPAND_FILL; listing.custom_minimum_size.y=100; add_child(listing)
	refresh()
func refresh() -> void:
	var ids: Array=entries.keys()
	var metric: String=["damage","kills","control"][order.selected]
	ids.sort_custom(func(a,b):
		var x: float=entries[a].freeze+entries[a].knockback if metric=="control" else entries[a][metric]
		var y: float=entries[b].freeze+entries[b].knockback if metric=="control" else entries[b][metric]
		return a<b if x==y else x>y)
	listing.text="[color=#aacbd2]実ダメージを集計。凍結時間は敵ごとの合計。[/color]\n\n"
	if ids.is_empty(): listing.text+="まだ貢献の記録はありません。"
	for id in ids:
		var row: Dictionary=entries[id]
		var label:=display_name(id)
		if id.begins_with("weapon:"):
			var key: String=id.get_slice(":",1)
			label+=" Lv.%d"%weapons[key] if weapons.has(key) else "（進化・合体前）"
		else: label="【援護】"+label if id.begins_with("support:") else "【必殺技】"+label
		listing.text+="[color=#a9eeea][b]"+label+"[/b][/color]\nダメージ %d  /  撃破 %d\n"%[row.damage,row.kills]
		if row.knockback>0: listing.text+="押し返し %d回\n"%row.knockback
		if row.freeze>0: listing.text+="凍結 %d回 / 実時間 %.1f秒\n"%[row.freeze,row.freeze_seconds]
		if row.healing>0 or row.prevented>0 or id in ["support:0","support:1","ultimate:bloom"]: listing.text+="回復 %d / 軽減 %d\n"%[row.healing,row.prevented]
		listing.text+="\n"
