extends RefCounted
## Time-based pacing, independent of how lucky the weapon draws are.
## Continuous interpolation avoids sudden health or spawn-rate jumps at phase edges.
const PHASES := [
	{"time": 0.0, "name": "雪原の目覚め", "rate": 0.38, "cap": 10, "hp": 1.0, "speed": 1.65, "damage": 0.7, "weights": [100, 0, 0, 0]},
	{"time": 45.0, "name": "跳ねる足音", "rate": 0.52, "cap": 16, "hp": 1.0, "speed": 1.85, "damage": 0.8, "weights": [75, 25, 0, 0]},
	{"time": 90.0, "name": "甲羅の行進", "rate": 0.7, "cap": 24, "hp": 1.3, "speed": 2.0, "damage": 0.9, "weights": [55, 30, 0, 15]},
	{"time": 150.0, "name": "牙の群れ", "rate": 0.95, "cap": 36, "hp": 1.8, "speed": 2.2, "damage": 1.0, "weights": [40, 30, 20, 10]},
	{"time": 210.0, "name": "雪原の包囲", "rate": 1.4, "cap": 48, "hp": 2.4, "speed": 2.35, "damage": 1.1, "weights": [35, 30, 20, 15]},
	{"time": 300.0, "name": "吹雪の大群", "rate": 2.5, "cap": 68, "hp": 3.4, "speed": 2.5, "damage": 1.2, "weights": [30, 30, 25, 15]},
	{"time": 420.0, "name": "極寒の猛攻", "rate": 3.8, "cap": 88, "hp": 4.8, "speed": 2.7, "damage": 1.35, "weights": [25, 30, 25, 20]},
	{"time": 540.0, "name": "終わらない冬", "rate": 5.0, "cap": 100, "hp": 6.2, "speed": 2.9, "damage": 1.5, "weights": [25, 25, 30, 20]},
]
const FIRST_SPAWN := 3.0
const BOSS_INTERVAL := 120.0
const FINAL_BOSS_TIME := 600.0
const BOSS_SPAWN_RATE := 0.5
const BOSS_REST := 8.0


static func xp_for_level(level: int) -> int:
	var step := maxi(0, level - 1)
	return 12 + 8 * step + 2 * step * step


static func profile(seconds: float) -> Dictionary:
	var index := 0
	for candidate in range(PHASES.size()):
		if seconds >= PHASES[candidate].time:
			index = candidate
	var current: Dictionary = PHASES[index]
	var next: Dictionary = PHASES[mini(index + 1, PHASES.size() - 1)]
	var blend := clampf((seconds - current.time) / maxf(1.0, next.time - current.time), 0, 1)
	var result := current.duplicate(true)
	for key in ["rate", "hp", "speed", "damage"]:
		result[key] = lerpf(current[key], next[key], blend)
	result.cap = int(lerpf(current.cap, next.cap, blend))
	# Keep the endless phase challenging without infinite enemy counts or chase speed.
	result.hp += maxf(0, seconds - 540.0) / 90.0
	result.phase = index + 1
	return result


static func pick_kind(seconds: float, rng: RandomNumberGenerator) -> int:
	var weights: Array = profile(seconds).weights
	var roll := rng.randi_range(1, 100)
	for kind in range(weights.size()):
		roll -= int(weights[kind])
		if roll <= 0:
			return kind
	return 0
