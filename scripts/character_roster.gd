extends RefCounted
static var selected_id: String = "classic"
const CHARACTERS := {
	"classic": {"name":"メガネペンギン", "weapon":"frost", "hint":"氷ブラスター：最寄りの敵へ連射"},
	"pink": {"name":"ピンクペンギン", "weapon":"heart", "hint":"ハートの波動：大きなハートで3体貫通"},
}
static func selected() -> String:
	return selected_id if CHARACTERS.has(selected_id) else "classic"
