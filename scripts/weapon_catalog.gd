extends RefCounted

const ITEMS := {
	"gust":{"name":"ぱたぱた扇風機","description":"前方160度へ風を放ち、押し返す。\nボスにはダメージのみ。","style":"前方固定 / ノックバック","color":Color("a8efdc"),"cooldown":2.6,"damage":1},
	"popsicle":{"name":"ひえひえアイスキャンディ","description":"近い敵へ氷菓を発射し、周囲を凍結。\nボスにはダメージのみ。","style":"自動照準 / 凍結","color":Color("99cfff"),"cooldown":3.8,"damage":1},
	"udon":{"name":"ちゅるちゅるおうどん","description":"どんぶりから麺を伸ばして巻き戻す。\n通常敵を少し引き寄せ、往復で攻撃。","style":"自動照準 / 巻き込み・往復","color":Color("f2de9c"),"cooldown":2.4,"damage":1},
	"heart": {"name":"ハートの波動", "description":"最寄りの敵へハートを放つ。\n直線上の敵を最大3体貫通。", "style":"自動照準 / 3体貫通", "color":Color("f578b2"), "cooldown":0.65, "damage":2},
	"rear_fan": {"name": "しっぽの散弾", "description": "背後へ5発の散弾を放つ。\n逃げながら追手を迎撃。", "style": "後方固定 / 威力3 × 5発", "color": Color("ffba8a"), "cooldown": 1.7, "damage": 3},
	"rear_bomb": {"name": "うしろ花火", "description": "背後4.5mへ花火を投げる。\n0.65秒後に半径3mで爆発。", "style": "後方設置 / 威力8", "color": Color("ef9fff"), "cooldown": 2.7, "damage": 8},
	"whip": {"name": "オーロラリボン", "description": "前方を大きく薙ぎ払う。\n近距離の群れに向き直って攻撃。", "style": "前方120度 / 威力7", "color": Color("ff9fdb"), "cooldown": 1.6, "damage": 7},
	"trail": {"name": "ほのおのスケート", "description": "移動した足元に炎を残す。\n追ってくる敵を炎の道へ誘導。", "style": "移動設置 / 威力2・4秒持続", "color": Color("ff8559"), "cooldown": 0.65, "damage": 2},
	"bounce": {"name": "氷玉ビリヤード", "description": "最寄りの敵へ大きな氷玉。\nアリーナの壁で反射して貫通。", "style": "自動照準 / 反射・威力3", "color": Color("7ee7ef"), "cooldown": 2.7, "damage": 3},
	"turret": {"name": "ゆきだるま砲台", "description": "その場に8秒間の砲台を設置。\n近い敵を狙って援護射撃。", "style": "設置 / 自動連射・威力2", "color": Color("d5eeff"), "cooldown": 8.0, "damage": 2},
	"seeker": {"name": "ミツバチロケット", "description": "3匹のハチが敵を追尾。\n標的が倒れると別の敵へ。", "style": "追尾3発 / 威力2", "color": Color("ffcf5c"), "cooldown": 2.5, "damage": 2},
	"beam": {"name": "極光プリズム", "description": "最寄りの敵へ一直線の光線。\n発射方向を固定して連続貫通。", "style": "自動照準 / 直線・威力3", "color": Color("bda2ff"), "cooldown": 3.4, "damage": 3},
	"frost": {"name": "氷ブラスター", "description": "最寄りの敵を狙う\n連射型の氷弾。", "style": "連射 / 単体", "color": Color("85efff"), "cooldown": 0.28, "damage": 1},
	"fan": {"name": "羽根ショット", "description": "向いている方向へ5発。\n体の向きで狙う扇状攻撃。", "style": "前方固定 / 威力2 × 5発", "color": Color("f7c4ed"), "cooldown": 1.25, "damage": 2},
	"spear": {"name": "つららランス", "description": "向いている方向へ貫通槍。\n敵を正面に並べて一掃。", "style": "前方固定 / 威力5・貫通", "color": Color("7ac7f9"), "cooldown": 1.8, "damage": 5},
	"ember": {"name": "おひさまロッド", "description": "前方8mに火球を落とす。\n予告地点で0.7秒後に爆発。", "style": "固定地点 / 威力6・半径3.2m", "color": Color("ffac65"), "cooldown": 2.1, "damage": 6},
	"lightning": {"name": "かみなりベル", "description": "画面内のランダム3地点に落雷。\n半径3mをまとめて攻撃。", "style": "画面内ランダム / 威力5", "color": Color("ffe47d"), "cooldown": 1.65, "damage": 5},
	"orbit": {"name": "真珠のまもり", "description": "2つの真珠が体の周囲を旋回。\n近づく敵を繰り返し攻撃。", "style": "周回 / 近距離", "color": Color("c5b8ff"), "cooldown": 4.0, "damage": 2},
	"nova": {"name": "氷河のチャイム", "description": "体を中心に冷気の輪が広がる。\n全方向の敵をまとめて攻撃。", "style": "全方位 / 波紋", "color": Color("91f4d0"), "cooldown": 2.8, "damage": 2},
	"mine": {"name": "どんぐりボム", "description": "足元に爆弾を置く。\n敵が踏むと周囲ごと爆発。", "style": "設置 / 待ち伏せ", "color": Color("d7ad76"), "cooldown": 2.3, "damage": 4},
	"boomerang": {"name": "おさかなブーメラン", "description": "近い敵の方向へ楕円を描く。\n一周してから手元に戻る。", "style": "自動照準 / 往復", "color": Color("f5a8bd"), "cooldown": 2.2, "damage": 2},
	"storm": {"name": "星ふるスノードーム", "description": "近い敵の位置に嵐を設置。\n設置後はその場で継続攻撃。", "style": "自動照準 / 設置範囲", "color": Color("afbcff"), "cooldown": 3.8, "damage": 1},
}


