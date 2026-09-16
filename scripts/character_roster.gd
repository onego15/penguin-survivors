extends RefCounted
static var selected_id: String = "classic"
const CHARACTERS := {
	"classic": {"name":"メガネペンギン", "weapon":"frost", "ultimate":"blizzard", "hint":"氷ブラスター：最寄りの敵へ連射"},
	"pink": {"name":"ピンクペンギン", "weapon":"heart", "ultimate":"bloom", "hint":"ハートの波動：大きなハートで3体貫通"},
}
const ULTIMATES := {
	"blizzard":{"name":"エンペラー・ブリザード", "damage":100, "heal":0, "visual":preload("res://scripts/ultimate_visual.gd"), "sound":"ultimate", "hint":"必殺技：範囲攻撃100ダメージ"},
	"bloom":{"name":"ラブリー・ブルーム", "damage":80, "heal":20, "visual":preload("res://scripts/bloom_visual.gd"), "sound":"bloom", "hint":"必殺技：範囲攻撃＋HP20回復"},
}
static func selected() -> String:
	return selected_id if CHARACTERS.has(selected_id) else "classic"
