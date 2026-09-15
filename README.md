# Arcane Swarm — Frostfin Expedition

Godot 4 + GDScriptの、見下ろし視点3Dサバイバルです。
丸みのある立体パーツを組み合わせたキャラクターと、雪のアリーナを使用しています。
外部アセット・プラグイン・Blenderは不要です。

## 起動・操作

Godot 4で `project.godot` を開き、**F5（プロジェクト実行）**で開始します。

- **WASD**：移動（斜め移動も同じ速度）
- **射撃**：12m以内の最寄りの敵へ自動射撃
- **マウスホイール**：ズーム（12〜30、初期値20）
- **R**：ゲームオーバー後に再挑戦

`scenes/character_gallery.tscn` を開いて **F6** で、キャラクターを大きく表示するモデル一覧を起動できます。

## プレイヤー・武器

二頭身のコウテイペンギン。丸メガネ、黒と白の体、黄色い耳・首元、短い足、青緑のマフラーが特徴です。
歩くと体・翼・足が動き、停止中も頭がわずかに動きます。

魚型の氷ブラスター「Frostfin」は、銃身・金色のリング・背びれ・氷の結晶で構成しています。
体の向きと独立して照準を合わせ、銃口から氷弾を発射。反動とマズルフラッシュも付きます。
命中時は敵が縮み、氷の破片が散ります。撃破時は動物の色に合わせた破片が散ります。

## 動物の敵

| 種類 | 外見 | 行動 | 耐久力 | 接触ダメージ |
| --- | --- | --- | --- | --- |
| キツネ | 尖った耳、白い頬、大きな尻尾 | 尻尾を振り、左右にジグザグ接近 | 2発 | 10 |
| ウサギ | 長い耳、薄紫の毛、丸い尻尾 | 方向を決めて跳躍し、着地後に一拍休む | 2発 | 10 |
| イノシシ | 大きな鼻、牙、背中の剛毛 | 接近→0.8秒の予告→直線突進→1.1秒の休止 | 5発 | 18 |
| カメ | 模様のある甲羅、短い足 | ゆっくり一直線に追跡する高耐久型 | 8発 | 12 |

4種類が順番に出現します。攻撃を受けた敵にはHPバーが表示されます。
ウサギの跳躍は見た目と移動速度の変化であり、空中無敵にはなりません。
イノシシの橙色の線は突進方向の予告です。狙いは予告開始時に固定されます。

プレイヤーは接触後0.8秒間無敵です。敵は14〜19m離れたアリーナ内に出現します。
時間とともに出現間隔と移動速度が上がります。敵は最大100体、弾と演出には寿命があります。

## 構成

- `scenes/main.tscn`：ゲームの起動シーン
- `scenes/character_gallery.tscn`：モデル一覧の起動シーン
- `scripts/main.gd`：出現管理・標的選択・カメラ・HUD・再開
- `scripts/player.gd`：移動・HP・歩行・武器照準と反動
- `scripts/enemy.gd`：種類別ステータス・移動・突進の状態遷移・ダメージ
- `scripts/character_models.gd`：ペンギン、魚型ブラスター、4種類の動物の形状
- `scripts/visuals.gd`：形状生成と共通マテリアル・球メッシュのキャッシュ
- `scripts/projectile.gd`：氷弾と移動区間を使った命中判定
- `scripts/hit_effect.gd`：命中・撃破の破片演出
- `scripts/arena.gd`：照明・雪面・外周の木と装飾
- `scripts/character_gallery.gd`：モデル展示
- `tests/smoke_test.gd`：基本機能の統合テスト14項目
- `tests/animal_behaviors_test.gd`：動物の動作・耐久力・武器の統合テスト19項目

モデルはGDScriptから生成されます。`Head`、`WingLeft`、`Tail`などの名前付きNode3Dを関節として動かします。
色と形状は `character_models.gd`、敵の性能は `enemy.gd` の `STATS` で調整できます。

## 検証

Godot 4.7.2で統合テスト33項目が成功し、OpenGL Compatibilityの実画面でモデルとゲーム画面を確認済みです。

`godot` をGodot 4の実行ファイルのパスに置き換えて実行できます。

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/animal_behaviors_test.gd
```
