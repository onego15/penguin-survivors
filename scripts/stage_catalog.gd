extends RefCounted
static var selected_id: String="snowfield"
const STAGES={
	"snowfield":{"name":"雪原", "background":"snowfield", "obstacles":false, "difficulty":"res://scripts/difficulty.gd", "wave_set":"snowfield", "boss_script":"res://scripts/final_boss.gd", "midboss_script":"res://scripts/miniboss.gd", "music":"snowfield", "boss_music":"final_boss", "phase_music":"final_boss_phase2", "boss_name":"冬の王・グレイシャー", "phase_name":"吹雪の王"},
	"castle":{"name":"夜の氷の城", "background":"castle", "obstacles":true, "difficulty":"res://scripts/difficulty.gd", "wave_set":"castle", "boss_script":"res://scripts/noctis.gd", "midboss_script":"res://scripts/castle_miniboss.gd", "music":"castle", "boss_music":"noctis", "phase_music":"noctis_phase2", "boss_name":"氷城の梟王・ノクティス", "phase_name":"月影の支配者"},
}
const CASTLE_WAVES=[
	{"name":"城門の羽音","hint":"揺れるコウモリを迎え撃とう","pairs":[[0,10]],"new":[10]},
	{"name":"氷の回廊","hint":"門の鍵と着弾予告を見よう","pairs":[[3,11]],"new":[3,11]},
	{"name":"白い跳躍","hint":"突進から離れ、横跳びの後を狙おう","pairs":[[2,12]],"new":[2,12]},
	{"name":"回廊の射線","hint":"壁で射線を切り、開いた門へ","pairs":[[12,4],[11,1]],"new":[4]},
	{"name":"狩人の足音","hint":"回り込む狼を正面へ誘導","pairs":[[5,11],[3,4]],"new":[5]},
	{"name":"交差する影","hint":"門だけでなく壁の端も通れる","pairs":[[10,5],[12,11]],"new":[]},
	{"name":"月下の追手","hint":"突進を壁に誘導しよう","pairs":[[2,4],[5,12]],"new":[]},
	{"name":"角の衛兵","hint":"ヤギの予告を横へ避けよう","pairs":[[13,11],[13,3]],"new":[13]},
	{"name":"仮面の間","hint":"射線と突進を同時に見よう","pairs":[[13,4],[12,5]],"new":[]},
	{"name":"梟王への道","hint":"開いた門と外周を使って決戦へ","pairs":[[13,5],[11,4],[10,12]],"new":[]},
]
