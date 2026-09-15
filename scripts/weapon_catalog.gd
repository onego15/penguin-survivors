extends RefCounted

const ITEMS := {
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
	"ember": {"name": "おひさまロッド", "description": "前方6mに火球を落とす。\n予告地点で0.7秒後に爆発。", "style": "固定地点 / 威力6・半径3.2m", "color": Color("ffac65"), "cooldown": 2.1, "damage": 6},
	"lightning": {"name": "かみなりベル", "description": "画面内のランダム3地点に落雷。\n半径3mをまとめて攻撃。", "style": "画面内ランダム / 威力5", "color": Color("ffe47d"), "cooldown": 1.65, "damage": 5},
	"orbit": {"name": "真珠のまもり", "description": "2つの真珠が体の周囲を旋回。\n近づく敵を繰り返し攻撃。", "style": "周回 / 近距離", "color": Color("c5b8ff"), "cooldown": 4.0, "damage": 2},
	"nova": {"name": "氷河のチャイム", "description": "体を中心に冷気の輪が広がる。\n全方向の敵をまとめて攻撃。", "style": "全方位 / 波紋", "color": Color("91f4d0"), "cooldown": 2.8, "damage": 2},
	"mine": {"name": "どんぐりボム", "description": "足元に爆弾を置く。\n敵が踏むと周囲ごと爆発。", "style": "設置 / 待ち伏せ", "color": Color("d7ad76"), "cooldown": 2.3, "damage": 4},
	"boomerang": {"name": "おさかなブーメラン", "description": "近い敵を狙って飛び戻る。\n移動で帰りの軌道を操る。", "style": "自動照準 / 往復", "color": Color("f5a8bd"), "cooldown": 2.2, "damage": 2},
	"storm": {"name": "星ふるスノードーム", "description": "近い敵の位置に嵐を設置。\n設置後はその場で継続攻撃。", "style": "自動照準 / 設置範囲", "color": Color("afbcff"), "cooldown": 3.8, "damage": 1},
}


static func damage(id: String, rank: int) -> int:
	return ITEMS[id].damage + int((rank - 1) / 2)


static func cooldown(id: String, rank: int) -> float:
	return ITEMS[id].cooldown * maxf(0.35, pow(0.92, rank - 1))
