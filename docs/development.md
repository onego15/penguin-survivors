# 開発・テスト

[READMEへ戻る](../README.md) · [武器](weapons.md) · [ステージ](stages.md) · [過去の検証記録](development-history.md)

## 実行環境

- Godot 4.7.2、GDScript、Compatibilityレンダラーで確認。
- `project.godot` をGodotで開き、F5でタイトルから実行。
- モデルはPrimitive Meshから生成。外部アセット・プラグイン・Blenderは不要。
- 通常プレイにはPython不要。音源の再生成だけPython 3の標準ライブラリを使います。

`scenes/character_gallery.tscn` を開いてF6でモデル一覧を起動できます。城のモデルや新武器の実画面は各ガイドと `docs/screenshots/` にあります。

## 主な構成

| 場所 | 役割 |
|---|---|
| `scenes/title.tscn` / `scripts/title_screen.gd` | タイトル・キャラとステージの選択 |
| `scenes/main.tscn` / `scripts/main.gd` | ゲーム進行・HUD・シーン間の接続 |
| `scripts/player.gd` / `character_roster.gd` | 移動・HP・キャラ定義 |
| `scripts/weapon_catalog.gd` / `weapon_system.gd` | 22武器の定義・強化・自動発動 |
| `scripts/weapon_attack.gd` / `advanced_attack.gd` | 武器の移動・命中・寿命 |
| `scripts/control_attack.gd` / `enemy_control.gd` / `udon_attack.gd` | 制御武器・状態異常・麺の往復と引き寄せ |
| `scripts/difficulty.gd` / `wave_director.gd` / `stage_catalog.gd` | 難易度・Wave・ステージ定義 |
| `scripts/castle_obstacles.gd` | 壁・門・経路探索・攻撃の遮断 |
| `scripts/enemy.gd` / `special_enemy.gd` / `castle_enemy.gd` | 通常敵の共通処理と固有行動 |
| `scripts/final_boss.gd` / `noctis.gd` / `final_battle_director.gd` | ラスボス・決戦増援と援護枠 |
| `scripts/game_audio.gd` / `assets/audio/` | BGM・効果音・ミュート |
| `tests/` | 自動テスト・自動操作による比較 |
| `tools/` | 音源生成・撮影・描画負荷の点検 |

表の短いファイル名も `scripts/` 内です。性能の正本はコードの定義値で、数値を変えるときは[武器](weapons.md)・[ステージ](stages.md)も合わせて更新します。

## 自動テストの実行

プロジェクトのルートから実行します。以下の `godot` はPATHに登録したGodot実行ファイル名です。Windowsでは使用するGodotのコンソール版exeのパスへ置き換えられます。

```sh
godot --headless --path . --script tests/weapons_test.gd
godot --headless --path . --script tests/control_weapons_test.gd
godot --headless --path . --script tests/castle_control_rebalance_test.gd
godot --headless --path . --script tests/castle_behavior_test.gd
```

| テスト | 主な確認内容 |
|---|---|
| `weapons_test.gd` | XP・抽選・蓄積・一時停止・武器の命中と寿命 |
| `upgrade_udon_ghost_test.gd` | Lv.5上限・候補枯渇・実際の強化値・麺・ゴースト |
| `control_weapons_test.gd` | ノックバック・凍結・耐性・中断・死亡解除 |
| `castle_control_rebalance_test.gd` | 城門跳躍・門貫通攻撃・長距離の引き寄せ |
| `castle_rules_test.gd` / `castle_behavior_test.gd` | 門・解禁順・武器遮断・敵とノクティスの挙動 |
| `pink_character_test.gd` / `bloom_test.gd` | キャラ選択・初期装備・ハート・回復必殺技 |
| `ultimate_test.gd` / `final_battle_test.gd` | 必殺技・手下・形態別の援護枠 |
| `wave_test.gd` / `support_test.gd` | Wave進行・サポートの抽選と同行 |

`control_balance_audit.gd` などの比較スクリプトは自動回避・固定装備の限定条件で動きます。通常プレイや人間の操作と同じ難易度を保証するものではありません。過去の実測値と測定条件は[検証記録](development-history.md)に保存しています。

ドキュメントのみの変更ではリンク・数値・表を確認します。挙動を変更した場合は対応テストと関連する回帰テストを実行し、表示変更はCompatibilityの実画面でも確認します。

## 音源

オリジナルの合成WAVを同梱。通常BGM・中ボス曲・ステージ別ラスボス第一／第二形態・祝勝曲があります。形態別曲は同じ再生位置から0.8秒でクロスフェード。M／Nのミュート設定は同一起動中の再挑戦へ引き継ぎます。

再生成はプロジェクトルートで次を実行します。既存の音源ファイルを書き換えます。

```sh
python tools/generate_audio.py
```

## スクリーンショット・動画

直近の撮影スクリプトは `tools/capture_castle_control_rebalance.gd` と `tools/capture_control_weapons.gd`。画面を使うため、`--headless` を付けずに実行します。撮影用に時間・装備・敵配置を設定し、`docs/screenshots/` の画像を更新します。

デモ動画の収録方法とフレーム検証は[動画のREADME](videos/README.md)へ。既存動画は雪原の過去バージョンです。最新機能の証拠として扱わず、現在の画面は各ガイドを参照してください。
