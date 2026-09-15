extends RefCounted

const ITEMS := {
	"frost": {"name": "氷ブラスター", "description": "最寄りの敵を狙う\n連射型の氷弾。", "style": "連射 / 単体", "color": Color("85efff"), "cooldown": 0.28, "damage": 1},
	"fan": {"name": "羽根ショット", "description": "5枚の羽根を扇状に発射。\n正面に広がる群れに強い。", "style": "5方向 / 拡散", "color": Color("f7c4ed"), "cooldown": 1.25, "damage": 1},
	"spear": {"name": "つららランス", "description": "敵を貫く巨大なつらら。\n一直線に並ぶ敵を一掃。", "style": "貫通 / 直線", "color": Color("7ac7f9"), "cooldown": 1.8, "damage": 3},
	"ember": {"name": "おひさまロッド", "description": "火の玉が着弾時に爆発。\n周囲の敵も巻き込む。", "style": "爆発 / 範囲", "color": Color("ffac65"), "cooldown": 2.1, "damage": 3},
	"lightning": {"name": "かみなりベル", "description": "雷が近くの敵へ次々に連鎖。\n最大3体を瞬時に攻撃。", "style": "連鎖 / 3体", "color": Color("ffe47d"), "cooldown": 1.65, "damage": 2},
	"orbit": {"name": "真珠のまもり", "description": "2つの真珠が体の周囲を旋回。\n近づく敵を繰り返し攻撃。", "style": "周回 / 近距離", "color": Color("c5b8ff"), "cooldown": 4.0, "damage": 2},
	"nova": {"name": "氷河のチャイム", "description": "体を中心に冷気の輪が広がる。\n全方向の敵をまとめて攻撃。", "style": "全方位 / 波紋", "color": Color("91f4d0"), "cooldown": 2.8, "damage": 2},
	"mine": {"name": "どんぐりボム", "description": "足元に爆弾を置く。\n敵が踏むと周囲ごと爆発。", "style": "設置 / 待ち伏せ", "color": Color("d7ad76"), "cooldown": 2.3, "damage": 4},
	"boomerang": {"name": "おさかなブーメラン", "description": "飛んで戻ってくるおさかな。\n行きと帰りで敵を貫く。", "style": "往復 / 貫通", "color": Color("f5a8bd"), "cooldown": 2.2, "damage": 2},
	"storm": {"name": "星ふるスノードーム", "description": "敵の位置に星の嵐を作る。\n範囲内に継続ダメージ。", "style": "設置範囲 / 継続", "color": Color("afbcff"), "cooldown": 3.8, "damage": 1},
}


static func damage(id: String, rank: int) -> int:
	return ITEMS[id].damage + int((rank - 1) / 2)


static func cooldown(id: String, rank: int) -> float:
	return ITEMS[id].cooldown * maxf(0.35, pow(0.92, rank - 1))
