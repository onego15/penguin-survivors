extends RefCounted
## Session selection; a run and each hostile actor capture their own immutable ID.
static var selected_id: String="normal"
const IDS=["easy","normal","hard","expert"]
const ITEMS={
	"easy":{"name":"やさしい","hint":"敵が少なめ・被ダメージ控えめ。少ないXPで成長。","hp":0.8,"damage":0.65,"rate":0.8,"cap":0.8,"xp":0.8,"intervals":[15,12],"minion_caps":[4,6]},
	"normal":{"name":"ノーマル","hint":"これまでと同じバランスで冒険。","hp":1.0,"damage":1.0,"rate":1.0,"cap":1.0,"xp":1.0,"intervals":[12,9],"minion_caps":[6,8]},
	"hard":{"name":"ハード","hint":"敵の数・耐久・攻撃力が少し上昇。","hp":1.15,"damage":1.2,"rate":1.15,"cap":1.1,"xp":1.0,"intervals":[10,8],"minion_caps":[6,8]},
	"expert":{"name":"エキスパート","hint":"多くの強敵に挑む、最も厳しい戦い。","hp":1.3,"damage":1.4,"rate":1.35,"cap":1.2,"xp":1.0,"intervals":[9,7],"minion_caps":[6,8]},
}
static func valid(id: String) -> String: return id if ITEMS.has(id) else "normal"
static func data(id: String) -> Dictionary: return ITEMS[valid(id)]
# Multipliers are percentages: round the percentage first to avoid 50 * 1.1
# becoming 55.00000000000001 and incorrectly rounding up to 56.
static func scaled(value: int, multiplier: float) -> int:
	return ceili(float(value*roundi(multiplier*100))/100.0)
static func source(node: Node) -> String:
	while is_instance_valid(node):
		if node.has_meta("difficulty_id"): return valid(node.get_meta("difficulty_id"))
		if "difficulty_id" in node: return valid(node.difficulty_id)
		node=node.get_parent()
	return "normal"
static func inherit_attack(origin: Node, attack: Node) -> void:
	attack.set_meta("difficulty_id",source(origin))
static func prepare(enemy: Node, id: String) -> void:
	enemy.set_meta("difficulty_id",valid(id))
static func apply_hp(enemy: Node) -> void:
	if enemy.get_meta("difficulty_hp_applied",false): return
	enemy.health=maxi(1,scaled(enemy.health,data(source(enemy)).hp))
	enemy.max_health=enemy.health
	enemy.set_meta("difficulty_hp_applied",true)
static func profile(seconds: float, id: String) -> Dictionary:
	var value:=preload("res://scripts/difficulty.gd").profile(seconds)
	var tier:=data(id); value.rate*=tier.rate; value.cap=clampi(scaled(value.cap,tier.cap),1,100)
	return value
static func xp(level: int, id: String) -> int:
	return maxi(1,scaled(preload("res://scripts/difficulty.gd").xp_for_level(level),data(id).xp))