const MAX_RANK:=5
const SHAPES={
	"frost":{"reach":12.0}, "heart":{"reach":12.0,"pierce":3},
	"fan":{"reach":13.6,"count":5}, "rear_fan":{"reach":13.6,"count":5},
	"spear":{"reach":19.5}, "rear_bomb":{"radius":3.0}, "ember":{"radius":3.2},
	"lightning":{"radius":3.0,"count":3}, "whip":{"radius":3.8},
	"trail":{"radius":1.25,"duration":4.0}, "bounce":{"duration":5.0},
	"turret":{"reach":12.0,"duration":8.0}, "seeker":{"reach":12.0,"count":3,"duration":3.0},
	"beam":{"reach":12.0,"duration":1.3}, "orbit":{"radius":2.2,"count":2},
	"nova":{"radius":4.2}, "mine":{"radius":3.0,"duration":8.0},
	"boomerang":{"reach":12.0,"travel":9.1,"duration":2.4}, "storm":{"radius":2.6,"duration":3.2},
	"udon":{"reach":11.0,"radius":1.2},
}
static func stats(id: String, rank: int) -> Dictionary:
	var n:=clampi(rank,1,MAX_RANK)-1
	if id=="gust": return {"damage":[1,2,2,3,3][n],"cooldown":[2.6,2.45,2.3,2.15,2.0][n],"reach":[6.0,6.5,7.0,7.5,8.0][n],"knockback":[3.0,3.0,3.5,4.0,4.5][n]}
	if id=="popsicle": return {"damage":[1,2,2,3,3][n],"cooldown":[3.8,3.6,3.4,3.2,3.0][n],"reach":12.0,"radius":[1.3,1.45,1.6,1.75,1.9][n],"freeze":[1.0,1.0,1.2,1.2,1.4][n]}
	var result: Dictionary=SHAPES[id].duplicate()
	var many:=id in ["fan","rear_fan","seeker","lightning","orbit"]
	result.damage=int(ITEMS[id].damage)+n if id=="frost" else ceili(float(ITEMS[id].damage)*(1+(0.4*ceilf(n/2.0) if many else 0.5*n)))
	result.cooldown=float(ITEMS[id].cooldown)*(1-(0.025 if id=="frost" or id=="orbit" else 0.05)*n)
	if result.has("reach"): result.reach*=1+0.1*n
	if result.has("travel"): result.travel*=1+0.1*n
	if result.has("radius"): result.radius*=1+(0.1 if id in ["whip","orbit"] else 0.06)*n
	if result.has("duration"): result.duration*=1+0.075*n
	if result.has("count"): result.count+=n/2
	if result.has("pierce"): result.pierce+=n/2
	return result
static func damage(id: String, rank: int) -> int:
	return stats(id,rank).damage
static func cooldown(id: String, rank: int) -> float:
	return stats(id,rank).cooldown
static func upgrade_text(id: String, rank: int) -> String:
	var before:=stats(id,rank)
	var after:=stats(id,rank+1)
	var lines: Array[String]=[]
	for key in ["damage","cooldown","reach","radius","count","duration","pierce","travel","knockback","freeze"]:
		if not before.has(key) or before[key]==after[key]: continue
		var names:={"damage":"威力","cooldown":"間隔","reach":"射程","radius":"半径","count":"数","duration":"持続","pierce":"貫通数","travel":"到達距離","knockback":"押し返し","freeze":"凍結時間"}
		if key in ["damage","count","pierce"]: lines.append("%s %d → %d"%[names[key],before[key],after[key]])
		else: lines.append("%s %.2f → %.2f%s"%[names[key],before[key],after[key],"m" if key in ["reach","radius","travel","knockback"] else "秒"])
	return "\n".join(lines)
